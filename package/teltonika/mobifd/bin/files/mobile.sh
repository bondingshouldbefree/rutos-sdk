#Mobile configuration management lib

. /usr/share/libubox/jshn.sh
. /lib/functions.sh

# when device contains 2 internal modems, this function will return '2' if
#  selected modem(inc_id) is builtin and primary.
# And if it's only builtin, then '1'
is_builtin_modem() {
	local builtin primary

	eval "$(jsonfilter -q -i "/etc/board.json" \
		-e "builtin=@['modems'][@.id='$1'].builtin" \
		-e "primary=@['modems'][@.id='$1'].primary" \
		)"

	[ -z "$builtin" ] && echo 0 && return

	[ "$builtin" -eq 1 ] && {
		[ -z "$primary" ] && echo 1 && return
		[ "$primary" -eq 1 ] && echo 2 && return
		echo 1
		return
	}

	echo 0
}

is_dual_modem() {
	[ "$(jsonfilter -i /etc/board.json -e '@.hwinfo.dual_modem')" = "true" ] && echo 1 || echo 0
}

find_mdm_ubus_obj() {
	local modem_id="$1"
	local mdm_list curr_id

	mdm_list="$(ubus list gsm.modem*)"
	[ -z "$mdm_list" ] && echo "" && return

	for val in $mdm_list; do
		json_load "$(ubus call "$val" info)"
		json_get_var curr_id usb_id
		[ "$curr_id" = "$modem_id" ] && {
			echo "$val"
			return
		}
	done

	echo ""
}

find_mdm_mobifd_obj() {
	local modem_id="$1"
	mdm_ubus_obj="$(find_mdm_ubus_obj "$modem_id")"
	[ -z "$mdm_ubus_obj" ] && echo "" || echo "${mdm_ubus_obj:4}"
}

handle_retry() {
	local retry="$1"
	local interface="$2"

	if [ "$retry" -ge 5 ]; then
		rm /tmp/conn_retry_$interface >/dev/null 2>/dev/null
		object=$(find_mdm_mobifd_obj $modem)
		[ -z "$object" ] && echo "Can't find modem $modem gsm object" && return
		echo "$modem $interface reloading mobifd"
		ubus -t 180 call mobifd.$object reload
		ifdown "$interface"
	else
		retry="$((retry + 1))"
		rm /tmp/conn_retry_$interface >/dev/null 2>/dev/null
		echo "$retry" > /tmp/conn_retry_$interface
	fi
}

# finds esim_profile where status is 1 and returns index of that profile
# returns 0 if not and esim or no active esim profile
get_active_esim_profile_index() {
	local modem="$1"
	local esim_profiles
	local esim_profile_index
	local esim_profile_status
	local is_esim

	object=$(find_mdm_mobifd_obj $modem)
	[ -z "$object" ] && echo "Can't find modem $modem gsm object" && return

	# todo: once rpcd esim support is added, use that instead of mobifd
	esim_profiles="$(ubus call mobifd.$object list_esim_profiles)"
	[ -z "$esim_profiles" ] && echo "-1" && return

	json_load "$esim_profiles"

	# check if is_esim is true
	json_get_var is_esim is_esim
	[ "$is_esim" != "1" ] && echo "0" && return

	#find esim_profile with status 1
	json_select profiles
	json_get_keys profiles
	for profile in $profiles; do
		json_select "$profile"
		json_get_var esim_profile_status status
		json_select ..
		[ "$esim_profile_status" = "1" ] && {
			esim_profile_index="$profile"
			#convert to 0 based index
			esim_profile_index=$((esim_profile_index-1))
			echo "$esim_profile_index"
			return
		}
	done

	[ -z "$esim_profile_index" ] && logger -t "mobile.sh" "No active esim profile"

	echo "-1"
}

gsm_soft_reset() {
	local modem_id="$1"
	local mdm_ubus_obj

	mdm_ubus_obj="$(find_mdm_ubus_obj "$modem_id")"
	[ -z "$mdm_ubus_obj" ] && echo "gsm.modem object not found" && return

	ubus call "$mdm_ubus_obj" set_func "{\"func\":\"rf\",\"reset\":false}" >/dev/null 2>/dev/null

	sleep 2

	ubus call "$mdm_ubus_obj" set_func "{\"func\":\"full\",\"reset\":false}" >/dev/null 2>/dev/null
}

