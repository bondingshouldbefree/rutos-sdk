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
	logger -t "netifd" "$cmd"

	while true; do
		ret=$($cmd)
		if [ "$ret" = "" ] || [ "$ret" = "\"Failed to connect to service\"" ] || \
                [ "$ret" = "\"Request canceled\"" ] || [ "$ret" = "\"Unknown error\"" ] ; then

			count=$((count+1))
			sleep $timeout
		else
			break
		fi
		if [ "$count" = "$max_try" ]; then
			gsm_hard_reset "$modem"
			kill_uqmi_processes "$device"
			return 1
		fi
	done
}

call_uqmi_command() {
	command="$1"
	skip_reset="$2"
	logger -t "netifd" "$command"
	ret=$($command)
	[ -n "$ret" ] && echo "$ret"
	qmi_error_handle "$ret" "$error_cnt" "$modem" "$skip_reset" || return 1
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
		call_uqmi_command "uqmi -s -d ${device} -t 3000 --set-client-id wds,$cid \
--stop-network 0xFFFFFFFF --autoconnect"
		logger -t "qmux" "Freeing cid: ${cid}"
		call_uqmi_command "uqmi -s -d ${device} -t 3000 --set-client-id wds,$cid \
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

	logger "$command"
	ret=$(eval $command)
	if [ "$red_cap" = "true" ] && [ "$ret" = "" ]; then
		 return 0
	fi
	qmi_error_handle "$ret" "$error_cnt" "$modem" || return 1
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
	while [ "$reg_status" != "attached" ]; do
		gsm_call=$(ubus call $gsm_modem get_ps_att_state)
		reg_status=$(jsonfilter -s "$gsm_call" -e '@.state')

		[ -z "$reg_status" ] && echo "Can't get PS registration state" && return 1
		[ "$reg_status" = "attached" ] && return 0

		if [ "$registration_timeout" -lt "$timeout" ]; then
			let "registration_timeout += 5"
			sleep 5
		else
			echo "Network registration failed"
			proto_notify_error "$interface" NO_NETWORK
			handle_retry "$retry_before_reinit" "$interface"
			return 1
		fi
	done
	return 0
}

wait_for_serving_system() {
	local registration_timeout=0
	local serving_system="$(uqmi -s -d "$device" $options --get-serving-system)"
	qmi_error_handle "$serving_system" "$error_cnt" "$modem" || return 1
	while [ "$(echo "$serving_system" | grep registration | \
		awk -F '\"' '{print $4}')" != "registered" ] && \
		[ "$( echo "$serving_system" | grep PS | awk -F ' ' '{print $2}' | \
		awk -F ',' '{print $1}')" != "attached" ]
	do
		[ -e "$device" ] || return 1
		if [ "$registration_timeout" -lt "$timeout" ]; then
			let "registration_timeout += 5"
			sleep 5
		else
			echo "Network registration failed"
			proto_notify_error "$interface" NO_NETWORK
			handle_retry "$retry_before_reinit" "$interface"
			return 1
		fi
		serving_system="$(uqmi -s -d "$device" $options --get-serving-system)"
		qmi_error_handle "$serving_system" "$error_cnt" "$modem" || return 1
	done
	return 0
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