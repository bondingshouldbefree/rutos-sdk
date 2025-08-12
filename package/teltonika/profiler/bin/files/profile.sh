#!/bin/sh
# shellcheck disable=3010,3043,2317,3057

. /lib/functions.sh
. /lib/upgrade/common.sh

export CONFFILES=/tmp/profile.conffiles
RM_CONFFILES=/tmp/rm_profile.conffiles
PROFILE_VERSION_FILE=/etc/profile_version
EXCEPTIONS="etc/config/rms_connect_timer etc/config/profiles etc/crontabs/root etc/hosts etc/config/luci etc/config/vuci
	etc/inittab etc/group etc/passwd etc/profile etc/shadow etc/shells etc/sysctl.conf etc/rc.local  etc/config/teltonika
	etc/default-config etc/dropbear/dropbear_ecdsa_host_key etc/dropbear/dropbear_ed25519_host_key"

EXTRA_FILES="/etc/firewall.user /etc/profile_version"

KNOWN_CLEANS="/etc/config/event_juggler"

TMP_PATH="/tmp/tmp_root/"
MAIN_PATH="$(uci_get profiles general path /etc/profiles)"
CURRENT_PROFILE="$(uci_get profiles general profile default)"

log() {
	logger -s -t "$(basename "$0")" "$1"
}