kill_uqmi_processes() {
	local device="$1"
	logger -t "mobile.sh" "Clearing uqmi processes for $device"
	killall "uqmi -d $device" 2>/dev/null
	killall "uqmi -s -d $device" 2>/dev/null
}

gsm_hard_reset() {
	local modem_id="$1"
	echo "Calling \"mctl --reboot -i $modem_id\""
	mctl --reboot -i "$modem_id"
}

call_mobifd_reject_33_handler() {
	local modem_id="$1"
	local interface="$2"
	local gsm_name modem_num

	gsm_name="$(find_mdm_ubus_obj "$modem_id")"
	[ -z "$gsm_name" ] && {
		echo "Error: Unable to determine modem name for ID $modem_id" >&2
		return 1
	}

	modem_num="${gsm_name: -1}"
	ubus call "mobifd.modem$modem_num" reject_cause_33 "{\"interface\":\"$interface\"}"
}

qmi_error_handle() {
	local error="$1"
	local error_cnt_in="$2"
	local modem_id="$3"
	local skip_reset="$4"

	echo "$error" | grep -qi "Unknown error" && {
		error_cnt=$((error_cnt_in+1))
		logger -t "mobile.sh" "Received unknown error($error_cnt/5): $error"
		[ $error_cnt = "5" ] && {
			gsm_hard_reset "$modem_id"
			kill_uqmi_processes "$device"
			return 1
		}
		return 0
	}

	echo "$error" | grep -qi "error" && {
		logger -t "mobile.sh" "$error"
	}

	echo "$error" | grep -qi "call throttled" && {
		logger -t "mobile.sh" "QMI call error, Connection attempt throttled by network"
		ifdown "$interface"
		call_mobifd_reject_33_handler "$modem_id" "$interface"
		return 2
	}

	echo "$error" | grep -qi "Service option not subscribed" && {
		logger -t "mobile.sh" "QMI call error, reason type 3GPP: \"Service option not subscribed\""
		ifdown "$interface"
		call_mobifd_reject_33_handler "$modem_id" "$interface"
		return 2
	}

	echo "$error" | grep -qi "Client IDs exhausted" && {
			logger -t "mobile.sh" "ClientIdsExhausted! resetting counter..."
			proto_notify_error "$interface" NO_CID
			uqmi -s -d "$device" --sync
			return 1
	}

	echo "$error" | grep -qi "Failed to connect to service" && {
		logger -t "mobile.sh" "Device not responding, restarting module"
		gsm_hard_reset "$modem_id"
		kill_uqmi_processes "$device"
		return 1
	}

	echo "$error" | grep -qi "Request canceled" && {
		logger -t "mobile.sh" "Device returns bad packages, restarting module"
		gsm_hard_reset "$modem_id"
		kill_uqmi_processes "$device"
		return 1
	}

	echo "$error" | grep -qi "Invalid arguments given" && {
		logger -t "mobile.sh" "Got QMI WDS core error. Restarting the WDS service"
		uqmi -d "$device" --reset-wds
		sleep 5
		return 1
	}

	echo "$error" | grep -qi "Call Failed" && {
		[ "$skip_reset" != "true" ] && {
			logger -t "mobile.sh" "Device not responding, resetting mobile network"
			sleep 10
			gsm_soft_reset "$modem_id"
		}
		return 1
	}

	return 0
}

sim1_pass=
sim2_pass=
get_passthrough_interfaces() {
	local sim method
	config_get method "$1" "method"
	config_get sim "$1" "sim"
	[ "$method" = "passthrough" ] && [ "$sim" = "1" ] && sim1_pass="$1"
	[ "$method" = "passthrough" ] && [ "$sim" = "2" ] && sim2_pass="$1"
}

