
# This file contains functions related to port PoE management for ping reboot functionality

restart_poe() {
	/bin/ubus call poeman set "{\"port\":\"$1\",\"enable\":false}"
	sleep 3
	/bin/ubus call poeman set "{\"port\":\"$1\",\"enable\":true}"
}

restart_port() {
	ubus list poeman >/dev/null 2>&1 || return 0
	config_load poe || {
		log "Failed to load poe config. Insufficient permissions."

		return 1
	}

	if [ -n "$1" ]; then
		config_get POE_ENABLE "$1" "poe_enable" 0
		config_get NAME "$1" "name" ""
		if [ "$POE_ENABLE" = 1 ] && [ -n "$NAME" ]; then
			restart_poe "$NAME"
		fi
	fi
}

get_hex_from_position() {
	position=$(($1 + 1))
	local hex_value=""
	if [ -z "$1" ] || [ "$1" -le 1 ]; then
		hex_value="0x01"
	else
		local decimal_value=$((2 ** (position - 1)))
		hex_value=$(printf "0x%02x" "$decimal_value")
	fi
	echo "$hex_value"
}

get_position_from_hex() {
	local value="$1"
	local position=0

	# Remove the "0x" prefix and convert to decimal
	local decimal_value=$(echo "$value" | sed 's/0x//' | awk '{printf "%d", "0x" $0}')

	while [ $((decimal_value % 2)) -eq 0 ]; do
		decimal_value=$((decimal_value / 2))
		position=$((position + 1))
	done

	echo "$position"
}

perform_double_ping() {
	local ping_cmd="$PINGCMD"
	local ipv4_ping=0
	local ipv6_ping=0

	for i in $(cat /proc/net/arp | grep -w "$1" | awk '{print $1}'); do
		if [ -n "$i" ] && [ "$i" != "IP" ]; then
			if exec_ping "$ping_cmd" "$i"; then
				ipv4_ping=1
			fi
		fi
	done

	ping_cmd="$PINGCMDV6"
	for j in $(ip -6 neigh | grep -w "$1" | awk '{print $5}'); do
		if [ -n "$j" ]; then
			if exec_ping "$ping_cmd" "$j"; then
				ipv6_ping=1
			fi
		fi
	done

	if [ "$ipv4_ping" = 1 ] || [ "$ipv6_ping" = 1 ] && [ "$2" -ge "$3" ]; then
		echo 1
	else
		echo 0
	fi
}

# only used for switches port ping by ip
port_host_ping() {
	local host="$1"
	local ping_cmd="$PINGCMD"

	[ "$IP_TYPE" = "ipv6" ] && ping_cmd="$PINGCMDV6"

	if exec_ping "$ping_cmd" "$host"; then
		set_fail_counter 0 "$host"
	else
		check_tries "-p" "Host ${host} unreachable" "${TIME} min. until next ping retry" "$host"
	fi
}

# returns number of connected IPs on the given port
connected_ips() {
	local port="$1"
	local ips=0
	local mac

	if [ $HAS_SWCONFIG = 0 ]; then
		for mac in $(bridge fdb | grep "$port" | grep "self" | awk '{print $1}'); do
			local ip4=$(cat /proc/net/arp | grep -w "$mac" | awk '{print $1}')
			local ip6=$(ip -6 neigh | grep -w "$mac" | awk '{print $1}')

			[ -n "$ip4" ] || [ -n "$ip6" ] && ips=$((ips + 1))
		done
	else
		local port_num=$(echo "$port" | sed 's/port\([0-9]*\).*/\1/')
		local oldIFS="$IFS"
		while IFS= read -r line; do
			set -- $line
			local i=$1
			local j=$2
			[ -z "$i" ] || [ -z "$j" ] && break

			local position=$(get_position_from_hex "$j")

			if [ "$position" = "$port_num" ]; then
				local ip4=$(cat /proc/net/arp | grep -w "$i" | awk '{print $1}')
				local ip6=$(ip -6 neigh | grep -w "$i" | awk '{print $1}')

				[ -n "$ip4" ] || [ -n "$ip6" ] && ips=$((ips + 1))
			fi
		done <<EOF
		$(swconfig dev switch0 get dump_arl | awk '{print $2, $4}')
EOF
		IFS="$oldIFS"
	fi

	echo "$ips"
}

