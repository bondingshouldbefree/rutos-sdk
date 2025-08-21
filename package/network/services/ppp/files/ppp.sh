#!/bin/sh

[ -x /usr/sbin/pppd ] || exit 0

[ -n "$INCLUDE_ONLY" ] || {
	. /lib/functions.sh
	. /lib/functions/network.sh
	. /lib/netifd/netifd-proto.sh
	init_proto "$@"
}

ppp_select_ipaddr()
{
	local subnets=$1
	local res
	local res_mask

	for subnet in $subnets; do
		local addr="${subnet%%/*}"
		local mask="${subnet#*/}"

		if [ -n "$res_mask" -a "$mask" != 32 ]; then
			[ "$mask" -gt "$res_mask" ] || [ "$res_mask" = 32 ] && {
				res="$addr"
				res_mask="$mask"
			}
		elif [ -z "$res_mask" ]; then
			res="$addr"
			res_mask="$mask"
		fi
	done

	echo "$res"
}

ppp_exitcode_tostring()
{
	local errorcode=$1
	[ -n "$errorcode" ] || errorcode=5

	case "$errorcode" in
		0) echo "OK" ;;
		1) echo "FATAL_ERROR" ;;
		2) echo "OPTION_ERROR" ;;
		3) echo "NOT_ROOT" ;;
		4) echo "NO_KERNEL_SUPPORT" ;;
		5) echo "USER_REQUEST" ;;
		6) echo "LOCK_FAILED" ;;
		7) echo "OPEN_FAILED" ;;
		8) echo "CONNECT_FAILED" ;;
		9) echo "PTYCMD_FAILED" ;;
		10) echo "NEGOTIATION_FAILED" ;;
		11) echo "PEER_AUTH_FAILED" ;;
		12) echo "IDLE_TIMEOUT" ;;
		13) echo "CONNECT_TIME" ;;
		14) echo "CALLBACK" ;;
		15) echo "PEER_DEAD" ;;
		16) echo "HANGUP" ;;
		17) echo "LOOPBACK" ;;
		18) echo "INIT_FAILED" ;;
		19) echo "AUTH_TOPEER_FAILED" ;;
		20) echo "TRAFFIC_LIMIT" ;;
		21) echo "CNID_AUTH_FAILED";;
		*) echo "UNKNOWN_ERROR" ;;
	esac
}

ppp_generic_init_config() {
	proto_config_add_string username
	proto_config_add_string password
	proto_config_add_string keepalive
	proto_config_add_boolean keepalive_adaptive
	proto_config_add_int demand
	proto_config_add_string pppd_options
	proto_config_add_string 'connect:file'
	proto_config_add_string 'disconnect:file'
	[ -e /proc/sys/net/ipv6 ] && proto_config_add_string ipv6
	proto_config_add_boolean authfail
	proto_config_add_int mtu
	proto_config_add_string pppname
	proto_config_add_string unnumbered
	proto_config_add_boolean persist
	proto_config_add_int maxfail
	proto_config_add_int holdoff
}

