
# This file contains functions related to mobile management for ping reboot functionality

get_modem_num() {
	local modem="$1"
	local found_modem=""

	local modem_objs=$(ubus list gsm.*)

	for i in $modem_objs
	do
		found_modem=$(ubus call "$i" info 2> /dev/null | grep usb_id | sed 's/.* //g')
		[ "$modem" = "${found_modem:1:-2}" ] && echo "${i//[!0-9]/}" && return 0
	done

	return 1
}

restart_modem() {
	/bin/ubus -t 20 call mctl reboot "{\"id\":\"$1\"}"
}

restart_mobile_interface() {
	local interface="$1"

	[ -n "$interface" ] || {
		log "No active mobile interface found."

		return
	}

	ubus -t 10 call network.interface down "{\"interface\": \"${interface}\"}" 2>/dev/null
	sleep 1
	ubus -t 10 call network.interface up "{\"interface\": \"${interface}\"}" 2>/dev/null
}

get_l3_device() {
	local interface=$1
	local suffix=$2
	local sim="$3"

	local status=$(ubus call network.interface status "{ \"interface\" : \"${interface}${suffix}\" }" 2>/dev/null)
	[ -z "$status" ] && return

	json_init
	json_load "$status"
	json_get_var up "up"

	[ "$up" -ne 1 ] && return

	ACTIVE_MOBILE_IFACES="$ACTIVE_MOBILE_IFACES $interface"

	json_get_var l3_device "l3_device"
	DEV_IFACE_MAP=$(kvmap_insert "$DEV_IFACE_MAP" "$l3_device" "$interface")
	# IF_OPTION contains list of ifnames (e.g. "qmimux0")
	if [ "$sim" = "2" ]; then
		! list_contains IF_OPTION2 "$l3_device" && IF_OPTION2="$IF_OPTION2 $l3_device"
	else
		! list_contains IF_OPTION1 "$l3_device" && IF_OPTION1="$IF_OPTION1 $l3_device"
	fi
}

get_dual_modem_sim_slot()
{
	local modem_id="$1"

	json_select ..
	json_get_keys modems modems
	json_select modems
	for modem in $modems; do
		json_select "$modem"
		json_get_vars id builtin primary >/dev/null 2>&1
		[ "$id" != "$modem_id" ] && {
			json_select ..
			continue
		}

		if [ "$builtin" -eq 1 ] && { [ -z "$primary" ] || [ "$primary" -eq 0 ]; }; then
			echo "2"
			return
		else
			echo "1"
			return
		fi
	done
}

get_active_mobile_interface() {
	local section_name="$1"

	config_get modem "$section_name" "modem"
	config_get sim "$section_name" sim

	[ -z "$modem" ] && return

	json_load_file "/etc/board.json"
	json_select hwinfo
	json_get_var dual_modem dual_modem >/dev/null 2>&1
	[  -n "$dual_modem" ] && [ "$dual_modem" -eq 1 ] && {
		DUAL_MODEM=1
		sim=$(get_dual_modem_sim_slot "$modem")
	}

	# Check IPv6, IPv4 and legacy interface names for an l3_device
	#FIXME: what if IPV4 type selected but IPV6 interface is available?
	get_l3_device "$section_name" "_6" "$sim"
	get_l3_device "$section_name" "_4" "$sim"
	if [ \( -z "$IF_OPTION1" -a "$sim" = "1" \) ] || [ \( -z "$IF_OPTION2" -a "$sim" = "2" \) ]; then
		get_l3_device "$section_name" "" "$sim"
	fi
}

get_modem() {
	local modem modems id builtin primary
	local primary_modem=""
	local builtin_modem=""
	json_init
	json_load_file "/etc/board.json"
	json_get_keys modems modems
	json_select modems || return

	for modem in $modems; do
		json_select "$modem"
		json_get_vars builtin primary id

		[ -z "$id" ] && {
			json_select ..
			continue
		}

		[ "$builtin" ] && builtin_modem=$id
		[ "$primary" ] && {
			primary_modem=$id
			break
		}

		json_select ..
	done

	[ -n "$primary_modem" ] && {
		MODEM=$primary_modem
		return
	}

	if [ -n "$builtin_modem" ]; then
		primary_modem=$builtin_modem
	else
		json_load "$(/bin/ubus call gsm.modem0 info)"
		json_get_vars usb_id
		primary_modem="$usb_id"
	fi

	MODEM=$primary_modem
}

send_sms() {
	local modem_num=$(get_modem_num "$MODEM")
	for phone in $PHONE_LIST; do
		local res=$(ubus call gsm.modem"$modem_num" send_sms "{\"number\":\"${phone}\", \"text\": \"${MESSAGE}\"}")
		res=$(echo "$res" | grep -o OK)

		if [ "$res" != "OK" ]; then
			set_fail_counter "$CURRENT_TRY"
		fi
	done
}

is_over_limit() {
	local iface="$1"
	local over_limit

	if [ "$STOP_ACTION" -eq 1 ]; then
		local res=$(ubus call quota_limit.${iface} status)
		if [ -z "$res" ]; then
			return 1 # limit not enabled
		fi
		json_init
		json_load "$res"
		json_get_var over_limit "event_sent"
	else
		over_limit=0
	fi

	[ "$over_limit" -eq 1 ]
}
