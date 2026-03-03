. /lib/functions.sh

create_mobile_iface() {

	local intf="$1"
	local modem="$2"
	local modem_number="$3"
	local sim_card="$4"

	[ -n "$sim_card" ] || sim_card=1
	logger "Adding new interface: $intf modem $modem metric $((modem_number + 1))"

	uci_add network interface "$intf"
	uci_set network $intf proto "wwan"
	uci_set network $intf modem "$modem"
	uci_set network $intf sim "$sim_card"
	uci_set network $intf metric "$((modem_number + 1))"
	uci_set network $intf pdp "1"

	uci_commit network

	ubus call network reload
	return 0
}

update_firewall_zone() {
	local zone="$1"
	local intf="$2"

	local name network

	update_firewall() {
		local cfg="$1"
		local intf="$2"
		local name network

		config_get name "$cfg" name
		config_get network "$cfg" network

		if [ "$name" = "wan" ] && ! list_contains network "$intf"; then
			append network "$intf"
			uci_set firewall "$cfg" network "$network"
			uci_commit firewall
		fi
	}

	config_load "firewall"
	config_foreach update_firewall zone $intf
}

create_multiwan_iface() {

	[ -f /etc/config/mwan3 ] || return 0

	local intf="$1"
	local metric="$2"
	local section

	uci_add mwan3 interface "$intf"
	section="$CONFIG_SECTION"
	uci_set mwan3 $section interval '3'
	uci_set mwan3 $section enabled '0'
	uci_set mwan3 $section family 'ipv4'

	uci_add mwan3 condition
	section="$CONFIG_SECTION"
	uci_set mwan3 $section interface "$intf"
	uci_set mwan3 $section track_method 'ping'
	uci add_list mwan3.$section.track_ip="1.1.1.1"
	uci add_list mwan3.$section.track_ip="8.8.8.8"
	uci_set mwan3 $section reliability '1'
	uci_set mwan3 $section count '1'
	uci_set mwan3 $section timeout '2'
	uci_set mwan3 $section down '3'
	uci_set mwan3 $section up '3'

	uci_add mwan3 member "${intf}_member_mwan"
	section="$CONFIG_SECTION"
	uci_set mwan3 $section interface "$intf"
	uci_set mwan3 $section metric "$metric"

	uci_add mwan3 member "${intf}_member_balance"
	section="$CONFIG_SECTION"
	uci_set mwan3 $section interface "$intf"
	uci_set mwan3 $section weight "1"

	uci add_list mwan3.mwan_default.use_member="${intf}_member_mwan"
	uci add_list mwan3.balance_default.use_member="${intf}_member_balance"
	uci_commit mwan3
}

MODEM_FOUND="0"
check_modem_id() {

	local cfg="$1"
	local current_modem_id="$2"
	local new_position="$3"
	local option="$4"
	local position

	config_get modem "$cfg" "$option" ""

	if [ "$modem" == "$current_modem_id" ]; then

		[ "$option" = "info_modem_id" ] && MODEM_FOUND="1" && return

		if [ "$new_position" = "" ]; then
			MODEM_FOUND="1"
			return
		fi

		config_get position "$cfg" position ""
		if [ "$new_position" = "$position" ]; then
			MODEM_FOUND="1"
		fi
	fi

}

get_mnf_sim_pin() {
	local modem_num mnf_cfg mnf_modem num
	local sim_pos=0
	local modem="$1"
	local position="$2"

	modem_num="$(jsonfilter -i "/etc/board.json" -e "@.modems[@.id=\"$modem\"].num" 2>/dev/null)"
	[ -z "$modem_num" ] && return

	for num in $(seq 1 4); do
		mnf_cfg="$(/sbin/mnf_info -C "$num" 2>/dev/null)"
		[ -z "$mnf_cfg" ] && break

		mnf_modem=${mnf_cfg:1:1}
		[ $mnf_modem -eq 0 ] && continue # Skip empty

		[ $mnf_modem -eq $modem_num ] && sim_pos=$((sim_pos + 1)) && [ $sim_pos -eq $position ] && {
			/sbin/mnf_info -S "$num" 2>/dev/null
			return
		}
	done
}

