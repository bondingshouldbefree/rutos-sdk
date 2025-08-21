#!/bin/ash

. /lib/functions.sh
. /usr/share/libubox/jshn.sh

[ -f "/lib/functions/mobile.sh" ] && \
	. /lib/functions/mobile.sh

json_select_array() {
	local _json_no_warning=1

	json_select "$1"
	[ $? = 0 ] && return

	json_add_array "$1"
	json_close_array

	json_select "$1"
}

json_select_object() {
	local _json_no_warning=1

	json_select "$1"
	[ $? = 0 ] && return

	json_add_object "$1"
	json_close_object

	json_select "$1"
}

ucidef_set_interface() {
	local network=$1; shift

	[ -z "$network" ] && return

	json_select_object network
	json_select_object "$network"

	while [ -n "$1" ]; do
		local opt=$1; shift
		local val=$1; shift

		[ -n "$opt" -a -n "$val" ] || break

		[ "$opt" = "device" -a "$val" != "${val/ //}" ] && {
			json_select_array "ports"
			for e in $val; do json_add_string "" "$e"; done
			json_close_array
		} || {
			json_add_string "$opt" "$val"
		}
	done

	if ! json_is_a proto string; then
		case "$network" in
			lan) json_add_string proto static ;;
			wan) json_add_string proto dhcp ;;
			*) json_add_string proto none ;;
		esac
	fi

	json_select ..
	json_select ..
}

ucidef_set_interface_default_macaddr() {
	local network="$1" ifname

	json_select_object 'network'
		json_select_object "$network"
		if json_is_a ports array; then
			json_select_array 'ports'
			json_get_keys port_id
			for i in $port_id; do
				json_get_var port "$i"
				ifname="${ifname} $port"
			done
			json_select ..
		else
			json_get_var ifname 'device'
		fi
		json_select ..
	json_select ..

	for i in $ifname; do
		local macaddr="$2"; shift
		[ -n "$macaddr" ] || break
		json_select_object 'network-device'
			json_select_object "$i"
				json_add_string 'macaddr' "$macaddr"
			json_select ..
		json_select ..
	done
}

ucidef_set_board_id() {
	json_select_object model
	json_add_string id "$1"
	json_select ..
}

ucidef_set_board_platform() {
	json_select_object model
	json_add_string platform "$1"
	json_select ..
}

ucidef_set_model_name() {
	json_select_object model
	json_add_string name "$1"
	json_select ..
}

ucidef_set_compat_version() {
	json_select_object system
	json_add_string compat_version "${1:-1.0}"
	json_select ..
}

ucidef_set_interface_lan() {
	ucidef_set_interface "lan" device "$1" proto "${2:-static}"
}

ucidef_set_interface_wan() {
	ucidef_set_interface "wan" device "$1" proto "${2:-dhcp}"
}

ucidef_set_interfaces_lan_wan() {
	local lan_if="$1"
	local wan_if="$2"

	ucidef_set_interface_lan "$lan_if"
	ucidef_set_interface_wan "$wan_if"
}

_ucidef_add_switch_port() {
	# inherited: $num $device $need_tag $want_untag $role $index $prev_role
	# inherited: $n_cpu $n_ports $n_vlan $cpu0 $cpu1 $cpu2 $cpu3 $cpu4 $cpu5

	n_ports=$((n_ports + 1))

	json_select_array ports
		json_add_object
			json_add_int num "$num"
			[ -n "$device"     ] && json_add_string  device     "$device"
			[ -n "$need_tag"   ] && json_add_boolean need_tag   "$need_tag"
			[ -n "$want_untag" ] && json_add_boolean want_untag "$want_untag"
			[ -n "$role"       ] && json_add_string  role       "$role"
			[ -n "$index"      ] && json_add_int     index      "$index"
			[ -n "$sfp"        ] && json_add_boolean sfp	    "$sfp"
		json_close_object
	json_select ..

	# record pointer to cpu entry for lookup in _ucidef_finish_switch_roles()
	[ -n "$device" ] && {
		export "cpu$n_cpu=$n_ports"
		n_cpu=$((n_cpu + 1))
	}

	# create/append object to role list
	[ -n "$role" ] && {
		json_select_array roles

		if [ "$role" != "$prev_role" ]; then
			json_add_object
				json_add_string role "$role"
				json_add_string ports "$num"
			json_close_object

			prev_role="$role"
			n_vlan=$((n_vlan + 1))
		else
			json_select_object "$n_vlan"
				json_get_var port ports
				json_add_string ports "$port $num"
			json_select ..
		fi

		json_select ..
	}
}