passthrough_mode=
get_passthrough() {
	config_get primary "$1" primary
	[ "$primary" = "1" ] && {
		config_get sim "$1" position;
		passthrough_mode=$(eval uci -q get network.\${sim${sim}_pass}.passthrough_mode 2>/dev/null);
	}
}

setup_bridge_v4() {
	local dev="$1"
	local modem_num="$2"
	local p2p updated_mask
	local dhcp_param_file="/tmp/dnsmasq.d/bridge"
	local model
	echo "$parameters4"

	[[ "$dev" = "rmnet_data"* ]] && { ## TRB5 uses qmicli - different format
		bridge_ipaddr="$(echo "$parameters4" | sed -n "s_.*IPv4 address: \([0-9.]*\)_\1_p")"
		bridge_mask="$(echo "$parameters4" | sed -n "s_.*IPv4 subnet mask: \([0-9.]*\)_\1_p")"
		bridge_gateway="$(echo "$parameters4" | sed -n "s_.*IPv4 gateway address: \([0-9.]*\)_\1_p")"
		bridge_dns1="$(echo "$parameters4" | sed -n "s_.*IPv4 primary DNS: \([0-9.]*\)_\1_p")"
		bridge_dns2="$(echo "$parameters4" | sed -n "s_.*IPv4 secondary DNS: \([0-9.]*\)_\1_p")"
	} || {
		json_load "$parameters4"
		json_select "ipv4"
		json_get_var bridge_ipaddr ip
		json_get_var bridge_mask subnet
		json_get_var bridge_gateway gateway
		json_get_var bridge_dns1 dns1
		json_get_var bridge_dns2 dns2
	}

	config_load network
	config_foreach get_passthrough_interfaces interface
	config_get p2p "$interface" p2p "0"

	config_load simcard
	config_foreach get_passthrough sim

	if [ "$p2p" -eq 1 ]; then
		bridge_mask="255.255.255.255"
		bridge_gateway="169.254.0.2"
	else
		updated_mask=$(validate_cidr "$bridge_ipaddr" "$bridge_gateway" "$bridge_mask") && bridge_mask="$updated_mask"
	fi

	json_init
	json_add_string name "${interface}_4"
	json_add_string ifname "$dev"
	json_add_string proto "none"
	json_add_object "data"
	ubus call network add_dynamic "$(json_dump)"
	IFACE4="${interface}_4"

	json_init
	json_add_string interface "${interface}_4"
	[ -n "$zone" ] && {
		json_add_string zone "$zone"
		iptables -w -A forwarding_${zone}_rule -m comment --comment "!fw3: Mobile bridge" -j zone_lan_dest_ACCEPT
	}
	ubus call network.interface set_data "$(json_dump)"

	json_init
	json_add_string interface "${interface}"
	json_add_string bridge_ipaddr "$bridge_ipaddr"
	json_add_string bridge_gateway "$bridge_gateway"
	ubus call network.interface set_data "$(json_dump)"

	json_init
	json_add_string modem "$modem"
	json_add_string sim "$sim"
	ubus call network.interface."${interface}_4" set_data "$(json_dump)"
	json_close_object

	json_init
	json_add_string name "mobile_bridge"
	json_add_string ifname "br-lan"
	json_add_string proto "static"
	json_add_string gateway "0.0.0.0"
	json_add_array ipaddr
	json_add_string "" "$bridge_gateway"
	json_close_array
	json_add_string ip4table "40"
	ubus call network add_dynamic "$(json_dump)"

	ip route add default dev "$dev" table 42
	ip route add "$bridge_ipaddr" dev br-lan
	ip route add default via "$bridge_ipaddr" dev br-lan table 43

	ip rule add pref 5042 iif br-lan lookup 42
	ip rule add pref 5043 iif "$dev" lookup 43
	#sysctl -w net.ipv4.conf.br-lan.proxy_arp=1 #2>/dev/null
	model="$(gsmctl --model ${modem_num:+-O "$modem_num"})"
	[ "${model:0:4}" = "UC20" ] || [ "${model:0:6}" = "RG500U" ] && ip neighbor add proxy "$bridge_ipaddr" dev "$dev" 2>/dev/null

	[ -n "$mac" ] && {
		ip neigh flush dev br-lan
		ip neigh add "$bridge_ipaddr" dev br-lan lladdr "$mac"
	}

	iptables -w -A postrouting_rule -m comment --comment "Bridge mode" -o "$dev" -j ACCEPT -tnat

	> $dhcp_param_file
	[ -z "$mac" ] && mac="*:*:*:*:*:*"
	[ "$passthrough_mode" != "no_dhcp" ] && {
		echo "dhcp-range=tag:mobbridge,$bridge_ipaddr,static,$bridge_mask,${leasetime:-1h}" > "$dhcp_param_file"
		echo "shared-network=br-lan,$bridge_ipaddr" >> "$dhcp_param_file"
		echo "dhcp-host=$mac,set:mobbridge,$bridge_ipaddr" >> "$dhcp_param_file"
		echo "dhcp-option=tag:mobbridge,br-lan,3,$bridge_gateway" >> "$dhcp_param_file"

		[ -n "$bridge_dns1" ] || [ -n "$bridge_dns2" ] && {
			echo "dhcp-option=tag:mobbridge,br-lan,6${bridge_dns1:+,$bridge_dns1}${bridge_dns2:+,$bridge_dns2}" >> "$dhcp_param_file"
			echo "server=$bridge_dns1" >> "$dhcp_param_file"
			echo "server=$bridge_dns2" >> "$dhcp_param_file"
		}
	}
	[ "$passthrough_mode" = "no_dhcp" ] && {
		echo "server=$bridge_dns1" >> "$dhcp_param_file"
		echo "server=$bridge_dns2" >> "$dhcp_param_file"
	}

	echo "method:$method bridge_ipaddr:$bridge_ipaddr" > "/var/run/${interface}_braddr"

	/etc/init.d/dnsmasq reload

	if is_device_dsa ; then
		restart_dsa_interfaces
	else
		swconfig dev 'switch0' set soft_reset 5 &
	fi

}