multiple_ports() {
	local port=$(echo "$1" | cut -d'=' -f1)
	local expected_ips=$(echo "$1" | cut -d'=' -f2)
	local decimal_value=$(echo "$port" | sed 's/[^0-9]*//g')
	local devices_count
	local passed_pings=0

	CURRENT_TRY=$(get_fail_counter "$port")
	CURRENT_TRY=$((CURRENT_TRY + 1))
	set_fail_counter "$CURRENT_TRY" "$port"

	local ips=$(connected_ips "$port")
	if [ "$ips" -lt "$expected_ips" ]; then
		check_tries "-p" "" "${TIME} min. until next ping retry" "" "$port"
		return
	fi
	if [ $HAS_SWCONFIG = 0 ]; then
		devices_count=$(bridge fdb | grep "$port" | grep "self" | awk '{print $1}' | wc -l)
	else
		local hex="$(get_hex_from_position "$decimal_value")"
		devices_count=$(swconfig dev switch0 get dump_arl | grep -c "$hex")
	fi

	if [ $HAS_SWCONFIG = 0 ]; then
		for i in $(bridge fdb | grep "$port" | grep "self" | awk '{print $1}'); do
			local passed=$(perform_double_ping "$i" "$devices_count" "$expected_ips")
			passed_pings=$((passed_pings+passed))
		done
	else
		local oldIFS="$IFS"
		while IFS= read -r line; do
			set -- $line
			local i=$1
			local j=$2
			[ -z "$i" ] && [ -z "$j" ] && break

			local position=$(get_position_from_hex "$j")

			if [ "$position" = "$decimal_value" ]; then
				local passed=$(perform_double_ping "$i" "$devices_count" "$expected_ips")
				passed_pings=$((passed_pings+passed))
			fi
		done <<EOF
		$(swconfig dev switch0 get dump_arl | awk '{print $2, $4}')
EOF
		IFS="$oldIFS"
	fi

	if [ "$passed_pings" -ge "$expected_ips" ]; then
		set_fail_counter 0 "$port"
		return
	fi
	check_tries "-p" "" "${TIME} min. until next ping retry" "" "$port"
}

get_all_poe_ports() {
	local p=""
	config_load poe
	_foreach_port() { p="$p $1"; }
	config_foreach _foreach_port port p
	config_load ping_reboot
	echo "$p"
}

# iterates over HOST list and tries to map each host to a PoE port, final result is:
# option port '<host1>,<port1> <host2>,<port2> ...'
# also called from init script to map hosts to ports on config change
map_hosts_to_ports() {
	check_suid "$PINGCMD $PINGCMDV6" || return 1
	local all_poe_ports=$(get_all_poe_ports)
	local need_commit=0
	PORT_HOST_MAP="$PORT"
	if [ -n "$PORT" ]; then
		for host in $HOST; do
			# if PORT does not contain ",", we need to map it to IP (to avoid using uci defaults)
			echo "$PORT" | grep "$KV_SEP" >/dev/null 2>&1 && break
			PORT_HOST_MAP="$host$KV_SEP$PORT"
			need_commit=1
			break
		done
	fi

	# remove mappings for hosts not in HOST list anymore
	for kv in $PORT_HOST_MAP; do
		local key=$(echo "$kv" | cut -d$KV_SEP -f1)
		if ! list_contains HOST "$key"; then
			PORT_HOST_MAP=$(kvmap_remove "$PORT_HOST_MAP" "$key")
			need_commit=1
		fi
	done

	for host in $HOST; do
		local mac=""
		if [ "$IP_TYPE" = "ipv6" ]; then
			mac=$(ip -6 neigh | grep -w "$host" | awk '{print $5}')
		else
			#Ping before getting MAC address. In other case, ARP table will could be empty in some situations.
			#Basicaly it is an arp-scan equivalent since we do not have such a command in a TSW devices.
			$PINGCMD -W 2 -s 56 -q -c 1 "$host" >/dev/null 2>&1
			mac=$(cat /proc/net/arp | grep -w "$host" | awk '{print $4}')
		fi
		if [ -z "$mac" ] || [ "$mac" = "00:00:00:00:00:00" ]; then
			continue
		fi

		local port=""
		if [ $HAS_SWCONFIG = 0 ]; then
			port=$(bridge fdb | grep -w "$mac" | grep "self" | awk '{print $3}')
		else
			local portmap=$(swconfig dev switch0 get dump_arl | grep -w "$mac" | awk '{print $4}')
			local position=$(get_position_from_hex "$portmap")
			port="port${position}"
		fi

		if [ -z "$port" ] || ! list_contains all_poe_ports "$port"; then
			continue
		fi

		local old_port=$(kvmap_get "$PORT_HOST_MAP" "$host")
		if [ "$old_port" != "$port" ]; then
			PORT_HOST_MAP=$(kvmap_insert "$PORT_HOST_MAP" "$host" "$port")
			need_commit=1
		fi
	done
	[ "$need_commit" -eq 1 ] && uci_set ping_reboot "$SECTION" port "$PORT_HOST_MAP" && uci_commit ping_reboot
	return 0
}

perform_port_ping() {
	if [ "$PING_PORT_TYPE" = "ping_ip" ]; then
		map_hosts_to_ports

		for host in $HOST; do
			CURRENT_TRY=$(get_fail_counter "$host")
			CURRENT_TRY=$((CURRENT_TRY + 1))
			set_fail_counter "$CURRENT_TRY" "$host"

			port_host_ping "$host"
		done
	else
		check_suid "$PINGCMD $PINGCMDV6" || return 1
		config_get len "$SECTION" "port_host_LENGTH" 0
		if [ -n "$len" ]; then
			config_list_foreach "$SECTION" port_host multiple_ports "$SECTION"
		fi
	fi
}
