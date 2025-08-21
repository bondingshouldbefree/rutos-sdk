# Copyright (C) 2006-2014 OpenWrt.org
# Copyright (C) 2006 Fokus Fraunhofer <carsten.tittel@fokus.fraunhofer.de>
# Copyright (C) 2010 Vertical Communications

# color codes
CLR_RESET='\033[0m'

CLR_RED='\033[1;31m'
CLR_GREEN='\033[1;32m'
CLR_YELLOW='\033[1;33m'
CLR_BLUE='\033[1;34m'
CLR_CYAN='\033[1;36m'

debug () {
	${DEBUG:-:} "$@"
}

# newline
N="
"

_C=0
NO_EXPORT=1
LOAD_STATE=1
LIST_SEP=" "

# xor multiple hex values of the same length
xor() {
	local val
	local ret="0x$1"
	local retlen=${#1}

	shift
	while [ -n "$1" ]; do
		val="0x$1"
		ret=$((ret ^ val))
		shift
	done

	printf "%0${retlen}x" "$ret"
}

append() {
	local var="$1"
	local value="$2"
	local sep="${3:- }"

	eval "export ${NO_EXPORT:+-n} -- \"$var=\${$var:+\${$var}\${value:+\$sep}}\$value\""
}

to_lower() {
	tr '[A-Z]' '[a-z]' <<-EOF
		$@
	EOF
}

list_contains() {
	local var="$1"
	local str="$2"
	local val

	eval "val=\" \${$var} \""
	[ "${val%% $str *}" != "$val" ]
}

config_load() {
	[ -n "$IPKG_INSTROOT" ] && return 0
	uci_load "$@"
}

reset_cb() {
	config_cb() { return 0; }
	option_cb() { return 0; }
	list_cb() { return 0; }
}
reset_cb

package() {
	return 0
}

config () {
	local cfgtype="$1"
	local name="$2"

	export ${NO_EXPORT:+-n} CONFIG_NUM_SECTIONS=$((CONFIG_NUM_SECTIONS + 1))
	name="${name:-cfg$CONFIG_NUM_SECTIONS}"
	append CONFIG_SECTIONS "$name"
	export ${NO_EXPORT:+-n} CONFIG_SECTION="$name"
	config_set "$CONFIG_SECTION" "TYPE" "${cfgtype}"
	[ -n "$NO_CALLBACK" ] || config_cb "$cfgtype" "$name"
}

option () {
	local varname="$1"; shift
	local value="$*"

	config_set "$CONFIG_SECTION" "${varname}" "${value}"
	[ -n "$NO_CALLBACK" ] || option_cb "$varname" "$*"
}

list() {
	local varname="$1"; shift
	local value="$*"
	local len

	config_get len "$CONFIG_SECTION" "${varname}_LENGTH" 0
	[ $len = 0 ] && append CONFIG_LIST_STATE "${CONFIG_SECTION}_${varname}"
	len=$((len + 1))
	config_set "$CONFIG_SECTION" "${varname}_ITEM$len" "$value"
	config_set "$CONFIG_SECTION" "${varname}_LENGTH" "$len"
	append "CONFIG_${CONFIG_SECTION}_${varname}" "$value" "$LIST_SEP"
	[ -n "$NO_CALLBACK" ] || list_cb "$varname" "$*"
}

config_unset() {
	config_set "$1" "$2" ""
}

# config_get <variable> <section> <option> [<default>]
# config_get <section> <option>
config_get() {
	case "$2${3:-$1}" in
		*[!A-Za-z0-9_]*) : ;;
		*)
			case "$3" in
				"") eval echo "\"\${CONFIG_${1}_${2}:-\${4}}\"";;
				*)  eval export ${NO_EXPORT:+-n} -- "${1}=\${CONFIG_${2}_${3}:-\${4}}";;
			esac
		;;
	esac
}

# get_bool <value> [<default>]
get_bool() {
	local _tmp="$1"
	case "$_tmp" in
		1|on|true|yes|enabled) _tmp=1;;
		0|off|false|no|disabled) _tmp=0;;
		*) _tmp="$2";;
	esac
	echo -n "$_tmp"
}

