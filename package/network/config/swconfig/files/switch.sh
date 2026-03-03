#!/bin/sh
# Copyright (C) 2009 OpenWrt.org

EXEC=0
__LAN_TARGET=""

setup_switch_dev() {
	local name
	local cmd="$2"
	config_get name "$1" name
	name="${name:-$1}"
	[ -d "/sys/class/net/$name" ] && ip link set dev "$name" up
	swconfig dev "$name" "$cmd" network

	config_get fiber_priority "$1" fiber_priority

	[ -n "$fiber_priority" ] && {
		swconfig dev "$name" set preference "$fiber_priority"
	}

	EXEC=1
}

setup_switch() {
	local cmd="load"
	[ "$(jsonfilter -i /etc/board.json -e '@.hwinfo.sw_rst_on_init')" = "true" ] && {
		swconfig dev "switch0" set reset;
		return 0
	}

	[ "$1" = "reset" ] && cmd="reset_and_load"

	config_load network
	config_foreach setup_switch_dev switch "$cmd"

	[ "$EXEC" = "0" ] && swconfig list &>/dev/null && {
		swconfig dev "switch0" $cmd network;
	}
}

get_dhcp_sections() {

	local dhcp_state=""
	local new_l=$'\n'

	[ ! -f "/etc/config/dhcp" ] && echo "" && return 0

	config_cb() {
		local iface=$(uci_get dhcp "$2" interface)
		skip=$(uci_get network $iface disabled "0")
		[ "$skip" = "1" ] && return 1
		[ "$1" != "dhcp" ] && return 1

		dhcp_state="${dhcp_state:-}$1.$2 ${new_l}"

		option_cb() {
			[ "$skip" = "1" ] && return 1
			[ "$1" = "interface" ] && __LAN_TARGET="${__LAN_TARGET:-}$2 "

			dhcp_state="${dhcp_state}$1=$2 ${new_l}"
		}
	}

	config_load dhcp
	reset_cb

	echo "${dhcp_state%?}"

	return 0
}

get_lan_sections() {

	local lan_state=""
	local lan_sect=""
	local new_l=$'\n'

	[ ! -f "/etc/config/network" ] && echo "" && return 0

	lan_cb() {
		[ "$(config_get "$1" "disabled")" = "1" ] && return 1
		[[ "$__LAN_TARGET" =~ "$1\b" ]] || return 1

		config_get proto "$1" "proto"
		[ "$proto" != "static" ] && return 1

		lan_state="${lan_state:-}interface.$1 ${new_l}"

		lan_state="${lan_state:-}ipaddr=$(config_get $1 "ipaddr") ${new_l}"
		lan_state="${lan_state:-}netmask=$(config_get "$1" "netmask") ${new_l}"
	}

	switch_cb() {
		lan_state="${lan_state:-}switch ${new_l}"
		lan_state="${lan_state:-}fiber_priority=$(config_get "$1" "fiber_priority") ${new_l}"
		lan_state="${lan_state:-}mirror_monitor_port=$(config_get "$1" "mirror_monitor_port") ${new_l}"
		lan_state="${lan_state:-}mirror_source_port=$(config_get "$1" "mirror_source_port") ${new_l}"
		lan_state="${lan_state:-}enable_mirror_rx=$(config_get "$1" "enable_mirror_rx") ${new_l}"
		lan_state="${lan_state:-}enable_mirror_tx=$(config_get "$1" "enable_mirror_tx") ${new_l}"
	}

	config_load network
	config_foreach lan_cb interface
	config_foreach switch_cb switch

	echo "${lan_state%?}"

	return 0
}

get_vlan_sections() {
	local lan_state=""
	local new_l=$'\n'

	[ ! -f "/etc/config/network" ] && echo "" && return 0

	switch_vlan_cb() {
		lan_state="${lan_state:-}switch_vlan ${new_l}"

		lan_state="${lan_state:-}vlan=$(config_get "$1" "vlan") ${new_l}"
		lan_state="${lan_state:-}ports=$(config_get "$1" "ports") ${new_l}"
		lan_state="${lan_state:-}vid=$(config_get "$1" "vid") ${new_l}"
	}

	config_load network
	config_foreach switch_vlan_cb switch_vlan

	echo "${lan_state%?}"

	return 0
}

ports_info_cb() {

	local section="$1"
	local f_path="$2"
	local disabled="0"

	local speed="speed $(config_get "$section" "speed")"
	local duplex="duplex $(config_get "$section" "duplex")"
	local autoneg="autoneg $(config_get "$section" "autoneg")"
	local port_num="$(config_get "$section" "port_num")"
	local advert="$(config_get "$section" "advert")"
	local role="$(config_get "$section" "role")"
	config_get enabled "$section" "enabled" "1"

	[ "$enabled" = "0" ] && disabled="1"

	[ -z "$port_num" ] && return 1

	[ "$3" == "reset" ] || compare_md_states "$disabled $speed $duplex $autoneg $advert" "$section" "$f_path" || return 1

	/sbin/swconfig dev switch0 port "$port_num" set disable "$disabled"

	local platform="$(jsonfilter -i /etc/board.json -e '@.model.platform')"
	# Set "apply" for all platforms except RUTX, ports on RUTX are already disabled with "set disabled"
	[ "$platform" = "RUTX" ] || /sbin/swconfig dev switch0 set apply

	[ "$disabled" = "1" ] && return 1

	# Only rutx wan handling must be done via ethtool
	[ "$platform" = "RUTX" ] && [ "$role" = "wan" ] && return 1

	# Set values as is if not present in config
	[ "$speed" == "speed " ] && speed="speed $(/sbin/swconfig dev switch0 port "$port_num" get speed)"
	[ "$duplex" == "duplex " ] && duplex="duplex $(/sbin/swconfig dev switch0 port "$port_num" get duplex)"
	[ "$autoneg" == "autoneg " ] && autoneg="autoneg $(/sbin/swconfig dev switch0 port "$port_num" get aneg)"

	/sbin/swconfig dev "switch0" port "$port_num" set link "$speed $duplex $autoneg"
	[ "$autoneg" = "autoneg on" ] && [ -n "$advert" ] && /sbin/swconfig dev "switch0" port "$port_num" set advert "$advert"
}