setup_static_v4() {
	local dev="$1"
	echo "Setting up $dev V4 static"
	echo "$parameters4"

	[[ "$dev" = "rmnet_data"* ]] && { ## TRB5 uses qmicli - different format
		ip_4="$(echo "$parameters4" | sed -n "s_.*IPv4 address: \([0-9.]*\)_\1_p")"
		dns1_4="$(echo "$parameters4" | sed -n "s_.*IPv4 primary DNS: \([0-9.]*\)_\1_p")"
		dns2_4="$(echo "$parameters4" | sed -n "s_.*IPv4 secondary DNS: \([0-9.]*\)_\1_p")"
	} || {
		json_load "$parameters4"
		json_select "ipv4"
		json_get_var ip_4 ip
		json_get_var dns1_4 dns1
		json_get_var dns2_4 dns2
	}

	json_init
	json_add_string name "${interface}_4"
	json_add_string ifname "$dev"
	json_add_string proto static
	json_add_string gateway "0.0.0.0"

	json_add_array ipaddr
		json_add_string "" "$ip_4"
	json_close_array

	json_add_array dns
		[ -n "$dns1_4" ] && json_add_string "" "$dns1_4"
		[ -n "$dns2_4" ] && json_add_string "" "$dns2_4"
	json_close_array

	[ -n "$ip4table" ] && json_add_string ip4table "$ip4table"
	proto_add_dynamic_defaults

	ubus call network add_dynamic "$(json_dump)"
}

setup_dhcp_v4() {
	local dev="$1"
	echo "Setting up $dev V4 DCHP"
	json_init
	json_add_string name "${interface}_4"
	json_add_string ifname "$dev"
	json_add_string proto "dhcp"
	json_add_string script "/lib/netifd/dhcp_mobile.script"
	json_add_boolean ismobile "1"
	[ -n "$ip4table" ] && json_add_string ip4table "$ip4table"
	proto_add_dynamic_defaults
	ubus call network add_dynamic "$(json_dump)"
}