# config_get_bool <variable> <section> <option> [<default>]
config_get_bool() {
	local _tmp
	config_get _tmp "$2" "$3" "$4"
	_tmp="$(get_bool "$_tmp" "$4")"
	export ${NO_EXPORT:+-n} "$1=$_tmp"
}

config_set() {
	local section="$1"
	local option="$2"
	local value="$3"

	export ${NO_EXPORT:+-n} "CONFIG_${section}_${option}=${value}"
}

config_foreach() {
	local ___function="$1"
	[ "$#" -ge 1 ] && shift
	local ___type="$1"
	[ "$#" -ge 1 ] && shift
	local section cfgtype

	[ -z "$CONFIG_SECTIONS" ] && return 0
	for section in ${CONFIG_SECTIONS}; do
		config_get cfgtype "$section" TYPE
		[ -n "$___type" ] && [ "x$cfgtype" != "x$___type" ] && continue
		eval "$___function \"\$section\" \"\$@\""
	done
}

config_list_foreach() {
	[ "$#" -ge 3 ] || return 0
	local section="$1"; shift
	local option="$1"; shift
	local function="$1"; shift
	local val
	local len
	local c=1

	config_get len "${section}" "${option}_LENGTH"
	[ -z "$len" ] && return 0
	while [ $c -le "$len" ]; do
		config_get val "${section}" "${option}_ITEM$c"
		eval "$function \"\$val\" \"\$@\""
		c="$((c + 1))"
	done
}

default_prerm() {
	local root="${IPKG_INSTROOT:-$(awk '/^dest root / { if ($3 != "/") print $3 }' /etc/opkg.conf)}"
	local pkgname="$(basename ${1%.*})"
	local ret=0

	if [ -f "$root/usr/lib/opkg/info/${pkgname}.prerm-pkg" ]; then
		( . "$root/usr/lib/opkg/info/${pkgname}.prerm-pkg" )
		ret=$?
	fi

	local shell="$(command -v bash)"
	for i in $(grep -s "^$root/etc/init.d/" "$root/usr/lib/opkg/info/${pkgname}.list"); do
		if [ -n "$IPKG_INSTROOT" ]; then
			${shell:-/bin/sh} "$root/etc/rc.common" "$root$i" disable
		else
			if [ "$PKG_UPGRADE" != "1" ]; then
				"$i" disable
			fi
			"$i" stop
		fi
	done

	#Remove config files from all profiles
	[ -f /usr/sbin/profile.sh ] && {
		/usr/sbin/profile.sh -p "$root/usr/lib/opkg/info/${pkgname}.list"
	}

	return $ret
}


set_config_owner() {
	local pkgname="$1"
	local uname="$2"
	local gname="$3"

	[ -e "$root/usr/lib/opkg/info/${pkgname}.conffiles" ] || return

	while IFS= read -r filepath; do
		chown "$uname:$gname" "$filepath"
	done < "$root/usr/lib/opkg/info/${pkgname}.conffiles"
}

add_group_and_user() {
	local pkgname="$1"
	local rusers="$(sed -ne 's/^Require-User: *//p' $root/usr/lib/opkg/info/${pkgname}.control 2>/dev/null)"
	local owner=0

	if [ -n "$rusers" ]; then
		local tuple oIFS="$IFS"
		for tuple in $rusers; do
			local uid gid uname gname

			IFS=":"
			set -- $tuple; uname="$1"; gname="$2"
			IFS="="
			set -- $uname; uname="$1"; uid="$2"
			set -- $gname; gname="$1"; gid="$2"
			IFS="$oIFS"

			if [ -n "$gname" ] && [ -n "$gid" ]; then
				group_exists "$gname" || group_add "$gname" "$gid"
			elif [ -n "$gname" ]; then
				gid="$(group_add_next "$gname")"
			fi

			if [ -n "$uname" ]; then
				user_exists "$uname" || user_add "$uname" "$uid" "$gid"
			fi

			if [ -n "$uname" ] && [ -n "$gname" ]; then
				group_add_user "$gname" "$uname"
			fi

			[ "$owner" -eq 0 ] && {
				set_config_owner "$pkgname" "$uname" "$gname"
				owner=1
			}

			unset uid gid uname gname
		done
	fi
}

