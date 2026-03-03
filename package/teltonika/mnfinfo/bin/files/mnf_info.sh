#!/bin/sh

usage() {
	echo "Displays manufacturer information
   -m, --mac                        Get MAC address
   -t, --maceth                     Get Eth MAC address
   -w, --wps                        Get WPS
   -n, --name                       Get device name
   -s, --sn                         Get serial number
   -b, --batch                      Get batch
   -v, --blver                      Get bootloader version
   -H, --hwver                      Get hardware version (major)
   -B, --branch                     Get hardware branch
   -F, --full_hwver                 Get hardware branch and version
   -C, --simcfg <SIM_NUMBER>        Get config of <SIM_NUMBER>
   -d, --boot_profile <SIM_NUMBER>  Get eSIM bootstrap profile of <SIM_NUMBER>
   -S, --simpin <SIM_NUMBER>        Get pincode of <SIM_NUMBER>
   -P, --set_simpin <SIM_NUMBER>    Set pincode of <SIM_NUMBER>
   -p, --pin <PIN>                  Set pincode to <PIN>
                                    \`-p erase\` to erase the PIN
   -Q, --set_iccid <SIM_NUMBER>     Set iccid for <SIM_NUMBER>
   -q, --iccid <ICCID>              <ICCID> to set
                                    \`-p erase\` to erase the ICCID
   -h, --help                       Show help" 1>&2
   exit 1
}

val () {
	cat /sys/mnf_info/$1 2>/dev/null || echo -n "N/A"
	echo ""
}

sim_idx_ok() {
	[ -z "$1" ] || [ "$1" = "0" ] || ! echo "$1" | grep -q "^[0-9]*$" || \
		[ "$1" -gt "$(cat /sys/mnf_info/sim_count)" ] && {
		usage
	}
}

sim_cfg () {
	sim_idx_ok "$1"
	cut -d '_' -f "$1" /sys/mnf_info/sim_cfg
	exit $?
}

gbp () {
	sim_idx_ok "$1"
	local res="$(cat /log/boot_$1_iccid 2>/dev/null)"
	echo "${res:-N/A}"
	exit 0
}

gpin () {
	sim_idx_ok "$1"
	grep "^[0-9]*$" "/log/sim_$1_pin" 2>/dev/null || {
		cat "/sys/mnf_info/simpin$1" 2>/dev/null
		echo ""
		exit $?
	}
	exit 0
}

spin () {
	sim_idx_ok "$1"

	[ "$2" = "erase" ] && {
		echo -n -e "\xff\xff\xff\xff"  > "/log/sim_$1_pin" 2>/dev/null
		exit 0
	}

	len=${#2}
	[ "$len" -lt 4 ] || [ "$len" -gt 8 ] || ! echo "$2" | grep -q "^[0-9]*$" && {
		echo "ERROR: Expected 4-8 digits for PIN." 1>&2
		exit 1
	}

	echo -n "$2"  > "/log/sim_$1_pin" 2>/dev/null
	exit $?
}

siccid () {
	sim_idx_ok "$1"

	f="/log/boot_$1_iccid"

	[ "$(id -u)" -ne "0" ] && ! id -Gn | grep -qw "gsm" && {
		echo "ERROR: Need root user or log group" 1>&2
		exit 1
	}

	[ "$2" = "erase" ] && {
		rm -f "$f"
		exit 0
	}

	len=${#2}
	[ "$len" -lt 18 ] || [ "$len" -gt 24 ] || ! echo "$2" | grep -q "^[0-9]*$" && {
		echo "ERROR: Expected 18-24 digits for iccid." 1>&2
		exit 1
	}

	echo -n "$2"  > "$f" 2>/dev/null

	chown :log "$f"
	chmod 660 "$f"

	exit $?
}

full_hwver () {
	local hwver="$(val hwver)"
	cat /sys/mnf_info/branch 2>/dev/null || echo -n "N/A"
	
	echo "$1" | grep -q "^A-Z$" /sys/mnf_info/branch && {
		echo "$hwver.$(cat /sys/mnf_info/branch)"
		exit 0
	}

	echo "$hwver"
	exit 0
}

SIMPIN_IDX=

if [[ $# -eq 0 ]]; then
	usage
fi

while [[ $# -gt 0 ]]; do
	case "$1" in
		--help) usage ;;
		--mac) val mac ;;
		--maceth) val maceth ;;
		--name) val name ;;
		--wps) val wps;;
		--sn) val serial ;;
		--batch) val batch ;;
		--blver) val blver ;;
		--hwver) val hwver ;;
		--full_hwver) full_hwver ;;
		--hwver_lo) val hwver_lo ;;
		--branch) val branch ;;
		--passw) val pass;;
		--wifi_pass) val wpass;;
		--boot_profile) gbp "$2" ;;
		--simcfg) sim_cfg "$2" ;;
		--simpin) gpin "$2" ;;
		--set_simpin) SIMPIN_IDX="$2"; shift 2; continue ;; # Shift exactly 2 times
		--pin) spin "$SIMPIN_IDX" "$2" ;;
		--set_iccid) SIMPIN_IDX="$2"; shift 2; continue ;; # Shift exactly 2 times
		--iccid) siccid "$SIMPIN_IDX" "$2" ;;
		--*)
			echo "Option does not exist: '$1'" 1>&2
			usage
			;;
		-?*) break ;; # Short options, possibly combined
		*)
			exit 1 # Legacy behavior
			;;
	esac
	shift
done


# Short options, possibly combined
while getopts "hmtnwsbvHFLBxWQd:C:S:P:p:q:" o; do
	case "${o}" in
		h) usage ;;
		m) val mac ;;
		t) val maceth ;;
		n) val name ;;
		w) val wps;;
		s) val serial ;;
		b) val batch ;;
		v) val blver ;;
		H) val hwver ;;
		F) full_hwver ;;
		L) val hwver_lo ;;
		B) val branch ;;
		x) val pass;;
		W) val wpass;;
		d) gbp "$2" ;;
		C) sim_cfg "$2" ;;
		S) gpin "$2" ;;
		P) SIMPIN_IDX="$2"; shift 2 ;;
		p) spin "$SIMPIN_IDX" "$2" ;;
		Q) SIMPIN_IDX="$2"; shift 2 ;;
		q) siccid "$SIMPIN_IDX" "$2" ;;
		*)
			echo "Option does not exist: '$1'" 1>&2
			usage
			;;
	esac
done