setup_dhcp_v6() {
	local dev="$1"
	echo "Setting up $dev V6 DHCP"
	json_init
	json_add_string name "${interface}_6"
	json_add_string ifname "$dev"
	json_add_string proto "dhcpv6"
	[ -n "$ip6table" ] && json_add_string ip6table "$ip6table"
	json_add_boolean ignore_valid 1
	proto_add_dynamic_defaults
	# RFC 7278: Extend an IPv6 /64 Prefix to LAN
	[ "$delegate" -eq 0 ] || json_add_string extendprefix 1
	ubus call network add_dynamic "$(json_dump)"
}

setup_static_v6() {
	local dev="$1"
	echo "Setting up $dev V6 static"
	echo "$parameters6"

	local custom="$(uci get network.${interface}.dns 2>/dev/null)"

	[[ "$dev" = "rmnet_data"* ]] && { ## TRB5 uses qmicli - different format
		ip6_with_prefix="$(echo "$parameters6" | sed -n "s_.*IPv6 address: \([0-9a-f:]*\)_\1_p")"
		ip_6="${ip6_with_prefix%/*}"
		[[ -z "$custom" ]] && {
			dns1_6="$(echo "$parameters6" | sed -n "s_.*IPv6 primary DNS: \([0-9a-f:]*\)_\1_p")"
			dns2_6="$(echo "$parameters6" | sed -n "s_.*IPv6 secondary DNS: \([0-9a-f:]*\)_\1_p")"
		}
		} || {
		json_load "$parameters6"
		json_select "ipv6"
		json_get_var ip_6 ip
		json_get_var ip_prefix_length ip-prefix-length
		ip_6="${ip_6%/*}"
		ip6_with_prefix="$ip_6/$ip_prefix_length"
			[[ -z "$custom" ]] && {
				json_get_var dns1_6 dns1
				json_get_var dns2_6 dns2
			}
		json_get_var ip_pre_len ip-prefix-length
	}

	json_init
	json_add_string name "${interface}_6"
	json_add_string ifname "$dev"
	json_add_string proto static
	json_add_string ip6gw "::0"

	[ -n "$delegate" ] && [ "$delegate" == 0 ] || {
		json_add_array ip6prefix
		json_add_string "" "$ip6_with_prefix"
		json_close_array
	}

	json_add_array ip6addr
		json_add_string "" "${ip_6}/128"
	json_close_array

	json_add_array dns
		[ -n "$dns1_6" ] && json_add_string "" "$dns1_6"
		[ -n "$dns2_6" ] && json_add_string "" "$dns2_6"
	json_close_array

	[ -n "$ip6table" ] && json_add_string ip6table "$ip6table"
	proto_add_dynamic_defaults

	ubus call network add_dynamic "$(json_dump)"
}

check_digits() {
	var="$1"
	echo "$var" | grep -E '^[+-]?[0-9]+$'
}

ubus_set_interface_data() {
	local modem sim zone iface_and_type
	modem="$1"
	sim="$2"
	zone="$3"
	iface_and_type="$4"

	json_init
	json_add_string modem "$modem"
	json_add_string sim "$sim"
	[ -n "$zone" ] && json_add_string zone "$zone"

	ubus call network.interface."${iface_and_type}" set_data "$(json_dump)"
}

get_pdp() {
	local pdp
	config_load network
	config_get pdp "$1" "pdp" "1"
	echo "$pdp"
}

get_config_sim() {
	local sim
	local DEFAULT_SIM="1"
	config_load network
	config_get sim "$1" "sim" "1"
	[ -z "$sim" ] && logger -t "mobile.sh" "sim option not found in config. Taking default: $DEFAULT_SIM" \
				  && sim="$DEFAULT_SIM"
	echo "$sim"
}

get_config_esim() {
	local esim
	local DEFAULT_ESIM="0"
	config_load network
	config_get esim "$1" "esim_profile" "0"
	[ -z "$esim" ] && esim="$DEFAULT_ESIM"
	echo "$esim"
}