add_uci_conffiles() {
	local opkg_command=""
	local file="$1"
	local misc_files=""

	if [ -f "/bin/opkg" ]; then
		opkg_command="opkg list-changed-conffiles"
	else
		# if opkg doesn't exist, save the entire /etc directory
		find "/etc" -type f -o -type l 2>/dev/null >"$file"
		# exclude these directories
		sed -i "/\/etc\/uci-defaults\//d;
			/\/etc\/init.d\//d;
			/\/etc\/modules-boot.d\//d;
			/\/etc\/modules.d\//d;
			/\/etc\/profiles\//d;
			/\/etc\/rc.button\//d;
			/\/etc\/rc.d\//d;
			/\/etc\/hotplug.d\//d" "$file"
	fi

	misc_files=$(sed -ne '/^[[:space:]]*$/d; /^#/d; p' \
		/etc/sysupgrade.conf /lib/upgrade/keep.d/* /usr/local/lib/upgrade/keep.d/* 2>/dev/null)

	[ -n "$opkg_command" ] && eval "$opkg_command" | sed 's|^/usr/local/etc/|/etc/|' >"$file"
	#Do not qoute ${misc_files} !!!!
	# shellcheck disable=2086 # Splitting is intended here
	[ -n "$misc_files" ] && find ${misc_files} -type f -o -type l 2>/dev/null >>"$file"

	# removes duplicates
	[ -f "$file" ] && {
		local temp="$(sort -u "$file")"
		printf '%s' "$temp" >"$file"
	}

	return 0
}

remove_exceptions() {
	# shellcheck disable=2086 # Splitting is intended here
	sed -i'' -e "$(printf "\,%s,d; " $EXCEPTIONS)" "$1"
}

remove_exceptions_from_file() {
	local dir="$1"
	cd "$dir" || return 1

	# shellcheck disable=2086 # Splitting is intended here
	rm -f $EXCEPTIONS

	cd - >/dev/null || return 1
}

add_extras() {
	# shellcheck disable=2086 # Splitting is intended here
	printf "%s\n" $EXTRA_FILES >>"$CONFFILES"
}

is_switch() {
	[ "$(jsonfilter -q -i /etc/board.json -e '@.hwinfo.switch')" = "true" ]
}

remove_section() {
	local section="$1"
	local config="$2"
	local option="$3"
	local value

	config_get value "$section" "$option" ""
	[ -n "$value" ] && uci_remove "$config" "$section"
}

remove_option() {
	local section="$1"
	local config="$2"
	local option="$3"
	local value

	config_get value "$section" "$option" ""
	[ -n "$value" ] && uci_remove "$config" "$section" "$option"
}

config_remove_if_exists() {
	local config="$1"
	local section="$2"
	local option="$3"
	local action="$4"

	config_load "$config"
	config_foreach "$action" "$section" "$config" "$option"
	uci_commit "$config"
}

update_tmp_md5_config() {
	local profile="$1"
	local cfg_name="$2"
	local md5_file="/etc/profiles/${profile}.md5"

	local cfg_file="${TMP_PATH}etc/config/$cfg_name"
	[ -f "$cfg_file" ] && {
		sed -i "/$cfg_name/d" "$md5_file"
		md5sum "$cfg_file" | sed "s|$TMP_PATH|/|" >>"$md5_file"
	}
}

__fix_conf_files() {
	local profile="$1"
	local uci_dir="$UCI_CONFIG_DIR"

	# Set global uci config dir
	UCI_CONFIG_DIR="${TMP_PATH}etc/config"

	local network_action="remove_section"
	is_switch && {
		network_action="remove_option"
		config_remove_if_exists "tswconfig" "switch_port" "macaddr" "remove_option"
		update_tmp_md5_config "$profile" "tswconfig"
	}

	config_remove_if_exists "network" "device" "macaddr" "$network_action"
	update_tmp_md5_config "$profile" "network"

	# Revert global uci config dir
	UCI_CONFIG_DIR="$uci_dir"
}

__add_conf_files() {
	local profile="$1" filelist="$2"
	local cfg_name misc_files keep_files

	for i in $(grep -sE "^/etc/config/|^/usr/local/etc/config/" "$filelist"); do
		i="${i#/usr/local}"
		cfg_name=$(basename "$i")
		local destination_file="${TMP_PATH}etc/config/$cfg_name"
		# Check if the file already exists in the destination directory
		[ -s "$destination_file" ] && continue
		cp "$i" "$destination_file"
		sed -i "/$cfg_name/d" "/etc/profiles/${profile}.md5"
		md5sum "$i" >>"/etc/profiles/${profile}.md5"
	done

	keep_files=$(grep -sE "^/lib/upgrade/keep.d/|^/usr/local/lib/upgrade/keep.d/" "$filelist")
	[ -z "$keep_files" ] && return

	misc_files=$(sed -ne '/^[[:space:]]*$/d; /^#/d; p' ${keep_files} 2>/dev/null)
	[ -n "$misc_files" ] &&
		find ${misc_files} -type f -o -type l >/tmp/keep_files 2> /dev/null
}

__rm_conf_files() {
	local profile=$1 filelist=$2
	local cfg_name keep_files

	for i in $(grep -sE "^/etc/config/|^/usr/local/etc/config/" "$filelist"); do
		i="${i#/usr/local}"
		cfg_name=$(basename "$i")

		rm -f "${TMP_PATH}etc/config/${cfg_name}"
		sed -i "/$cfg_name/d" "/etc/profiles/${profile}.md5"
	done

	keep_files=$(grep -sE "^/lib/upgrade/keep.d/|^/usr/local/lib/upgrade/keep.d/" "$filelist")
	[ -z "$keep_files" ] && return

	for i in $(sed -ne '/^[[:space:]]*$/d; /^#/d; p' ${keep_files} 2>/dev/null); do
		rm -rf "${TMP_PATH:?}${i:1}"
	done
}

__update_tar() {
	local cb=$1
	local filelist=$2
	local profile name

	for profile in /etc/profiles/*.tar.gz; do
		mkdir -p "$TMP_PATH"
		tar xzf "$profile" -C "$TMP_PATH"
		name=$(basename "$profile" .tar.gz)
		$cb "$name" "$filelist"
		[ -e "/tmp/keep_files" ] && keep=" -T /tmp/keep_files"

		tar cz${keep} -f "$profile" -C "$TMP_PATH" "."
		rm -rf "$TMP_PATH" /tmp/keep_files
	done
}

fix_configs() {
	__update_tar __fix_conf_files "$1"
}

install_pkg() {
	__update_tar __add_conf_files "$1"
}

remove_pkg() {
	__update_tar __rm_conf_files "$1"
}

do_save_conffiles() {
	local conf_tar=$1

	[ -z "$conf_tar" ] && return 1
	[ -z "$(rootfs_type)" ] && {
		log "Cannot save config while running from ramdisk."
		ask_bool 0 "Abort" && exit
		return 1
	}

	add_uci_conffiles "$CONFFILES"
	# Do not save these configs
	remove_exceptions "$CONFFILES"
	echo -en "\n" >>"$CONFFILES"
	add_extras
	cp /etc/version "$PROFILE_VERSION_FILE"

	tar czf "$conf_tar" -T "$CONFFILES" 2>/dev/null
	rm -f "$CONFFILES" "$PROFILE_VERSION_FILE"
	return 0
}

create_md5() {
	local md5_file=$1
	[ -z "$md5_file" ] && return 1
	md5sum /etc/config/* /etc/shadow | grep -vE "profiles|rms_connect_timer" >"$md5_file"
}

is_legacy_profile() {
	#There is no correct way to indicate legacy profile, so we searching for dinosaurs here
	[ -e "/etc/config/coovachilli" ] && [ -e "/etc/config/sms_gateway" ] &&
		[ -e "/etc/config/data_limit" ]
}

__check_compatibility() {
	local old_major="$1"
	local old_minor="$2"
	local dir="$3"
	local version="${dir##*/}"
	local uci_major="${version%%.*}"
	local uci_minor="${version#*.}"

	# ignore non-numeric directory names
	case "$uci_minor" in
		''|*[!0-9]*) uci_minor="" ;;
		*) ;;
	esac

	[ "$version" = "$uci_minor" ] && uci_minor=""

	[ -n "$uci_major" ] && [ -n "$uci_minor" ] || return 0
	[ "$uci_major" -lt "$old_major" ] && return 1
	[ "$uci_major" -eq "$old_major" ] && [ "$uci_minor" -lt "$old_minor" ] && return 1

	return 0
}

