#!/bin/sh

. /usr/share/libubox/jshn.sh

bname=$(basename $0)
alias logger="logger -s -t $bname"

usage() {
	echo -e "\
Usage:
	$bname exfat|ext4 device [label]    format last inserted USB MSD, partition label is optional
	$bname devices                      list USB MSDs in json
	$bname unmount [device|mountpoint]  unmount an USB MSD
"
}

strstr() {
	[ "${1#*$2*}" != "$1" ]
}

refresh_msd() {
	sync
	partprobe $msd
	return 0
}

msdos_pt() {
	local r;
	sync
	for dev in $msd*; do
		[ -e $dev ] && r=$(umount -f $dev 2>&1)
		strstr "$r" "Resource busy" && {
			logger "$r"
			return 1
		}
	done

	dd if=/dev/zero of=$msd bs=1M count=16 conv=fsync || {
		logger "failed to clear partitions on $msd"
		return 1
	}

	refresh_msd

	[ "$1" = "ntfs" ] || [ "$1" = "exfat" ] && local system_id="7" || local system_id="83"
	# create msdos partition table with a single partition spanning the whole disk
	echo -e "o\nn\np\n1\n\n\nt\n$system_id\nw\n" | fdisk $msd || {
		logger "failed to create partition table on $msd"
		return 1
	}

	refresh_msd

	local c=0
	while [ $c -lt 60 ]; do
		[ -e $msd1 ] && return 0
		logger "waiting for $msd1..."
		c=$((c+1))
		sleep 1
	done

	logger "failed to create partition table on $msd: timed out waiting for device"
	return 1
}

is_sdcard() {
	[ "$(cat /sys/block/$1/device/type 2>&-)" = 'SD' ]
}

basedev() {
	local dev="$(readlink -f /sys/class/block/$(basename $1))"
	if [ ! -e "$dev/device" ]; then
		dev="$(readlink -f "$dev/..")"
	fi
	echo -n "$(basename "$dev")"
}

validate_set_msd() {
	local bd="$(basedev $1)" bi="$(block info | grep -m 1 $1)"

	local MOUNT="${bi##*MOUNT=\"}"
	MOUNT="${MOUNT%%\"*}"

	msd="/dev/$bd"
	if is_sdcard $bd; then
		msd1=$msd"p1"
	else
		msd1=$msd"1"
	fi

	[ ! -b "$msd" ] || [ "$MOUNT" = "/ext" ] && {
		logger "'$1' storage device unavailable"
		return 1
	}
	samba_in_use "$MOUNT" && {
		logger "'$1' storage device in use by samba"
		return 2
	}
	minidlna_in_use "$MOUNT" && {
		logger "'$1' storage device in use by minidlna"
		return 3
	}

	return 0
}

add_space_consumption() {
	local dev=$(df -h | grep "$1") || return

	local IFS=' ' c=0
	for w in $dev; do
		case $c in
		2)
			json_add_string used $w
		;;
		3)
			json_add_string available $w
		;;
		4)
			json_add_string used_percentage $w
		;;
		esac

		c=$((c + 1))
	done
}

