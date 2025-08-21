#!/bin/sh
. /usr/share/libubox/jshn.sh

[ "$(id -u)" != 0 ] && {
	# This must be ACL protected
	res=$(ubus -t 0 call rpc-sys-ext troubleshoot ${1:+"{\"pass\":\"$1\"}"})
	rc=$?
	[ $rc -eq 4 ] && logger "Access denied for user($(id -u))"
	[ $rc -ne 0 ] && exit $rc

	json_load "$res"
	json_get_vars output exit_code

	echo -n "$output"

	# Is ret_code a number?
	[ "$exit_code" -eq "exit_code" ] 2>/dev/null || exit 1

	exit $exit_code
}

. /lib/functions.sh
. /lib/functions/libtroubleshoot.sh

PACK_DIR="/tmp/troubleshoot/"
ROOT_DIR="${PACK_DIR}root/"
DELTA_DIR="/tmp/delta/"
PACK_FILE="/tmp/troubleshoot.tar"
CENSORED_STR="VALUE_REMOVED_FOR_SECURITY_REASONS"
WHITE_LIST="
dropbear.@dropbear[0].PasswordAuth
dropbear.@dropbear[0].RootPasswordAuth
luci.flash_keep.passwd
mosquitto.mqtt.password_file
openvpn.teltonika_auth_service.persist_key
openvpn.teltonika_auth_service.auth_user_pass
rpcd.@login[0].username
rpcd.@login[0].password
rpcd.@rms_login[0].username
rpcd.@rms_login[0].password
uhttpd.main.key
uhttpd.hotspot.key
rms_mqtt.rms_mqtt.key_file
"
DIR_LIST="/etc/config /etc/crontabs /etc/dropbear /etc/firewall.user /etc/group /etc/hosts \
/etc/inittab /etc/passwd /etc/profile /etc/rc.local /etc/shells /etc/sysctl.conf \
/etc/uhttpd.crt /etc/uhttpd.key /etc/board.json"

#ignore sshfs mount dir if it on tmp directory
SSHFS_DIR=$(grep "fuse.sshfs" /etc/mtab | awk '{print $2}' | awk -F'/' '/^\/tmp\//{print $3}')

IGNORE_DIR_LIST="troubleshoot luci-indexcache luci-indexcache luci-modulecache firmware.img $SSHFS_DIR"

