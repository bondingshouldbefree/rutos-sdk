#!/bin/sh

. /lib/functions.sh
. /lib/config/uci.sh
. /usr/share/libubox/jshn.sh
[ -r "/usr/libexec/reboot_utils/ping_reboot_mobile.sh" ] && . /usr/libexec/reboot_utils/ping_reboot_mobile.sh

USAGE="Usage: ping_reboot.sh [-p] [-h] <section_name>
  -p, --portmap      Only map hosts to ports and exit, only available on PoE devices
  -h, --help         Show this help message"
SHOW_HELP=0
DO_PORTMAP=0
SECTION=""

while [ $# -gt 0 ]; do
	case "$1" in
		-h|--help)
			SHOW_HELP=1
			shift
			;;
		-p|--portmap)
			DO_PORTMAP=1
			shift
			;;
		*)
			if [ -z "$SECTION" ]; then
				SECTION="$1"
				shift
			else
				echo "Unknown argument: $1"
				echo "$USAGE"
				exit 1
			fi
			;;
	esac
done
if [ "$SHOW_HELP" -eq 1 ]; then
	echo "$USAGE"
	exit 0
fi
if [ -z "$SECTION" ]; then
	echo "Error: <section_name> argument is required."
	echo "$USAGE"
	exit 1
fi

WDIR="/var/run/preboot"
FILE="${WDIR}/wget_check_file"
PINGCMD="/bin/ping"
PINGCMDV6="/bin/ping6"
DFOTA_LOCK="/var/lock/modem_dfota.lock"
DUAL_MODEM=0
HAS_SWCONFIG=0
FAIL_COUNT_FILE="${WDIR}/fail_counter_${SECTION}"
KV_SEP=","
ACTIVE_MOBILE_IFACES="" # e.g. "mob1s1a1 mob2s1a1"
# contains list of mobile ifnames for each sim (e.g. "qmimux0 qmimux1")
IF_OPTION1=""
IF_OPTION2=""
# Map of mobile device to interface (e.g. "qmimux0,mob1s1a1 qmimux1,mob2s1a1"). Used for quota_limit check
DEV_IFACE_MAP=""
# Map of hosts to ports (e.g. "host1,port1 host2,port2"). Used for port ping to know which port to restart when device with IP disappears
PORT_HOST_MAP=""

kvmap_get() {
	local map="$1"
	local key="$2"
	echo "$map" | tr ' ' '\n' | grep "^$key$KV_SEP" | cut -d$KV_SEP -f2
}
kvmap_remove() {
	local map="$1"
	local key="$2"

	map=$(echo "$map" | tr ' ' '\n' | grep -v "^$key$KV_SEP" | tr '\n' ' ')
	echo "$map" | sed 's/^ *//;s/ *$//'
}
kvmap_insert() {
	local map="$1"
	local key="$2"
	local value="$3"

	map=$(echo "$map" | tr ' ' '\n' | grep -v "^$key$KV_SEP" | tr '\n' ' ')
	map="$map$key$KV_SEP$value"
	echo "$map" | sed 's/^ *//;s/ *$//'
}

log() {
	/usr/bin/logger -t ping_reboot.sh "$@"
}

check_suid() {
	for i in $1; do
		$i --help > /dev/null 2>&1 || {
			log "Insufficient permissions to execute '$i' command."
			return 1
		}
	done
}

get_config() {
	config_get ENABLE "$SECTION" "enable" 0
	config_get TIMEOUT "$SECTION" "time_out" 0
	config_get TIME "$SECTION" "time" 0
	config_get RETRIES "$SECTION" "retry" 0
	config_get HOST "$SECTION" "host" ""
	config_get PORT_HOST "$SECTION" "port_host" ""
	config_get ACTION "$SECTION" "action" 0
	config_get PACKET_SIZE "$SECTION" "packet_size" 0
	config_get MODEM "$SECTION" "modem" ""
	config_get TYPE "$SECTION" "type" ""
	config_get STOP_ACTION "$SECTION" "stop_action" 0
	# Determines if ping is done using any available interface (1) or any mobile interface (2)
	config_get IF_TYPE "$SECTION" "interface" 1
	config_get PHONE_LIST "$SECTION" "number" ""
	config_get MESSAGE "$SECTION" "message" ""
	config_get MODEM_ID_SMS "$SECTION" "modem_id_sms" ""
	config_get IP_TYPE "$SECTION" ip_type "ipv4"
	config_get IP_TYPE1 "$SECTION" ip_type1 "ipv4"
	config_get IP_TYPE2 "$SECTION" ip_type2 "ipv4"
	config_get PING_PORT_TYPE "$SECTION" ping_port_type ""
	config_get PORT "$SECTION" port ""
	config_get ACTION_WHEN "$SECTION" action_when "all"
}