add_user_groups() {
	local pkgname="$1"
	local groups="$(sed -ne 's/^UserGroups: *//p' $root/usr/lib/opkg/info/${pkgname}.control 2>/dev/null)"

	[ -n "$groups" ] || return

	local uname gnames gname
	local tuple oIFS="$IFS"

	IFS=":"
	set -- $groups; uname="$1"; gnames="$2"
	IFS="$oIFS"

	[ -n "$uname" ] || return
	for gname in $gnames; do
		group_exists "$gname" && group_add_user "$gname" "$uname"
	done
}

set_file_attributes() {
	local pkgname="$1"
	local attrs="$(sed -ne 's/^FileAttributes: *//p' "$root/usr/lib/opkg/info/${pkgname}.control" 2>/dev/null)"
	
	parse_attr_line() {
		local line="$1"
		local oIFS="$IFS"
		IFS=':'
		set -- $line ; binary="$1"; user="$2"; group="$3"; suid="$4"; caps="$5"
		IFS="$oIFS"
		[ -f "$root/$binary" ] || return
		[ "$in_fakeroot" = "y" ] && echo "processing $line"
		local user_id group_id
		user_id="$(awk -F: -v user="$user" '$1 == user { print $3 }' "${IPKG_INSTROOT}/etc/passwd")" 
		[ -z "$group" ] && [ -z "$user" ] && {
			user_id=0
			user="root"
		}
		[ -z "$group" ] && group_id="$(awk -F: -v user="$user" '$1 == user { print $4 }' "${IPKG_INSTROOT}/etc/passwd")" 
		[ -n "$group" ] && group_id="$(awk -F: -v group="$group" '$1 == group { print $3 }' "${IPKG_INSTROOT}/etc/group")" 
		[ -z "$user_id" -o -z "$group_id" ] && {
			echo "could not resolve user or group: $user($user_id):$group($group_id)"
			[ "$in_fakeroot" = "y" ] && exit 1
			user_id=0
			group_id=0
		}
		[ "$in_fakeroot" = "y" ] && set -e
		chown "$user_id:$group_id" "$root/$binary"
		[ "$suid" = "y" ] && chmod +s "$root/$binary"
		[ -n "$caps" ] && /usr/sbin/setcap "$caps" "$root/$binary"
		[ "$in_fakeroot" = "y" ] && set +e
	}

	[ -n "$attrs" ] || return
	local oIFS="$IFS"
	IFS=';'
	set -- $attrs ; while [ "$1" ] ; do
		parse_attr_line "$1"
		shift
	done
}

default_postinst() {
	local root="${IPKG_INSTROOT:-$(awk '/^dest root / { if ($3 != "/") print $3 }' /etc/opkg.conf)}"
	local pkgname="$(basename ${1%.*})"
	local filelist="$root/usr/lib/opkg/info/${pkgname}.list"
	local ret=0

	add_group_and_user "${pkgname}"
	add_user_groups "${pkgname}"
	set_file_attributes "${pkgname}"

	if [ -f "$root/usr/lib/opkg/info/${pkgname}.postinst-pkg" ]; then
		( . "$root/usr/lib/opkg/info/${pkgname}.postinst-pkg" )
		ret=$?
	fi

	if [ -d "$root/rootfs-overlay" ]; then
		cp -R $root/rootfs-overlay/. $root/
		rm -fR $root/rootfs-overlay/
	fi

	if [ -z "$IPKG_INSTROOT" ]; then
		if grep -m1 -q -s "^$root/etc/modules.d/" "$filelist"; then
			kmodloader
		fi

		if grep -m1 -q -s "^$root/usr/share/acl.d" "$filelist"; then
			kill -1 $(pgrep ubusd)
		fi

		if grep -m1 -q -s "^$root/etc/sysctl.d/" "$filelist"; then
			/etc/init.d/sysctl restart
		fi

		if grep -m1 -q -s "^$root/etc/uci-defaults/" "$filelist"; then
			uci_apply_defaults
		fi

		if grep -m1 -q -s "^$root/etc/permtab.d/" "$filelist"; then
			/sbin/perm -a
		fi

		rm -fr /tmp/luci-indexcache
	fi

	local shell="$(command -v bash)"
	grep -s "^$root/etc/init.d/" "$filelist" | while IFS= read -r i; do
		if [ -n "$IPKG_INSTROOT" ]; then
			${shell:-/bin/sh} "$root/etc/rc.common" "$root$i" enable
		else
			if [ "$PKG_UPGRADE" != "1" ]; then
				"$i" enable
			fi
			"$i" start
		fi
	done

	#Install config files to all profiles
	[ -f /usr/sbin/profile.sh ]  && {
		/usr/sbin/profile.sh -i "$filelist"
	}

	# restore /etc/config permissions
	[ -n "$IPKG_INSTROOT" ] || /sbin/perm /etc/config

	return $ret
}

