#!/bin/sh

xappend() {

	local file="$1"
	shift
	echo "$@" >> "$file"
}

bfd_get_status() {

	config_get enabled "bfd" "enabled" "0"

	[ "$enabled" == "0" ] && return 1

	return 0
}

bfd_profile_cb() {

	local section="$1"
	local cfg="/var/run/frr/bfd.conf"

	config_get receive_interval "$section" "receive_interval"
	config_get transmit_interval "$section" "transmit_interval"

	xappend "$cfg" "profile" "$section"

	[ -n "$receive_interval" ] && xappend "$cfg" "receive-interval" "$receive_interval"
	[ -n "$transmit_interval" ] && xappend "$cfg" "transmit-interval" "$transmit_interval"

	echo "" >> "$cfg"
}

bfd_peers_cb() {

	local section="$1"
	local cfg="/var/run/frr/bfd.conf"

	config_get enabled "$section" "enabled"
	[ "$enabled" == "1" ] || return 0

	config_get multihop "$section" "multihop"
	config_get passive_mode "$section" "passive_mode"

	config_get ip "$section" "ip"
	config_get interface "$section" "interface"
	config_get profile "$section" "profile"
	config_get receive_interval "$section" "receive_interval"
	config_get transmit_interval "$section" "transmit_interval"
	config_get detect_multiplier "$section" "detect_multiplier"

	[ -n "$interface" ] && ip="${ip} interface ${interface}"
	[ -n "$multihop" ] && ip="${ip} multihop local-address ${multihop}"

	[ -n "$ip" ] && xappend "$cfg" "peer" "$ip"

	[ "$passive_mode" = "1" ] && xappend "$cfg" "passive-mode"
	[ -n "$detect_multiplier" ] && xappend "$cfg" "detect-multiplier" "$detect_multiplier"
	[ -n "$profile" ] && xappend "$cfg" "profile" "$profile"
	[ -n "$receive_interval" ] && xappend "$cfg" "receive-interval" "$receive_interval"
	[ -n "$transmit_interval" ] && xappend "$cfg" "transmit-interval" "$transmit_interval"

	echo "" >> "$cfg"
}

bfd_utils_parse_config() {

	local cfg="/var/run/frr/bfd.conf"

	config_load bfd

	bfd_get_status || return 0

	xappend "$cfg" "bfd"
	config_foreach bfd_profile_cb "profile"
	config_foreach bfd_peers_cb "peer"
}

