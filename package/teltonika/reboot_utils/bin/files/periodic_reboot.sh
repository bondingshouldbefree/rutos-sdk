#!/bin/sh

. /usr/share/libubox/jshn.sh
. /lib/functions.sh

DFOTA_LOCK="/var/lock/modem_dfota.lock"

log() {
	/usr/bin/logger -t periodic_reboot.sh "$@"
}

get_modem_num() {

	local modem="$1"
	local found_modem=""

	local modem_objs=$(ubus list gsm.*)

	for i in $modem_objs
	do
		found_modem=$(ubus call "$i" info 2> /dev/null | grep usb_id | sed 's/.* //g')
		[ "$modem" == "${found_modem:1:-2}" ] && echo "${i//[!0-9]/}" && return 0
	done

	return 1
}

get_modem() {
	local modem modems id builtin primary
	local primary_modem builtin_modem

	json_init
	json_load "$(cat /etc/board.json)"
	json_get_keys modems modems
	json_select modems

	for modem in $modems; do
		json_select "$modem"
		json_get_vars builtin primary id
		[ -n "$builtin" ] && [ -n "$id" ] && builtin_modem=$id
		[ -n "$primary" ] && [ -n "$id" ] && {
			primary_modem=$id
			break
		}
		json_select ..
	done

	[ -n "$primary_modem" ] && {
		echo "$primary_modem"

		return 0
	}

	if [ -z "$builtin_modem" ]; then
		json_load "$(/bin/ubus call gsm.modem0 info)"
		json_get_vars usb_id
		primary_modem="$usb_id"
	else
		primary_modem=$builtin_modem
	fi

	echo "$primary_modem"
}

reboot_modem() {
	local sec=$1
	local modem_id

	config_get modem_id "$sec" modem
	[ -n "$modem_id" ] || modem_id=$(get_modem)
	[ -n "$modem_id" ] || {
		log "Failed to get modem id"
		return 1
	}

	ubus call mctl reboot "{\"id\":\"$modem_id\"}"
}

reboot_device() {
	log "Rebooting device"
	ubus call rpc-sys reboot "{\"safe\":true,\"args\":[\"-e\"]}"
}


preboot_lock() {
	[ -e "$DFOTA_LOCK" ] && {
		[ -r "$DFOTA_LOCK" ] && [ -w "$DFOTA_LOCK" ] || {
			log "Insufficient permissions to access $DFOTA_LOCK"

			return 0
		}
		lock -n "$DFOTA_LOCK" || {
			return 1
		}
	}

	return 0
}

perform_reboot() {
	local sec=$1
	local action

	config_load periodic_reboot
	config_get action "$sec" action
	[ -z "$action" ] && {
		log "Action is not set"
	}

	#Lock only if the lock file exists to avoid creating a file with a different ownership
	[ -e "$DFOTA_LOCK" ] && [ -r "$DFOTA_LOCK" ] && [ -w "$DFOTA_LOCK" ] && {
		lock "$DFOTA_LOCK" || log "Failed to access lock. Insufficient permissions?"
	}

	case $action in
		1)
			reboot_device;;
		2)
			
			reboot_modem "$sec";;
	esac

	[ -e "$DFOTA_LOCK" ] && lock -u "$DFOTA_LOCK"
}

perform_reboot "$1"
