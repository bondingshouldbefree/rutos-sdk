#uqmi shared functions

. /lib/functions.sh
. /lib/functions/mobile.sh

first_uqmi_call()
{
	local cmd="$1"

	local count="0"
	local max_try="6"
	local timeout="2"
	local ret

	while true; do
		logger -t "netifd" "$cmd"
		ret=$($cmd)
		case "$ret" in
		"" | '"Failed to connect to service"' | '"Request canceled"' | '"Unknown error"' | '"Request timed out"' )
			count=$((count+1))
			sleep $timeout
			;;
		*) break ;;
		esac
		if [ "$count" = "$max_try" ]; then
			gsm_hard_reset "$modem"
			kill_uqmi_processes "$device"
			return 1
		fi
	done
}

verify_data_connection() {
    #refractor this
	local pdptype_in="$1"
	case "$pdptype_in" in
	ip)
		[ "$ipv4" != "1" ] && {
			qmi_error_handle "$pdh_4" "$retry_before_reinit" "$modem" ""
			echo "Failed to create IPV4 connection"
			sleep $fail_timeout
			proto_notify_error "$interface" "$pdh_4"
			handle_retry "$retry_before_reinit" "$interface"
			return 1
		}
		;;
	ipv6)
		[ "$ipv6" != "1" ] && {
			qmi_error_handle "$pdh_6" "$retry_before_reinit" "$modem" ""
			echo "Failed to create IPV6 connection"
			sleep $fail_timeout
			proto_notify_error "$interface" "$pdh_6"
			handle_retry "$retry_before_reinit" "$interface"
			return 1
		}
		;;
	ipv4v6)
		[ "$ipv4" != "1" ] && {
			cid_4=""
		}
		[ "$ipv6" != "1" ] && {
			cid_6=""
		}
		[ "$ipv4" != "1" ] && [ "$ipv6" != "1" ] && {
			qmi_error_handle "$pdh_4" "$retry_before_reinit" "$modem" "" && \
			qmi_error_handle "$pdh_6" "$retry_before_reinit" "$modem" ""
			echo "Failed to create IPV4V6 connection"
			proto_notify_error "$interface" "$pdh_6"
			proto_notify_error "$interface" "$pdh_4"
			sleep $fail_timeout
			handle_retry "$retry_before_reinit" "$interface"
			return 1
		}
		;;
	esac
	return 0
}