get_md5() {

	local md5_state=$(echo "$1" | md5sum | cut -d " " -f1)

	echo "$md5_state"
	return 0
}

compare_md_states() {

	local state="$1"
	local data_name="$2"
	local f_path="$3"
	local section="$4"

	[ ! -f "$f_path" ] && {
		echo "${data_name}${section}: $(get_md5 "$state")" > $f_path
		return 0
	}

	local old_md5=$(grep "^${data_name}${section}:" "$f_path" | awk '{print $2}')
	local new_md5=$(get_md5 "$state")

	[ "$old_md5" == "" ] && {
		echo "${data_name}${section}: $new_md5" >> "$f_path"
		return 0
	}

	[ "$old_md5" == "$new_md5" ] && return 1

	$(sed -i "s/^${data_name}${section}: .*$/${data_name}${section}: ${new_md5}/" "$f_path")

	return 0
}

setup_port_links() {

	local f_path="/tmp/state/ports_state"
	local port_link="$(jsonfilter -i /etc/board.json -e '@.hwinfo.port_link')"

	[ -z "$port_link" ] || [ "$port_link" = "false" ] && return 1

	[ ! -f "$f_path" ] && touch "$f_path"

	config_load network
	config_foreach ports_info_cb port "$f_path" "$1"

	return 0
}

check_network_states() {

	local state_f="/tmp/state/network_md5state"
	local data_set=$(get_dhcp_sections ; get_lan_sections)

	[ "$1" = "init" ] && {
		setup_port_links
		echo "lan: $(get_md5 "$data_set")" > "$state_f"
		echo "vlan: $(get_md5 "$(get_vlan_sections)")" >> "$state_f"
		return 0
	}

	compare_md_states "$data_set" "lan" "$state_f" && return 0

	return 1
}

clear_vlans() {
	local old_vlans="$(swconfig dev switch0 show | grep VLAN | tr -d "VLAN :")"
	local state_f="/tmp/state/vlan_ports_state"
	local json_state="$(cat "$state_f" 2>/dev/null || echo '{}')"

	for vlan in $old_vlans; do
		if ! jsonfilter -q -s "$json_state" -e "@.vlans[@.vlan=\"$vlan\"]" >/dev/null 2>&1; then
			swconfig dev switch0 vlan "$vlan" set ports ""
		fi
	done
}

check_vlan_states() {
	local state_f="/tmp/state/network_md5state"
	local data_set=$(get_vlan_sections)

	compare_md_states "$data_set" "vlan" "$state_f"
}

check_vlan_tags() {
	local state_f="/tmp/state/vlan_ports_state"
	local idx=0
	local json_data=$(cat "$state_f" 2>/dev/null || echo '{}')
	local untagged_dump="$(jsonfilter -q -s "$json_data" -e '@.untagged_ports' || echo '[]')"
	local untagged_ports=""

	local status=0

	switch_vlan_cb() {
		local vlan ports device vid
		local section="$1"

		vlan=$(config_get "$section" vlan)
		vid=$(config_get "$section" vid)
		ports=$(config_get "$section" ports)
		device=$(config_get "$section" device)

		json_add_object "$idx"
		json_add_string "vlan" "$vlan"
		json_add_string "vid" "$vid"
		json_add_string "device" "$device"

		for port in $ports; do
			echo "$port" | grep -q 't' && continue
			# Check if the VLAN port last reload/restart was untagged
			if ! jsonfilter -q -s "$untagged_dump" -e "@[@ = $port]" >/dev/null 2>&1; then
				status=1 # Untagged VLAN port was created, restart the switch
			fi

			untagged_ports="$untagged_ports $port"
			json_add_string "_$port" "u"
		done

		json_close_object
		idx=$(( idx + 1 ))
	}

	json_init
	config_load network

	json_add_array vlans
	config_foreach switch_vlan_cb switch_vlan
	json_close_array

	json_add_array untagged_ports
	for port in $untagged_ports; do
		json_add_int "" "$port"
	done
	json_close_array

	json_dump > "$state_f"

	[ "$status" = "1" ]
}

load_vlans() {
	clear_vlans "$old_vlans"

	config_load network
	local switchdevs

	switch_vlan_cb() {
		local config="$1"
		local vlan vid ports device

		device=$(config_get "$config" device)
		[ -z "$device" ] && return
		echo "$switchdevs" | grep -q "$device" || switchdevs="$switchdevs $device"

		vlan=$(config_get "$config" vlan)
		ports=$(config_get "$config" ports)
		vid=$(config_get "$config" vid)

		[ -n "$vid" ] && swconfig dev "$device" vlan "$vlan" set vid "$vid"
		swconfig dev "$device" vlan "$vlan" set ports "$ports"
	}

	config_foreach switch_vlan_cb switch_vlan
	for switch in $switchdevs; do
		swconfig dev "$switch" set apply
	done
}

[ -f /usr/share/libubox/jshn.sh ] && . /usr/share/libubox/jshn.sh