notify_mtu_diff(){
	local operator_mtu="$1"
	local interface_name="$2"
	local current_mtu="$3"
	[ -n "$operator_mtu" ] && [ "$operator_mtu" != "$current_mtu" ] && {
		echo "Notifying WebUI that operator ($operator_mtu) and configuration MTU ($current_mtu) differs"
		ubus send vuci.notify "{\"event\": \"mtu\", \"data\": {\"iface_name\": \"$interface_name\", \"operator_mtu\": \"$operator_mtu\"}}"
	}
}

get_modem_type() {
	local modem_id="$1"
	local modem modems id primary

	json_init
	json_load_file "/etc/board.json"
	json_get_keys modems modems
	json_select modems

	arr_len(){
		echo $#
	}

	local modem_count="$(arr_len $modems)"

	for modem in $modems; do
		json_select "$modem"
		json_get_vars id builtin primary

		[ "$id" != "$modem_id" ] && json_select .. && continue
		[ "$builtin" != "1" ] && json_select .. && continue

		[ "$modem_count" -gt 1 ] && {
			[ "$primary" = "1" ] && echo "primary" || echo "secondary"
		} || echo "internal"
		return
	done
	echo "external"
}

is_device_dsa(){
	[ "$(jsonfilter -i /etc/board.json -e '@.hwinfo.dsa')" = "true" ]
}

restart_dsa_interfaces(){
	restart_dsa_interfaces_cb() {
		local ifname
		config_get ifname "$1" "ifname"
		[ ${ifname:0:3} = "lan" ] && (
			ip link set "$ifname" down 2>/dev/null
			sleep 5
			ip link set "$ifname" up 2>/dev/null
		) &
	}
	config_load network
	config_foreach restart_dsa_interfaces_cb port
}

get_braddr_var() {
	grep -o "$1:[^ ]*" "/var/run/${2}_braddr" 2>/dev/null | cut -d':' -f2
}

subnet_to_cidr() {
	case "$1" in
		255.255.255.255) echo 32 ;;
		255.255.255.254) echo 31 ;;
		255.255.255.252) echo 30 ;;
		255.255.255.248) echo 29 ;;
		255.255.255.240) echo 28 ;;
		255.255.255.224) echo 27 ;;
		255.255.255.192) echo 26 ;;
		255.255.255.128) echo 25 ;;
		255.255.255.0)   echo 24 ;;
		*) return 1 ;;
	esac
}

validate_cidr() {
	local ipaddr="$1"
	local gateway="$2"
	local subnet="$3"
	local min_cidr=24
	local cidr current_cidr ipcalc_output network broadcast

	cidr=$(subnet_to_cidr "$subnet") || return 1
	current_cidr="$cidr"

	while [ "$current_cidr" -ge "$min_cidr" ]; do
		ipcalc_output=$(ipcalc.sh "$ipaddr/$current_cidr")
		network=$(echo "$ipcalc_output" | grep 'NETWORK=' | cut -d= -f2)
		broadcast=$(echo "$ipcalc_output" | grep 'BROADCAST=' | cut -d= -f2)
		new_netmask=$(echo "$ipcalc_output" | grep 'NETMASK=' | cut -d= -f2)

		if [ "$ipaddr" = "$network" ] || [ "$ipaddr" = "$broadcast" ] || \
				 [ "$gateway" = "$network" ] || [ "$gateway" = "$broadcast" ]; then
			current_cidr=$((current_cidr - 1))
		else
			break
		fi
	done

	if [ "$current_cidr" -ge "$min_cidr" ]; then
		echo "$new_netmask"
	else
		return 1
	fi
}

get_simcount_by_modem_num() {
	local modem_num="$1"
	local simcount=0

	for sim in $(seq 4); do
		sim_cfg="$(mnf_info -C $sim 2> /dev/null)"
		# Find the amount of matches to the modem_num
		if [ -n "$sim_cfg" ] && [ "${sim_cfg:1:1}" = "$modem_num" ]; then
			simcount=$((simcount + 1))
		fi
	done

	echo $simcount
}

reload_mobifd() {
	local gsm_modem="$1"
	local interface="$2"
	object=$(find_mdm_mobifd_obj $gsm_modem)
	if [ -z "$object" ]; then
		echo "Can't find modem $gsm_modem gsm object, reloading mobifd"
		ubus -t 180 call mobifd reload
		return
	fi
	echo "$gsm_modem $interface reloading mobifd"
	ubus -t 180 call mobifd.$object reload
}