clear_connection_values() {
	local interface device conn_proto
	interface="$1"
	device="$2"
	conn_proto="$3"
	qmi_call_retry_count=1

	cids_to_clear=$(ls "/var/run/${conn_proto}/${interface}.cid_"*) 2>/dev/null
	# iterate through all cids and clear them
	for cid_file in $cids_to_clear; do
		if [ ! -f "$cid_file" ]; then
			logger -t "qmux" "File $cid_file does not exist, Skipping"
			continue
		fi
		cid=${cid_file##*/}
		cid=${cid#${interface}.cid_}
		if [ -z "$cid" ]; then
			logger -t "qmux" "No CID found in file $cid_file, Skipping"
			continue
		fi

		logger -t "qmux" "Stopping network on device: ${device} cid: $cid"
		call_qmi_command "uqmi -s -d ${device} -t 3000 --set-client-id wds,$cid \
--stop-network 0xFFFFFFFF --autoconnect"
		logger -t "qmux" "Freeing cid: ${cid}"
		call_qmi_command "uqmi -s -d ${device} -t 3000 --set-client-id wds,$cid \
--release-client-id wds"

		rm -f "$cid_file"
	done
}

uqmi_modify_data_format() {
	QMI_PROTOCOL="$1"
	if [ "$QMI_PROTOCOL" = "qmi" ]; then
		command="uqmi -d "${device}" $options --wda-set-data-format --link-layer-protocol raw-ip \
--ul-protocol disabled --dl-protocol disabled"
	elif [ $dl_max_size -gt 16384 ]; then
		command="uqmi -d "$device" $options --wda-set-data-format --qos-format 0 \
--link-layer-protocol raw-ip --endpoint-type hsusb --endpoint-iface-number $ep_iface
--ul-protocol qmapv5 --dl-protocol qmapv5 --ul-max-datagrams $ul_max_datagrams --ul-datagram-max-size $ul_max_size \
--dl-max-datagrams $dl_max_datagrams --dl-datagram-max-size $dl_max_size --dl-min-padding 0"
	else
		command="uqmi -d "${device}" $options --wda-set-data-format --link-layer-protocol raw-ip \
--ul-protocol qmap --dl-protocol qmap --dl-max-datagrams $dl_max_datagrams \
--dl-datagram-max-size $dl_max_size --ul-max-datagrams $ul_max_datagrams --ul-datagram-max-size $ul_max_size --dl-min-padding 0"
	fi

	call_qmi_command "$command" "true" || [ "$red_cap" = "true" ]
}

wait_for_clear_connection_values()
{
	local interface="$1"
	local device="$2"
	local conn_proto="$3"
	clear_increased_timeout=30

	clear_connection_values "$interface" "$device" "$conn_proto" &
	pid_clear=$!
	# wait for clear_connection_values to finish or until timeout is reached
	current_timeout=0
	while kill -0 $pid_clear 2>/dev/null; do
		sleep 3
		current_timeout=$((current_timeout+3))
		if [ $current_timeout -ge $clear_increased_timeout ]; then
			kill -9 $pid_clear
			logger -t "qmux" "clear_connection_values $interface $iptype reached a timeout"
			break
		fi
	done
}

background_clear_conn_values()
{
	local interface="$1"
	local device="$2"
	local conn_proto="$3"

	wait_for_clear_connection_values "$interface" "$device" "$conn_proto"

	logger -t "qmux" "$interface teardown successful"
	rm "/tmp/shutdown_$interface"
}

wait_for_serving_system_via_at_commands() {
	local reg_status=""
	local registration_timeout=0
	local max_registration_timeout=6
	while [ "$registration_timeout" -lt "$max_registration_timeout" ]; do
		gsm_call=$(ubus call $gsm_modem get_ps_att_state)
		reg_status=$(jsonfilter -s "$gsm_call" -e '@.state')

		[ -z "$reg_status" ] && echo "Can't get PS registration state" && return 1
		[ "$reg_status" = "attached" ] && return 0

		let "registration_timeout += 1"
		sleep 5
	done

	echo "Network registration failed"
	proto_notify_error "$interface" NO_NETWORK
	handle_retry "$retry_before_reinit" "$interface"
	return 1
}

wait_for_serving_system() {
	local registration_timeout=0
	local serving_system=""
	local max_registration_timeout=6
	while [ "$registration_timeout" -lt "$max_registration_timeout" ]; do
		serving_system=$(call_qmi_command "uqmi -s -d $device $options --get-serving-system") || return 1

		[ -e "$device" ] || return 1
		if [ "$(echo "$serving_system" | grep registration | \
			awk -F '\"' '{print $4}')" = "registered" ] || \
			[ "$( echo "$serving_system" | grep PS | awk -F ' ' '{print $2}' | \
			awk -F ',' '{print $1}')" = "attached" ]; then
			echo "$serving_system"
			return 0
		fi

		let "registration_timeout += 1"
		sleep 5
	done

	echo "Network registration failed"
	proto_notify_error "$interface" NO_NETWORK
	handle_retry "$retry_before_reinit" "$interface"
	return 1
}

get_dynamic_mtu() {
	local parameters="$1"
	local connstate="$2"
	local interface_name="$3"
	local operator_mtu="$(echo "$parameters" | jsonfilter -qe '@.mtu')"

	[ -z "$mtu" ] && [ "$connstate" = "1" ] && {
		mtu="$operator_mtu"
		mtu_state="dynamic"
	} || mtu_state="configured"

	notify_mtu_diff "$operator_mtu" "$interface_name" "$mtu"
}

set_mtu() {
	local interface_name="$1"
	[ -z "$mtu" ] && mtu_state="default" && mtu=1500
	[ -z "$mtu" ] || {
		echo "Setting $mtu_state MTU: $mtu on $interface_name"
		ip link set mtu "$mtu" "$interface_name"
	}
}

wait_for_shutdown_complete()
{
	local interface="$1"
	shutdown_timeout=30

	while [ -f "/tmp/shutdown_$interface" ]; do
		[ $shutdown_timeout -eq 0 ] && {
			rm "/tmp/shutdown_$interface"
			logger -t "qmux" "shutdown_$interface flag removed after 60s timeout"
			break
		}
		sleep 2
		shutdown_timeout=$((shutdown_timeout-1))
	done
}

uqmi_start_network() {
	local _iptype=$1
	local _is_ipv4
	_is_ipv4=$([ "$_iptype" -eq 4 ] && echo 1 || echo 0)
	state=0

	cid=$(call_qmi_command "uqmi -d $device $options --get-client-id wds") || return 1


	if ! check_digits "$cid"; then
		echo "Unable to obtain client IPV$_iptype ID"
	fi
	touch "/var/run/qmux/$interface.cid_$cid"

	#~ Bind context to port
	# Dont call this on connm proto
	[ -n "$ifid" ] && call_qmi_command "uqmi -d $device $options --wds-bind-mux-data-port --mux-id ${ifid} --ep-iface-number ${ep_iface} --set-client-id wds,${cid}"

	#~ Set ip type on CID
	call_qmi_command "uqmi -d $device $options --set-ip-family ipv$_iptype --set-client-id wds,$cid" || return 1

	#~ Start PS call
	"${red_cap:-false}" && [ "$_is_ipv4" -eq 1 ] || ip_family_arg="--ip-family ipv$_iptype"
	pdh=$(call_qmi_command "uqmi -d $device $options --set-client-id wds,$cid \
--start-network --profile $pdp $ip_family_arg" "true")

	#~ Check if we haven't received a specific error that
	# requires waiting for an action from mobifd, and don't need to retry
	# on this case we need to relase client id
	if [ $? -eq 2 ]; then
		return 1
	fi

	if ! check_digits "$pdh"; then
		# pdh is a numeric value on success
		echo "Unable to connect IPv$_iptype"
		return 0
	fi

	# Check data connection state
	connstat="$(call_qmi_command "uqmi -d $device $options --set-client-id wds,"$cid" --get-data-status" | awk -F '"' '{print $2}')"
	if [ "$connstat" = "connected" ]; then
		state=1
	else
		echo "No IPV_$iptype data link!"
	fi
	parameters="$(call_qmi_command "uqmi -d $device $options --set-client-id wds,"$cid" --get-current-settings")"
	get_dynamic_mtu "$parameters" "$state" "$interface"

	return 0
}