include() {
	local file

	for file in $(ls $1/*.sh 2>/dev/null); do
		. $file
	done
}

find_mtd_index() {
	local PART="$(grep "\"$1\"" /proc/mtd | awk -F: '{print $1}')"
	local INDEX="${PART##mtd}"

	echo ${INDEX}
}

find_mtd_part() {
	local INDEX=$(find_mtd_index "$1")
	local PREFIX=/dev/mtdblock

	[ -d /dev/mtdblock ] && PREFIX=/dev/mtdblock/
	echo "${INDEX:+$PREFIX$INDEX}"
}

find_mmc_part() {
	local DEVNAME PARTNAME ROOTDEV

	if grep -q "$1" /proc/mtd; then
		echo "" && return 0
	fi

	if [ -n "$2" ]; then
		ROOTDEV="$2"
	else
		ROOTDEV="mmcblk*"
	fi

	for DEVNAME in /sys/block/$ROOTDEV/mmcblk*p*; do
		PARTNAME="$(grep PARTNAME ${DEVNAME}/uevent | cut -f2 -d'=')"
		[ "$PARTNAME" = "$1" ] && echo "/dev/$(basename $DEVNAME)" && return 0
	done
}

group_add() {
	local name="$1"
	local gid="$2"
	local rc
	[ -f "${IPKG_INSTROOT}/etc/group" ] || return 1
	[ -n "$IPKG_INSTROOT" ] || lock /var/lock/group
	echo "${name}:x:${gid}:" >> ${IPKG_INSTROOT}/etc/group
	[ -n "$IPKG_INSTROOT" ] || lock -u /var/lock/group
}

group_exists() {
	grep -qs "^${1}:" ${IPKG_INSTROOT}/etc/group
}

group_add_next() {
	local gid gids
	gid=$(grep -s "^${1}:" ${IPKG_INSTROOT}/etc/group | cut -d: -f3)
	if [ -n "$gid" ]; then
		echo $gid
		return
	fi
	gids=$(cut -d: -f3 ${IPKG_INSTROOT}/etc/group)
	gid=1000
	while echo "$gids" | grep -q "^$gid$"; do
		gid=$((gid + 1))
	done
	group_add $1 $gid
	echo $gid
}

group_add_user() {
	local grp delim=","
	grp=$(grep -s "^${1}:" ${IPKG_INSTROOT}/etc/group)
	echo "$grp" | cut -d: -f4 | grep -q $2 && return
	echo "$grp" | grep -q ":$" && delim=""
	[ -n "$IPKG_INSTROOT" ] || lock /var/lock/passwd
	sed -i "s/$grp/$grp$delim$2/g" ${IPKG_INSTROOT}/etc/group
	[ -n "$IPKG_INSTROOT" ] || lock -u /var/lock/passwd
}

user_add() {
	local name="${1}"
	local uid="${2}"
	local gid="${3}"
	local desc="${4:-$1}"
	local home="${5:-/var/run/$1}"
	local shell="${6:-/bin/false}"
	local rc
	[ -z "$uid" ] && {
		uids=$(cut -d: -f3 ${IPKG_INSTROOT}/etc/passwd)
		uid=1000
		while echo "$uids" | grep -q "^$uid$"; do
			uid=$((uid + 1))
		done
	}
	[ -z "$gid" ] && gid=$uid
	[ -f "${IPKG_INSTROOT}/etc/passwd" ] || return 1
	[ -n "$IPKG_INSTROOT" ] || lock /var/lock/passwd
	echo "${name}:x:${uid}:${gid}:${desc}:${home}:${shell}" >> ${IPKG_INSTROOT}/etc/passwd
	echo "${name}:x:0:0:99999:7:::" >> ${IPKG_INSTROOT}/etc/shadow
	[ -n "$IPKG_INSTROOT" ] || lock -u /var/lock/passwd
	[ -e "${IPKG_INSTROOT}${home}" ] || {
		mkdir -p -m 0775 "${IPKG_INSTROOT}${home}" && chown "$uid:$gid" "${IPKG_INSTROOT}${home}"
	}
}

user_exists() {
	grep -qs "^${1}:" ${IPKG_INSTROOT}/etc/passwd
}

board_name() {
	[ -e /tmp/sysinfo/board_name ] && cat /tmp/sysinfo/board_name || echo "generic"
}

cmdline_get_var() {
	local var=$1
	local cmdlinevar tmp

	for cmdlinevar in $(cat /proc/cmdline); do
		tmp=${cmdlinevar##${var}}
		[ "=" = "${tmp:0:1}" ] && echo ${tmp:1}
	done
}

check_compatibility() {
	local old_major="$1"
	local old_minor="$2"
	local dir="$3"
	local version="${dir##*/}"
	local uci_major="${version%%.*}"
	local uci_minor="${version#*.}"

	# ignore non-numeric directory names
	case "$uci_minor" in
		''|*[!0-9]*) uci_minor="" ;;
		*) ;;
	esac

	[ "$version" = "$uci_minor" ] && uci_minor=""

	[ -n "$uci_major" ] && [ -n "$uci_minor" ] || return 0
	[ "$uci_major" -lt "$old_major" ] && return 1
	[ "$uci_major" -eq "$old_major" ] && [ "$uci_minor" -lt "$old_minor" ] && return 1

	return 0
}

