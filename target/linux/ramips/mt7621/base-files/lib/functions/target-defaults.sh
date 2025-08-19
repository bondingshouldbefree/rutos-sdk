#!/bin/ash

. /lib/functions/uci-defaults.sh

ucidef_target_defaults() {
	local model="$1"
	local hw_ver="$2"
	local branch="$3"

	case "$model" in
	OTD5*)
		ucidef_add_static_modem_info "$model" "2-1" "primary"
	;;
	TAP2*)
		ucidef_set_interface_default_macaddr "lan" "$(mtd_get_mac_binary config 0x0)"
	;;
	RUTM09*)
		ucidef_add_static_modem_info "$model" "1-2" "primary" "gps_out"
	;;
	RUTM11*)
		ucidef_add_static_modem_info "$model" "1-2" "primary" "gps_out"
	;;
	RUTM12*)
		ucidef_add_static_modem_info "$model" "1-1" "primary" "gps_out"
		ucidef_add_static_modem_info "$model" "1-2"
	;;
	RUTM20*)
		ucidef_add_static_modem_info "$model" "2-1" "primary"
	;;
	RUTM30* |\
	RUTM31*)
		ucidef_add_static_modem_info "$model" "2-1" "primary"
	;;
	RUTM50*)
		if [ "$branch" == "A" ]; then
			ucidef_set_release_version "7.7"
			ucidef_set_hwinfo m2_modem
			gps=""
		else
			ucidef_set_hwinfo gps
			gps="gps_out"
		fi
		ucidef_add_static_modem_info "$model" "2-1" "primary" "$gps"
	;;
	RUTM51*)
		ucidef_add_static_modem_info "$model" "2-1" "primary"
	;;
	RUTM52*)
		ucidef_add_static_modem_info "$model" "2-1.1" "primary"
		ucidef_add_static_modem_info "$model" "2-1.2"
	;;
	RUTM54*)
		ucidef_add_static_modem_info "$model" "2-1" "primary"
	;;
	RUTM55*)
		ucidef_add_static_modem_info "$model" "2-1" "primary"
	;;
	RUTM56*)
		ucidef_add_static_modem_info "$model" "2-1" "primary"
		ucidef_add_static_modem_info "$model" "1-2"
	;;
	RUTM59*)
		ucidef_add_static_modem_info "$model" "2-1" "primary" "gps_out"
	;;
	ATRM50*)
		ucidef_add_static_modem_info "$model" "2-1" "primary" "gps_out"
		[ "$hw_ver" -gt 4 ] && ucidef_set_hwinfo itxpt
	;;
	esac
}
