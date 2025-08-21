#!/bin/sh
[ -n "$INCLUDE_ONLY" ] || {
	. /lib/functions.sh
	. /lib/functions/mobile.sh
	. /lib/netifd/netifd-proto.sh
	init_proto "$@"
}

proto_pppmobile_init_config() {
	#~ This proto usable only with proto wwan
	available=1
	no_device=1
	disable_auto_up=1
	teardown_on_l3_link_down=1

	proto_config_add_string delay
	proto_config_add_string modes
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
	proto_config_add_string passthrough_mode
	proto_config_add_string leasetime
	proto_config_add_string mac
	proto_config_add_int mtu

	proto_config_add_defaults
}

add_ipv4_dynamic_ifname() {
	local ifname_="$1"

	json_init
	json_add_string pppname "ppp-$interface"
	json_add_string name "$ifname_"
	json_add_string device "$ctl_device"
	json_add_string proto "ppp"
	json_add_string ipv6 "0"
	json_add_string nopersist
	[ -n "$ip4table" ] && json_add_string ip4table "$ip4table"
	[ -n "$zone" ] && json_add_string zone "$zone"

	proto_add_dynamic_defaults
	ubus call network add_dynamic "$(json_dump)"

	json_init
	json_add_string modem "$modem"
	json_add_string sim "$sim"
	[ -n "$zone" ] && json_add_string zone "$zone"
	ubus call network.interface."$ifname_" set_data "$(json_dump)"
}

add_ipv6_dynamic_ifname() {
	local ifname_="$1"

	json_init
	json_add_string pppname "ppp-$interface"
	json_add_string name "$ifname_"
	json_add_string device "$ctl_device"
	json_add_string proto "ppp"
	json_add_string ipv6 "1"
	json_add_boolean ignore_valid 1
	[ "$delegate" -eq 0 ] || json_add_string extendprefix 1
	[ -n "$ip6table" ] && json_add_string ip6table "$ip6table"
	[ -n "$zone" ] && json_add_string zone "$zone"

	proto_add_dynamic_defaults
	ubus call network add_dynamic "$(json_dump)"

	[ "$method" != "bridge" ] && [ "$method" != "passthrough" ] && {
		json_init
		json_add_string modem "$modem"
		json_add_string sim "$sim"
		[ -n "$zone" ] && json_add_string zone "$zone"
		ubus call network.interface."$ifname_" set_data "$(json_dump)"
	}
}

update_mobile_ifname() {
	proto_init_update "ppp-$interface" 1
	proto_set_keep 1
	proto_add_data
	json_add_string "pdp" "$pdp"
	json_add_string "method" "$method"
	json_add_boolean "static_mobile" "1" # Required for mdcollect
	proto_close_data

	proto_send_update "$interface"
}

add_hide_dynamic_ipv6_interface() {
	local ifname_="$1"

	json_init
	json_add_string name "$ifname_"
	json_add_string proto "dhcpv6"
	json_add_string area_type "wan"
	json_add_string device "ppp-$interface"

	json_add_string extendprefix 1
	json_add_boolean ignore_valid 1
	[ -n "$ip6table" ] && json_add_string ip6table "$ip6table"
	[ -n "$zone" ] && json_add_string zone "$zone"
	proto_add_dynamic_defaults
	ubus call network add_dynamic "$(json_dump)"

	# this need to mdcollect to recognize interface as mobile
	[ "$method" != "bridge" ] && [ "$method" != "passthrough" ] && {
		json_init
		json_add_string modem "$modem"
		json_add_string sim "$sim"
		[ -n "$zone" ] && json_add_string zone "$zone"
		ubus call network.interface."$ifname_" set_data "$(json_dump)"
	}
}

down_mobile_interfaces() {
	local interface="$1"
	ubus call network.interface down "{\"interface\":\"${interface}_4\"}" 2>/dev/null
	ubus call network.interface down "{\"interface\":\"${interface}_6\"}" 2>/dev/null
	ubus call network.interface down "{\"interface\":\"ppp-${interface}_6\"}" 2>/dev/null
}

wait_data_connection() {
	local ifname_="$1"
	local i

	## need to wait while interface appear
	local max_wait=10
	echo "Looking l3 device for $ifname_ interface"
	for i in $(seq $max_wait); do
		l3_device=$(ifstatus "$ifname_" | grep l3_device)
		if [ -z "$l3_device" ]; then
			sleep 1
		else
			ubus -t 1 call gpsd modman '{"wwan":true}' 2>/dev/null
		 	return 0
		fi
		if [ $i -eq $max_wait ]; then
			echo "Can't find l3 device for $ifname_ interface"
			ubus call network.interface remove "{\"interface\":\"$ifname_\"}" 2>/dev/null
			ubus -t 1 call gpsd modman '{"wwan":false}' 2>/dev/null
			return 1
		fi
	done

    	return 1
}