add_simcard_config() {
	local pin
	local device="$1"
	local position="$2"
	local primary="$3"
	local builtin="$4"
	local volte="$5"

	if [ -s /etc/config/simcard ]; then
		MODEM_FOUND="0"
		config_load "simcard"
		config_foreach check_modem_id sim "$device" "$position" modem
	fi

	if [ "$MODEM_FOUND" = "1" ]; then
		return
	fi

	[ -z "$position" ] && position=1

	pin="$(get_mnf_sim_pin "$device" "$position")"

	[ -e /etc/config/simcard ] || touch /etc/config/simcard
	uci_add simcard sim
	uci_set simcard $CONFIG_SECTION modem "$device"
	uci_set simcard $CONFIG_SECTION position "$position"
	uci_set simcard $CONFIG_SECTION volte "$volte"
	[ "$primary" -eq 1 ] && uci_set simcard $CONFIG_SECTION primary "$primary"
	[ -n "$pin" ] && [ "$pin" != "N/A" ] && uci_set simcard $CONFIG_SECTION pincode "$pin"
	uci_commit simcard

	[ -x "/bin/trigger_vuci_routes_reload" ] && /bin/trigger_vuci_routes_reload
}

add_modem_settings_config() {
	local usb_id="$1"
	[ -e /etc/config/simcard ] || return

	MODEM_FOUND="0"
	config_load "simcard"
	config_foreach check_modem_id modem "$usb_id" "" modem
	[ "$MODEM_FOUND" -eq 1 ] && return

	# Add modem section to simcard config
	uci_add simcard modem
	uci_set simcard $CONFIG_SECTION modem "$usb_id"
	uci_set simcard $CONFIG_SECTION flight_mode "0"
	uci_commit simcard
}

add_sms_storage_config() {

	local device="$1"
	MODEM_FOUND="0"

	[ -f /etc/config/simcard ] || return

	config_load "simcard"
	config_foreach check_modem_id simman "$device" "1" info_modem_id

	[ "$MODEM_FOUND" = "1" ] && return

	[ -z "$device" ] && return

	uci_add simcard simman
	uci_set simcard "$CONFIG_SECTION" free "5"
	uci_set simcard "$CONFIG_SECTION" info_modem_id "$device"
	uci_commit simcard
}

add_sim_switch_config() {
	local device="$1"
	local position="$2"
	local is_bootstrap="$3"

	[ -f /etc/config/sim_switch ] || return 0
	[ -z "$position" ] && position=1

	uci_add sim_switch sim
	uci_set sim_switch $CONFIG_SECTION modem "$device"
	uci_set sim_switch $CONFIG_SECTION position "$position"
	[ "$is_bootstrap" -eq 1 ] && configure_bootstrap_sim_switch_rules "$device" "$position" "$CONFIG_SECTION"

	uci_commit sim_switch

	[ -x "/bin/trigger_vuci_routes_reload" ] && /bin/trigger_vuci_routes_reload
}

configure_bootstrap_sim_switch_rules() {
	local device="$1"
	local position="$2"
	local CONFIG_SECTION="$3"

	uci_set sim_switch "$CONFIG_SECTION" enabled '1'
	uci_set sim_switch "$CONFIG_SECTION" enable_back '1'
	uci_set sim_switch "$CONFIG_SECTION" switch_back '15' # Switch back after 15 minutes
	uci_set sim_switch "$CONFIG_SECTION" order "$position"

	configure_rules_for_primary_sim() {
		local section="$1"
		local modem primary_position

		config_get modem "$section" modem
		config_get primary_position "$section" position

		if [ "$modem" = "$device" ] && [ "$primary_position" = "1" ]; then
			uci_set sim_switch "$section" enabled '1'
			uci_set sim_switch "$section" retry_count '10'
			uci_set sim_switch "$section" interval '360'
			uci_set sim_switch "$section" sim_not_ready '1'
			uci_set sim_switch "$section" order "$primary_position"
			return
		fi
	}

	config_load sim_switch
	config_foreach configure_rules_for_primary_sim sim
}

add_quota_limit_config() {
	local interface="$1"
	touch /etc/config/quota_limit
	chown "network:network" "/etc/config/quota_limit"
	chmod 666 "/etc/config/quota_limit"

	[ -z "$(uci_get quota_limit "$interface")" ] && {
		uci_add quota_limit interface "$interface"
		uci_commit quota_limit
		chown "network:network" "/tmp/.uci/quota_limit"
		chmod 666 "/tmp/.uci/quota_limit"
	}
}

