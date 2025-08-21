#!/bin/sh
. /lib/netifd/uqmi_shared_functions.sh
[ -n "$INCLUDE_ONLY" ] || {
	. /lib/functions.sh
	. /lib/functions/mobile.sh
	. /lib/netifd/netifd-proto.sh
	init_proto "$@"
}

proto_connm_init_config() {
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

proto_connm_setup() {
	#~ This proto usable only with proto wwan
	local interface="$1"

	local ipv4 ipv6 delay mtu deny_roaming leasetime mac
	local active_sim="1" options

	local connstat method
	local device apn auth username password pdp modem pdptype sim dhcp dhcpv6 delegate
	local $PROTO_DEFAULT_OPTIONS IFACE4 IFACE6 ip4table ip6table parameters4 parameters6
	local pdh_4 pdh_6 cid cid_4 cid_6
	local retry_before_reinit
	local error_cnt

	json_get_vars device modem pdptype sim delay method mtu dhcp dhcpv6 ip4table ip6table \
	leasetime mac delegate $PROTO_DEFAULT_OPTIONS

	mkdir -p "/var/run/qmux/"

	local gsm_modem="$(find_mdm_ubus_obj "$modem")"
	[ -z "$gsm_modem" ] && {
			echo "Failed to find gsm modem ubus object, exiting."
			return 1
	}

	# wait for shutdown to complete
	wait_for_shutdown_complete "$interface"

	pdp=$(get_pdp "$interface")

	[ -n "$delay" ] || [ "$pdp" = "1" ] && delay=0 || delay=3
	sleep "$delay"

#~ Parameters part------------------------------------------------------
	[ -z "$sim" ] && sim=$(get_config_sim "$interface")
	active_sim=$(get_active_sim "$interface" "$old_cb" "$gsm_modem")
	[ "$active_sim" = "0" ] && echo "Failed to get active sim" && reload_mobifd "$modem" "$interface" && return
	esim_profile_index=$(get_active_esim_profile_index "$modem")
	# verify active sim by return value(non zero means that the check failed)
	verify_active_sim "$sim" "$active_sim" "$interface" || { reload_mobifd "$modem" "$interface"; return; }
	# verify active esim profile index by return value(non zero means that the check failed)
	verify_active_esim "$esim_profile_index" "$interface" || { reload_mobifd "$modem" "$interface"; return; }
	deny_roaming=$(get_deny_roaming "$active_sim" "$modem" "$esim_profile_index")
#~ ---------------------------------------------------------------------
	if [ "$deny_roaming" = "1" ]; then
		reg_stat_str=$(jsonfilter -s "$(ubus call $gsm_modem info)" -e '@.cache.reg_stat_str')
		if [ "$reg_stat_str" = "Roaming" ]; then
			echo "Roaming detected. Stopping connection"
			proto_notify_error "$interface" "Roaming detected"
			proto_block_restart "$interface"
			return
		fi
	fi

	[ -n "$ctl_device" ] && device="$ctl_device"
	[ -n "$ctl_ifname" ] && ifname="$ctl_ifname"
	[ -z "$timeout" ] && timeout="30"
	[ -z "$metric" ] && metric="1"

	service_name="wds"
	options="--timeout 30000"

#~ Connectivity part----------------------------------------------------

	pdptype="$(echo "$pdptype" | awk '{print tolower($0)}')"
	[ "$pdptype" = "ip" ] || [ "$pdptype" = "ipv6" ] || [ "$pdptype" = "ipv4v6" ] || pdptype="ip"

	first_uqmi_call "uqmi -d $device --timeout 10000 --set-autoconnect disabled" || return 1

	# Disable no roaming flag
	call_uqmi_command "uqmi -d $device $options --modify-profile 3gpp,${pdp} --profile-name ${pdp} --roaming-disallowed-flag no"

	retry_before_reinit="$(cat /tmp/conn_retry_$interface)" 2>/dev/null
	[ -z "$retry_before_reinit" ] && retry_before_reinit="0"

	wait_for_serving_system || return 1

	[ "$pdptype" = "ip" ] || [ "$pdptype" = "ipv4v6" ] && {

		cid_4=$(call_uqmi_command "uqmi -d $device $options --get-client-id wds")
		[ $? -ne 0 ] && return 1

		check_digits $cid_4
		if [ $? -ne 0 ]; then
			echo "Unable to obtain client IPV4 ID"
		fi
		touch "/var/run/qmux/$interface.cid_$cid_4"
		echo "cid4: $cid_4"

		#~ Set ipv4 on CID
		call_uqmi_command "uqmi -d $device $options --set-ip-family ipv4 \
--set-client-id wds,$cid_4"
		[ $? -ne 0 ] && return 1

		#~ Start PS call
		pdh_4=$(call_uqmi_command "uqmi -d $device $options --set-client-id wds,$cid_4 \
--start-network --profile $pdp --ip-family ipv4" "true")

		echo "pdh4: $pdh_4"

		check_digits $pdh_4
		if [ $? -ne 0 ]; then
		# pdh_4 is a numeric value on success
			echo "Unable to connect IPv4"
		else
			# Check data connection state
			connstat="$(uqmi -d $device $options --set-client-id wds,"$cid_4" \
					--get-data-status | awk -F '"' '{print $2}')"
			if [ "$connstat" = "connected" ]; then
				ipv4=1
			else
				echo "No IPV4 data link!"
			fi
			parameters4="$(uqmi -d $device $options --set-client-id wds,"$cid_4" \
--get-current-settings)"
			get_dynamic_mtu "$parameters4" "$ipv4" "$interface"
		fi
	}

	[ "$pdptype" = "ipv6" ] || [ "$pdptype" = "ipv4v6" ] && {

		cid_6=$(call_uqmi_command "uqmi -d $device $options --get-client-id wds")
		[ $? -ne 0 ] && return 1

		check_digits $cid_6
		if [ $? -ne 0 ]; then
			echo "Unable to obtain client IPV6 ID"
		fi
		touch "/var/run/qmux/$interface.cid_$cid_6"
		echo "cid6: $cid_6"

		#~ Set ipv6 on CID
		ret=$(call_uqmi_command "uqmi -d $device $options --set-ip-family ipv6 \
--set-client-id wds,$cid_6")
		[ $? -ne 0 ] && return 1

		#~ Start PS call
		pdh_6=$(call_uqmi_command "uqmi -d $device $options --set-client-id wds,$cid_6 \
--start-network --profile $pdp --ip-family ipv6" "true")

		echo "pdh6: $pdh_6"

		# pdh_6 is a numeric value on success
		check_digits $pdh_6
		if [ $? -ne 0 ]; then
			echo "Unable to connect IPv6"
		else
			# Check data connection state
			connstat="$(uqmi -d $device $options --set-client-id wds,"$cid_6" \
					--get-data-status | awk -F '"' '{print $2}')"
			if [ "$connstat" = "connected" ]; then
				ipv6=1
			else
				echo "No IPV6 data link!"
			fi
			parameters6="$(uqmi -d $device $options --set-client-id wds,"$cid_6" \
--get-current-settings)"
			get_dynamic_mtu "$parameters6" "$ipv6" "$interface"
		fi
	}

	fail_timeout=$((delay+10))
	verify_data_connection "$pdptype" || return 1

	echo "Setting up $ifname"

	set_mtu "$ifname"

	proto_init_update "$ifname" 1
	proto_set_keep 1
	proto_add_data

	[ -n "$pdh_4" ] && [ "$ipv4" = "1" ] && {
		json_add_string "cid_4" "$cid_4"
		json_add_string "pdh_4" "$pdh_4"
	}

	[ -n "$pdh_6" ] && [ "$ipv6" = "1" ] && {
		json_add_string "cid_6" "$cid_6"
		json_add_string "pdh_6" "$pdh_6"
	}

	json_add_string "pdp" "$pdp"
	json_add_string "method" "$method"
	json_add_boolean "static_mobile" "1" # Required for mdcollect
	proto_close_data
	proto_send_update "$interface"

	local zone="$(fw3 -q network "$interface" 2>/dev/null)"

	[ "$method" = "bridge" ] || [ "$method" = "passthrough" ] && [ -n "$cid_4" ] && {
		setup_bridge_v4 "$ifname" "$modem"
		ethtool -r eth0
		iptables -A postrouting_rule -o rmnet0 -tnat -j ACCEPT

		#Passthrough
		[ "$method" = "passthrough" ] && {
			iptables -w -tnat -I postrouting_rule -o "$ifname" -j SNAT --to "$bridge_ipaddr"
			ip route add default dev "$ifname" metric "$metric"
		}
	}

	[ "$method" != "bridge" ] && [ "$method" != "passthrough" ] && \
	[ -n "$pdh_4" ] && [ "$ipv4" = "1" ] && {
		if [ "$dhcp" = 0 ]; then
			setup_static_v4 "$ifname"
		else
			setup_dhcp_v4 "$ifname"
		fi

		IFACE4="${interface}_4"
		ubus_set_interface_data "$modem" "$sim" "$zone" "$IFACE4"
	}

	[ -n "$pdh_6" ] && [ "$ipv6" = "1" ] && {
		if [ "$dhcpv6" = 0 ]; then
			setup_static_v6 "$ifname"
		else
			setup_dhcp_v6 "$ifname"
		fi

		IFACE6="${interface}_6"
		ubus_set_interface_data "$modem" "$sim" "$zone" "$IFACE6"
	}

	[ "$ipv4" != "1" ] && [ "$pdptype" = "ip" ] && proto_notify_error "$interface" "$pdh_4"
	[ "$ipv6" != "1" ] && [ "$pdptype" = "ipv6" ] && proto_notify_error "$interface" "$pdh_6"
	[ "$pdptype" = "ipv4v6" ] && [ "$ipv4" != "1" ] && [ "$ipv6" != "1" ] && proto_notify_error "$interface" "$pdh_4" && proto_notify_error "$interface" "$pdh_6"

	proto_export "IFACE4=$IFACE4"
	proto_export "IFACE6=$IFACE6"
	proto_export "OPTIONS=$options"
	proto_run_command "$interface" qmuxtrack "$device" "$modem" "$cid_4" "$cid_6"
}

proto_connm_teardown() {
	local interface="$1"
	local device="/dev/cdc-wdm0" conn_proto
	local bridge_ipaddr method
	local braddr_f="/var/run/${interface}_braddr"
	touch "/tmp/shutdown_$interface"

	[ -n "$ctl_device" ] && device=$ctl_device

	echo "Stopping network $interface"

	conn_proto="qmux"

	[ -f "$braddr_f" ] && {
		method=$(get_braddr_var method "$interface")
		bridge_ipaddr=$(get_braddr_var bridge_ipaddr "$interface")
	}

	background_clear_conn_values "$interface" "$device" "$conn_proto" &

	ubus call network.interface down "{\"interface\":\"${interface}_4\"}"
	ubus call network.interface down "{\"interface\":\"${interface}_6\"}"

	[ "$method" = "bridge" ] || [ "$method" = "passthrough" ] && {
		ip rule del pref 5042
		ip rule del pref 5043
		ip route flush table 42
		ip route flush table 43
		ip route del "$bridge_ipaddr"
		ubus call network.interface down "{\"interface\":\"mobile_bridge\"}"
		rm -f "/tmp/dnsmasq.d/bridge" 2>/dev/null
		rm -f "$braddr_f" 2> /dev/null
		ethtool -r eth0

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
	add_protocol connm
}