__apply_defaults() {
	local dir="$1"

	for file in $(ls -v "$dir"); do
		[ -d "${dir}/${file}" ] && continue
		( . "${dir}/${file}" 2>/dev/null ) && rm -f "${dir}/${file}"
	done
}

uci_apply_defaults() {
	local top_dir="/tmp/uci-defaults"
	mkdir -p "$top_dir"
	cp -r /rom/etc/uci-defaults/* "$top_dir/"
	chmod -R +x "$top_dir/"
	[ -z "$(ls -A "$top_dir/")" ] && return 0

	local old_version="$(cat "${TMP_PATH}${PROFILE_VERSION_FILE}")"
	local new_version="$(cat /etc/version)"

	[ -z "$old_version" ] && old_version="$new_version"

	local old_major=$(echo "$old_version" | awk -F . '{ print $2 }')
	local old_minor=$(echo "$old_version" | awk -F . '{ print $3 }')

	rm -rf ${top_dir}/linux

	# do not execute legacy scripts when coming from 7.x
	[ "$old_major" -ge 7 ] && rm -rf ${top_dir}/001_rut*

	# do not execute old scripts when coming from 8.x
	[ "$old_major" -gt 7 ] && rm -rf ${top_dir}/old

	# do not execute old scripts when coming from 7.4.x
	[ "$old_major" -eq 7 ] && [ "$old_minor" -ge 4 ] && rm -rf ${top_dir}/old

	#for legacy rut9/rut2 migration
	is_legacy_profile && {
		touch /etc/config/teltonika
		cp /rom/etc/migrate.conf/* /etc/migrate.conf/
	}

	for dir in $(ls -v $top_dir); do
		[ -d "${top_dir}/$dir" ] || continue
		__check_compatibility "$old_major" "$old_minor" "$dir" || continue
		__apply_defaults "${top_dir}/$dir"
	done
	__apply_defaults "$top_dir"

	rm -rf "$top_dir/"
	rm -f /etc/migrate.conf/*
}

call_config_event() {
	/bin/ubus call service event "{ \"type\": \"config.change\", \"data\": { \"package\": \"$1\" }}"
}

apply_config() {
	local md5file="${1:-/var/run/config.md5}"

	[ -f "$md5file" ] && {
		local network=0

		for c in $(diff "$md5file"); do
			[ "$c" = "network" ] && {
				network=1
				continue
			}
			call_config_event "$c"
		done

		/bin/ubus -t 180 call mobifd reload >/dev/null
		[ "$network" -eq 1 ] && call_config_event "network"
	}

	find /etc/config -type f ! -name 'profiles' -exec md5sum {} + >"$md5file"
	return 0
}

change_config() {
	local md5file="/var/run/config.md5"
	local new="$1"

	uci_get "profiles" "$new" || {
		log "Profile '$new' not found"
		return 1
	}

	local archive="${MAIN_PATH}$(uci_get profiles $name archive)"
	[ -f "$archive" ] || {
		log "Unable to retrieve profile '$new' archive name"
		return 1
	}

	[ ! -r "$archive" ] && {
		log "Unable to read '$archive'"
		return 1
	}

	rm -f "$md5file"
	apply_config "$md5file"

	# rpcd scripts set a umask of 077 while script expects 022
	umask 022

	mkdir -p "$TMP_PATH"
	tar xzf "$archive" -C "$TMP_PATH" 2>&- || {
		log "Unable to extract '$archive'"
		return 1
	}

	cmp -s "${TMP_PATH}${PROFILE_VERSION_FILE}" /etc/version || {
		# Legacy profiles do not have some config files so we need to reset
		# these files before applying profile
		for file in $KNOWN_CLEANS; do
			cp "/rom$file" "$file"
		done
	}

	# Fixing legacy profiles
	remove_exceptions_from_file "$TMP_PATH"

	# the /etc/config folder itself is not added into the archive
	# so we need to restore the permissions to what we expect
	chown 100:users "$TMP_DIR"/etc/config/
	chmod 777 "$TMP_DIR"/etc/config/

	cp -af "$TMP_PATH"/* /

	rm -rf "$TMP_PATH"
	uci_set "profiles" "general" "profile" "$new" || {
		log "Unable to set new profile via uci"
		return 1
	}

	uci_commit "profiles" || {
		log "Unable to commit new profile changes via uci"
		return 1
	}

	uci_apply_defaults
	apply_config "$md5file"
	/bin/ubus send vuci.notify '{"event":"profile_changed"}'
	return 0
}

diff() {
	local md5file="$1"

	[ -z "$md5file" ] && return 1

	for c in $(md5sum -c "$md5file" 2>/dev/null | sed -nE -e 's/(.*):\s+FAILED/\1/p'); do
		echo "${c##*/}" # for known input (in this case regular fullpath filenames) it's equivalent to basename, but faster
	done

	return 0
}

