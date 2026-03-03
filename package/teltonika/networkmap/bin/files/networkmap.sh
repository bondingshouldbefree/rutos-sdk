#!/bin/sh

. /usr/share/libubox/jshn.sh

BIN="/bin/networkmap"
[ -x "$BIN" ] || BIN="/usr/local$BIN"

main () {
	case "$1" in
		list)
			json_init
			json_add_object "scan"
			json_add_array "interfaces"
			json_close_array
			json_close_object
			json_add_object "update"
			json_close_object
			json_dump
		 	;;
		call)
			case "$2" in
				scan)
					read input
					json_load "$input"
					json_is_a interfaces array || return 1
					local args=""
					local idx=1
					json_select interfaces
					while json_is_a $idx string; do
						local iface
						json_get_var iface $idx
						args="$args -i $iface"
						idx=$(( idx + 1 ))
					done
					$BIN $args > /dev/null 2>&1
					code=$?
					json_init
					json_add_int code "$code"
					json_dump
				;;
				update)
					$BIN -u > /dev/null 2>&1
					code=$?
					json_init
					json_add_string code "$code"
					json_dump
				;;
			esac
		;;
	esac
}

main "$@"
