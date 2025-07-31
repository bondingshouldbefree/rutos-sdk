#!/bin/ash

. /lib/functions/uci-defaults.sh

boot_target_pre_board_detect() {
	local param="$(/sbin/mnf_info --name)"
	local router_name="${param:0:6}"

	[ "$router_name" = "RUTX08" ] || [ "$router_name" = "RUTX09" ] && \
		rm /etc/modules.d/ath10k
}

ucidef_target_defaults() {
	local model="$1"

	case "$model" in
	RUTX09*)
		ucidef_add_static_modem_info "$model" "3-1" "primary" "gps_out"
	;;
	RUTX11*)
		ucidef_add_static_modem_info "$model" "3-1" "primary" "gps_out"
	;;
	RUTX12*)
		ucidef_add_static_modem_info "$model" "3-1" "primary" "gps_out"
		ucidef_add_static_modem_info "$model" "1-1.2"
	;;
	RUTX14*)
		ucidef_add_static_modem_info "$model" "1-1" "primary" "gps_out"
	;;
	RUTX50*)
		ucidef_add_static_modem_info "$model" "2-1" "primary" "gps_out"
	;;
	RUTXR1*)
		ucidef_add_static_modem_info "$model" "3-1" "primary"
	;;
	esac
}