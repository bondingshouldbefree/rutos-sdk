#!/bin/sh

[ -z "$1" ] && echo "Error: should be run by udhcpc" && exit 1

get_options() {
	noopt="/tmp/udhcpc.noopt.${interface:-unknown}"

	[ -z "$opt43" ] && {
		[ -f "$noopt" ] || logger -t udhcpc "Error: no option 43"
		echo 1 > "$noopt"
		rm -f /tmp/udhcpc.result
		exit 0
	}

	rm -f "$noopt"
	echo "$opt43" > /tmp/udhcpc.result
}

case "$1" in
	bound)
		get_options
	;;
esac
