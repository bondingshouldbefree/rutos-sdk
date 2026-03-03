#!/bin/sh
. /lib/functions.sh

CONFIG_PORT_EXISTS=0
STATUS_PATH="/tmp/port_mirroring/status"
HAS_DSA="$(jsonfilter -i /etc/board.json -e '@.hwinfo.dsa')"
HAS_DISABLE_LEARN="$(swconfig dev switch0 help | grep disable_mac_learn)"
HAS_FLUSH="$(swconfig dev switch0 help | grep flush_arl_table)"
CPU_PORT="$(swconfig dev switch0 get cpu_port 2> /dev/null)"

help() {
	echo "Software Port Mirroring"
	echo "Usage: $(basename $0) setup|teardown|reload"
}

setup() {
	local mirror_monitor_port mirror_source_port enable_mirror_rx enable_mirror_tx

	config_load "port_mirroring"
	config_get mirror_monitor_port "config" mirror_monitor_port
	config_get mirror_source_port "config" mirror_source_port
	config_get_bool enable_mirror_rx "config" enable_mirror_rx "0"
	config_get_bool enable_mirror_tx "config" enable_mirror_tx "0"

	[ -s "$STATUS_PATH" ] && {
		local old_md5="$(cat "$STATUS_PATH" | md5sum)"
		local new_md5="$(echo "$mirror_monitor_port $mirror_source_port $enable_mirror_rx $enable_mirror_tx" | md5sum)"
		[ "$old_md5" != "$new_md5" ] && teardown
	}
	[ -z "$mirror_source_port" ] || [ -z "$mirror_monitor_port" ] && return
	[ "$enable_mirror_rx" != "1" ] && [ "$enable_mirror_tx" != "1" ] && return

	if [ "$HAS_DSA" = "true" ]; then
		setup_dsa "$mirror_monitor_port" "$mirror_source_port" "$enable_mirror_rx" "$enable_mirror_tx"
	else
		setup_sw "$mirror_monitor_port" "$mirror_source_port" "$enable_mirror_rx" "$enable_mirror_tx"
	fi

	echo "$mirror_monitor_port $mirror_source_port $enable_mirror_rx $enable_mirror_tx" > "$STATUS_PATH"
}

setup_dsa() {
	local mirror_monitor_port="$1"
	local mirror_source_port="$2"
	local enable_mirror_rx="$3"
	local enable_mirror_tx="$4"

	ip link set up dev "$mirror_monitor_port"
	tc qdisc add dev "$mirror_source_port" clsact
	[ "$enable_mirror_rx" == "1" ] && \
		tc filter add dev "$mirror_source_port" ingress matchall skip_sw action mirred egress mirror dev "$mirror_monitor_port"
	[ "$enable_mirror_tx" == "1" ] && \
		tc filter add dev "$mirror_source_port" egress matchall skip_sw action mirred egress mirror dev "$mirror_monitor_port"
}

config_sw_cpu_port() {
	local section="$1"
	local check_port="$2"
	local value="$3"
	local device port disable_mac_learn

	config_get device "$section" device
	config_get port "$section" port
	config_get disable_mac_learn "$section" disable_mac_learn

	[ "$device" = "switch0" ] || return
	[ "$port" = "$check_port" ] || return

	CONFIG_PORT_EXISTS=1
	uci_set network "$section" disable_mac_learn "$value"
}

config_sw_mac_learning() {
	local value="$1"

	# save to config to set option after network restart
	config_load network
	config_foreach config_sw_cpu_port switch_port "$CPU_PORT" "$value"
	[ "$CONFIG_PORT_EXISTS" -eq 0 ] && {
		uci_add network switch_port
		local section="$CONFIG_SECTION"
		uci_set network "$section" device "switch0"
		uci_set network "$section" port "$CPU_PORT"
		uci_set network "$section" disable_mac_learn "$value"
	}
	uci_commit network

	swconfig dev switch0 port "$CPU_PORT" set disable_mac_learn "$value"
	swconfig dev switch0 set apply
	[ -n "$HAS_FLUSH" ] && {
		for port in $(seq 0 "$CPU_PORT"); do
			swconfig dev switch0 port "$port" set flush_arl_table
		done
	}
}

setup_sw() {
	local mirror_monitor_port="$1"
	local mirror_source_port="$2"
	local enable_mirror_rx="$3"
	local enable_mirror_tx="$4"

	[ -n "$HAS_DISABLE_LEARN" ] && [ -n "$CPU_PORT" ] && \
		config_sw_mac_learning "1"

	ip link set up dev "$mirror_monitor_port"
	tc qdisc add dev "$mirror_source_port" clsact
	tc qdisc add dev "$mirror_monitor_port" clsact

	[ "$enable_mirror_rx" == "1" ] && {
		ebtables -A FORWARD -i "$mirror_source_port" -o "$mirror_monitor_port" -j mark --set-mark 1
		tc filter add dev "$mirror_monitor_port" egress prio 1 handle 1 fw action drop
		tc filter add dev "$mirror_source_port" ingress prio 1 matchall action mirred egress mirror dev "$mirror_monitor_port"
	}

	[ "$enable_mirror_tx" == "1" ] && {
		ebtables -A FORWARD -i "$mirror_monitor_port" -o "$mirror_source_port" -j mark --set-mark 2
		tc filter add dev "$mirror_source_port" egress prio 1 handle 2 fw action pass
		tc filter add dev "$mirror_source_port" egress prio 2 matchall action mirred egress mirror dev "$mirror_monitor_port"
	}
}

teardown() {
	local mirror_monitor_port mirror_source_port enable_mirror_rx enable_mirror_tx

	[ -s "$STATUS_PATH" ] || return
	read mirror_monitor_port mirror_source_port enable_mirror_rx enable_mirror_tx < "$STATUS_PATH"

	if [ "$HAS_DSA" = "true" ]; then
		teardown_dsa "$mirror_monitor_port" "$mirror_source_port"
	else
		teardown_sw "$mirror_monitor_port" "$mirror_source_port"
	fi

	rm -f "$STATUS_PATH"
}

teardown_dsa() {
	local mirror_monitor_port="$1"
	local mirror_source_port="$2"

	tc filter del dev "$mirror_source_port" ingress > /dev/null 2>&1
	tc filter del dev "$mirror_source_port" egress > /dev/null 2>&1
	tc qdisc del dev "$mirror_source_port" clsact > /dev/null 2>&1
}

teardown_sw() {
	local mirror_monitor_port="$1"
	local mirror_source_port="$2"

	tc filter del dev "$mirror_source_port" ingress > /dev/null 2>&1
	tc filter del dev "$mirror_source_port" egress > /dev/null 2>&1
	tc qdisc del dev "$mirror_source_port" clsact > /dev/null 2>&1

	tc filter del dev "$mirror_monitor_port" egress > /dev/null 2>&1
	tc qdisc del dev "$mirror_monitor_port" clsact > /dev/null 2>&1

	ebtables -D FORWARD -i "$mirror_source_port" -o "$mirror_monitor_port" -j mark --set-mark 1 > /dev/null 2>&1
	ebtables -D FORWARD -i "$mirror_monitor_port" -o "$mirror_source_port" -j mark --set-mark 2 > /dev/null 2>&1

	[ -n "$HAS_DISABLE_LEARN" ] && [ -n "$CPU_PORT" ] && \
		config_sw_mac_learning "0"
}

mkdir -p "$(dirname "$STATUS_PATH")"

case "$1" in
setup)
	setup
	;;
teardown)
	teardown
	;;
reload)
	teardown
	setup
	;;
*)
	help
	exit
	;;
esac