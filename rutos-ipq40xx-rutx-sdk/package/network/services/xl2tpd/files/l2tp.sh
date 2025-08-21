#!/bin/sh

[ -x /usr/sbin/xl2tpd ] || exit 0
if [ -x /usr/sbin/xl2tpd6 ] || [ -x /usr/local/usr/sbin/xl2tpd6 ]; then
	L2TPV6_SUPPORT=1
fi

[ -n "$INCLUDE_ONLY" ] || {
	. /lib/functions.sh
	. /lib/netifd/netifd-proto.sh
	init_proto "$@"
}

proto_l2tp_init_config() {
	proto_config_add_string "username"
	proto_config_add_string "password"
	proto_config_add_string "keepalive"
	proto_config_add_array "pppd_options"
	proto_config_add_int "mtu"
	proto_config_add_int "checkup_interval"
	proto_config_add_string "server"
	proto_config_add_boolean "defaultroute"
	available=1
	no_device=1
	no_proto_task=1
	teardown_on_l3_link_down=1
}

check_bind() {
	config_get bind_to "$1" bind_to

	[ "$bind_to" = "$2" ] || continue
	if ! swanctl --list-sas --child ${1} 2>/dev/null | grep -q "INSTALLED"; then
		logger "L2TP instance ${bind_to} cannot start, it's bound to unestablished IPsec connection ${1}."
		BIND_STOP=1
	fi
}

proto_l2tp_add_opts() {
	[ -n "$1" ] && echo "$1" >> "$3"
}

proto_l2tp_setup() {
	local interface="$1"

	local fail_count="0"
	[ -f "/var/run/xl2tpd/$interface.failcount" ] && fail_count="$(cat "/var/run/xl2tpd/$interface.failcount")"
	local sleep_time="$(($fail_count * 30))"
	[ "$sleep_time" -gt "180" ] && sleep_time="180"
	if [ "$sleep_time" -gt "0" ]; then
		logger -t "l2tp" "Interface '$interface' is waiting $sleep_time seconds for the next connection retry"
		sleep "$sleep_time"
	fi

	local optfile="/var/run/xl2tpd/options.${interface}"
	local static_opt="/etc/ppp/options.l2tp"
	local active_wan="/tmp/run/mwan3/active_wan"
	local ip serv_addr server host defaultroute IP6 default_int

	json_get_vars server defaultroute
	BIND_STOP=0                                                        
	config_load ipsec         
	config_foreach check_bind connection "$interface"
	[ "$BIND_STOP" -eq 1 ] && exit 1

	if echo "$server" | grep -Eq '^\[[0-9a-fA-F:]+\]:[0-9]{1,5}$' || \
	echo "$server" | grep -Eq '^[0-9A-Fa-f]{1,4}:' || \
	[ "$server" = "::1" ]; then
		[ "$L2TPV6_SUPPORT" != 1 ] && logger -t "l2tp" "Interface '$interface': missing l2tpv6_support package for connection to IPv6 host" && exit 1
		IP6=1
		if echo "$server" | grep -Eq '^\[[0-9a-fA-F:]+\]:[0-9]{1,5}$'; then
			host="$(echo "$server" | sed -n 's/^\[\(.*\)\]:[0-9]\+$/\1/p')"
		else
			host="$server"
		fi
	else
		host="${server%:*}"
	fi

	for ip in $(resolveip -t 5 "$host"); do
		case "$ip" in
		*:*)
			IP6=1
			;;
		esac

		[ "$defaultroute" -eq 1 ] && [ "$IP6" != 1 ] && {
			if [ -f "$active_wan" ]; then
				default_int=$(cat "$active_wan")
					if [ "$default_int" = "mob1s1a1" ] || [ "$default_int" = "mob1s2a1" ]; then
						default_int="${default_int}_4"
					fi
					default="$(ubus call network.interface dump | jsonfilter -e '@.interface[@.interface="'"${default_int}"'"].device')"
			fi
			[ -z "$default" ] && default="$(ip route show default | head -n 1 | awk -F"dev " '{print $2}' | sed 's/\s.*$//')"
			gw="$(ip route show default dev $default | head -n 1 | awk -F"via " '{print $2}' | sed 's/\s.*$//')"
			metric="$(ip route show default dev $default | awk -F"metric " '{print $2}' | sed 's/\s.*$//')"

			[ -n "$gw" ] && ip route add "$ip" via "$gw" dev "$default" metric "$metric" || ip route add "$ip" dev "$default" metric "$metric"
			echo "$default" >> /var/run/xl2tpd/default-status
		}
		serv_addr=1
	done
	if [ "$IP6" = 1 ]; then
		if [ "$L2TPV6_SUPPORT" != 1 ]; then
			logger -t "l2tp" "Interface '$interface': missing l2tpv6_support package for connection to IPv6 host"
			IP6=
		else
			[ -e "/etc/xl2tpd/xl2tpd6.conf" ] || ln -s /etc/xl2tpd/xl2tpd.conf /etc/xl2tpd/xl2tpd6.conf
		fi
	fi

	[ -n "$serv_addr" ] || {
		echo "Could not resolve server address" >&2
		sleep 5
		proto_setup_failed "$interface"
		exit 1
	}

	# Start and wait for xl2tpd
	if [ ! -p /var/run/xl2tpd/l2tp${IP6:+6}-control ] || [ -z "$(pidof xl2tpd${IP6:+6})" ]; then
		/etc/init.d/xl2tpd stop && /etc/init.d/xl2tpd start${IP6:+ 6}
		local wait_timeout=0
		while [ ! -p /var/run/xl2tpd/l2tp${IP6:+6}-control ]; do
			wait_timeout=$((wait_timeout + 1))
			[ "$wait_timeout" -gt 5 ] && {
				echo "Cannot find xl2tpd control file." >&2
				proto_setup_failed "$interface"
				exit 1
			}
			sleep 1
		done
	fi

	local demand keepalive username password pppd_options mtu
	json_get_vars demand keepalive username password pppd_options mtu
	if [ "${demand:-0}" -gt 0 ]; then
		demand="precompiled-active-filter /etc/ppp/filter demand idle $demand"
	else
		demand="persist"
	fi

	local interval="${keepalive##*[, ]}"
	[ "$interval" != "$keepalive" ] || interval=5

	keepalive="${keepalive:+lcp-echo-interval $interval lcp-echo-failure ${keepalive%%[, ]*}}"
	username="${username:+user \"$username\" password \"$password\"}"
	mtu="${mtu:+mtu $mtu mru $mtu}"

	config_load network
	config_get auth_pap "$interface" auth_pap "0"
	[ "$auth_pap" = "0" ] && allow_pap="refuse-pap"
	config_get auth_chap "$interface" auth_chap "1"
	[ "$auth_chap" = "0" ] && allow_chap="refuse-chap"
	config_get auth_mschap2 "$interface" auth_mschap2 "1"
	[ "$auth_mschap2" = "0" ] && allow_mschap2="refuse-mschap-v2"

	cat "$static_opt" > "$optfile"
	cat <<EOF >>"$optfile"