ppp_generic_setup() {
	local config="$1"; shift
	local localip

	json_get_vars ip6table demand keepalive keepalive_adaptive username password pppd_options pppname unnumbered persist maxfail holdoff peerdns

	[ ! -e /proc/sys/net/ipv6 ] && ipv6=0 || json_get_var ipv6 ipv6

	if [ "$ipv6" = 0 ]; then
		ipv6=""
	elif [ -z "$ipv6" -o "$ipv6" = auto ]; then
		ipv6=1
		autoipv6=1
	fi

	if [ "${demand:-0}" -gt 0 ]; then
		demand="precompiled-active-filter /etc/ppp/filter demand idle $demand"
	else
		demand=""
	fi
	if [ -n "$persist" ]; then
		[ "${persist}" -lt 1 ] && persist="nopersist" || persist="persist"
	fi
	if [ -z "$maxfail" ]; then
		[ "$persist" = "persist" ] && maxfail=0 || maxfail=1
	fi
	[ -n "$mtu" ] || json_get_var mtu mtu
	[ -n "$pppname" ] || pppname="${proto:-ppp}-$config"
	[ -n "$unnumbered" ] && {
		local subnets
		( proto_add_host_dependency "$config" "" "$unnumbered" )
		network_get_subnets subnets "$unnumbered"
		localip=$(ppp_select_ipaddr "$subnets")
		[ -n "$localip" ] || {
			proto_block_restart "$config"
			return
		}
	}

	[ -n "$keepalive" ] || keepalive="5 1"

	local lcp_failure="${keepalive%%[, ]*}"
	local lcp_interval="${keepalive##*[, ]}"
	local lcp_adaptive="lcp-echo-adaptive"
	[ "${lcp_failure:-0}" -lt 1 ] && lcp_failure=""
	[ "$lcp_interval" != "$keepalive" ] || lcp_interval=5
	[ "${keepalive_adaptive:-1}" -lt 1 ] && lcp_adaptive=""
	[ -n "$connect" ] || json_get_var connect connect
	[ -n "$disconnect" ] || json_get_var disconnect disconnect

	proto_run_command "$config" /usr/sbin/pppd \
		nodetach ipparam "$config" \
		ifname "$pppname" \
		${localip:+$localip:} \
		${lcp_failure:+lcp-echo-interval $lcp_interval lcp-echo-failure $lcp_failure $lcp_adaptive} \
		${ipv6:++ipv6} \
		${autoipv6:+set AUTOIPV6=1} \
		${ip6table:+set IP6TABLE=$ip6table} \
		${peerdns:+set PEERDNS=$peerdns} \
		nodefaultroute \
		usepeerdns \
		$demand $persist maxfail $maxfail \
		${holdoff:+holdoff "$holdoff"} \
		${username:+user "$username" password "$password"} \
		${connect:+connect "$connect"} \
		${disconnect:+disconnect "$disconnect"} \
		ip-up-script /lib/netifd/ppp-up \
		${ipv6:+ipv6-up-script /lib/netifd/ppp6-up} \
		ip-down-script /lib/netifd/ppp-down \
		${ipv6:+ipv6-down-script /lib/netifd/ppp-down} \
		${mtu:+mtu $mtu mru $mtu} \
		"$@" $pppd_options
}

ppp_generic_teardown() {
	local interface="$1"
	local errorstring=$(ppp_exitcode_tostring $ERROR)

	case "$ERROR" in
		0)
		;;
		2)
			proto_notify_error "$interface" "$errorstring"
			proto_block_restart "$interface"
		;;
		11|19)
			json_get_var authfail authfail
			proto_notify_error "$interface" "$errorstring"
			if [ "${authfail:-0}" -gt 0 ]; then
				proto_block_restart "$interface"
			fi
		;;
		*)
			proto_notify_error "$interface" "$errorstring"
		;;
	esac

	proto_kill_command "$interface"
}

# PPP on serial device

proto_ppp_init_config() {
	proto_config_add_string "device"
	ppp_generic_init_config
	no_device=1
	available=1
	lasterror=1
}

proto_ppp_setup() {
	local config="$1"

	json_get_var device device
	ppp_generic_setup "$config" "$device"
}

proto_ppp_teardown() {
	ppp_generic_teardown "$@"
}

proto_pppoe_init_config() {
	ppp_generic_init_config
	proto_config_add_string "ac"
	proto_config_add_string "service"
	proto_config_add_string "host_uniq"
	proto_config_add_int "padi_attempts"
	proto_config_add_int "padi_timeout"
	proto_config_add_int "tag"
	proto_config_add_int "priority"

	lasterror=1
}

proto_pppoe_setup() {
	local config="$1"
	local iface="$2"

	/sbin/modprobe -qa slhc ppp_generic pppox pppoe

	json_get_var mtu mtu
	mtu="${mtu:-1492}"

	json_get_var ac ac
	json_get_var service service
	json_get_var host_uniq host_uniq
	json_get_var padi_attempts padi_attempts
	json_get_var padi_timeout padi_timeout
	json_get_var tag tag
	json_get_var priority priority

	ppp_generic_setup "$config" \
		plugin pppoe.so \
		${ac:+rp_pppoe_ac "$ac"} \
		${service:+rp_pppoe_service "$service"} \
		${host_uniq:+host-uniq "$host_uniq"} \
		${padi_attempts:+pppoe-padi-attempts $padi_attempts} \
		${padi_timeout:+pppoe-padi-timeout $padi_timeout} \
		"nic-$iface"

        [ -n "$tag" ] && [ -n "$priority" ] && ip link set $iface type vlan egress $tag:$priority
}

proto_pppoe_teardown() {
	ppp_generic_teardown "$@"
}