_ucidef_finish_switch_roles() {
	# inherited: $name $n_cpu $n_vlan $cpu0 $cpu1 $cpu2 $cpu3 $cpu4 $cpu5
	local index role roles num device need_tag want_untag port ports

	json_select switch
		json_select "$name"
			json_get_keys roles roles
		json_select ..
	json_select ..

	for index in $roles; do
		eval "port=\$cpu$(((index - 1) % n_cpu))"

		json_select switch
			json_select "$name"
				json_select ports
					json_select "$port"
						json_get_vars num device need_tag want_untag
					json_select ..
				json_select ..

				if [ ${need_tag:-0} -eq 1 -o ${want_untag:-0} -ne 1 ]; then
					num="${num}t"
					device="${device}.${index}"
				fi

				json_select roles
					json_select "$index"
						json_get_vars role ports
						json_add_string ports "$ports $num"
						json_add_string device "$device"
					json_select ..
				json_select ..
			json_select ..
		json_select ..

		json_select_object network
			local devices

			json_select_object "$role"
				# attach previous interfaces (for multi-switch devices)
				json_get_var devices device
				if ! list_contains devices "$device"; then
					devices="${devices:+$devices }$device"
				fi
			json_select ..
		json_select ..

		ucidef_set_interface "$role" device "$devices"
	done
}

ucidef_set_ar8xxx_switch_mib() {
	local name="$1"
	local type="$2"
	local interval="$3"

	json_select_object switch
		json_select_object "$name"
			json_add_int ar8xxx_mib_type $type
			json_add_int ar8xxx_mib_poll_interval $interval
		json_select ..
	json_select ..
}

ucidef_add_switch() {
	local enabled=1
	if [ "$1" = "enabled" ]; then
		shift
		enabled="$1"
		shift
	fi

	local name="$1"; shift
	local port num role device index need_tag prev_role sfp
	local cpu0 cpu1 cpu2 cpu3 cpu4 cpu5
	local n_cpu=0 n_vlan=0 n_ports=0

	json_select_object switch
		json_select_object "$name"
			json_add_boolean enable "$enabled"
			json_add_boolean reset 1

			for port in "$@"; do
				case "$port" in
					[0-9]*@*)
						num="${port%%@*}"
						device="${port##*@}"
						need_tag=0
						want_untag=0
						[ "${num%t}" != "$num" ] && {
							num="${num%t}"
							need_tag=1
						}
						[ "${num%u}" != "$num" ] && {
							num="${num%u}"
							want_untag=1
						}
					;;
					[0-9]*:*:[0-9]*)
						num="${port%%:*}"
						index="${port##*:}"
						role="${port#[0-9]*:}"; role="${role%:*}"
					;;
					[0-9]*:*)
						[ "${port: -2}" = "#s" ] && sfp=1 && port="${port%%#s}"
						num="${port%%:*}"
						role="${port##*:}"
					;;
				esac

				if [ -n "$num" ] && [ -n "$device$role" ]; then
					_ucidef_add_switch_port
				fi

				unset num device role index need_tag want_untag sfp
			done
		json_select ..
	json_select ..

	_ucidef_finish_switch_roles
}

ucidef_add_switch_attr() {
	local name="$1"
	local key="$2"
	local val="$3"

	json_select_object switch
		json_select_object "$name"

		case "$val" in
			true|false) [ "$val" != "true" ]; json_add_boolean "$key" $? ;;
			[0-9]) json_add_int "$key" "$val" ;;
			*) json_add_string "$key" "$val" ;;
		esac

		json_select ..
	json_select ..
}

ucidef_add_switch_port_attr() {
	local name="$1"
	local port="$2"
	local key="$3"
	local val="$4"
	local ports i num

	json_select_object switch
	json_select_object "$name"

	json_get_keys ports ports
	json_select_array ports

	for i in $ports; do
		json_select "$i"
		json_get_var num num

		if [ -n "$num" ] && [ $num -eq $port ]; then
			json_select_object attr

			case "$val" in
				true|false) [ "$val" != "true" ]; json_add_boolean "$key" $? ;;
				[0-9]) json_add_int "$key" "$val" ;;
				*) json_add_string "$key" "$val" ;;
			esac

			json_select ..
		fi

		json_select ..
	done

	json_select ..
	json_select ..
	json_select ..
}

ucidef_set_interface_macaddr() {
	local network="$1"
	local macaddr="$2"

	ucidef_set_interface "$network" macaddr "$macaddr"
}

ucidef_set_network_options() {
	json_select_object "network_options"
	n=$#

	for i in $(seq $((n / 2))); do
		opt="$1"
		val="$2"

		if [ "$val" -eq "$val" ] 2>/dev/null; then
			json_add_int "$opt" "$val"
		else
			[ "$val" = "true" ] && val=1 || val=0
			json_add_boolean "$opt" "$val"
		fi
		shift; shift
	done
	json_select ..
}

ucidef_set_poe() {
	json_select_object poe
		json_add_int "chip_count" "$1"
		json_add_int "poe_ports" "$2"
		shift 2
		json_select_array ports
			while [ $# -gt 0 ]; do
				json_add_object ""
					json_add_string "name" "$1"
					json_add_string "class" "$2"
					json_add_int "budget" "$3"
				json_close_object
				shift 3
			done
		json_select ..
	json_select ..
}

ucidef_set_poe_chip() {
	json_select_object poe
		json_select_array poe_chips
			json_add_object ""
				for port in "$@"; do
					case "$port" in
						0X*)
							json_add_string address "$port"
						;;
						[0-9]:*)
							json_add_string chan"${port%%:*}" "${port##*:}"
						;;
					esac
				done
			json_close_object
		json_select ..
	json_select ..
}