ipparam "$interface"
ifname "l2tp-$interface"
$keepalive
$username
$mtu
$allow_pap
$allow_chap
$allow_mschap2
EOF

	json_for_each_item proto_l2tp_add_opts pppd_options "$optfile"

	xl2tpd${IP6:+6}-control${IP6:+ -c /var/run/xl2tpd/l2tp6-control} add-lac l2tp-${interface} pppoptfile=${optfile} lns=${server} || {
		echo "xl2tpd${IP6:+6}-control: Add l2tp-$interface failed" >&2
		proto_setup_failed "$interface"
		exit 1
	}
	xl2tpd${IP6:+6}-control${IP6:+ -c /var/run/xl2tpd/l2tp6-control} connect-lac l2tp-${interface} || {
		echo "xl2tpd${IP6:+6}-control: Connect l2tp-$interface failed" >&2
		proto_setup_failed "$interface"
		exit 1
	}
}

proto_l2tp_teardown() {
	local interface="$1"
	local optfile="/var/run/xl2tpd/options.${interface}"
	local server defaultroute IP6
	json_get_vars server defaultroute

	if echo "$server" | grep -Eq '^[0-9A-Fa-f]{1,4}:'; then
		[ "$L2TPV6_SUPPORT" = 1 ] && IP6=1
		host="$server"
	else
		host="${server%:*}"
	fi


	rm -f ${optfile}
	if [ -p "/var/run/xl2tpd/l2tp${IP6:+6}-control" ]; then
		xl2tpd${IP6:+6}-control${IP6:+ -c /var/run/xl2tpd/l2tp6-control} remove-lac l2tp-${interface} || {
			echo "xl2tpd${IP6:+6}-control: Remove l2tp-$interface failed" >&2
		}
	fi
	# Wait for interface to go down
	while [ -d /sys/class/net/l2tp-${interface} ]; do
		sleep 1
	done

	if [ -n "$defaultroute" ] && [ "$IP6" != 1 ]; then
		hosts=$(resolveip -t 5 "$host")
		for ip in $hosts; do
			ip route delete "$ip"
		done
	fi
	[ -f "/var/run/xl2tpd/default-status" ] && rm "/var/run/xl2tpd/default-status" >/dev/null 2>&1
}

[ -n "$INCLUDE_ONLY" ] || {
	add_protocol l2tp
}
