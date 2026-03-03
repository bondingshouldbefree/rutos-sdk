#!/bin/sh

get_openvpn_option() {
	local config="$1"
	local variable="$2"
	local option="$3"
	local value

	value=$(sed -n -e 's/^[[:space:]]*'"$option"'\s*[:]*[[:space:]]\+\(.*\)$/\1/p' "$config" | tail -n 1)
	[ -n "$value" ] || return 1
	value=$(echo "$value" | awk '{$1=$1; print}')

	export -n "$variable=$value"
	return 0
}