ucidef_check_path() {
	local hwver_str="$4"
	[ -n "$hwver_str" ] && {
		local hwver_cur_hi="$(cat /sys/mnf_info/hwver | cut -b 3-4)"
		local hwver_cur_lo="$(cat /sys/mnf_info/hwver_lo 2>/dev/null | cut -b 3-4)"
		local hwver_cur="$(expr $hwver_cur_hi \* 100 + $hwver_cur_lo)"

		hwver_from="$(echo "$hwver_str" | cut -d '-' -f 1 | awk -F "." '{print $1*100+$2%100}')"
		hwver_to="$(echo "$hwver_str" | cut -d '-' -f 2 | awk -F "." '{print $1*100+$2%100}')"

		[ "$hwver_cur" -lt "$hwver_from" ]  && return
		[ "$hwver_cur" -gt "$hwver_to" ] && [ "$hwver_to" -ne 0 ] && return
	}

	json_select_array "checks"
		json_add_object
			json_add_string name "$1"
			json_add_string path "$2"
			json_add_string action "$3"
		json_close_object
	json_close_array
}

ucidef_add_dot1x_server_capabilities() {
	local guest_vlan="$1"
	local fallback_vlan="$2"
	local isolation_method="$3"
	json_add_object "port_security"
	json_add_boolean guest_vlan $guest_vlan
	json_add_boolean fallback_vlan "$fallback_vlan"
	json_add_string isolation_method "$isolation_method"
	json_close_object

}

ucidef_add_static_modem_info() {
	#Parameters: model usb_id sim_count other_params
	local model usb_id count
	local modem_counter=0
	local sim_count=1

	model="$1"
	usb_id="$2"

	json_get_keys count modems
	[ -n "$count" ] && modem_counter="$(echo "$count" | wc -w)"

	modem_num=$((modem_counter + 1))

	json_select_array "modems"
		json_add_object
			json_add_string id "$usb_id"
			json_add_string num "$modem_num"
			json_add_boolean builtin 1
			sim_count=$(get_simcount_by_modem_num $modem_num)
			json_add_int simcount "$sim_count"

			for i in "$@"; do
				case "$i" in
					primary)
						json_add_boolean primary 1
						;;
					gps_out)
						json_add_boolean gps_out 1
					;;
				esac
			done

		json_close_object
	json_select ..
}

ucidef_add_serial_capabilities() {
	json_select_array serial
		json_add_object
			[ -n "$1" ] && {
				json_select_array devices
				for d in $1; do
					json_add_string "" $d
				done
				json_select ..
			}

			json_select_array bauds
			for b in $2; do
				json_add_string "" $b
			done
			json_select ..

			json_select_array data_bits
			for n in $3; do
				json_add_string "" $n
			done
			json_select ..

			json_select_array flow_control
			for n in $4; do
				json_add_string "" $n
			done
			json_select ..

			json_select_array stop_bits
			for n in $5; do
				json_add_string "" $n
			done
			json_select ..

			json_select_array parity_types
			for n in $6; do
				json_add_string "" $n
			done
			json_select ..

			json_select_array duplex
			for n in $7; do
				json_add_string "" $n
			done
			json_select ..

			json_add_string "path" $8

		json_close_object
	json_select ..
}

ucidef_add_wlan_bssid_limit() {
	json_select_object wlan
		json_add_object "$1"
			json_add_int bssid_limit "$2"
		json_close_object
	json_select ..
}

ucidef_set_hwinfo() {
	local args=" $* "

	json_select_object hwinfo

	for opt in $args; do
		[ -z "$opt" ] && continue
		json_add_boolean "$opt" 1
		shift
	done

	json_select ..
}

ucidef_unset_hwinfo() {
	local args=" $* "

	json_select_object hwinfo

	for opt in $args; do
		json_remove_boolean "$opt"
	done

	json_select ..
}

ucidef_set_esim() {
	json_select_object hwinfo
	json_add_boolean "esim" 1
	json_select ..
}

ucidef_check_tpm() {
	[ -e /dev/tpm0 ] || ucidef_unset_hwinfo "tpm"
}

ucidef_set_release_version() {
	json_add_string release_version "$1"
}

ucidef_set_usb_jack() {
	json_add_string "usb_jack" "$1"
}

ucidef_set_usb_jack_low_speed() {
	json_add_string "usb_jack_low_speed" "$1"
}

board_config_update() {
	json_init
	[ -f ${CFG} ] && json_load "$(cat ${CFG})"

	# auto-initialize model id and name if applicable
	if ! json_is_a model object; then
		json_select_object model
			[ -f "/tmp/sysinfo/board_name" ] && \
				json_add_string id "$(cat /tmp/sysinfo/board_name)"
			[ -f "/tmp/sysinfo/model" ] && \
				json_add_string name "$(cat /tmp/sysinfo/model)"
		json_select ..
	fi
}

board_config_flush() {
	json_dump -i -o ${CFG}
	[ "$CFG" = "/etc/board.json" ] && md5sum ${CFG} > /etc/board.hash
}

