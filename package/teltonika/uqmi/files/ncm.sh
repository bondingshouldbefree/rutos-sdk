#!/bin/sh
. /lib/netifd/uqmi_shared_functions.sh
[ -n "$INCLUDE_ONLY" ] || {
	. /lib/functions.sh
	. /lib/functions/mobile.sh
	. /lib/netifd/netifd-proto.sh
	init_proto "$@"
}

proto_ncm_init_config() {
	available=1
	no_device=1
	disable_auto_up=1
	teardown_on_l3_link_down=1

	proto_config_add_boolean dhcp
	proto_config_add_boolean dhcpv6
	proto_config_add_boolean delegate
	proto_config_add_int ip4table
	proto_config_add_int ip6table

	#teltonika specific
	proto_config_add_string modem
	proto_config_add_string pdp
	proto_config_add_string pdptype
	proto_config_add_string sim
	proto_config_add_string method
	proto_config_add_string delay
	proto_config_add_string passthrough_mode
	proto_config_add_string leasetime
	proto_config_add_string mac
	proto_config_add_int mtu

	proto_config_add_defaults
}

get_next_ip () {
	local ip="$1" ip_hex next_ip next_ip_hex
	ip_hex=$(printf '%.2X%.2X%.2X%.2X\n' `echo ${ip} | sed -e 's/\./ /g'`)
	next_ip_hex=$(printf %.8X `echo $(( 0x${ip_hex} + 1 ))`)
	next_ip=$(printf '%d.%d.%d.%d\n' `echo ${next_ip_hex} | sed -r 's/(..)/0x\1 /g'`)
	echo "$next_ip"
}

get_netmask_gateway() {
	local ip="$1" ip_net="$1" ip_broad="$1" mask=30 gateway_net same_net=0
	gateway="$ip_broad"

	while [ "$ip_net" = "$ip" -o "$ip_broad" = "$gateway" -a "$same_net" -eq 1 ]; do
		eval "$(ipcalc.sh "$ip/$mask")"
		ip_net="$NETWORK"
		netmask="$NETMASK"
		ip_broad="$BROADCAST"
		gateway="$(get_next_ip ${ip})" # Get gateway IP address
		eval "$(ipcalc.sh "$gateway/$mask")" # Get gateway network IP address
		gateway_net="$NETWORK"
		[ "$gateway_net" = "$ip_net" ] && {
			same_net=1
		}
		let "mask-=1"
	done
}

parse_ipv4_information() {
	local pdp="$1"
	local modem_id="$2"
	local parsed_ip primary_dns secondary_dns mdm_ubus_obj errno

	mdm_ubus_obj="$(find_mdm_ubus_obj "$modem_id")"

        json_load "$(ubus call "$mdm_ubus_obj" get_pdp_addr "{\"index\":${pdp}}")"
        json_get_var parsed_ip addr

        [ -z "$parsed_ip" ]  && {
                echo "Can't parse IP address!"
                return 1
        }

        json_load "$(ubus call "$mdm_ubus_obj" get_dns_addr "{\"cid\":${pdp}}")"
        json_get_var primary_dns pri_dns
        json_get_var secondary_dns sec_dns
        json_get_var errno errno

        [ -n "$errno" ] && {
                echo "Can't get primary and secondary DNS!"
                return 1
        }

	get_netmask_gateway "$parsed_ip"

	json_init
	json_add_object "ipv4"
	json_add_string ip "$parsed_ip"
	json_add_string dns1 "$primary_dns"
	json_add_string dns2 "$secondary_dns"
	json_add_string gateway "$gateway"
	json_add_string subnet "$netmask"
	json_close_object

	parameters4="$(json_dump)"
	return 0
}

failure_notify() {
	local pdptype="$1"
	case "$pdptype" in
		ip)
			proto_notify_error "$interface" FAILED_IPV4
			exit 1
			;;
		ipv6)
			proto_notify_error "$interface" FAILED_IPV6
			exit 1
			;;
		ipv4v6)
			proto_notify_error "$interface" FAILED_IPV4V6
			exit 1
			;;
	esac
}