get_active_sim() {
	local interface="$1"
	local old_cb="$2"
	local gsm_modem="$3"
	local active_sim="0"
	local max_retries=5
	local retry=0

	json_set_namespace gobinet old_cb

	while [ "$retry" -le "$max_retries" ]; do
		json_load "$(ubus call $gsm_modem get_sim_slot)"
		json_get_var active_sim index
		[ -n "$active_sim" ] && [ "$active_sim" != "0" ] && break
		retry="$((retry + 1))"
		sleep 2
	done

	json_set_namespace $old_cb

	[ -z "$active_sim" ] && active_sim="0"

	echo "$active_sim"
}

get_deny_roaming() {
	local active_sim="$1"
	local modem="$2"
	local esim_profile="$3"

	deny_roaming="0"

	deny_roaming_parse() {
		local section="$1"
		local mdm
		local esim_prof
		local position
		config_get position "$section" position
		config_get mdm "$section" modem
		config_get esim_prof "$section" esim_profile "0"

		[ "$modem" = "$mdm" ] && \
		[ "$position" = "$active_sim" ] && \
		[ "$esim_prof" = "$esim_profile" ] && {
			config_get deny_roaming "$section" deny_roaming "0"
		}
	}

	config_load simcard
	config_foreach deny_roaming_parse "sim"

	echo "$deny_roaming"
}

verify_active_sim() {
	local sim="$1"
	local active_sim="$2"
	local interface="$3"

	[ -z "$sim" ] && sim=$(get_config_sim "$interface")

# 	Restart if check failed
	if [ "$active_sim" -lt 1 ] || [ "$active_sim" -gt 4 ]; then
		echo "Bad active sim: $active_sim."
		return 1
	fi

# check if current sim and interface also if current esim match as well
	[ "$active_sim" = "$sim" ] || {
		echo "Active sim: $active_sim. \
		This interface uses different simcard: $sim."
		proto_notify_error "$interface" WRONG_SIM
		proto_block_restart "$interface"
		return 1
	}

	return 0
}

verify_active_esim() {
	local esim_profile="$1"
	local interface="$2"

	config_esim_profile=$(get_config_esim "$interface")

	[ "$esim_profile" = "$config_esim_profile" ] || {
		echo "This interface uses different esim profile: $config_esim_profile."
		proto_notify_error "$interface" WRONG_ESIM
		proto_block_restart "$interface"
		return 1
	}

	return 0
}


ucidef_check_esim() {
	local simcfg="$(cat /sys/mnf_info/sim_cfg)"
	json_select_object hwinfo
	json_get_vars mobile
	[ "$mobile" = "1" ] && {
		for i in $(seq 2 8 26); do
			[ "$i" -gt "${#simcfg}" ] && break
  			if [ "${simcfg:i:1}" = "2" ]; then
				json_add_boolean "esim" 1
    			break
  			fi
		done
	}
	json_select ..
}

ucidef_check_dual_sim() {
	json_select_object hwinfo
	json_get_vars mobile
	[ "$mobile" = "1" ] && [ "$(cat /sys/mnf_info/sim_count)" -gt "1" ] && {
		json_add_boolean "dual_sim" 1
	}
	json_select ..
}

control_mobile_interfaces() {
	local modem="$1"
	local action="$2"

	[ -z "$modem" ] && return 1
	[ -z "$action" ] && return 1

	# List all interfaces in the network configuration
	for interface in $(uci show network | grep '=interface' | cut -d'.' -f2 | cut -d'=' -f1); do
		# Get the modem ID for the current interface
		local modem_id=$(uci get network.$interface.modem 2>/dev/null)
		# Check modem ID
		if [ "$modem_id" = "$modem" ]; then
			# Bring down the interface
			$action $interface
			echo "Performing $action $interface for modem ID $modem_id"
		fi
	done
}
metric=0
get_highest_metric() {
	uci_load "network"

	# Loop through each section in the 'network' configuration
	config_foreach get_interface_metric interface
}
get_interface_metric() {
	local int_metric

	# Check if the "metric" option exists for this section
	config_get int_metric "$1" metric

	# If the metric is found and is greater than the current highest, update it
	if [ -n "$int_metric" ] && [ "$int_metric" -gt "$metric" ]; then
		metric="$int_metric"
	fi
}

