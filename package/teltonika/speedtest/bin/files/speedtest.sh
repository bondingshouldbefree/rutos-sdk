#!/bin/sh

. /usr/share/libubox/jshn.sh

BIN="/usr/bin/speedtest"
[ -x "$BIN" ] || BIN="/usr/local$BIN"

main () {
	case "$1" in
		list) echo '{ "get_server_list": { "search": "String" }, "run": { "custom_url": "String", "time": 1, "iface": "wan" } }' ;;
		call)
			case "$2" in
				get_server_list)
					read input
					json_load "$input"
					local search
					json_get_var search "search"
					res="$($BIN -g "$search")"
					code=$?
					rm -f /tmp/speedtest.json # workaround speedtest bug. It creates a status file even if just -g is called.
					json_init
					json_add_string output "$res"
					json_add_int code "$code"
					json_dump
				;;
				run)
					read input
					json_load "$input"
					local custom_url time iface
					json_get_var custom_url "custom_url"
					json_get_var time "time"
					json_get_var iface "iface"
					(
						set -- -s
						set -- "$@" -t "${time:-15}"
						[ -n "$custom_url" ] && set -- "$@" -u "$custom_url"
						[ -n "$iface" ] && set -- "$@" -w "$iface"
						exec "$BIN" "$@"
					) > /dev/null 2>&1 &
					json_init
					json_add_string code 0
					json_dump
				;;
			esac
		;;
	esac
}

main "$@"