proto_ncm_setup() {
	local interface="$1"
	local devicename="$2"
	local mtu method device pdp modem pdptype sim dhcp dhcpv6 $PROTO_DEFAULT_OPTIONS IFACE4 IFACE6 delay passthrough_mode leasetime mac
	local ip4table ip6table mdm_ubus_obj pin_state pdp_ctx_state pdp_ctx delegate
	local timeout=2 retries=0
	local active_sim="1"
	local retry_before_reinit

	json_get_vars mtu method device modem pdptype sim dhcp dhcpv6 delay ip4table ip6table passthrough_mode leasetime mac delegate $PROTO_DEFAULT_OPTIONS

	local mdm_ubus_obj="$(find_mdm_ubus_obj "$modem")"
	[ -z "$mdm_ubus_obj" ] && echo "gsm.modem object not found. Downing $interface interface" && ifdown $interface

	pdp=$(get_pdp "$interface")

	[ -n "$delay" ] || [ "$pdp" = "1" ] && delay=0 || delay=3
	sleep "$delay"

#~ Parameters part------------------------------------------------------
	[ -z "$sim" ] && sim=$(get_config_sim "$interface")
	active_sim=$(get_active_sim "$interface" "$old_cb" "$mdm_ubus_obj")
	[ "$active_sim" = "0" ] && echo "Failed to get active sim" && reload_mobifd "$modem" "$interface" && return
	esim_profile_index=$(get_active_esim_profile_index "$modem")
	# verify active sim by return value(non zero means that the check failed)
	verify_active_sim "$sim" "$active_sim" "$interface" || { reload_mobifd "$modem" "$interface"; return; }
	# verify active esim profile index by return value(non zero means that the check failed)
	verify_active_esim "$esim_profile_index" "$interface" || { reload_mobifd "$modem" "$interface"; return; }
	deny_roaming=$(get_deny_roaming "$active_sim" "$modem" "$esim_profile_index")
#~ ---------------------------------------------------------------------

	if [ "$deny_roaming" = "1" ]; then
		reg_stat_str=$(jsonfilter -s "$(ubus call $mdm_ubus_obj info)" -e '@.cache.reg_stat_str')
		if [ "$reg_stat_str" = "Roaming" ]; then
			echo "Roaming detected. Stopping connection"
			proto_notify_error "$interface" "Roaming detected"
			proto_block_restart "$interface"
			return
		fi
	fi

	echo "Connection setup for ${interface} starting!"

	retry_before_reinit="$(cat /tmp/conn_retry_$interface)" 2>/dev/null
	[ -z "$retry_before_reinit" ] && retry_before_reinit="0"
	[ -z "$metric" ] && metric="1"

        #~ Find interface name
	[ -z "$device" ] && device="$devicename"
        devname="$(basename "$device")"
        ifname="$(ls /sys/bus/usb/devices/$devname/*/net/ | tail -1)"

	[ -n "$ifname" ] || {
		echo "The interface could not be found."
		proto_notify_error "$interface" NO_IFACE
		return
	}

	pdptype="$(echo "$pdptype" | awk '{print tolower($0)}')"
	[ "$pdptype" = "ip" -o "$pdptype" = "ipv6" -o "$pdptype" = "ipv4v6" ] || pdptype="ip"

	#DOTO: this must be fixed if there will be a multi apn option
	qiact_list_full=$(ubus call "$mdm_ubus_obj" get_attached_pdp_ctx_list 2>&1)

	if [ "$qiact_list_full" != "Command failed: Operation not supported" ]; then

		qiact_list=$(echo "$qiact_list_full" | grep "activated")

		if [ "$qiact_list" = "" ]; then
			echo "Activating PDP CID${pdp}!"
			json_load "$(ubus -t 150 call "$mdm_ubus_obj" set_pdp_ctx_state "{\"cid\":${pdp},\"state\":\"activated\"}")"
			json_get_var pdp_ctx status

			[ "${pdp_ctx::2}" != "OK" ] && {
				echo "Can't activate PDP context! Error: ${pdp_ctx}"
				handle_retry "$retry_before_reinit" "$interface"
				failure_notify "$pdptype"
			}
		else
			echo "PDP CID${pdp} already activated!"
		fi

		echo "Starting setup data call!"

		json_load "$(ubus call "$mdm_ubus_obj" set_pdp_call "{\"mode\":\"call_once\",\"cid\":${pdp},\"urc_en\":true}")"
		json_get_var pdp_act status

		[ "${pdp_act::2}" != "OK" ] && {
			echo "Data call failed! Error: ${pdp_act}"
			handle_retry "$retry_before_reinit" "$interface"
			failure_notify "$pdptype"
			ifdown "$interface"
			return 1
		}
	fi

	mtu="${mtu:-1500}"

	[ -z "$mtu" ] || {
		echo "Setting MTU: ${mtu} on ${ifname}"
		ip link set mtu "$mtu" "$ifname"
	}

	# Disable GRO, CDC NCM does not provide RX csum offloading.
	ethtool -K $ifname gro off

	proto_init_update "$ifname" 1
	proto_set_keep 1
	proto_add_data
	json_add_string "pdp" "$pdp"
	json_add_string "method" "$method"
	json_add_boolean "static_mobile" "1" # Required for mdcollect
	proto_close_data
	proto_send_update "$interface"

	local zone="$(fw3 -q network "$interface" 2>/dev/null)"

	[ "$method" = "bridge" -o "$method" = "passthrough" ] && \
	[ "$pdptype" = "ip" -o "$pdptype" = "ipv4v6" ] && {

		parse_ipv4_information "$pdp" "$modem" && {
			setup_bridge_v4 "$ifname" "$modem"

			#Passthrough
			[ "$method" = "passthrough" ] && {
				iptables -w -tnat -I postrouting_rule -o "$ifname" -j SNAT --to "$bridge_ipaddr"
				ip route add default dev "$ifname" metric "$metric"
			}
		}
	}

	[ "$method" != "bridge" ] && [ "$method" != "passthrough" ] && \
	[ "$pdptype" = "ip" -o "$pdptype" = "ipv4v6" ] && {
		if [ "$dhcp" = 0 ]; then
			setup_static_v4 "$ifname"

		else
			setup_dhcp_v4 "$ifname"
		fi

		json_init
		json_add_string modem "$modem"
		json_add_string sim "$sim"
		[ -n "$zone" ] && json_add_string zone "$zone"

		ubus call network.interface."${interface}_4" set_data "$(json_dump)" 2>/dev/null
		IFACE4="${interface}_4"
	}

	[ "$pdptype" = "ipv6" -o "$pdptype" = "ipv4v6" ] && {
# 		if [ "$dhcpv6" = 0 ]; then
# 			setup_static_v6 "$ifname"
# 		else
# 			setup_dhcp_v6 "$ifname"
# 		fi

		#We faces some issue and notify that only DHCP works with IPv6
		setup_dhcp_v6 "$ifname"

		json_init
		json_add_string modem "$modem"
		json_add_string sim "$sim"
		[ -n "$zone" ] && json_add_string zone "$zone"

		ubus call network.interface."${interface}_6" set_data "$(json_dump)" 2>/dev/null
		IFACE6="${interface}_6"
	}

	#Run udhcpc to obtain lease
	proto_export "IFACE4=$IFACE4"
	proto_export "IFACE6=$IFACE6"

	proto_run_command "$interface" ncm_conn.sh "$ifname" "$pdp" "$modem"
}

