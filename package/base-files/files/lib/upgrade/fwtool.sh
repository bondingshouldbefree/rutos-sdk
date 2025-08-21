. /lib/upgrade/common.sh

# fwtool error messages
# 0 - No error
# 1 - Signature processing error
# 2 - Image signature not present
# 3 - Use sysupgrade -F to override this check when downgrading or flashing to vendor firmware
# 4 - Image metadata not present
# 5 - /etc/board.json file not found
# 6 - Invalid firmware metadata
# 7 - Device code mismatch
# 8 - Hardware version mismatch
# 9 - Batch number mismatch
# 10 - Serial number mismatch
# 11 - Firmware have new password scheme and can not be downgraded
# 12 - Firmware version is to old
# 13 - Firmware is not compatible with current bootloader version
# 14 - Firmware is not supported by this device
# 15 - Insufficient free space in /tmp
# 16 - Downgrade is not allowed
# 17 - Only authorized firmware is allowed
# 18 - Upgrade terminated due to low battery level

fwtool_msg() {
	local file="/tmp/fwtool_last_error"

	v "$1"
	ubus call log write_ext "{'event': '$1', 'sender': 'sysupgrade', 'table': 1, 'write_db': 1}"

	if [ ! -f "$file" ] || [ "$(cat "$file")" = "0" ]; then
		echo "$2" > "$file"
	fi
}

fwtool_pre_upgrade() {
	fwtool -q -t -s /dev/null "$1"
	fwtool -q -t -i /dev/null "$1"
}