proto_pppmobile_setup() {
	#~ This proto usable only with proto wwan
	local interface="$1"
	local pdp modem sim delay $PROTO_DEFAULT_OPTIONS
	local ip4table ip6table delegate
	local active_sim="1"
	local ifname

	json_get_vars pdp pdptype modem sim delay ip4table ip6table delegate $PROTO_DEFAULT_OPTIONS
	[ -n $modem ] && modem="$devicename"

	local mdm_ubus_obj="$(find_mdm_ubus_obj "$modem")"
	[ -z "$mdm_ubus_obj" ] && echo "gsm.modem object not found. Downing $interface interface" && ifdown $interface

	config_load network
	config_get sim "$interface" "sim" "1"
	config_get pdp "$interface" "pdp" "1"
	config_get method "$interface" "method" "1"

	local zone="$(fw3 -q network "$interface" 2>/dev/null)"

	[ -n "$delay" ] || [ "$pdp" = "1" ] && delay=0 || delay=3
	sleep "$delay"

	echo "Got SIM$sim for modem $modem"


#~ Parameters part------------------------------------------------------
	#[ -z "$sim" ] && sim=$(get_config_sim "$interface")
	active_sim=$(get_active_sim "$interface" "$old_cb" "$mdm_ubus_obj")
	[ "$active_sim" = "0" ] && echo "Failed to get active sim" && reload_mobifd "$modem" "$interface" && return
	esim_profile_index=$(get_active_esim_profile_index "$modem")
	# verify active sim by return value(non zero means that the check failed)
	verify_active_sim "$sim" "$active_sim" "$interface" || { reload_mobifd "$modem" "$interface"; return; }
	# verify active esim profile index by return value(non zero means that the check failed)
	verify_active_esim "$esim_profile_index" "$interface" || { reload_mobifd "$modem" "$interface"; return; }
	deny_roaming=$(get_deny_roaming "$active_sim" "$modem" "$esim_profile_index")

	if [ "$deny_roaming" = "1" ]; then
		reg_stat_str=$(jsonfilter -s "$(ubus call $mdm_ubus_obj info)" -e '@.cache.reg_stat_str')
		if [ "$reg_stat_str" = "Roaming" ]; then
			echo "Roaming detected. Stopping connection"
			proto_notify_error "$interface" "Roaming detected"
			proto_block_restart "$interface"
			return
		fi
	fi

#~ Connection part------------------------------------------------------
	dialnumber=${dialnumber:-"*99#"}
	echo -ne "ATD$dialnumber\r\n" > "$ctl_device"

#~ Network setup part------------------------------------------------------

	pdptype="$(echo "$pdptype" | awk '{print tolower($0)}')"

	case $pdptype in
	ip)
		echo "PDP type IP"
		ifname="${interface}_4"

		add_ipv4_dynamic_ifname "$ifname"
		wait_data_connection "$ifname" || return
		update_mobile_ifname "$ifname"
	;;
	ipv6)
		echo "PDP type IPv6"
		ifname="${interface}_6"

		add_ipv6_dynamic_ifname "ppp-$ifname"
		wait_data_connection "ppp-$ifname" || return
		update_mobile_ifname "$ifname"
		add_hide_dynamic_ipv6_interface "$ifname"
	;;
	ipv4v6)
		echo "PDP type IPv4v6"
		ifname_4="${interface}_4"
		ifname_6="${interface}_6"

		add_ipv6_dynamic_ifname "$ifname_4"
		wait_data_connection "$ifname_4"
		if [ "$?" = "0" ]; then
			update_mobile_ifname "$interface"
		# 	## need to add secondary interface to run dhcpv6 protocol
			add_hide_dynamic_ipv6_interface "$ifname_6"
		else
			down_mobile_interfaces "$interface"
			sleep 20
			return
		fi

	;;
	esac
}

#~ ---------------------------------------------------------------------
proto_pppmobile_teardown() {
	local interface="$1"
	local bridge_ipaddr method

	json_load "$(ubus call network.interface.$interface status)"
	json_select data
	json_get_vars method bridge_ipaddr

	echo "Stopping network $interface"
	gsmctl -A 'AT&D2' > /dev/null
	down_mobile_interfaces "$interface"

	[ "$method" = "bridge" ] || [ "$method" = "passthrough" ] && {
		ip rule del pref 5042
		ip rule del pref 5043
		ip route flush table 42
		ip route flush table 43
		ip route del "$bridge_ipaddr"
		ip neigh del "$bridge_ipaddr" dev br-lan 2>/dev/null
		swconfig dev switch0 set soft_reset 5 &
	}

	#Clear passthrough and bridge params
	iptables -t nat -F postrouting_rule

	local zone="$(fw3 -q network "$interface" 2>/dev/null)"
	iptables -F forwarding_${zone}_rule

	rm -f "/tmp/dnsmasq.d/bridge" 2>/dev/null
	ip neigh flush proxy
}

[ -n "$INCLUDE_ONLY" ] || {
	add_protocol pppmobile
}