proto_ncm_teardown() {
	local interface="$1" pdp bridge_ipaddr method
	json_get_vars pdp modem
	local braddr_f="/var/run/${interface}_braddr"

	mdm_ubus_obj="$(find_mdm_ubus_obj "$modem")"

	echo "Stopping network ${interface}"

	[ -f "$braddr_f" ] && {
		method=$(get_braddr_var method "$interface")
		bridge_ipaddr=$(get_braddr_var bridge_ipaddr "$interface")
	}

	#Kill udhcpc instance
	proto_kill_command "$interface"
	ubus call network.interface."${interface}_4" remove 2>/dev/null
	ubus call network.interface."${interface}_6" remove 2>/dev/null

	#Stop data call
	ubus -t 3 call "$mdm_ubus_obj" set_pdp_call "{\"mode\":\"disconnect\",\"cid\":${pdp},\"urc_en\":true,\"timeout\":0}"

	#Deactivate context
	ubus -t 3 call "$mdm_ubus_obj" set_pdp_ctx_state "{\"cid\":${pdp},\"state\":\"deactivated\",\"timeout\":0}"
	kill -9 $(cat /var/run/ncm_conn.pid 2>/dev/null) &>/dev/null
	rm -f /var/run/ncm_conn.pid &>/dev/null

	[ "$method" = "bridge" ] || [ "$method" = "passthrough" ] && {
		ip rule del pref 5042
		ip rule del pref 5043
		ip route flush table 42
		ip route flush table 43
		ip route del "$bridge_ipaddr"
		ubus call network.interface down "{\"interface\":\"mobile_bridge\"}"
		rm -f "/tmp/dnsmasq.d/bridge"

		if is_device_dsa ; then
			restart_dsa_interfaces
		else
			swconfig dev 'switch0' set soft_reset 5 &
		fi
		rm -f "$braddr_f" 2> /dev/null

		#Clear passthrough and bridge params
		iptables -t nat -F postrouting_rule

		local zone="$(fw3 -q network "$interface" 2>/dev/null)"
		iptables -F forwarding_${zone}_rule

		ip neigh flush proxy
		ip neigh flush dev br-lan
		ip neigh del "$bridge_ipaddr" dev br-lan 2>/dev/null
	}

	proto_init_update "*" 0
	proto_send_update "$interface"
}

[ -n "$INCLUDE_ONLY" ] || {
	add_protocol ncm
}