rm_conffiles() {
	add_uci_conffiles "$RM_CONFFILES"
	# Do not save these configs
	remove_exceptions "$RM_CONFFILES"

	# shellcheck disable=2046 # Splitting is intended here
	rm $(cat $RM_CONFFILES)
}

handle_profile_list() {
	local config="$1"

	config_get updated "$config" updated

	[ $LIST_COUNT -gt 0 ] && {
		echo ","
	}

	echo "{"
	echo "\"name\": \"$config\","
	echo "\"updated\": $updated,"

	if [ "$config" = "$CURRENT_PROFILE" ]; then
		echo "\"active\": 1"
	else
		echo "\"active\": 0"
	fi
	echo "}"

	LIST_COUNT=$((LIST_COUNT + 1))
}

check_profile_exists() {
	local config="$1"
	local new_name="$2"

	[ "$config" = "$new_name" ] && {
		echo "{\"status\": 1, \"error\": \"profile '$new_name' already exists\"}"
		exit 1
	}

	local id
	config_get id "$config" id 0

	local next_id=$((id + 1))
	[ $next_id -gt $NEXT_PROFILE_ID ] && NEXT_PROFILE_ID=$next_id
}

check_name() {
	local name="$1"
	local length=$(echo -n "$name" | wc -m)

	[ $length -lt 1 ] && {
		echo '{"status": 22, "error": "no argument provided"}'
		exit 1
	}

	# check name len
	# limit set to be the same as-is in the webUI.
	[ $length -gt 20 ] && {
		echo '{"status": 22, "error": "given profile name too long (limit: 20 characters)"}'
		exit 1
	}

	# Sanitize input
	local sanitized=$(echo $name | sed 's/ /_/g; s/[^a-zA-Z0-9_]//g')

	# Breaks if name is invalid.
	# better to inform the user of their mistake, rather
	# than contiuing on after making changes to user input,
	# since this ubus object will likely only be called from
	# other scripts/programs
	[ "$sanitized" != "$name" ] && {
		echo '{"status": 22, "error": "invalid profile name"}'
		exit 1
	}
}

# Checks if a name matches the reserved names in /etc/profiles
check_default() {
	local name="$1"

	# Check if names won't interfere with the default profile files in /etc/profiles
	[ "$name" = "default" ] || [ "$name" = "template" ] && {
		echo '{"status": 22, "error": "profile name cannot be '\''template'\'' or '\''default'\''"}'
		exit 1
	}
}

call_handle_create() {
	local name="$1"
	local options="$2"

	# Skip validation if option -s is passed
	[ "$options" = "-s" ] || {
		check_name "$name"
		check_default "$name"
	}

	config_load profiles

	NEXT_PROFILE_ID=0
	config_foreach check_profile_exists profile "$name"

	local now="$(date +%s)"
	local archive="${name}_${now}.tar.gz"
	local md5file="${name}_${now}.md5"

	[ "$name" = "default" ] || [ "$name" = "template" ] && {
		archive="${name}.tar.gz"
		md5file="${name}.md5"
	}

	[ "$name" = "default" ] && NEXT_PROFILE_ID=0

	# Create new config in uci
	uci_add profiles profile "$name"
	uci_set profiles "$name" id "$NEXT_PROFILE_ID"
	uci_set profiles "$name" updated "$now"
	uci_set profiles "$name" archive "$archive"
	uci_set profiles "$name" md5file "$md5file"

	uci_commit profiles

	# Create profile from template if option -t is passed
	[ "$options" = "-t" ] && {
		local template_archive="${MAIN_PATH}template.tar.gz"
		local template_md5file="${MAIN_PATH}template.md5"

		[ -f "$template_archive" ] || {
			echo '{"status": 3, "error": "template not found"}'
			exit 1
		}

		cp -af "$template_archive" "${MAIN_PATH}${archive}"
		cp -af "$template_md5file" "${MAIN_PATH}${md5file}"

		echo '{ "status": 0, "id": '"$NEXT_PROFILE_ID"', "updated": '"$now"', "archive": "'"$archive"'", "md5file": "'"$md5file"'" }'
		exit 0
	}

	do_save_conffiles "${MAIN_PATH}${archive}"
	create_md5 "${MAIN_PATH}${md5file}"

	uci commit

	echo '{ "status": 0, "id": '"$NEXT_PROFILE_ID"', "updated": '"$now"', "archive": "'"$archive"'", "md5file": "'"$md5file"'" }'
}