apply_defaults() {
	local dir="$1"

	find "$dir" -maxdepth 1 -type f | sort -V | while read -r file; do
		echo "uci-defaults: - executing $file -"
		( . "$file" ) && rm -f "$file"
	done
}

uci_apply_defaults() {
	echo "uci-defaults: - init -"

	local old_version="$(cat /etc/last_version 2>/dev/null)"
	local new_version="$(cat /etc/version)"
	local top_dir="/etc/uci-defaults"

	[ -z "$old_version" ] && old_version="$(uci -q get system.system.device_fw_version)"
	[ -z "$old_version" ] && old_version="$new_version"
	[ "$old_version" = "$new_version" ] || {
		uci set system.system.device_fw_version="$new_version"
		echo "$old_version" > /etc/last_version
	}
	[ -z "$(ls -A /etc/uci-defaults/)" ] && return

	local old_major=$(echo "$old_version" | awk -F . '{ print $2 }')
	local old_minor=$(echo "$old_version" | awk -F . '{ print $3 }')

	# do not execute legacy scripts when coming from 7.x
	[ "$old_major" -ge 7 ] && rm -rf ${top_dir}/001_rut*

	# do not execute old scripts when coming from 8.x
	[ "$old_major" -gt 7 ] && rm -rf ${top_dir}/old

	# do not execute old scripts when coming from 7.4.x
	[ "$old_major" -eq 7 ] && [ "$old_minor" -ge 4 ] && rm -rf ${top_dir}/old

	mkdir -p "/tmp/.uci"

	find "$top_dir" -maxdepth 1 -type d | sort -V | while read -r dir; do
		[ "$dir" == "$top_dir" ] && continue
		check_compatibility "$old_major" "$old_minor" "$(basename "$dir")" || continue
		apply_defaults "$dir"
	done

	# execute scripts that are from custom packages
	apply_defaults "$top_dir"

	uci commit
}

sync_permissions_and_ownerships() {
	src_dir="/rom/etc/config"
	dest_dir="/etc/config"

	for src_file in "$src_dir"/*; do
		[ -f "$src_file" ] || continue
		dest_file="$dest_dir/$(basename "$src_file")"
		[ -f "$dest_file" ] || continue

		permissions=$(ls -l "$src_file" | awk '{k=0;for(i=0;i<=8;i++)k+=((substr($1,i+2,1)~/[rwx]/)*2^(8-i));if(k)printf("%0o ",k)}')
		chmod $permissions "$dest_file"
		# Ownership is not saved in /rom, always owned by root
	done

	/sbin/perm -r /etc
}

fix_permissions()
{
	chmod $1 "$2"
	chown "$3" "$2"
}

[ -z "$IPKG_INSTROOT" ] && [ -f /lib/config/uci.sh ] && . /lib/config/uci.sh
