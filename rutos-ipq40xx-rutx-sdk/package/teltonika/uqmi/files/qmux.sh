#!/bin/ash
. /lib/netifd/uqmi_shared_functions.sh
[ -n "$INCLUDE_ONLY" ] || {
	. /lib/functions.sh
	. /lib/functions/mobile.sh
	. /lib/netifd/netifd-proto.sh
	init_proto "$@"
}

proto_qmux_init_config() {
	#~ This proto usable only with proto wwan
	available=1
	no_device=1
	disable_auto_up=1
	teardown_on_l3_link_down=1

	proto_config_add_string apn
	proto_config_add_string auth
	proto_config_add_string username
	proto_config_add_string password
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

remove_qmimux() {
	local wwan="$1" qmux="$2"
	[ -f "/sys/class/net/${qmux}/qmi/del_mux" ] && \
	cat "/sys/class/net/${wwan}/qmap/mux_id" 2>/dev/null > "/sys/class/net/${qmux}/qmi/del_mux"
}

proto_qmux_setup() {
	#~ This proto usable only with proto wwan
	local interface="$1"

	local ipv4 ipv6 delay mtu qmimux qmux ifid deny_roaming ret leasetime mac
	local active_sim="1"

	local dataformat connstat old_cb gobinet method
	local device apn auth username password pdp modem pdptype sim dhcp dhcpv6 delegate
	local $PROTO_DEFAULT_OPTIONS IFACE4 IFACE6 ip4table ip6table parameters4 parameters6
	local pdh_4 pdh_6 cid cid_4 cid_6
	local retry_before_reinit
	local error_cnt

	json_get_vars pdp device modem pdptype sim delay method mtu dhcp dhcpv6 ip4table ip6table \
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

	gsm_info=$(ubus call $gsm_modem info)
	red_cap=$(jsonfilter -q -s "$gsm_info" -e '@.red_cap')

	if [ "$deny_roaming" = "1" ]; then
		reg_stat_str=$(jsonfilter -s "$gsm_info" -e '@.cache.reg_stat_str')
		if [ "$reg_stat_str" = "Roaming" ]; then
			echo "Roaming detected. Stopping connection"
			proto_notify_error "$interface" "Roaming detected"
			proto_block_restart "$interface"
			return
		fi
	fi

	get_qmimux_by_id() {
		local interface
		for interface in /sys/class/net/qmimux*; do
			if [ "$1" -eq "$(cat "${interface}/qmap/mux_id" 2>/dev/null | \
			awk '{printf "%d", $1}')" ]; then
				qmimux="${interface:15}" #Because of /sys/class/net/
				break
			fi
		done
	}

	get_last_mux_id() {
		local tid interface
		ifid=0
		tid=0
		for interface in /sys/class/net/qmimux*; do
			tid="$(cat "${interface}/qmap/mux_id" 2>/dev/null | awk '{printf "%d", $1}')"
			[ "$tid" != "" ] && [ "$tid" -gt "$ifid" ] && ifid="$tid"
		done
		let "ifid++"
	}

	manage_qmimux_interface() {
		local fd=1000
		flock -n $fd &> /dev/null
		if [ "$?" != "0" ]; then
			exec 1000>"/var/lock/qmimux.lock"
			flock $fd
			if [ "$?" != "0" ]; then
				echo "$interface Lock failed"
				return 0
			fi
			#Create new qmimux interface
			get_last_mux_id
			echo "$ifid" > "/sys/class/net/${ifname}/qmi/add_mux" 2>/dev/null
			get_qmimux_by_id "$ifid"
			flock -u $fd
		fi
		return 1
	}

#~ ---------------------------------------------------------------------
	[ -n "$ctl_device" ] && device="$ctl_device"
	[ -z "$timeout" ] && timeout="30"
	[ -z "$metric" ] && metric="1"
	service_name="wds"
	options="--timeout 6000"

	#~ Find interface name
	devname="$(basename "$device")"
	devpath="$(readlink -f /sys/class/usbmisc/$devname/device/)"
	ifname="$(ls "$devpath"/net)"

	[ -n "$ifname" ] || {
		echo "The interface could not be found."
		proto_notify_error "$interface" NO_IFACE
		return 1
	}

	#Change rx_urb_size
	ip link set "$ifname" mtu "$dl_max_size" || {
		echo "Can not set aggregation size $dl_max_size on ${ifname}!"
		proto_notify_error "$interface" NO_AGGR
		return 1
	}

	set_package_aggregation() {
		local path="$1"
		local value="$2"
		local curr_value

		curr_value=$(cat "$path")

		if [ "$curr_value" != "$value" ]; then
			echo "$value" > "$path" 2>/dev/null
		fi
	}

	set_package_aggregation "/sys/class/net/${ifname}/qmi/tx_max_size_mux" "$ul_max_size"
	set_package_aggregation "/sys/class/net/${ifname}/qmi/tx_max_datagrams_mux" "$ul_max_datagrams"

	manage_qmimux_interface && return 1

#~ Connectivity part----------------------------------------------------
	echo "Calculated qmimux ifname: $qmimux"

	echo -e "${ifname}\n${qmimux}" > "/var/run/qmux/${interface}.up"

	first_uqmi_call "uqmi -d $device --timeout 10000 --set-autoconnect disabled" || return 1

	dataformat="$(uqmi -d "$device" $options --wda-get-data-format)"
	qmi_error_handle "$dataformat" "$error_cnt" "$modem" || return 1

	if [[ "$dataformat" =~ '"raw-ip"' ]]; then

		[ -f "/sys/class/net/$ifname/qmi/raw_ip" ] || {
			echo "Device only supports raw-ip mode but is missing this \
required driver attribute: /sys/class/net/$ifname/qmi/raw_ip"
			proto_notify_error "$interface" NO_RAW_IP
			return 1
		}

		echo "Informing driver of raw-ip for $ifname .."
		ret=$(uqmi -d "$device" $options --set-expected-data-format raw-ip)
		qmi_error_handle "$ret" "$error_cnt" "$modem" || return 1

		echo "Y" > "/sys/class/net/${ifname}/qmi/raw_ip" 2>/dev/null
	fi

	uqmi_modify_data_format "qmux"
	[ $? -ne 0 ] && return 1

	pdptype="$(echo "$pdptype" | awk '{print tolower($0)}')"
	[ "$pdptype" = "ip" ] || [ "$pdptype" = "ipv6" ] || [ "$pdptype" = "ipv4v6" ] || pdptype="ip"

	if [ "$red_cap" != "true" ]; then

		call_uqmi_command "uqmi -d $device $options--modify-profile 3gpp,${pdp} --roaming-disallowed-flag no"
	fi

	#if this flag exist CM should only establish that type connection
	pdp_error_cause_flg=$(cat /tmp/mobile/$interface 2>/dev/null)

	retry_before_reinit="$(cat /tmp/conn_retry_$interface)" 2>/dev/null
	[ -z "$retry_before_reinit" ] && retry_before_reinit="0"

	if [ "$red_cap" = "true" ]; then
		wait_for_serving_system_via_at_commands || return 1
	else
		wait_for_serving_system || return 1
	fi

	[[ "$pdptype" = "ip" ]] || [[ "$pdptype" = "ipv4v6" && "$pdp_error_cause_flg" != "IPv6" ]] && {

		cid_4=$(call_uqmi_command "uqmi -d $device $options --get-client-id wds")
		[ $? -ne 0 ] && return 1

		check_digits $cid_4
		if [ $? -ne 0 ]; then
			echo "Unable to obtain client IPV4 ID"
		fi
		touch "/var/run/qmux/$interface.cid_$cid_4"
		echo "cid4: $cid_4"

		#~ Bind context to port
		call_uqmi_command "uqmi -d $device $options --wds-bind-mux-data-port --mux-id \
${ifid} --ep-iface-number ${ep_iface} --set-client-id wds,${cid_4}"

		#~ Set ipv4 on CID
		call_uqmi_command "uqmi -d $device $options --set-ip-family ipv4 \
--set-client-id wds,$cid_4"
		# on this case we need to relase client id
		if [ $? -ne 0 ]; then
			return 1
		fi

		#~ Start PS call
		if [ "$red_cap" = "true" ]; then
			pdh_4=$(call_uqmi_command "uqmi -d $device $options --set-client-id wds,$cid_4 \
--start-network --profile $pdp" "true")
		else
			pdh_4=$(call_uqmi_command "uqmi -d $device $options --set-client-id wds,$cid_4 \
--start-network --profile $pdp --ip-family ipv4" "true")
		fi
		#~ Check if we haven't received a specific error that
		# requires waiting for an action from mobifd, and don't need to retry
		# on this case we need to relase client id
		if [ $? -eq 2 ]; then
			return 1
		fi

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

	[[ "$pdptype" = "ipv6" ]] || [[ "$pdptype" = "ipv4v6" && "$pdp_error_cause_flg" != "IPv4" ]] && {

		cid_6=$(call_uqmi_command "uqmi -d $device $options --get-client-id wds")
		[ $? -ne 0 ] && return 1

		check_digits $cid_6
		if [ $? -ne 0 ]; then
			echo "Unable to obtain client IPV6 ID"
		fi
		touch "/var/run/qmux/$interface.cid_$cid_6"
		echo "cid6: $cid_6"

		call_uqmi_command "uqmi -d $device $options --wds-bind-mux-data-port --mux-id $ifid \
--ep-iface-number $ep_iface --set-client-id wds,$cid_6"

		#~ Set ipv6 on CID
		ret=$(call_uqmi_command "uqmi -d $device $options --set-ip-family ipv6 \
--set-client-id wds,$cid_6")
		# on this case we need to relase client id
		if [ $? -ne 0 ]; then
			return 1
		fi

		#~ Start PS call
		pdh_6=$(call_uqmi_command "uqmi -d $device $options --set-client-id wds,$cid_6 \
--start-network --ip-family ipv6 --profile $pdp" "true")
		#~ Check if we haven't received a specific error that
		# requires waiting for an action from mobifd, and don't need to retry
		# on this case we need to relase client id
		if [ $? -eq 2 ]; then
			return 1
		fi

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

	echo "Setting up $qmimux"
	rm -f /tmp/mobile/$interface

	set_mtu "$qmimux"

	# Disable GRO on non-qmapv5 interfaces, only qmapv5 provides RX csum offloading.
	[ $dl_max_size -le 16384 ] && ethtool -K "$qmimux" gro off

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
		setup_bridge_v4 "$qmimux"

		#Passthrough
		[ "$method" = "passthrough" ] && {
			iptables -w -tnat -I postrouting_rule -o "$qmimux" -j SNAT --to "$bridge_ipaddr"
			ip route add default dev "$qmimux" metric "$metric"
		}
	}

	[ "$method" != "bridge" ] && [ "$method" != "passthrough" ] && \
	[ -n "$pdh_4" ] && [ "$ipv4" = "1" ] && {
		if [ "$dhcp" = 0 ]; then
			setup_static_v4 "$qmimux"
		else
			setup_dhcp_v4 "$qmimux"
		fi

		IFACE4="${interface}_4"
		ubus_set_interface_data "$modem" "$sim" "$zone" "$IFACE4"
	}

	[ -n "$pdh_6" ] && [ "$ipv6" = "1" ] && {
		if [ "$dhcpv6" = 0 ]; then
			setup_static_v6 "$qmimux"
		else
			setup_dhcp_v6 "$qmimux"
		fi

		IFACE6="${interface}_6"
		ubus_set_interface_data "$modem" "$sim" "$zone" "$IFACE6"
	}

	[ "$ipv4" != "1" ] && [ "$pdptype" = "ip" ] && proto_notify_error "$interface" "$pdh_4"
	[ "$ipv6" != "1" ] && [ "$pdptype" = "ipv6" ] && proto_notify_error "$interface" "$pdh_6"
	[ "$pdptype" = "ipv4v6" ] && [ "$ipv4" != "1" ] && [ "$ipv6" != "1" ] && proto_notify_error "$interface" "$pdh_4" && proto_notify_error "$interface" "$pdh_6"

	proto_export "IFACE4=$IFACE4"
	proto_export "IFACE6=$IFACE6"
	proto_run_command "$interface" qmuxtrack "$device" "$modem" "$cid_4" "$cid_6"
}
#~ ---------------------------------------------------------------------

proto_qmux_teardown() {
	#~ netifd has 15 seconds timeout to finish this function
	#~ it is killed if not finished
	#~ Slow routers can fail to finish teardown
	#~ We need to put some time taking actions to background
	local interface="$1"
	local qmiif mif conn_proto
	local device bridge_ipaddr method
	local braddr_f="/var/run/${interface}_braddr"

	touch "/tmp/shutdown_$interface"
	json_get_vars device

	[ -n "$ctl_device" ] && device="$ctl_device"

	echo "Stopping network $interface"

	conn_proto="qmux"

	[ -f "$braddr_f" ] && {
		method=$(get_braddr_var method "$interface")
		bridge_ipaddr=$(get_braddr_var bridge_ipaddr "$interface")
	}

	mif=$(cat "/var/run/${conn_proto}/${interface}.up" 2>/dev/null | head -1)
	qmiif=$(cat "/var/run/${conn_proto}/${interface}.up" 2>/dev/null | tail -1)

	rm -f "/var/run/${conn_proto}/${interface}.up" 2> /dev/null

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

		if is_device_dsa ; then
			restart_dsa_interfaces
		else
			swconfig dev switch0 set soft_reset 5 &
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

	# Remove device after interfaces are down
	remove_qmimux "$qmiif" "$mif"

	proto_init_update "*" 0
	proto_send_update "$interface"
}

[ -n "$INCLUDE_ONLY" ] || {
	if [ $dl_max_size -gt 16384 ]; then
		add_protocol qmapv5
	else
		add_protocol qmux
	fi
}
