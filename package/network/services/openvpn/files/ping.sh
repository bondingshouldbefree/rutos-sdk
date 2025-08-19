#!/bin/sh

UP_FILE="/var/run/openvpn/openvpn-$INSTANCE.up"
NOT_PINGED=1

send_package() {
	local start end
	local type="$1"
	local tun_dev="$2"
	local ipa="$3"
	local mask="$4"

	if [ -z "$mask" ]; then
		eval "$(ipcalc.sh "$ipa")"
	else
		eval "$(ipcalc.sh "$ipa" "$mask")"
	fi
	if [ "$PREFIX" -lt "24" ]; then
		start="1"
		end="254"
	else
		start="${NETWORK##*.}"
		end="${BROADCAST##*.}"
	fi
	if [ "$PREFIX" = "32" ] && [ "$type" = "icmp" ]; then
		ping -c1 -W1 -I "$tun_dev" "$ipa" >/dev/null 2>&1 &
	else
		for i in $(seq "$start" "$end"); do
			if [ "$type" = "arp" ]; then
				arping -I "$tun_dev" -c1 -w1 "${IP%.*}.${i}" >/dev/null 2>&1 &
			elif [ "$type" = "icmp" ]; then
				ping -I "$tun_dev" -c1 -W1 "${IP%.*}.${i}" >/dev/null 2>&1 &
			fi
		done
	fi
	NOT_PINGED=0
}

ping_ipv4() {
	if [ -n "$ifconfig_remote" ]; then
		send_package "icmp" "$dev" "$ifconfig_remote" "255.255.255.255"
	elif [ -n "$ifconfig_local" ] && [ -n "$ifconfig_netmask" ]; then
		send_package "icmp" "$dev" "$ifconfig_local" "$ifconfig_netmask"
	elif [ "$dev_type" = "tap" ] && [ -n "$bridge" ] && [ "$bridge" != "none" ]; then
		dev_bridge="$(uci -q get network.${bridge}.name)"
		for ip in $(ip -f inet addr show "$dev_bridge" | awk '/inet / {print $2}'); do
			send_package "arp" "$dev" "$ip"
		done
	fi
}

ping_ipv6() {
	if [ -n "$ifconfig_ipv6_local" ] && [ -n "$ifconfig_ipv6_remote" ]; then
		{ ping6 -I "$dev" -c1 -W1 "$ifconfig_ipv6_remote" >/dev/null 2>&1; } &
	fi
}

: > "$UP_FILE"
chown openvpn:openvpn "$UP_FILE"
bridge="$(uci -q get openvpn.${INSTANCE}.to_bridge)"
if [ -n "$route_network_1" ]; then
	i=1
	route_network="$route_network_1"
	while [ -n "$route_network" ]; do
		[ "${route_network##*.}" = "0" ] && route_network="${route_network%.*}.1"
		send_package "icmp" "$dev" "$route_network" "255.255.255.255"
		i=$(( i+1 ))
		eval "route_network=\$route_network_$i"
	done
fi

[ "$NOT_PINGED" = 1 ] && ping_ipv4
[ "$NOT_PINGED" = 1 ] && ping_ipv6
{ sleep 7 && rm "$UP_FILE"; } &