get_fail_counter() {
	local key="$1"
	local val

	[ -r "$FAIL_COUNT_FILE" ] || {
		echo 0

		return 1
	}
	
	val=$(cat "$FAIL_COUNT_FILE")
	if [ -n "$key" ]; then
		local key_fail_count=$(kvmap_get "$val" "$key")
		[ -n "$key_fail_count" ] && echo "$key_fail_count" || echo 0
	else
		[ "$val" -eq "$val" ] 2>/dev/null && echo "$val" || echo 0
	fi
}

set_fail_counter() {
	local key="$2"

	#Validate if the argument is a number
	[ "$1" -eq "$1" ] 2>/dev/null || return
	if [ -n "$key" ]; then
		local fail_map=$(cat "$FAIL_COUNT_FILE")
		fail_map=$(kvmap_insert "$fail_map" "$key" "$1")
		echo "$fail_map" >"$FAIL_COUNT_FILE"
	else
		echo -n "$1" >"$FAIL_COUNT_FILE"
	fi
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

exec_action() {
	local port="$2"
	local host="$3"
	case "$ACTION" in
	"1")
		preboot_lock || {
			log "Cannot restart router. Process is locked by DFOTA process."

			exit 1
		}

		log "Rebooting router after ${CURRENT_TRY} unsuccessful tries"
		/bin/ubus call rpc-sys reboot "{\"safe\":true,\"args\":[\"$1\"]}"
		lock -u "$DFOTA_LOCK"
		;;
	"2")
		preboot_lock || {
			log "Cannot restart modem. Process is locked by DFOTA process."

			exit 1
		}

		log "Restarting modem after ${CURRENT_TRY} unsuccessful tries"
		ubus call log write_ext "{
			\"event\": \"Restarting modem after ${CURRENT_TRY} unsuccessful tries\",
			\"sender\": \"Ping Reboot\",
			\"table\": 0,
			\"write_db\": 1,
		}"
		restart_modem "$MODEM"
		lock -u "$DFOTA_LOCK"
		;;
	"4")
		preboot_lock || {
			log "Cannot restart modem. Process is locked by DFOTA process."

			exit 1
		}

		log "Reregistering after ${CURRENT_TRY} unsuccessful tries"
		ubus call log write_ext "{
			\"event\": \"Reregistering after ${CURRENT_TRY} unsuccessful tries\",
			\"sender\": \"Ping Reboot\",
			\"table\": 0,
			\"write_db\": 1,
		}"
		restart_modem "$MODEM"
		lock -u "$DFOTA_LOCK"
		;;
	"5")
		log "Restarting mobile data connection after ${CURRENT_TRY} unsuccessful retries"
		ubus call log write_ext "{
			\"event\": \"Restarting mobile data connection after ${CURRENT_TRY} unsuccessful retries\",
			\"sender\": \"Ping Reboot\",
			\"table\": 0,
			\"write_db\": 1,
		}"

		for iface in $ACTIVE_MOBILE_IFACES; do
			log "Restarting interface $iface"
			restart_mobile_interface "$iface"
		done
		;;
	"6")
		log "Sending message after ${CURRENT_TRY} unsuccessful retries"
		ubus call log write_ext "{
			\"event\": \"Sending message after ${CURRENT_TRY} unsuccessful retries\",
			\"sender\": \"Ping Reboot\",
			\"table\": 0,
			\"write_db\": 1,
		}"
		send_sms
		;;
	"7")
		if [ -z "$port" ]; then
			log "No port mapping found for host '$host'. Port restart will not be performed."
			return 1
		fi
		local msg=""
		[ -n "$host" ] && msg=" for host '$host'"
		log "Restarting port '$port' after ${CURRENT_TRY} unsuccessful retries$msg"
		ubus call log write_ext "{
			\"event\": \"Restarting port '$port' after ${CURRENT_TRY} unsuccessful retries$msg\",
			\"sender\": \"Ping Reboot\",
			\"table\": 0,
			\"write_db\": 1,
		}"
		restart_port "$port"
		;;
	"3" | *)
		log "${CURRENT_TRY} unsuccessful ${TYPE} tries"
		;;
	esac
}

