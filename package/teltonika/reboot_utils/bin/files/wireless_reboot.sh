#!/bin/sh

STATS_FILE="/sys/kernel/debug/ieee80211/phy0/mt76/reset"
RESET_FILE="/sys/kernel/debug/ieee80211/phy0/mt76/full_reset"

get_stats() {
	local awk_result awk_code
	awk_result=$(awk -F: '
		BEGIN { printf "{" }

		/Beacon stuck/ { gsub(/ /, "", $2); printf "\"beacon_stuck\":%s", $2 }
		/MCU hang/ { gsub(/ /, "", $2); printf ",\"mcu_hang\":%s", $2 }

		END { print "}" }
	' "$STATS_FILE" 2>&1)
	awk_code=$?
	if [ $awk_code -eq 0 ]; then
		echo "$awk_result"
	else
		echo '{"beacon_stuck":0,"mcu_hang":0}'
	fi
}

full_reset() {
	local err_msg code
	err_msg=$( (echo "1" > "$RESET_FILE") 2>&1 )
	code=$?
	if [ $code -ne 0 ] && [ -z "$err_msg" ]; then
		err_msg="Unknown error or silent failure"
	fi
	echo "{\"code\":$code,\"err_msg\":\"$err_msg\"}"
}

main () {
	case "$1" in
		list)
			echo '{ "get_stats": {}, "full_reset": {} }'
			;;
		call)
			case "$2" in
				get_stats)
					get_stats
					;;
				full_reset)
					full_reset
					;;
			esac
		;;
	esac
}

main "$@"