proto_pppoa_init_config() {
	ppp_generic_init_config
	proto_config_add_int "atmdev"
	proto_config_add_int "vci"
	proto_config_add_int "vpi"
	proto_config_add_string "encaps"
	no_device=1
	available=1
	lasterror=1
}

proto_pppoa_setup() {
	local config="$1"
	local iface="$2"

	/sbin/modprobe -qa slhc ppp_generic pppox pppoatm

	json_get_vars atmdev vci vpi encaps

	case "$encaps" in
		1|vc) encaps="vc-encaps" ;;
		*) encaps="llc-encaps" ;;
	esac

	ppp_generic_setup "$config" \
		plugin pppoatm.so \
		${atmdev:+$atmdev.}${vpi:-8}.${vci:-35} \
		${encaps}
}

proto_pppoa_teardown() {
	ppp_generic_teardown "$@"
}

proto_pptp_init_config() {
	ppp_generic_init_config
	proto_config_add_string "server"
	proto_config_add_string "interface"
	proto_config_add_boolean "client_to_client"
	proto_config_add_boolean "defaultroute"
	proto_config_add_boolean "disabled"
	proto_config_add_string "mppe"
	proto_config_add_array "mppe_encryption"
	available=1
	no_device=1
	lasterror=1
}

append_pptp_options() {
	local opt="$1"
	local options="$2"
	[ -n "$opt" ] && echo "$opt" | sed -e 's/^[ \t]*//' >> "$options"
}

proto_pptp_setup() {
	local config="$1"
	local ifname="pptp-$config"
	mkdir -p /var/etc/pptp
	local options="/var/etc/pptp/options.${ifname}"
	: > "$options"

	local ip serv_addr server interface s mwan_enabled status num gw metric device proto defaultroute encryptions opts mppe
	local mwan_enabled=0
	local i=1
	json_get_vars server defaultroute mppe
	json_get_values opts mppe_encryption
	if [ "$mppe" != "none" ]; then
		encryptions="no40,no56,no128"
		for opt in $opts; do
			encryptions=$(echo "$encryptions" | sed -e "s/,*no$opt//g" -e 's/^,//')
		done
		[ "$mppe" = "stateful" ] && mppe=""
		echo "mppe required${encryptions:+,$encryptions}${mppe:+,$mppe}" >>"$options"
	else
		echo "nomppe" >> "$options"
	fi

	config_load network
	config_list_foreach "$config" "pptp_options" append_pptp_options "$options"
	[ -e "$options" ] && options="file $options" || options=

	[ -n "$server" ] && {
		status="$(ubus call mwan3 status | jsonfilter -e '@.interfaces.*.status' 2>/dev/null)"
		for s in $status; do
			i=$((i+1))
			[ "$s" = "online" ] && {
				mwan_enabled=1
				num="$i"
			}
		done
		for ip in $(resolveip -t 5 "$server"); do
			if [ "$mwan_enabled" = 1 ]; then
				interface="$(mwan3 interfaces | awk "NR==$num" | awk '{print $2}')"
				network_get_protocol proto "$interface"
				if [ "$proto" = "wwan" ]; then
					network_get_device device "${interface}_4"
				else
					network_get_device device "${interface}"
				fi
			elif [ "$defaultroute" = 1 ]; then
				device="$(ip route show default | head -n 1 | awk -F"dev " '{print $2}' | sed 's/\s.*$//')"
			fi
			if [ -n "$device" ]; then
				gw="$(ip route show default dev $device | head -n 1 | awk -F"via " '{print $2}' | sed 's/\s.*$//')"
				metric="$(ip route show default dev $device | awk -F"metric " '{print $2}' | sed 's/\s.*$//')"
				ip route delete "$ip"
				[ -n "$gw" ] && ip route add "$ip" via "$gw" dev "$device" metric "$metric" || ip route add "$ip" dev "$device" metric "$metric"
			fi
			serv_addr=1
		done
	}
	[ -n "$serv_addr" ] || {
		echo "Could not resolve server address"
		sleep 5
		proto_setup_failed "$config"
		exit 1
	}

	/sbin/modprobe -qa slhc ppp_generic ppp_async ppp_mppe ip_gre gre pptp
	sleep 1

	ppp_generic_setup "$config" \
		plugin pptp.so \
		pptp_server $server \
		$options
}