check_tries() {
	local host="$4"
	local port="$5"
	if [ -n "$2" ]; then
		log "$2"
	fi

	if [ "$CURRENT_TRY" -ge "$RETRIES" ]; then
		if [ -n "$port" ]; then
			set_fail_counter 0 "$port"
		elif [ -n "$host" ]; then
			set_fail_counter 0 "$host"
			port=$(kvmap_get "$PORT_HOST_MAP" "$host")
		else
			set_fail_counter 0
		fi
		exec_action "$1" "$port" "$host"
	else
		log "$3"
	fi
}


# adjusts option length (returns 1 for single options and unmodified length for list options)
adjust_len() {
	local val="$1"
	local len="$2"

	if [ "$len" = 0 ]; then
		if [ -n "$val" ]; then
			echo 1
			return
		fi
	fi
	echo "$len"
}

exec_ping() {
	ping_cmd="$1"
	host="$2"
	sim="$3"
	local if_option="$IF_OPTION1"

	[ -z "$sim" ] && {
		$ping_cmd -W "$TIMEOUT" -s "$PACKET_SIZE" -q -c 1 "$host" >/dev/null 2>&1
		return $?
	}

	[ "$sim" = "2" ] && {
		if [ -n "$IF_OPTION2" ]; then
			if_option="$IF_OPTION2"
		else
			return 1
		fi
	}

	local all_over_limit=1
	for dev in $if_option; do
		local interface=$(kvmap_get "$DEV_IFACE_MAP" "$dev")
		if $ping_cmd -I "$dev" -W "$TIMEOUT" -s "$PACKET_SIZE" -q -c 1 "$host" >/dev/null 2>&1; then
			return 0
		elif is_over_limit "$interface"; then
			log "Interface $interface is over data limit. Considering ping successful."
			continue
		else
			all_over_limit=0
		fi
	done

	if [ "$all_over_limit" -eq 1 ]; then
		# if all interfaces are over limit, consider ping successful
		return 0
	fi

	return 1
}

perform_multiple_pings_ping() {
	local hosts="$1"
	local ping_cmd="$2"
	local sim="$3"
	local passed_var="$4"
	local failed_var="$5"

	if [ "$IF_TYPE" = "2" ]; then
		[ -z "$IF_OPTION1" ] && [ -z "$IF_OPTION2" ] && {
			check_tries "-p" "No mobile data connection active" "${TIME} min. until next ping retry"
			exit
		}
	fi

	for host in $hosts; do
		if exec_ping "$ping_cmd" "$host" "$sim"; then
			eval "$passed_var=\$(( $passed_var + 1 ))"
			log "Ping ${host} successful."
		elif [ "$ACTION_WHEN" = "any" ]; then
			check_tries "-p" "Host ${host} unreachable" \
				"${TIME} min. until next ping retry"
			eval "$failed_var=\$(( $failed_var + 1 ))"
			return;
		else
			eval "$failed_var=\$(( $failed_var + 1 ))"
			log "Ping ${host} failed."
		fi
	done
}

