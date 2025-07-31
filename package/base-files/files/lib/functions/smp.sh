#!/bin/sh

set_hex_val() {
	local file="$1"
	local val="$2"
	val="$(printf %x "$val")"
	[ -n "$DEBUG" ] && echo "$file = $val"
	echo "$val" > "$file"
}

default_rps() {
	local NPROCS="$(grep -c "^processor.*:" /proc/cpuinfo)"
	[ "$NPROCS" -gt 1 ] || exit

	local PROC_MASK="$(( (1 << $NPROCS) - 1 ))"

	for dev in /sys/class/net/*; do
		[ -d "$dev" ] || continue

		# ignore virtual interfaces
		[ -n "$(ls "${dev}/" | grep '^lower_')" ] && { 
			[ "${dev:15:6}" == "qmimux" ] || continue
		} 
		[ -d "${dev}/device" ] || { 
			[ "${dev:15:6}" == "qmimux" ] || continue
		} 

		device="$(readlink "${dev}/device")"
		device="$(basename "$device")"

		for q in ${dev}/queues/rx-*; do
			set_hex_val "$q/rps_cpus" "$PROC_MASK"
		done

		ntxq="$(ls -d ${dev}/queues/tx-* | wc -l)"

		idx="0"
		for q in ${dev}/queues/tx-*; do
			set_hex_val "$q/xps_cpus" "$((1 << $idx))"
			let "idx = idx + 1"
			[ "$idx" -ge "$NPROCS" ] && idx=0
		done
	done
}