fwtool_check_signature() {
	local ret

	[ $# -gt 1 ] && return 1

	[ ! -x /usr/bin/fwcert ] && {
		fwtool_msg "Signature processing error" "1"
		return 1
	}

	if ! fwtool -q -s /tmp/sysupgrade.ucert "$1"; then
		fwtool_msg "Image signature not present" "2"
		return 1
	fi

	fwtool -q -T -s /dev/null "$1" | \
		fwcert -m - -x "/tmp/sysupgrade.ucert" -P /etc/proprietary_keys &>/dev/null

	return $ret
}

fwtool_get_fw_version() {
	[ $# -ne 1 ] && return 1

	. /usr/share/libubox/jshn.sh

	if part_magic_cd "$1"; then
		dd if="$1" of=/tmp/sysupgrade.meta bs=32K count=1 2>/dev/null
	else
		if ! fwtool -q -i /tmp/sysupgrade.meta "$1"; then
			v "Firmware metadata not found"
			return 1
		fi
	fi

	json_load "$(cat /tmp/sysupgrade.meta)" || {
		v "Invalid firmware metadata"
		return 1
	}

	json_get_var fw_version "version" || {
		v "Missing version entry"
		return 1
	}

	echo "$fw_version"
}

fwtool_json_entry_array_check() {
	[ $# -ne 2 ] && return 1

	json_entry_name="$1"
	correct_value="$2"

	json_select "$json_entry_name" || {
		v "Missing $json_entry_name entry"
		return 1
	}

	json_get_keys entry_keys

	for k in $entry_keys; do
		json_get_var k_var "$k"
		if [ -n "$k_var" ]; then
			regex_value=$(echo "$correct_value" | grep -oe "$k_var")
			if [ "$correct_value" = "$regex_value" ]; then
				json_select ..
				return 0
			fi
		fi
	done

	json_select ..

	return 1
}

fwtool_json_release_version_check() {
	local new_major="$(echo $new_version | cut -d'.' -f 2)"
	local new_mid="$(echo $new_version | cut -d'.' -f 3)"
	local new_minor="$(echo $new_version | cut -d'.' -f 4)"
	[ -z $new_minor ] && new_minor="0"

	local release_major="$(echo $release_version | cut -d'.' -f 1)"
	local release_mid="$(echo $release_version | cut -d'.' -f 2)"
	local release_minor="$(echo $release_version | cut -d'.' -f 3)"

	[ -z "$release_minor" ] || [ "$release_minor" = "*" ] && release_minor="0"
	[ -z "$release_mid" ] || [ "$release_mid" = "*" ] && release_mid="0" && release_minor="0"
	[ -z "$release_major" ] || [  "$release_major" = "*" ] && release_major="0" && release_mid="0" && release_minor="0"

	if [ "$new_major" -le "$release_major" -a "$new_mid" -le "$release_mid" -a "$new_minor" -lt "$release_minor" ] || \
		[ "$new_major" -le "$release_major" -a "$new_mid" -lt "$release_mid" ] || \
		[ "$new_major" -lt "$release_major" ]; then
		return 1
	fi

	return 0
}

fwtool_check_image() {
	[ $# -gt 1 ] && return 1

	. /usr/share/libubox/jshn.sh

	local blver=$(mnf_info -v)
	local vb=$(echo $blver | grep '\-vb')
	local device_name=$(mnf_info -n | cut -c1-4 2>/dev/null)

	if part_magic_cd "$1"; then
		dd if="$1" of=/tmp/sysupgrade.meta bs=32K count=1 2>/dev/null
	else
		if ! fwtool -q -i /tmp/sysupgrade.meta "$1"; then
			fwtool_msg "Image metadata not present" "4"
			[ "$REQUIRE_IMAGE_METADATA" = 1 -a "$FORCE" != 1 ] && {
				fwtool_msg "Use sysupgrade -F to override this check when downgrading or flashing to vendor firmware" "3"
			}
			[ "$REQUIRE_IMAGE_METADATA" = 1 ] && return 1
			[ -n "$vb" ] && return 1
			return 0
		fi
	fi

	json_load_file /etc/board.json || {
		fwtool_msg "/etc/board.json file not found" "5"
		return 1
	}

	json_get_var release_version "release_version"

	json_load_file /tmp/sysupgrade.meta || {
		fwtool_msg "Invalid firmware metadata" "6"
		return 1
	}

	json_get_var new_version "version"
	current_device=$(mnf_info --name)
	current_hwver=$(mnf_info --hwver)
	current_batch=$(mnf_info --batch)
	current_serial=$(mnf_info --sn)

	fwtool_json_entry_array_check "device_code" "$current_device" || {
		fwtool_msg "Device code mismatch" "7"
		return 1
	}

	fwtool_json_entry_array_check "hwver" "$current_hwver" || {
		fwtool_msg "Hardware version mismatch" "8"
		return 1
	}

	fwtool_json_entry_array_check "batch" "$current_batch" || {
		fwtool_msg "Batch number mismatch" "9"
		return 1
	}

	fwtool_json_entry_array_check "serial" "$current_serial" || {
		fwtool_msg "Serial number mismatch" "10"
		return 1
	}

	fwtool_json_release_version_check || {
		fwtool_msg "Firmware version is too old" "12"
		return 1
	}

	device="$(cat /tmp/sysinfo/board_name)"
	devicecompat="$(uci -q get system.@system[0].compat_version)"
	[ -n "$devicecompat" ] || devicecompat="1.0"

	json_get_var imagecompat compat_version
	json_get_var compatmessage compat_message
	[ -n "$imagecompat" ] || imagecompat="1.0"

	# select correct supported list based on compat_version
	# (using this ensures that compatibility check works for devices
	#  not knowing about compat-version)
	local supported=supported_devices
	[ "$imagecompat" != "1.0" ] && supported=new_supported_devices
	json_select $supported || return 1

	json_get_keys dev_keys
	for k in $dev_keys; do
		json_get_var dev "$k"
		if [ "$dev" = "$device" ] || [ "$dev" = "*" ]; then
			# allow flashing firmwares with lower major compat version on RUTC devices
			if [ "$device_name" = "RUTC" ] && [ ${imagecompat%.*} -le ${devicecompat%.*} ]; then
				return 0
			fi

			# major compat version -> no sysupgrade
			if [ "${devicecompat%.*}" != "${imagecompat%.*}" ]; then
				v "The device is supported, but this image is incompatible for sysupgrade based on the image version ($devicecompat->$imagecompat)."
				[ -n "$compatmessage" ] && v "$compatmessage"
				return 1
			fi

			# minor compat version -> sysupgrade with -n required
			if [ "${devicecompat#.*}" != "${imagecompat#.*}" ] && [ "$SAVE_CONFIG" = "1" ]; then
				v "The device is supported, but the config is incompatible to the new image ($devicecompat->$imagecompat). Please upgrade without keeping config (sysupgrade -n)."
				[ -n "$compatmessage" ] && v "$compatmessage"
				return 1
			fi

			return 0
		fi
	done

	fwtool_msg "Firmware is not supported by this device" "14"
	return 1
}

fwtool_check_backup() {
	local backup_dir="$1"
	local size

	[ -n "$backup_dir" ] || return 1

	local this_device_code=$(mnf_info --name)
	local device_code_in_the_new_config=$(uci -q -c "${backup_dir}/etc/config" get system.system.device_code)

	[ "${this_device_code:0:4}" = "RUT2" ] && size=8 || size=7

	if [ "${#this_device_code}" -ne 12 ] || [ "${#device_code_in_the_new_config}" -ne 12 ] ||
			[ "${this_device_code:0:$size}" != "${device_code_in_the_new_config:0:$size}" ]; then
		return 1
	fi

	local this_device_fw_version=$(cat /etc/version)
	local fw_version_in_new_config=$(uci -q -c "${backup_dir}/etc/config" get system.system.device_fw_version)
	[ "${#fw_version_in_new_config}" -lt 12 ] && return 2

	local stripped_backup="${fw_version_in_new_config##*_}"
	local stripped_device="${this_device_fw_version##*_}"

	[ "$stripped_device" = "$stripped_backup" ] && return 0

	local before=$(printf "%s\n" "$stripped_device" "$stripped_backup")
	local sorted=$(echo "$before" | sort -V)

	[ "$before" = "$sorted" ] && return 2

	return 0
}

fwtool_check_upgrade_type() {
	local current_ver="$(cat /etc/version)"

	# cannot determine current version
	# assume it is the worst case - downgrade
	[ -z "$current_ver" ] && return 1

	local ver=$(fwtool_get_fw_version "$1")

	# cannot determine version from the archive
	# assume it is the worst case - downgrade
	[ "$?" -eq 1 ] || [ -z "$ver" ] && return 1

	local major="$(echo "$ver" | awk -F . '{print $2 }')"
	local minor="$(echo "$ver" | awk -F . '{print $3 }')"
	minor="$(echo "$minor" | awk -F _ '{ print $1 }')"

	local current_fw=$(echo "$current_ver" | awk -F . '{ print $1 }')
	local img_fw=$(echo "$ver" | awk -F . '{ print $1 }')

	local current_branch=$(echo "$current_fw" | awk -F _ '{ print $(NF - 1) }')
	local fw_branch=$(echo "$img_fw" | awk -F _ '{ print $(NF - 1) }')

	# cannot parse branch, assume it is the worst case - downgrade
	[ -z "$current_branch" ] || [ -z "$fw_branch" ] && return 1

	# downgrade on unknown branches
	case "$fw_branch" in
		F*|R*|H*|GPL*|SDK*|DEV*)
			;;
		*)
			return 1
			;;
	esac

	local current_client="$(echo "$current_fw" | awk -F _ '{ print $NF }')"
	local fw_client="$(echo "$img_fw" | awk -F _ '{ print $NF }')"

	# cannot parse client no, assume it is the worst case - downgrade
	[ -z "$current_client" ] || [ -z "$fw_client" ] && return 1

	# client numbers do not match, it is downgrade
	[ "$current_client" != "$fw_client" ] && return 1

	local current_major="$(echo "$current_ver" | awk -F . '{ print $2 }')"

	# cannot current major version, assume it is the worst case - downgrade
	[ -z "$current_major" ] || [ -z "$major" ] && return 1

	# current major is newer - downgrade
	[ "$current_major" -gt "$major" ] && return 1

	# current major is older - upgrade
	[ "$major" -gt "$current_major" ] && return 0

	local current_minor="$(echo "$current_ver" | awk -F . '{ print $3 }')"
	current_minor="$(echo "$current_minor" | awk -F _ '{ print $1 }')"

	# cannot current minor version, assume it is the worst case - downgrade
	[ -z "$current_minor" ] || [ -z "$minor" ] && return 1

	# current minor is newer - downgrade
	[ "$current_minor" -gt "$minor" ] && return 1

	return 0
}

fwtool_check_passwd_warning() {
	local device_name="$(mnf_info -n | cut -c1-4 2>/dev/null)"

	[ -n "$(mnf_info -x)" ] || return 0

	local ver="$(fwtool_get_fw_version "$1")"
	local fw_major="$(echo "$ver" | cut -d'.' -f2)"
	local fw_minor="$(echo "$ver" | cut -d'.' -f3 | cut -d'_' -f1)"
	local fw_hotfix="$(echo "$ver" | cut -d'.' -f4 | cut -d'_' -f1)"

	local target_hotfix="2"
	[ "$device_name" = "RUTX" ] || [ "$device_name" = "TRB1" ] && target_hotfix="4"

	[ "$fw_major" -lt 7 ] ||
		{ [ "$fw_major" -eq 7 ] && [ "$fw_minor" -lt 2 ]; } ||
		{ [ "$fw_major" -eq 7 ] && [ "$fw_minor" -eq 2 ] &&
			[ "$fw_hotfix" -lt "$target_hotfix" ]; } && {
		return 1
	}

	return 0
}
