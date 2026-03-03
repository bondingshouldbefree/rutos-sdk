FSB_PROC="/proc/bootconfig"
# Value 15 disables bootcounter
FSB_BOOTCNT_DEFAULT=15

fsb_get_chosen() {
	cat $FSB_PROC/chosen
}

fsb_commit() {
	echo 1 > $FSB_PROC/commit
}

# fsb_get_param <slot> <param>
fsb_get_param() {
	cat $FSB_PROC/"$1"/"$2"
}

# fsb_set_param <slot> <param> <value>
fsb_set_param() {
	echo "$3" > $FSB_PROC/"$1"/"$2"
}

fsb_get_upgrade_slot() {
	local chosen="$(fsb_get_chosen)"

	case "$chosen" in
	"rutos-a")
		echo "rutos-b"
		;;
	"rutos-b")
		echo "rutos-a"
		;;
	*)
		local a_prio="$(fsb_get_param rutos-a priority)"
		local b_prio="$(fsb_get_param rutos-b priority)"
		if [ "$a_prio" -gt "$b_prio" ]; then
			echo "rutos-b"
		else
			echo "rutos-a"
		fi
		;;
	esac
}

fsb_get_other_slot() {
	case "$1" in
	"rutos-a")
		echo "rutos-b"
		;;
	"rutos-b")
		echo "rutos-a"
		;;
	esac
}

fsb_upgrade_begin() {
	local new_primary="$1"
	local new_secondary="$(fsb_get_other_slot $new_primary)"

	fsb_set_param recovery force 0
	if [ "$(fsb_get_param recovery priority)" -ge 9 ]; then
		fsb_set_param recovery priority 1
	fi

	fsb_set_param "$new_secondary" force 0
	if [ "$(fsb_get_param $new_secondary priority)" -ge 9 ]; then
		fsb_set_param "$new_secondary" priority 8
	fi

	fsb_set_param "$new_primary" force 0
	fsb_set_param "$new_primary" priority 0
	fsb_set_param "$new_primary" successful_boot 0
	fsb_set_param "$new_primary" tries_remaining 3

	fsb_commit
}

fsb_upgrade_finalize() {
	local new_primary="$1"
	local new_secondary="$(fsb_get_other_slot $new_primary)"

	fsb_set_param "$new_primary" priority 9

	fsb_commit
}

fsb_init_bootconfig() {
	local primary="$1"
	local secondary="$(fsb_get_other_slot $primary)"

	fsb_set_param "$primary" force 0
	fsb_set_param "$primary" priority 9
	fsb_set_param "$primary" successful_boot 0
	fsb_set_param "$primary" tries_remaining "$FSB_BOOTCNT_DEFAULT"

	fsb_set_param "$secondary" force 0
	fsb_set_param "$secondary" priority 8
	fsb_set_param "$secondary" successful_boot 0
	fsb_set_param "$secondary" tries_remaining "$FSB_BOOTCNT_DEFAULT"

	fsb_set_param recovery force 0
	fsb_set_param recovery priority 0
	fsb_set_param recovery successful_boot 0
	fsb_set_param recovery tries_remaining "$FSB_BOOTCNT_DEFAULT"
}

fsb_get_mmc_block() {
	for part in /sys/block/mmcblk0/mmcblk0p*/uevent; do
		grep -qF "PARTNAME=$1" "$part" && {
			basename "${part%/uevent}"
			break
		}
	done
}

fsb_clean_old_slot() {
	local old_slot="$(fsb_get_other_slot "$1")"
	echo "failsafeboot: cleaning old slot: $old_slot. It may take a while ..." > /dev/kmsg

	if [ -d /sys/block/mmcblk0 ]; then
		local mmc_dev="/dev/$(fsb_get_mmc_block "$old_slot")"
		blkdiscard -s "$mmc_dev"
	else
		local mtd_dev="/dev/$(grep "$old_slot" /proc/mtd | cut -d: -f1)"
		ubiformat -q "$mtd_dev"
	fi

	echo "failsafeboot: $old_slot slot cleaned successfully" > /dev/kmsg
}

fsb_mark_boot_success() {
	local chosen="$1"

	fsb_set_param "$chosen" successful_boot 1
	fsb_set_param "$chosen" tries_remaining "$FSB_BOOTCNT_DEFAULT"

	fsb_commit
	logger -p 6 -t failsafeboot "slot '$1' marked as booted successfully"

	[ -f /etc/firstboot.flag ] && fsb_clean_old_slot "$chosen" && rm /etc/firstboot.flag
}