call_handle_update() {
	local options="$1"

	local prof_archive="${MAIN_PATH}/$(uci_get profiles "$CURRENT_PROFILE" archive)"
	local prof_md5="${MAIN_PATH}/$(uci_get profiles "$CURRENT_PROFILE" md5file)"

	[ -f "$prof_archive" ] || {
		echo '{ "status": 3, "error": "error updating current profile"}'
		exit 1
	}

	rm -f "$prof_archive"
	[ -f "$prof_md5" ] && rm -f "$prof_md5"

	local now="$(date +%s)"

	config_load profiles
	uci_set profiles "$CURRENT_PROFILE" updated "$now"
	uci_commit profiles

	do_save_conffiles "$prof_archive"
	create_md5 "$prof_md5"

	[ -f "$prof_archive" ] || {
		echo '{ "status": 3, "error": "error updating current profile"}'
		exit 1
	}

	[ "$options" = "-q" ] || echo '{ "status": 0 }'
}

call_handle_change() {
	local name="$1"
	local options="$2"

	check_name "$name"

	local scheduler="$(uci_get profiles general enabled "0")"
	[ "$options" != "-f" ] && [ "$scheduler" = "1" ] && {
		echo '{ "status": 1, "error": "can not change profile, scheduler is enabled"}'
		exit 1
	}

	call_handle_update -q

	local archive="$(uci_get profiles $name archive)"
	if [ -n "$archive" ]; then
		change_config "$name" &>/dev/null || {
			echo '{ "status": 4, "error": "error changing profile"}'
			exit 1
		}
		echo '{ "status": 0 }'
	else
		echo '{ "status": 2, "error": "profile not found"}'
		exit 1
	fi
}

call_handle_remove() {
	local name="$1"

	config_load profiles

	check_name "$name"
	check_default "$name"

	local archive_path="${MAIN_PATH}$(uci_get profiles $name archive \".\")"
	local md5file_path="${MAIN_PATH}$(uci_get profiles $name md5file \".\")"

	local err_chk=0
	[ -f "$archive_path" ] && rm -f "$archive_path" || err_chk=1
	[ -f "$md5file_path" ] && rm -f "$md5file_path" || err_chk=1

	[ $err_chk -eq 1 ] && {
		echo '{"status": 5, "error": "encountered errors while removing profile"}'
		exit 1
	}

	uci_remove profiles "$name"

	# profile currently in use is being removed,
	# reset to default.
	[ "$name" = "$CURRENT_PROFILE" ] && {
		change_config "default" &>/dev/null
	}

	uci_commit profiles
	uci commit

	echo '{ "status": 0 }'
}

call_handle_list() {
	LIST_COUNT=0

	echo '{ "profiles": ['
	config_load profiles
	config_foreach handle_profile_list profile
	echo ']}'
}

call_handle_diff() {
	local name="$1"

	check_name "$name"

	local md5file_path="${MAIN_PATH}$(uci_get profiles $name md5file \".\")"
	[ -f "$md5file_path" ] || {
		echo '{"status": 2, "error": "could not find profile"}'
		exit 1
	}

	echo '{ "status": 0, "diff": ['
	diff "${MAIN_PATH}${name}"*.md5 | sed 's/^/\"/; s/$/\",/'
	echo ']}'
}

[ -z "$1" ] && exit

case "$1" in
-b)
	call_handle_create "$2" "$3"
	;;
-c)
	call_handle_change "$2" "$3"
	;;
-u)
	call_handle_update
	;;
-d)
	call_handle_diff "$2"
	;;
-r)
	call_handle_remove "$2"
	;;
-l)
	call_handle_list
	;;
-f)
	fix_configs
	;;
# Used in "/lib/functions.sh"
-i)
	install_pkg "$2"
	;;
-p)
	remove_pkg "$2"
	;;
*)
	log "unrecognised option '$1'"
	exit 1
	;;
esac

exit $?