configure_firewall_bootstrap_esim_zone() {
	local intf="$1"
	local esim_idx=""
	local priority=1
	local index=1

	check_esim_zone() {
		local name

		config_get name "$1" name

		[ "$name" = "eSIM" ] && esim_idx="$1"
	}

	find_hightest_priority() {
		local prio
		config_get prio "$1" priority
		[ -n "$prio" ] && [ "$prio" -gt "$priority" ] && priority="$prio"
	}

	increase_values() {
		index=$((index + 1))
		priority=$((priority + 1))
	}

	config_load "firewall"
	config_foreach check_esim_zone zone

	if [ -z "$esim_idx" ]; then

		while uci_get "firewall" "$index" >/dev/null; do
			index=$((index + 1))
		done

		config_foreach find_hightest_priority rule

		uci_add firewall zone "$index"
		uci_set firewall $index name "eSIM"
		uci_set firewall $index input "DROP"
		uci_set firewall $index output "DROP"
		uci_set firewall $index forward "DROP"
		uci_set firewall $index masq "1"
		uci_set firewall $index mtu_fix "1"
		uci_set firewall $index network "$intf"

		increase_values

		uci_add firewall rule "$index"
		uci_set firewall $index name "Allow-DHCP-Input-eSIM"
		uci_set firewall $index target "ACCEPT"
		uci_add_list firewall $index dest_port "68"
		uci_add_list firewall $index proto "udp"
		uci_set firewall $index src "eSIM"
		uci_set firewall $index family "ipv4"
		uci_set firewall $index priority "$priority"

		increase_values

		uci_add firewall rule "$index"
		uci_set firewall $index name "Allow-DHCP-Output-eSIM"
		uci_set firewall $index target "ACCEPT"
		uci_set firewall $index dest "eSIM"
		uci_add_list firewall $index proto "udp"
		uci_add_list firewall $index dest_port "67"
		uci_set firewall $index family "ipv4"
		uci_set firewall $index priority "$priority"

		increase_values

		uci_add firewall rule "$index"
		uci_set firewall $index name "Allow-DNS-eSIM"
		uci_set firewall $index target "ACCEPT"
		uci_set firewall $index dest "eSIM"
		uci_add_list firewall $index proto "tcp"
		uci_add_list firewall $index proto "udp"
		uci_add_list firewall $index dest_port "53"
		uci_set firewall $index priority "$priority"

		increase_values

		uci_add firewall rule "$index"
		uci_set firewall $index name "Allow-RMS-eSIM"
		uci_set firewall $index target "ACCEPT"
		uci_add_list firewall $index proto "tcp"
		uci_set firewall $index dest "eSIM"
		uci_add_list firewall $index dest_port "15009"
		uci_add_list firewall $index dest_port "15010"
		uci_add_list firewall $index dest_port "15011"
		uci_add_list firewall $index dest_port "15039"
		uci_add_list firewall $index dest_port "15040"
		uci_add_list firewall $index dest_port "15041-15100"
		uci_set firewall $index priority "$priority"

		increase_values

		uci_add firewall rule "$index"
		uci_set firewall $index name "Allow-cURL-eSIM"
		uci_set firewall $index target "ACCEPT"
		uci_set firewall $index dest "eSIM"
		uci_add_list firewall $index proto "tcp"
		uci_add_list firewall $index dest_port "80"
		uci_add_list firewall $index dest_port "443"
		uci_set firewall $index enabled "0"
		uci_set firewall $index priority "$priority"
	else
		uci_set firewall $esim_idx network "$intf"
	fi

	uci_commit firewall
}

configure_modem() {
	local cfg="$1"
	local device="$2"
	local modem_cnt="$3"

	create_mobile_iface "$cfg" "$device" "$modem_cnt"
	update_firewall_zone "wan" "$cfg"
	create_multiwan_iface "$cfg" "$modem_cnt"
	add_simcard_config "$device" 1 1 "" "auto"
	add_sim_switch_config "$device" 1 0
	add_quota_limit_config "$cfg"
}

get_sim_position() {
	local modem_num="$1"
	local sim_position="$2"

	# Collect sim_cfg from all sim slots
	local full_sim_cfg=""
	for i in $(seq 4); do
		sim_cfg=$(mnf_info -C ${i} 2>/dev/null)
		[ -n "$sim_cfg" ] && full_sim_cfg="${full_sim_cfg:+${full_sim_cfg}_}${sim_cfg}"
	done

	# Sort by modem order and sim position if not dual modem
	[ -n "$(mnf_info -C 4 2>/dev/null)" ] &&
		sorted_sim_configs="$(echo $full_sim_cfg | tr '_' '\n')" ||
		sorted_sim_configs=$(echo $full_sim_cfg | tr '_' '\n' | awk '{print substr($0,3,1)substr($0,2,1),$0}' | sort | cut -d ' ' -f2)

	local pos=0
	local i=0
	for sim_config in $sorted_sim_configs; do
		i=$((i + 1))
		modem_bit=${sim_config:1:1}

		# Check if the modem and sim type match the input arguments
		if [ "$modem_bit" -eq "$modem_num" ]; then
			pos=$((pos + 1))
			[ "$pos" -eq "$sim_position" ] && echo "$i" && return 0
		fi
	done

	return 1
}