generate_random_str() {
	local out="$(tr </dev/urandom -dc A-Za-z0-9 2>/dev/null | head -c $1)"
	local is_ascii="$(echo -ne "$out" | strings)"

	if [ ${#is_ascii} -eq $1 ]; then
		echo "$out"
	fi
}

secure_tmp_config() {
	local value="$1"

	[ "${#value}" -lt 3 -o -f "$value" ] && return 0

	value="${value//\//\\/}"

	find "${ROOT_DIR}tmp/" \( -name "*.conf" -o -name "options*" -o -name "auth*" \) \
		-exec sed -i "s/ $value/$CENSORED_STR/g; s/\"$value\"/$CENSORED_STR/g" {} \;

	find "${ROOT_DIR}tmp/" \( -name "*.psk" -o -name "*secrets*" \) \
		-exec sed -i "s/$value/$CENSORED_STR/g" {} \;

	find "${ROOT_DIR}tmp/" -name "*localusers" \
		-exec sed -i "s/:$value:/:$CENSORED_STR:/g" {} \;

	find "${ROOT_DIR}tmp/" -name "hostapd*.conf" \
		-exec sed -i "s/=$value$/=$CENSORED_STR/g" {} \;
}

#FIXME: need optimization
secure_config() {
	local option value
	local lines="$(uci -c "$ROOT_DIR/etc/config" show |
		grep -iE "(\.)(.*)(pass|psw|pasw|psv|pasv|key|secret|username|id_scope|registration_id|x509certificate|x509privatekey)(.*)=" |
		grep -iE "((([A-Za-z0-9]|\_|\@|\[|\]|\-)*\.){2})(.*)(pass|psw|pasw|psv|pasv|key|secret|username|id_scope|registration_id|x509certificate|x509privatekey)(.*)=")"
	# local tmp_file=$(generate_random_str 64)

	local IFS=$'\n'
	mkdir "$DELTA_DIR"
	for line in $lines; do
		option="${line%%=\'*}"
		value="${line#*=\'}"
		value="${value%\'}"

		[ -n "$option" ] || continue

		echo "$WHITE_LIST" | grep -iqFx "$option"
		[ $? -ne 1 ] && continue

		secure_tmp_config "$value"
		uci -c "${ROOT_DIR}etc/config" -t "$DELTA_DIR" set "${option}=${CENSORED_STR}"
	done

	uci -c "$ROOT_DIR/etc/config" -t "$DELTA_DIR" commit
	rm -rf "$DELTA_DIR"

	local f fn
	for f in /etc/config/*; do
		fn="$ROOT_DIR/etc/config/$(basename $f)"
		[ -e "$fn" ] || continue
		touch -r "$f" "$fn"
	done
}

get_mnf_info() {
	local log_file="$1"
	local MNF_LIST="mac maceth name wps sn batch hwver"

	for arg in ${MNF_LIST}; do
		echo -ne "$arg:   \t" >>"$log_file"
		mnf_info --$arg >>"$log_file" 2>&1
	done

	# add SIMCFG info
	for idx in $(seq 1 4); do
		local simcfg="$(mnf_info -C $idx 2> /dev/null)"
		[ -n "$simcfg" ] && echo -e "sim${idx}_cfg:   \t${simcfg}" >>"$log_file"
	done
}

get_blver() {
	local log_file="$1"
	mnf_info --blver >>"$log_file" 2>&1
}

system_hook() {
	local log_file="${PACK_DIR}sysinfo.log"

	troubleshoot_init_log "SYSTEM INFORMATION" "$log_file"
	get_mnf_info "$log_file"

	ubus list sim &>/dev/null && {
		troubleshoot_init_log "Active SIM]" "$log_file"
		troubleshoot_add_log "$(ubus call gsm.modem0 get_sim_slot)" "$log_file"
	}

	troubleshoot_init_log "Firmware version" "$log_file"
	troubleshoot_add_file_log "/etc/version" "$log_file"

	troubleshoot_init_log "Bootloader version" "$log_file"
	get_blver "$log_file"

	troubleshoot_init_log "Time" "$log_file"
	troubleshoot_add_log "$(date)" "$log_file"

	troubleshoot_init_log "Uptime" "$log_file"
	troubleshoot_add_log "$(uptime)" "$log_file"
	[ -e /proc/version ] && {
		troubleshoot_init_log "Build string" "$log_file"
		troubleshoot_add_file_log "/proc/version" "$log_file"
	}
	[ -e /proc/mtd ] && {
		troubleshoot_init_log "Flash partitions" "$log_file"
		troubleshoot_add_file_log "/proc/mtd" "$log_file"
	}
	[ -e /proc/meminfo ] && {
		troubleshoot_init_log "Memory usage" "$log_file"
		troubleshoot_add_file_log "/proc/meminfo" "$log_file"
	}

	troubleshoot_init_log "Filesystem usage statistics" "$log_file"
	troubleshoot_add_log "$(df -h)" "$log_file"

	[ -d /log ] && {
		troubleshoot_init_log "Log dir" "$log_file"
		troubleshoot_add_log "$(ls -al /log/)" "$log_file"
	}

	[ -d "/sys/bus/usb" ] && {
		troubleshoot_init_log "USB DEVICES" "$log_file"
		troubleshoot_add_log "$(lsusb)" "$log_file"
	}

	troubleshoot_init_log "UBUS METHODS" "$log_file"
	troubleshoot_add_log "$(ubus list)" "$log_file"

	ubus list ip_block &>/dev/null && {
		troubleshoot_init_log "IP BLOCK" "$log_file"
		troubleshoot_add_log "$(ubus call ip_block show)" "$log_file"
	}
}

switch_hook() {
	local ethernet dsa
	local log_file="${PACK_DIR}switch.log"

	ethernet="$(jsonfilter -i /etc/board.json -e '@.hwinfo.ethernet')"
	[ "$ethernet" = "true" ] || return

	dsa="$(jsonfilter -i /etc/board.json -e '@.hwinfo.dsa')"
	if [ "$dsa" = "true" ]; then
		troubleshoot_init_log "VLANS" "$log_file"
		troubleshoot_add_log_ext "bridge" "vlan" "$log_file"
		troubleshoot_init_log "FDB" "$log_file"
		troubleshoot_add_log_ext "bridge" "fdb" "$log_file"
	else
		troubleshoot_init_log "Switch configuration" "$log_file"
		swconfig list | grep -q "switch0" &&
			troubleshoot_add_log_ext "swconfig" "dev switch0 show" "$log_file"
	fi
}

wifi_hook() {
	local wifi __tmp devname
	local log_file="${PACK_DIR}wifi.log"
	local mt76_debug_path="/sys/kernel/debug/ieee80211/phy0/mt76/reset"

	wifi="$(jsonfilter -i /etc/board.json -e '@.hwinfo.wifi')"
	[ "$wifi" = "true" ] && [ -n "$(which iw)" ] || return

	__tmp="$(ubus call network.wireless status 2>&1)"
	__cmd="$(jsonfilter -s "$__tmp" -e "wifaces=@.*.interfaces[@].ifname")"
	eval "$__cmd"

	[ -z "$wifaces" ] && return

	troubleshoot_init_log "WiFi interfaces" "$log_file"

	for devname in ${wifaces}; do
		troubleshoot_add_log "*Interface ${devname}*" "$log_file"
		troubleshoot_add_log "$(iwinfo "$devname" info)\n" "$log_file"

		troubleshoot_add_log "*Clients*" "$log_file"
		troubleshoot_add_log "$(iwinfo "$devname" assoclist)\n" "$log_file"
	done

	[ -e "$mt76_debug_path" ] && {
		troubleshoot_init_log "MT76 reset statistics" "$log_file"
		troubleshoot_add_file_log "$mt76_debug_path" "$log_file"
	}
}

systemlog_hook() {
	local log_flash_file
	local log_file="${PACK_DIR}system.log"

	troubleshoot_init_log "LOGGING INFORMATION" "$log_file"
	troubleshoot_init_log "Dmesg" "$log_file"
	troubleshoot_add_log "$(dmesg)" "$log_file"

	config_load system
	config_get log_flash_file system "log_file" ""

	troubleshoot_init_log "Logread" "$log_file"
	if [ -n "$log_flash_file" ] && [ -f "$log_flash_file" ] ; then
		local rotated_logs file
		# shellcheck disable=SC2010
		rotated_logs=$(ls -v "$(dirname "$log_flash_file")" | grep -i -E "$(basename "$log_flash_file").[0-9]+($|.gz)")
		for log in $rotated_logs ; do
			troubleshoot_init_log "Logfile $log" "$log_file"
			file="$(dirname "$log_flash_file")/$log"
			if [ "${file: -3}" != ".gz" ] ; then
				cat "$file" >> "$log_file"
			else
				zcat "$file" >> "$log_file"
			fi
		done
		troubleshoot_init_log "Logfile $(basename "$log_flash_file")" "$log_file"
		troubleshoot_add_file_log "$log_flash_file" "$log_file"
	else
		troubleshoot_add_log "$(logread)" "$log_file"
	fi
}

cloud_solutions_hook() {
	local log_file="${PACK_DIR}cloud_solutions.log"

	troubleshoot_init_log "CLOUD SOLUTIONS INFO" "$log_file"

	# RMS
	troubleshoot_add_log "RMS" "$log_file"
	rms_ubus_res=$(ubus call rms get_status 2>&1)
	rms_json_res=$(rms_json -p -v 18446744073709551615 -v 127 2>&1)
	printf "%s:\n%s\n\n%s\n" "rms get_status" "$rms_ubus_res" "$rms_json_res" >> "$log_file"
}

services_secure_passwords() {
	local file="$1"
	local lines passwd

	lines=$(grep "ppp\.sh" "$file")

	OLD_IFS="$IFS"
	IFS=$'\n'
	for line in $lines; do
		passwd=${line#*password\":\"}
		passwd="${passwd%\"*}"

		sed -i "s/$passwd/$CENSORED_STR/g" "$file"
	done
	IFS="$OLD_IFS"

	passwd=$(uci -q get modbusgateway.gateway.pass)
	[ -n "$passwd" ] &&
		sed -i "s/\"$passwd\"/$CENSORED_STR/g" "$file"

	passwd=$(uci -q get iottw.thingworx.appkey)
	[ -n "$passwd" ] &&
		sed -i "s/\"$passwd\"/$CENSORED_STR/g" "$file"
}

services_hook() {
	local log_file="${PACK_DIR}services.log"

	troubleshoot_init_log "Process activity" "$log_file"
	troubleshoot_add_log "$(top -b -n 1)" "$log_file"

	troubleshoot_init_log "SERVICES" "$log_file"
	troubleshoot_add_log "$(ubus call service list)" "$log_file"

	if [ -z "$1" ]; then
		services_secure_passwords "$log_file"
	fi
}

package_manager_hook() {
	local log_file="${PACK_DIR}package_manager.log"

	opkg_packets=""
	[ -d "/usr/lib/opkg/info" ] && [ "$(ls -A /usr/lib/opkg/info/*.control 2>/dev/null)" ] &&
		opkg_packets=$(grep -l "Router:" /usr/lib/opkg/info/*.control 2>/dev/null)
	[ -d "/usr/local/lib/opkg/info" ] && [ "$(ls -A /usr/local/lib/opkg/info/*.control 2>/dev/null)" ] &&
		opkg_packets="$opkg_packets $(grep -l "Router:" /usr/local/lib/opkg/info/*.control 2>/dev/null)"
	[ -z "$opkg_packets" ] && return

	troubleshoot_init_log "Installed packages from PM" "$log_file"
	troubleshoot_add_log "" "$log_file"

	for packet in $opkg_packets; do
		source_name=$(grep "SourceName:" "$packet" | awk -F ": " '{print $2}')
		troubleshoot_add_log "$source_name" "$log_file"
	done
}

serial_hook() {
	local log_file="${PACK_DIR}serial.log"

	file_list="/dev/rs232 /dev/rs485 /dev/mbus /dev/rsconsole"
	for file in $file_list; do
		if [ ! -e "$file" ]; then
			continue
		fi

		output=$(stty -F "$file" -a 2>/dev/null)
		info="Output for $file:\n$output"
		troubleshoot_add_log "$info" "$log_file"
	done

	file_list=$(ls /dev/usb_serial* 2>/dev/null)
	for file in $file_list; do
		output=$(stty -F "$file" -a 2>/dev/null)
		info="Output for $file:\n$output"
		troubleshoot_add_log "$info" "$log_file"
	done
}

generate_root_hook() {
	mkdir "$ROOT_DIR"
	mkdir "${ROOT_DIR}/etc"
	mkdir "${ROOT_DIR}/tmp"
	for file in $(ls /tmp/); do
		[ "$(echo ${IGNORE_DIR_LIST} | grep -wc ${file})" -gt 0 ] && continue
		[ -d "/tmp/${file}" ] && grep -q "/tmp/${file} " /proc/mounts && continue

		cp -prf "/tmp/${file}" "${ROOT_DIR}/tmp"
	done

	cp -pr ${DIR_LIST} "${ROOT_DIR}/etc"
	secure_config
}

generate_package() {
	cd /tmp || return

	if [ -z "$1" ]; then
		tar -czf "${PACK_FILE}.gz" troubleshoot >/dev/null 2>&1
	else
		tar -cf "$PACK_FILE" troubleshoot >/dev/null 2>&1
		which minizip >/dev/null || {
			echo "Could not create troubleshoot.tar.zip - minizip package is not installed";
			rm -f "$PACK_FILE"
			exit 1
		}
		minizip -s -p "$1" "${PACK_FILE}.zip" "$PACK_FILE" >/dev/null 2>&1
	fi

	rm -r "$PACK_DIR"
	rm -f "$PACK_FILE"
	rm -f "$TMP_LOG_FILE"
}

init() {
	rm -r "$PACK_DIR" >/dev/null 2>&1

	if [ -z  "$1" ]; then
		rm "${PACK_FILE}.gz" >/dev/null 2>&1
	else
		rm "${PACK_FILE}.zip" >/dev/null 2>&1
	fi

	mkdir "$PACK_DIR"
}

exec 200>"/var/run/troubleshoot.lock"
flock -n 200 || { echo "troubleshoot instance is already running"; exit 1; }

init "$1"

troubleshoot_hook_init system_hook
troubleshoot_hook_init switch_hook
troubleshoot_hook_init wifi_hook
troubleshoot_hook_init services_hook "$1"
troubleshoot_hook_init systemlog_hook
troubleshoot_hook_init cloud_solutions_hook
troubleshoot_hook_init package_manager_hook
troubleshoot_hook_init serial_hook

#init external hooks
for tr_source_file in /lib/troubleshoot/* /usr/local/lib/troubleshoot/*; do
	[ -f "$tr_source_file" ] && . "$tr_source_file"
done

troubleshoot_hook_init generate_root_hook
troubleshoot_run_hook_all

generate_package "$1"

exec 200>&-