# config.d functions
add_modem_section() {
	local id="$1"
	local num="$2"
	local simcount="$3"
	local builtin="$4"
	local custom_ifname
	local sim_pos=0

	get_highest_metric

	json_select ..
	json_get_vars custom_ifname
	json_select modems
	for count in $(seq "$simcount"); do
		interface="mob${num}s${count}a1"

		#~ Get sim slot and get bootstrap profile info
		sim_pos=$(get_sim_position $num $count)
		bootstrap_iccid=$(mnf_info -d${sim_pos} 2>/dev/null)
		[[ "$bootstrap_iccid" != "N/A" && -n "$bootstrap_iccid" ]] && is_bootstrap_profile="1" || is_bootstrap_profile="0"

		metric=$((metric + 1))

		uci -q delete network."${interface}"
		uci_add network interface "${interface}"
		uci_set network "${interface}" proto "wwan"
		uci_set network "${interface}" modem "$id"
		uci_set network "${interface}" metric "$metric"
		uci_set network "${interface}" sim "${count}"
		uci_set network "${interface}" dhcpv6 "0"
		uci_set network "${interface}" pdptype "ipv4v6"
		uci_set network "${interface}" method "nat"
		uci_set network "${interface}" auth "none"
		uci_set network "${interface}" area_type "wan"
		# Manual APN if bootstrap profile
		[ $is_bootstrap_profile -eq 1 ]  && {
			uci_set network "${interface}" auto_apn "0"
			uci_set network "${interface}" apn "360connect"
		} || uci_set network "${interface}" auto_apn "1"

		# Adding dhcp option only for RUT361
		[ "$(mnf_info -n | cut -b 1-6)" = "RUT361" ] && {
			uci_set network "${interface}" dhcp "0"
		}

		# if needed, use custom ifname for rmnet/other devices
		[ -n "${custom_ifname}" ] &&
			uci_set network "${interface}" device "${custom_ifname}"

		uci_commit network

		[ $is_bootstrap_profile -eq 1 ] && configure_firewall_bootstrap_esim_zone "$interface" ||
			update_firewall_zone "wan" "$interface"

		create_multiwan_iface "$interface" "$metric"
		add_simcard_config "$id" "${count}" "${count}" "$builtin"
		add_sim_switch_config "$id" "${count}" "$is_bootstrap_profile"
		add_quota_limit_config "$interface"
	done
	add_sms_storage_config "$id"
}

generate_dynamic_lte() {
[ -f /lib/functions/modem.sh ] || return
. /lib/functions/modem.sh

	local interface num id simcount builtin

	#creating simcard sections from board.json file
	if json_is_a modems array; then
		json_get_keys modems modems
		json_select modems

		num=1

		for modem in $modems; do
			json_select "$modem"
			json_get_vars id simcount builtin
			json_select ..
			add_modem_section "$id" "$num" "$simcount" "$builtin"
			num=$(( num + 1 ))
		done

		json_select ..
	else
		## because of RUTX8 have no default modem
		# after this script runs out simcard config
		# must not be empty due to external modems could appear to config
		echo " " >> /etc/config/simcard
	fi

	#creating simcard sections from conneted via USB
	for a in `ls /sys/bus/usb/devices`; do
		local vendor product
		[ -f "/sys/bus/usb/devices/$a/idVendor" ] && [ -f "/sys/bus/usb/devices/$a/idProduct" ] || continue
		vendor=$(cat "/sys/bus/usb/devices/$a/idVendor")
		product=$(cat "/sys/bus/usb/devices/$a/idProduct")
		[ -f "/lib/network/wwan/${vendor}:${product}" ] && {
			add_simcard_config "$a" "1" "0" ""
			add_sms_storage_config "$a"
		}
	done
}