perform_multiple_pings() {
	local passed_pings=0
	local failed_pings=0
	local ping_cmd="$PINGCMD"
	local ping_cmd1="$PINGCMD"
	local ping_cmd2="$PINGCMD"
	[ "$IP_TYPE" = "ipv6" ] && ping_cmd="$PINGCMDV6"
	[ "$IP_TYPE1" = "ipv6" ] && ping_cmd1="$PINGCMDV6"
	[ "$IP_TYPE2" = "ipv6" ] && ping_cmd2="$PINGCMDV6"

	check_suid "$ping_cmd $ping_cmd1 $ping_cmd2" || return 1

	config_get len "$SECTION" "host_LENGTH" 0
	config_get len1 "$SECTION" "host1_LENGTH" 0
	config_get len2 "$SECTION" "host2_LENGTH" 0

	if [ -z "$len" ] || { [ -z "$len1" ] || [ -z "$len2" ]; } then
		log "Failed to get host list."
		return;
	fi

	config_get host "$SECTION" "host" ""
	config_get host1 "$SECTION" "host1" ""
	config_get host2 "$SECTION" "host2" ""
	len=$(adjust_len "$host" "$len")
	len1=$(adjust_len "$host1" "$len1")
	len2=$(adjust_len "$host2" "$len2")

	[ "$len" -gt 0 ] && perform_multiple_pings_ping "$host" "$ping_cmd" "" passed_pings failed_pings

	if [ "$DUAL_MODEM" -eq 1 ]; then
		# Handle SIMs running simultaneously in dual modem devices
		[ "$len1" -gt 0 ] && perform_multiple_pings_ping "$host1" "$ping_cmd1" "1" passed_pings failed_pings
		[ "$len2" -gt 0 ] && perform_multiple_pings_ping "$host2" "$ping_cmd2" "2" passed_pings failed_pings
	elif [ -n "$MODEM" ]; then
		# Handle single SIM running in single modem devices
		json_load "$(ubus call gsm.modem0 get_sim_slot)"
		json_get_var index index
		if [ "$index" -eq 1 ]; then
			perform_multiple_pings_ping "$host1" "$ping_cmd1" "$index" passed_pings failed_pings
		else
			perform_multiple_pings_ping "$host2" "$ping_cmd2" "$index" passed_pings failed_pings
		fi
	fi

	[ "$ACTION_WHEN" = "any" ] && [ "$failed_pings" -ne 0 ] && return;

	if { [ "$len" -gt "0" ] && [ "$passed_pings" -ge "$len" ]; } || 
	{ [ "$len1" -gt "0" ] && [ "$passed_pings" -ge "$len1" ]; } || 
	{ [ "$len2" -gt "0" ] && [ "$passed_pings" -ge "$len2" ]; }
	then
		set_fail_counter 0
		log "Pings successful."
		return;
	elif [ "$ACTION_WHEN" = "all" ] && {
	{ [ "$len" -gt "0" ] && [ "$failed_pings" -ge "$len" ]; } || 
	{ [ "$len1" -gt "0" ] && [ "$failed_pings" -ge "$len1" ]; } || 
	{ [ "$len2" -gt "0" ] && [ "$failed_pings" -ge "$len2" ]; } ; }
	then
		check_tries "-p" "" "${TIME} min. until next ping retry"
		return;
	fi
	set_fail_counter 0
}

perform_wget() {
	local failed_wgets=0
	local passed_wgets=0
	config_get len "$SECTION" "host_LENGTH" 0
	len=$(adjust_len "$HOST" "$len")

	if [ -z "$len" ]; then
		log "Failed to get host list."
		return;
	fi

	for element in $HOST; do
		wget -q -T "$TIMEOUT" "$element" -O $FILE >/dev/null 2>&1

		if [ "$ACTION_WHEN" = "any" ] && [ ! -s $FILE ]; then
			check_tries "-g" "Can't wget URL." "Will be retrying wget"
			return;
		elif [ "$ACTION_WHEN" = "all" ] && [ ! -s $FILE ]; then
			failed_wgets=$((failed_wgets + 1))
			log "Wget ${element} URL failed."
		else
			passed_wgets=$((passed_wgets + 1))
			log "Wget ${element} URL successful."
		fi

		rm $FILE >/dev/null 2>&1
	done

	if [ "$passed_wgets" -ge "$len" ]; then
		set_fail_counter 0
		log "Wgets URL successful."
	elif [ "$failed_wgets" -ge "$len" ]; then
		check_tries "-g" "Can't wget URL." "Will be retrying wget"

		return
	fi

	set_fail_counter 0
}

setup() {
	config_load ping_reboot
	get_config

	[ "$ENABLE" -ne 1 ] && exit 0
	[ -d "$WDIR" ] || mkdir -p "$WDIR" 2>/dev/null || {
		log "Failed to create directory $WDIR"
		exit 1
	}

	[ -z "$MODEM" ] && {
		get_modem
		[ -n "$MODEM" ] && {
			uci_set ping_reboot "$SECTION" modem "$MODEM"
			uci_commit ping_reboot
		}
	}

	[ -n "$MODEM" ] && {
		config_load network || {
			log "Failed to load network config. Insufficient permissions."
			exit 1
		}
		config_foreach get_active_mobile_interface "interface"
	}

	config_load ping_reboot
}

setup

if [ $DO_PORTMAP -eq 1 ]; then
	. /usr/libexec/reboot_utils/ping_reboot_port.sh

	swconfig list > /dev/null 2>&1 && HAS_SWCONFIG=1
	map_hosts_to_ports
	exit
fi

case "$TYPE" in
"ping"|"wget")
	CURRENT_TRY=$(get_fail_counter)
	CURRENT_TRY=$((CURRENT_TRY + 1))
	set_fail_counter $CURRENT_TRY
	;;
esac

case "$TYPE" in
"ping")
	perform_multiple_pings
	;;
"wget")
	perform_wget
	;;
"port")
	. /usr/libexec/reboot_utils/ping_reboot_port.sh

	# port ping uses different fail counting
	swconfig list > /dev/null 2>&1 && HAS_SWCONFIG=1
	perform_port_ping
	;;
esac
