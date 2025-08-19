. /lib/functions/failsafeboot.sh
. /lib/upgrade/common.sh

REQUIRE_IMAGE_METADATA=1

nand_upgrade_ubi_fsb() {
	local ubi_file="$1"
	local mtdnum="$(find_mtd_index "$CI_UBIPART")"
	local attempts_limit=30

	if [ ! "$mtdnum" ]; then
		echo "cannot find mtd device $CI_UBIPART"
		umount -a
		reboot -f
	fi

	fwtool -q -t -i /dev/null "$1"

	local mtddev="/dev/mtd${mtdnum}"
	while [ $attempts_limit -gt 0 ]; do
		ubidetach -p "${mtddev}" 2>/dev/null && break
		attempts_limit=$((attempts_limit-1))
		sleep 1
	done
	sync
	fsb_upgrade_begin $CI_UBIPART

	ubiformat "${mtddev}" -y -f "${ubi_file}"
	if [ "$?" -ne 0 ]; then
		echo "Error writing to $CI_UBIPART"
		umount -a
		reboot -f
	fi

	ubiattach -p "${mtddev}"

	local conf_tar="/tmp/sysupgrade.tgz"
	sync
	[ -f "$conf_tar" ] && nand_restore_config "$conf_tar"
	echo "sysupgrade successful"

	fsb_upgrade_finalize $CI_UBIPART
	umount -a
	reboot -f
}

platform_check_image() {
	return 0
}

platform_do_upgrade() {
	CI_UBIPART="$(fsb_get_upgrade_slot)"
	nand_upgrade_ubi_fsb "$1"
}

platform_check_hw_support() {
	local nand_model_file="/sys/class/mtd/mtd8/nand_model"
	local board exp

	board="$(cat /sys/mnf_info/name)"

	{ ! prepare_metadata_hw_mods "$1"; } && return 1

	# nand type validation
	grep -q '^W25N02KV$' "$nand_model_file" && { ! find_hw_mod "W25N02KV"; } && {
		echo "Winbond NAND detected but fw does not support it"
		return 1
	}

	exp="^RUTM52"
	[[ $board =~ $exp ]] && {
		{ "$(lsusb | grep -E "0451:802(5|7)")"; } && { ! find_hw_mod "RUTM52_TUSB8020B"; } && return 1
	}

	return 0
}

# Power loss prevention: check ATRM50 battery before sysupgrade starts
platform_check_prerequisites() {
	if result=$(ubus call ioman.gpio.bat status 2>/dev/null); then

		value=$(echo "$result" | jsonfilter -e "@.value")
		[ "$value" = "0" ] && return 1
	fi

	return 0
}