samba_in_use() {
	local MOUNT="$1"
	killall -0 smbd 2>&- || return 1
	local dirs="$(uci show samba 2> /dev/null | grep -e 'sambashare\[[0-9]*\]\.path' | cut -f 2 -d '=')"
	for s in $dirs; do
		s=${s#\'}
		s=${s%\'}
		[ "$(readlink -f $s)" = "$MOUNT" ] && return 0
	done

	return 1
}

minidlna_in_use() {
	local MOUNT="$1"
	killall -0 minidlna 2>&- || return 1
	local IFS=$' ' lst="$(uci get minidlna.config.media_dir 2> /dev/null)"
	for s in $lst; do
		[ "$(readlink -f $s)" = "$MOUNT" ] && return 0
	done

	return 1
}

get_usb_device() {
	local file="/tmp/board.json"
	local path usb_jack
	path=$(readlink -f $1)
	usb_jack="$(jsonfilter -i $file -e '@.usb_jack')"
	strstr "$path" "$usb_jack" && echo usb || echo sd
}

add_description() {
	local path="/sys/block/$1/device"
	local description type

	if is_sdcard $1; then
		description="$(cat $path/name) $(cat $path/date)"
		type='sd'
	else
		description="$(cat $path/model)"
		type="$(get_usb_device $path)"
	fi

	# remove leading and trailing whitespaces
	description="${description#${description%%[![:space:]]*}}"
	description="${description%${description##*[![:space:]]}}"

	json_add_string type $type
	json_add_string description "$description"
}

extract_field() {
	local field="$1"
	local line="$2"

	strstr "$line" "$field" || return

	local value="${line#*${field}=\"}"
	value="${value%%\"*}"

	echo "$value"
}

json_list_device_stats() {
	local DEVICE=$(echo "$1" | cut -d: -f1)
	local bn=$(basename $DEVICE)
	local bd=$(basedev $bn)
	# skip devices with emmc
	[ "$bd" != "${bd#*mmcblk*}" ] &&
		[ "$(cat /sys/block/$bd/device/type)" = "MMC" ] && return 0

	local UUID=$(extract_field UUID $1)
	local MOUNT=$(extract_field MOUNT $1)
	local TYPE=$(extract_field TYPE $1)
	local LABEL=$(extract_field LABEL $1)
	local MOUNT=$(extract_field MOUNT $1)
	[ -z "$MOUNT" ] && return

	# if not /ext and not mounted on /usr/local/mnt/*, return
	local overlay_uuid="$(uci -q get fstab.overlay.uuid)"
	if [ -n "$overlay_uuid" ] && [ "$overlay_uuid" = "$UUID" ] && [ "$MOUNT" = "/ext" ]; then
		local is_overlay=1
	else
		[ -n "${MOUNT%%/usr/local/mnt/*}" ] && return 0
		local is_overlay=0
	fi

	json_add_object $bn
		json_add_string mountpoint $MOUNT
		json_add_string dev $DEVICE
		add_description $bd
		add_space_consumption $DEVICE
		[ -n "$TYPE" ] && json_add_string fs $TYPE
		[ -n "$LABEL" ] && json_add_string label $LABEL

		[ $is_overlay -eq 1 ] && json_add_string in_use memexp || {
			samba_in_use "$MOUNT" && json_add_string in_use samba
			minidlna_in_use "$MOUNT" && json_add_string in_use dlna
		}
		json_add_string status mounted
	json_close_object
}

devices() {
	local IFS=$'\n' block_list="$(block info | grep -E '^/dev/(sd|mmcblk[0-9])')"
	# IFS for loop to iterate over new lines and not spaces
	# block_list contains external storage devices and mmc cards (internal emmc has index of 0)
	json_init

	for line in $block_list; do
		json_list_device_stats "$line"
	done

	json_close_object
	json_dump -i
}

unmount() {
	local info=$(block info | grep -m 1 $1)
	[ -z "$info" ] && return 1

	local MOUNT="${info##*MOUNT=\"}"
	MOUNT="${MOUNT%%\"*}"
	[ -z "$MOUNT" ] && return 2

	umount $MOUNT || return 3
	rmdir $MOUNT

	local eject="$(readlink -f /sys/class/block/$(basename $1))"
	local subdir='/device/delete'
	local part="$eject/..$subdir"
	local unpart="$eject$subdir"
	if [ -e "$part" ]; then
		eject="$part"
	else
		eject="$unpart"
	fi
	echo 1 > "$eject"
}

blockdev_hotplug_pause() {
	local path='/tmp/.fmt-usb-msd_blockdev_hotplug_paused'
	if [ $1 -eq 1 ]; then
		touch $path
	else
		rm $path
	fi

	return 0
}

[ "$(id -u)" != 0 ] && {
	# Additional check: only users belonging to "mount" should be allowed
	[[ " $(id -nG) " =~ " mount" ]] || {
		logger "User($(id -u)) is not in \"mount\" group"
		exit 1
	}

	json_init
	json_add_array args
	for arg in "$@"; do
		json_add_string "" "$arg"
	done
	json_close_array

	# This must be ACL protected
	res=$(ubus -t 0 call rpc-format format "$(json_dump)")
	rc=$?
	[ $rc -eq 4 ] && logger "Access denied for user($(id -u))"
	[ $rc -ne 0 ] && exit $rc

	json_load "$res"
	json_get_vars output exit_code

	echo "$output"

	# Is ret_code a number?
	[ "$exit_code" -eq "exit_code" ] 2>/dev/null || exit 1

	exit $exit_code
}

case $1 in
	ntfs|exfat)
		validate_set_msd $2 || return
		blockdev_hotplug_pause 1
		msdos_pt $1 || return
		mkfs.exfat -L "$3" $msd1 || {
			logger "exfat volume creation failed"
			return 1
		}
		refresh_msd
		block mount
		blockdev_hotplug_pause 0
	;;
	ext?)
		validate_set_msd $2 || return
		blockdev_hotplug_pause 1
		msdos_pt $1 || return
		mkfs.ext4 -O ^has_journal -F -L "$3" $msd1 || {
			logger "EXT4 volume creation failed"
			return 1
		}
		refresh_msd
		block mount
		blockdev_hotplug_pause 0
	;;
	devices)
		devices
		return
	;;
	unmount)
		[ -z "$2" ] && { usage; return 1; }
		unmount $2
		return
	;;
	basedev)
		validate_set_msd $2 || return
		echo "$msd"
		return
	;;
	*)
		usage
		return 1
	;;
esac

[ $? -eq 0 ] && logger "$msd1 formatted successfully"