proto_pptp_teardown() {
	local ip server disabled
	disabled="$(uci -q get network.$1.disabled)"
	json_get_vars server
	[ -n "$server" ] && [ "$disabled" = 1 ] && {
		for ip in $(resolveip -t 5 "$server"); do
			ip route delete "$ip"
		done
	}
	ppp_generic_teardown "$@"
}

proto_sstp_init_config() {
	ppp_generic_init_config
	proto_config_add_string "server"
	proto_config_add_string "ca"
	proto_config_add_string "username"
	proto_config_add_string "password"
	proto_config_add_boolean "defaultroute"
	proto_config_add_array "sstp_options"
	available=1
	no_device=1
}

proto_sstp_setup() {
	local config="$1"
	local ifname="sstp-$config"
	local options="/var/run/sstpc/options.${ifname}"
	local server ip serv_addr ca username password defaultroute default_dev gw metric up opts

	json_get_vars server ca username password defaultroute
	json_get_values opts sstp_options
	
	for opt in $opts; do
		echo "$opt" >> "$options"
	done
	if [ -e "$options" ];then
		chown sstpc:sstpc "$options"
		options="file $options"
	else
		options=
	fi

	server_and_port=$server
	server="${server%%:*}" # split server and port

	[ -n "$server" ] && {
		for ip in $(resolveip -t 5 "$server"); do
			#ADDS STATIC ROUTE TO SERVER VIA ONE GATEWAY
			default_dev="$(ip --json route show default | jsonfilter -e '@.*.dev' | head -n1)"
			[ -n "$default_dev" ] && {
				gw="$(ip --json route show default | jsonfilter -e '@[@.dev="'"$default_dev"'"].gateway' | head -n1)"
				metric="$(ip --json route show default | jsonfilter -e '@[@.dev="'"$default_dev"'"].metric' | head -n1)"
				[ -z "$metric" ] && metric="0"
				[ -n "$gw" ] && ip route add "$ip" via "$gw" dev "$default_dev" metric "$metric" || \
								ip route add "$ip" dev "$default_dev" metric "$metric"
			}
			serv_addr=1
		done
	}
	[ -n "$serv_addr" ] || {
		echo "Could not resolve server address"
		sleep 5
		proto_setup_failed "$config"
		exit 1
	}
	
	[ "$defaultroute" -eq 1 ] || defaultroute=

	local load
	for module in slhc ppp_generic ppp_async ppp_mppe ip_gre gre pptp; do
		grep -q "$module" /proc/modules && continue
		/sbin/insmod $module 2>&- >&-
		load=1
	done
	[ "$load" = "1" ] && sleep 1

	up=$(ifstatus "${config}" | jsonfilter -e "@.up")
	[ "$up" = "true" ] && {
		proto_init_update "$ifname" 1
		proto_send_update "$config"
	}

	proto_set_user sstpc
	proto_run_command "$config" sstpc \
	${ca:+--ca-cert $ca} \
	--cert-warn \
	--log-level 1 \
	--tls-ext ${username:+--user $username} ${password:+--password $password} \
	--ipparam "$config" \
	$server_and_port \
	ipparam "$config" \
	ifname "$ifname" \
	nodetach \
	usepeerdns \
	${defaultroute:+replacedefaultroute defaultroute} \
	ip-up-script /lib/netifd/ppp-up \
	ip-down-script /lib/netifd/ppp-down \
	lcp-echo-interval 20 \
	lcp-echo-failure 5 \
	$options
}

proto_sstp_teardown() {
	local server
	local options="/var/run/sstpc/options.sstp-${1}"
	json_get_vars server
	server="${server%%:*}" # split server and port

	for ip in $(resolveip -t 5 "$server"); do
		#DELETES STATIC ROUTE TO SERVER VIA ONE GATEWAY
		route del $ip
	done
	[ -e "$options" ] && rm "$options"
	ppp_generic_teardown "$@"
}

[ -n "$INCLUDE_ONLY" ] || {
	add_protocol ppp
	[ -f /usr/lib/pppd/*/pppoe.so ] && add_protocol pppoe
	[ -f /usr/lib/pppd/*/pppoatm.so ] && add_protocol pppoa
	[ -f /usr/lib/pppd/*/pptp.so ] && add_protocol pptp
	if [ -f /usr/lib/sstp-pppd-plugin.so ] || [ -f /usr/local/usr/lib/sstp-pppd-plugin.so ]; then
		add_protocol sstp
	fi
}
