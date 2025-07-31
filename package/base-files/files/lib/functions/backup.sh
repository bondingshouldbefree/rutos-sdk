. /lib/functions.sh
. /usr/share/libubox/jshn.sh

export CONFFILES=/tmp/sysupgrade.conffiles
export ETCBACKUP_DIR=/etc/backup
export INSTALLED_PACKAGES=${ETCBACKUP_DIR}/installed_packages.txt

export UMOUNT_ETCBACKUP_DIR=0

list_conffiles() {
	awk '
		BEGIN { conffiles = 0 }
		/^Conffiles:/ { conffiles = 1; next }
		!/^ / { conffiles = 0; next }
		conffiles == 1 {
			sub(/^ \/usr\/local\/etc\//, " /etc/");
			print
		}
	' /usr/lib/opkg/status /usr/local/usr/lib/opkg/status 2> /dev/null
}

list_changed_conffiles() {
	# Cannot handle spaces in filenames - but opkg cannot either...
	list_conffiles | while read file csum; do
		[ -r "$file" ] || continue

		echo "${csum}  ${file}" | busybox sha256sum -sc - || echo "$file"
	done
}

list_static_conffiles() {
	local filter=$1

	find $(sed -ne '/^[[:space:]]*$/d; /^#/d; p' \
		/etc/sysupgrade.conf /lib/upgrade/keep.d/* /usr/local/lib/upgrade/keep.d/* 2>/dev/null) \
		\( -type f -o -type l \) $filter 2>/dev/null
}

add_conffiles() {
	local file="$1"

	( list_static_conffiles "$find_filter"; list_changed_conffiles ) |
		sort -u > "$file"
	return 0
}

add_overlayfiles() {
	local file="$1"

	local packagesfiles=$1.packagesfiles
	touch "$packagesfiles"

	if [ "$SAVE_OVERLAY_PATH" = / ]; then
		local conffiles=$1.conffiles
		local keepfiles=$1.keepfiles

		list_conffiles | cut -f2 -d ' ' | sort -u > "$conffiles"

		# backup files from /etc/sysupgrade.conf and /lib/upgrade/keep.d, but
		# ignore those aready controlled by opkg conffiles
		list_static_conffiles | sort -u |
			grep -h -v -x -F -f $conffiles > "$keepfiles"

		# backup conffiles, but only those changed if '-u'
		[ $SKIP_UNCHANGED = 1 ] &&
			list_changed_conffiles | sort -u > "$conffiles"

		# do not backup files from packages, except those listed
		# in conffiles and keep.d
		{
			find /usr/lib/opkg/info /usr/local/usr/lib/opkg/info -type f -name "*.list" -exec cat {} \; 2> /dev/null
			find /usr/lib/opkg/info /usr/local/usr/lib/opkg/info -type f -name "*.control" -exec sed \
				-ne '/^Alternatives/{s/^Alternatives: //;s/, /\n/g;p}' {} \; 2> /dev/null |
				cut -f2 -d:
		} | sed 's|^/usr/local/etc/|/etc/|' | grep -v -x -F -f $conffiles |
		     grep -v -x -F -f $keepfiles | sort -u > "$packagesfiles"
		rm -f "$keepfiles" "$conffiles"
	fi

	# busybox grep bug when file is empty
	[ -s "$packagesfiles" ] || echo > $packagesfiles

	( cd /overlay/upper/; find .$SAVE_OVERLAY_PATH \( -type f -o -type l \) $find_filter | sed \
		-e 's,^\.,,' \
		-e '\,^/etc/board.json$,d' \
		-e '\,/[^/]*-opkg$,d' \
		-e '\,^/etc/urandom.seed$,d' \
		-e "\,^$INSTALLED_PACKAGES$,d" \
		-e '\,^/usr/lib/opkg/.*,d' \
	) | grep -v -x -F -f $packagesfiles > "$file"

	rm -f "$packagesfiles"

	return 0
}

if [ $SAVE_OVERLAY = 1 ]; then
	[ ! -d /overlay/upper/etc ] && {
		echo "Cannot find '/overlay/upper/etc', required for '-c'" >&2
		exit 1
	}
	sysupgrade_init_conffiles="add_overlayfiles"
else
	sysupgrade_init_conffiles="add_conffiles"
fi

find_filter=""
if [ $SKIP_UNCHANGED = 1 ]; then
	[ ! -d /rom/ ] && {
		echo "'/rom/' is required by '-u'"
		exit 1
	}
	find_filter='( ( -exec test -e /rom/{} ; -exec cmp -s /{} /rom/{} ; ) -o -print )'
fi

include /lib/upgrade

do_save_conffiles() {
	local conf_tar="$1"

	[ "$(rootfs_type)" = "tmpfs" ] && {
		echo "Cannot save config while running from ramdisk." >&2
		rm -f "$conf_tar"
		exit
	}
	run_hooks "$CONFFILES" $sysupgrade_init_conffiles

	third_party_pkg=$(uci_get package_restore package_restore 3rd_party_pkg)

	# Request mdcolect to save the most recent version of its database.
	# Try for at most 5 times, because call fails if there are other SQL queries being executed
	ubus list mdcollect >/dev/null 2>/dev/null && {
		for i in $(seq 1 5); do
			ubus call mdcollect backup_db && break
		done
	}

	# Save user modified apn list
	[ -e /usr/bin/backup_apn_db ] && lua /usr/bin/backup_apn_db -b

	{
		[ -z "$CONF_BACKUP" ] && [ -d "/etc/api" ] && echo "/etc/api"
		[ -z "$CONF_BACKUP" ] && [ -e "/etc/ssl/certs/tlt-pairing.crt" ] && echo "/etc/ssl/certs/tlt-pairing.crt"
		[ -z "$CONF_BACKUP" ] && [ -e "/etc/umdns/tlt_pair.json" ] && echo "/etc/umdns/tlt_pair.json"
		[ -e /usr/share/mobifd/apn_backup.json ] && echo "/usr/share/mobifd/apn_backup.json" # APN db user backuped values
		[ -d /etc/profiles ] && echo "/etc/profiles"
		[ -d /etc/certificates ] && echo "/etc/certificates"

		cmp -s /etc/ssl/certs/ca-certificates.crt /rom/etc/ssl/certs/ca-certificates.crt ||
				echo "/etc/ssl/certs/ca-certificates.crt"

		[ -e /etc/privoxy/user_action_luci ] && echo "/etc/privoxy/user_action_luci"
		[ -d /etc/openvpn ] && {
			find "/etc/openvpn/" -name "auth_*"							# OpenVPN username and password files
			find "/etc/openvpn/" -name "askpass_*"						# OpenVPN PKCS password files
			find "/etc/openvpn/" -name "*.ovpn" | grep -v "template"	# OpenVPN configurations created from templates, excluding templates themselves
		}
		[ -d /etc/tailscale ] && find "/etc/tailscale/" -name "tailscaled.state"
		[ -d /etc/hostapd ] && find "/etc/hostapd/" -name "*.psk"		# hostapd psk files
		[ -e /etc/lpac_config.json ] && echo "/etc/lpac_config.json"            # lpac library config file
		[ -d /etc/aws ] && find /etc/aws -type f # AWS Thing certificates generated by the program
	} >>"$CONFFILES"

	opkg_packets=$(grep -sl "Router:" /usr/local/usr/lib/opkg/info/*.control)
	[ -f /etc/package_restore.txt ] && cp /etc/package_restore.txt /etc/package_restore.tmp

	for i in $opkg_packets; do
		tlt_name=$(grep "tlt_name:" "$i" | awk -F ": " '{print $2}')
		pkg_name=$(grep "AppName:" "$i" | awk -F ": " '{print $2}')
		[ -z "$pkg_name" ] && pkg_name=$(grep "Package:" "$i" | awk -F ": " '{print $2}')
		echo "$pkg_name - $tlt_name" >> /etc/package_restore.txt
	done

	[ -f /etc/package_restore.txt ] && {
		sorted="$(sort -u /etc/package_restore.txt)"
		echo "$sorted" > /etc/package_restore.txt
	}

	[ "$third_party_pkg" = "1" ] && {
		opkg_packets=$(find /overlay/upper/usr/lib/opkg/info/ -type f -name \
			       '*.control' -exec basename {} .control ';')
		[ -n "$opkg_packets" ] && echo "$opkg_packets" >> /etc/package_restore.txt
	}

	[ -f /etc/package_restore.txt ] && {
		echo "/etc/package_restore.txt" >> "$CONFFILES"
	}

	if [ "$SAVE_INSTALLED_PKGS" -eq 1 ]; then
		echo "${INSTALLED_PACKAGES}" >> "$CONFFILES"
		mkdir -p "$ETCBACKUP_DIR"
		# Avoid touching filesystem on each backup
		RAMFS="$(mktemp -d -t sysupgrade.XXXXXX)"
		mkdir -p "$RAMFS/upper" "$RAMFS/work"
		mount -t overlay overlay -o lowerdir=$ETCBACKUP_DIR,upperdir=$RAMFS/upper,workdir=$RAMFS/work $ETCBACKUP_DIR &&
			UMOUNT_ETCBACKUP_DIR=1 || {
				echo "Cannot mount '$ETCBACKUP_DIR' as tmpfs to avoid touching disk while saving the list of installed packages." >&2
				exit
			}

		# Format: pkg-name<TAB>{rom,overlay,unkown}
		# rom is used for pkgs in /rom, even if updated later
		find /usr/lib/opkg/info -name "*.control" \( \
			\( -exec test -f /rom/{} \; -exec echo {} rom \; \) -o \
			\( -exec test -f /overlay/upper/{} \; -exec echo {} overlay \; \) -o \
			\( -exec echo {} unknown \; \) \
			\) | sed -e 's,.*/,,;s/\.control /\t/' > ${INSTALLED_PACKAGES}
	fi

	v "Saving config files..."
	[ "$VERBOSE" -gt 1 ] && TAR_V="v" || TAR_V=""

	if [ -z "$CONF_PASSWORD" ]; then
		tar c${TAR_V}zf "$conf_tar" -T "$CONFFILES" 2>/dev/null
	else
		which minizip >/dev/null || {
			echo "Could not create $conf_tar - minizip package is not installed";
			exit 1
		}
		local conf_tar_trimmed=$(echo "$conf_tar" | sed 's/\.zip$//')
		tar -cf "$conf_tar_trimmed" -T "$CONFFILES" 2>/dev/null
		minizip -s -p "$CONF_PASSWORD" "$conf_tar" "$conf_tar_trimmed" >/dev/null 2>&1
		rm "$conf_tar_trimmed"
	fi

	if [ "$?" -ne 0 ]; then
		echo "Failed to create the configuration backup."
		rm -f "$conf_tar"
		exit 1
	fi

	[ "$UMOUNT_ETCBACKUP_DIR" -eq 1 ] && {
		umount "$ETCBACKUP_DIR"
		rm -rf "$RAMFS"
	}

	if [ -f /etc/package_restore.tmp ]; then
		mv /etc/package_restore.tmp /etc/package_restore.txt
	else
	    rm -rf /etc/package_restore.txt
	fi

	rm -f "$CONFFILES"
}

if [ $CONF_BACKUP_LIST -eq 1 ]; then
	run_hooks "$CONFFILES" $sysupgrade_init_conffiles
	[ "$SAVE_INSTALLED_PKGS" -eq 1 ] && echo ${INSTALLED_PACKAGES} >> "$CONFFILES"
	cat "$CONFFILES"
	rm -f "$CONFFILES"
	exit 0
fi

remove_section() {
	local section="$1"
	local config="$2"
	local option="$3"
	local value

	config_get value "$section" "$option" ""
	[ -n "$value" ] && uci_remove "$config" "$section"
}

remove_prepare() {
	local config="$1"
	CONFIG_PATH="${UCI_CONFIG_DIR:-"/etc/config"}"
	TMP_CONFIG_PATH="/tmp/original_config"

	mkdir -p "$TMP_CONFIG_PATH"
	cp -af "${CONFIG_PATH}/${config}" "${TMP_CONFIG_PATH}/"
	config_load "$config"
}

remove_section_containing_option() {
	local config="$1"
	local section="$2"
	local option="$3"

	remove_prepare "$config"
	config_foreach remove_section "$section" "$config" "$option"
	uci_commit "$config"
}

remove_option() {
	local config="$1"
	local section="$2"
	local option="$3"
	local value

	remove_prepare "$config"
	config_get value "$section" "$option" ""
	[ -n "$value" ] && {
		uci_remove "$config" "$section" "$option"
		uci_commit "$config"
	}
}

restore_configs() {
	for config in "$@"; do
		mv -f "${TMP_CONFIG_PATH}/${config}" "${CONFIG_PATH}/"
	done
}

missing_lines() {
	local file1 file2 out user data
	file1="$1"
	file2="$2"
	out="$3"

	cp "$file1" "$out"

	while IFS=":" read user data; do
		grep -q "^$user:" "$file1" || echo "$user:$data" >> "$out"
	done <"$file2"
}

restore_sme_fstab() {
	local rwm_device
	local rwm_target
	local overlay_uuid
	local overlay_target
	local overlay_sme
	local log_enabled
	local log_device

	local rwm=$(uci -q get fstab.rwm)
	local overlay=$(uci -q get fstab.overlay)
	local log=$(uci -q get fstab.log)

	if [ -n "$rwm" ] && [ -n "$overlay" ] && [ -n "$log" ]; then
		config_load fstab
		config_get rwm_device rwm device
		config_get rwm_target rwm target
		config_get overlay_uuid overlay uuid
		config_get overlay_target overlay target
		config_get overlay_sme overlay sme
		config_get log_enabled log enabled
		config_get log_device log device
		uci -c "/tmp/new_config_dir/etc/config" batch <<-EOF
			set fstab.rwm=$rwm
			set fstab.rwm.device=$rwm_device
			set fstab.rwm.target=$rwm_target
			set fstab.overlay=$overlay
			set fstab.overlay.uuid=$overlay_uuid
			set fstab.overlay.target=$overlay_target
			set fstab.overlay.sme=$overlay_sme
			set fstab.log=$log
			set fstab.log.enabled=$log_enabled
			set fstab.log.device=$log_device
			commit fstab
		EOF
	fi
}

restore_rms_auth_code() {
	local config="rms_mqtt"

	[ -s "/etc/config/$config" ] || return
	[ -s "/tmp/new_config_dir/etc/config/$config" ] || return

	local auth_code="$(uci -q get $config.rms_connect_mqtt.auth_code)"
	uci -c "/tmp/new_config_dir/etc/config" batch <<-EOF
		set $config.rms_connect_mqtt.auth_code="$auth_code"
		commit $config
	EOF
}

restore_rms_ids() {
	local opts="rms_id demo_rms_id local_rms_id"
	for opt_name in $opts; do
		local opt_val_file=$(cat "/log/$opt_name" 2>/dev/null)

		[ -n "$opt_val_file" ] && {
			uci -q -c "/tmp/new_config_dir/etc/config" set "rms_mqtt.rms_mqtt.$opt_name=$opt_val_file"
		} || {
			uci -q -c "/tmp/new_config_dir/etc/config" delete "rms_mqtt.rms_mqtt.$opt_name"
		}
	done
	uci -c "/tmp/new_config_dir/etc/config" commit rms_mqtt
}

merge_file() {
	file1="$1"
	file2="$2"
	output_file="$3"

	merge_col4() {
		echo "$1,$2" | tr ',' '\n' | sort -u | tr '\n' ',' | sed 's/^,//;s/,$//'
	}

	while IFS=: read -r col1 col2 col3 col4; do
		file1_data="$file1_data\n$col1:$col2:$col3:$col4"
	done <"$file1"

	while IFS=: read -r col1 col2 col3 col4; do
		file2_data="$file2_data\n$col1:$col2:$col3:$col4"
	done <"$file2"

	for line1 in $(echo -e "$file1_data"); do
		col1=$(echo "$line1" | cut -d: -f1)
		col2=$(echo "$line1" | cut -d: -f2)
		col3=$(echo "$line1" | cut -d: -f3)
		col4=$(echo "$line1" | cut -d: -f4)

		line2=$(echo -e "$file2_data" | grep "^$col1:")
		[ -z "$line2" ] && {
			echo "$line1" >>"$output_file"
			continue
		}
		col4_2=$(echo "$line2" | cut -d: -f4)
		merged_col4=$(merge_col4 "$col4" "$col4_2")
		echo "$col1:$col2:$col3:$merged_col4" >>"$output_file"
		file2_data=$(echo -e "$file2_data" | grep -v "^$col1:")
	done

	for line2 in $(echo -e "$file2_data"); do
		grep -q "$line2" "$output_file" && continue
		echo "$line2" >>"$output_file"
	done

	sed -i '/^:::/d' "$output_file"
}

apply_backup() {
	restore_rms_ids
	restore_sme_fstab
	restore_rms_auth_code
	/etc/init.d/mdcollectd stop
	/etc/init.d/simcard reload >/dev/null 2>/dev/null
	rm -f /tmp/new_config_dir/etc/config/hwinfo /tmp/new_config_dir/etc/inittab 2>/dev/null
	cp -af /tmp/new_config_dir/etc/ / 2>/dev/null
	cp -af /tmp/new_config_dir/usr/ / 2>/dev/null
	cp -a /rom/etc/uci-defaults/* /etc/uci-defaults/ 2>/dev/null
	rm -rf /tmp/new_config_dir
	rm -f /etc/last_version
	cp /rom/etc/shadow /rom/etc/passwd /rom/etc/group /tmp/
	missing_lines /tmp/passwd /etc/passwd /tmp/passwd_merged
	merge_file /tmp/group /etc/group /tmp/group_merged
	missing_lines /etc/shadow /tmp/shadow /tmp/shadow_merged
	cp /tmp/passwd_merged /etc/passwd
	cp /tmp/group_merged /etc/group
	cp /tmp/shadow_merged /etc/shadow
	rm /tmp/passwd /tmp/shadow /tmp/group /tmp/*_merged
	sync_permissions_and_ownerships
	fix_permissions 660 "/etc/config/network" "network:network"
	fix_permissions 660 "/etc/config/wireless" "network:network"
}

backup_size_validation() {
	local file="$1"
	local password="$2"
	local free_fmem=$(df -k | grep /overlay | awk '{print $4; exit}')

	# Add aditional 40 KB for reserve
	local file_size
	if [ "${file##*.}" = "zip" ]; then
		file_size=$(minizip -l -p "$password" "$file" | tail -1 | awk '{print ($2 / 1024) + 40}')
	elif [ "${file##*.}" = "7z" ]; then
		file_size=$(7zr l "$file" -p"$password" | tail -1 | awk '{print ($3 / 1024) + 40}')
	else
		file_size=$(gzip -dc < "$file" | wc -c | awk '{print ($1 / 1024) + 40 }')
	fi

	local validation=$(echo "$file_size $free_fmem" | awk '{if ($1 < $2) print 0; else print 1}')
	[ "$validation" -eq 0 ] || return 1

	return 0
}

if [ -n "$CONF_BACKUP" ]; then
	ubus call system update_profile &>/dev/null
	remove_section_containing_option "network" "device" "macaddr"
	remove_option "rms_mqtt" "rms_connect_mqtt" "auth_code"
	do_save_conffiles "$CONF_BACKUP"
	save_conffile_code=$?
	restore_configs "network" "rms_mqtt"
	[ "$save_conffile_code" -eq 0 ] && {
		ubus call log write_ext "{
			\"event\": \"Backup \\\"$(basename "$CONF_BACKUP")\\\" generated from current configuration\",
			\"sender\": \"Backup\",
			\"table\": 1,
			\"write_db\": 1,
		}"
	}
	exit $save_conffile_code
fi

if [ -n "$CONF_RESTORE" ]; then
	if [ "$CONF_RESTORE" != "-" ] && [ ! -f "$CONF_RESTORE" ]; then
		echo "Backup archive '$CONF_RESTORE' not found." >&2
		exit 1
	fi

	if [ "${CONF_RESTORE##*.}" = "zip" ]; then
		which minizip >/dev/null || {
			echo "Can not decrypt backup archive '$CONF_RESTORE' - minizip package is not installed" >&2
			exit 1
		}
	elif [ "${CONF_RESTORE##*.}" = "7z" ]; then
		which 7zr >/dev/null || {
			echo "Can not decrypt backup archive '$CONF_RESTORE' - 7zip package is not installed" >&2
			exit 1
		}
	elif [ -n "$CONF_PASSWORD" ]; then
		echo "Invalid backup format" >&2
		exit 1
	fi

	backup_size_validation "$CONF_RESTORE" "$CONF_PASSWORD" || exit 1

	[ "$VERBOSE" -gt 1 ] && TAR_V="v" || TAR_V=""

	mkdir -p /tmp/new_config_dir
	if [ -z "$CONF_PASSWORD" ]; then
		echo 'etc/rc.d/*' > /tmp/exclusions
		echo 'etc/profile' >> /tmp/exclusions
		tar -C /tmp/new_config_dir -x${TAR_V}zf "$CONF_RESTORE" -X '/tmp/exclusions'
		rm /tmp/exclusions
	else
		conf_tar_dirname=$(dirname "$CONF_RESTORE")
		if [ "${CONF_RESTORE##*.}" = "zip" ]; then
			minizip -x -o -s -d "$conf_tar_dirname" -p "$CONF_PASSWORD" "$CONF_RESTORE"
		elif [ "${CONF_RESTORE##*.}" = "7z" ]; then
			7zr e -aoa -p"$CONF_PASSWORD" "$CONF_RESTORE" -o"$conf_tar_dirname"
		fi
		conf_tar_trimmed=$(echo "$CONF_RESTORE" | sed "s/\.${CONF_RESTORE##*.}$//")
		tar -C /tmp/new_config_dir -x${TAR_V}f "$conf_tar_trimmed"
		rm -rf /tmp/new_config_dir/etc/rc.d/*
		rm -rf /tmp/new_config_dir/etc/profile
		rm -rf "$conf_tar_trimmed"
	fi
	ret=$?
	[ "$ret" -ne 0 ] && {
		v "Error restoring backup"
		exit "$ret"
	}

	fwtool_check_backup /tmp/new_config_dir
	backup_valid=$?
	#Just validate and exit
	[ "$CONF_BACKUP_VALIDATE" -eq 1 ] && {
		rm -rf /tmp/new_config_dir
		echo "$backup_valid"
		exit $backup_valid
	}
	[ "$backup_valid" -gt 0 ] && {
		if [ $FORCE -eq 1 ]; then
			v "Backup check failed but --force given - will restore anyway!" >&2
		else
			rm -rf /tmp/new_config_dir
			v "Backup archive is not valid."
			echo "$backup_valid"

			exit $backup_valid
		fi
	}

	v "Restoring config files..."
	apply_backup

	[ "$ret" -eq 0 ] && {
		ubus call log write_ext "{
			\"event\": \"Configuration restored from \\\"$(basename "$CONF_RESTORE")\\\" backup\",
			\"sender\": \"Backup\",
			\"table\": 1,
			\"write_db\": 1,
		}"
	}

	exit "$ret"
fi

if [ -n "$CONF_SYSUPGRADE" ]; then
	do_save_conffiles "$CONF_TAR"
	exit $?
fi
