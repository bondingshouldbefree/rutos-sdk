#!/bin/sh

network_hook() {
	local log_file="${PACK_DIR}network.log"

	is_executable "netstat" && {
		troubleshoot_init_log "ACTIVE CONNECTIONS" "$log_file"
		troubleshoot_add_log "$(netstat -tupan 2>/dev/null)" "$log_file"
	}

	troubleshoot_init_log "IP RULES" "$log_file"
	troubleshoot_add_log "$(ip rule)" "$log_file"
	troubleshoot_init_log "IP ROUTES" "$log_file"
	troubleshoot_add_log "$(ip route show table all)" "$log_file"

	is_executable "swanctl" && {
		troubleshoot_init_log "IPSEC STATUS" "$log_file"
		troubleshoot_add_log_ext "/etc/init.d/swanctl" "get_status" "$log_file"
	}
	is_executable "mwan3" && {
		troubleshoot_init_log "MULTIWAN STATUS" "$log_file"
		troubleshoot_add_log_ext "mwan3" "status" "$log_file"
	}

}

firewall_hook() {
	local log_file="${PACK_DIR}firewall.log"

	is_executable "iptables" && {
		troubleshoot_init_log "IPtables FILTER" "$log_file"
		troubleshoot_add_log_ext "ip" "tun" "$log_file"
		troubleshoot_add_log "$(iptables -L -nv)" "$log_file"

		troubleshoot_init_log "IPtables NAT" "$log_file" "$log_file"
		troubleshoot_add_log "$(iptables -t nat -L -nv)" "$log_file"

		troubleshoot_init_log "IPtables MANGLE" "$log_file" "$log_file"
		troubleshoot_add_log "$(iptables -t mangle -L -nv)" "$log_file"

		troubleshoot_add_log "$(iptables-save)" "$log_file"
	}

	is_executable "ebtables" && {
		troubleshoot_init_log "EBtables FILTER" "$log_file"
		troubleshoot_add_log_ext "ip" "tun" "$log_file"
		troubleshoot_add_log "$(ebtables -t filter -L --Lc)" "$log_file"

		troubleshoot_init_log "EBtables NAT" "$log_file"
		troubleshoot_add_log "$(ebtables -t nat -L --Lc)" "$log_file"

		troubleshoot_init_log "EBtables BROUTE" "$log_file"
		troubleshoot_add_log "$(ebtables -t broute -L --Lc)" "$log_file"
	}

	troubleshoot_init_log "NF Conntrack entry count" "$log_file"
	troubleshoot_add_log "$(wc -l /proc/net/nf_conntrack | awk '{print $1}')" "$log_file"
	troubleshoot_init_log "NF Conntrack first entries (up to 1000)" "$log_file"
	troubleshoot_add_log "$(head -1000 /proc/net/nf_conntrack)" "$log_file"
}

interfaces_hook() {
	local log_file="${PACK_DIR}network.log"
	local dhcp_list_data

	troubleshoot_init_log "Interfaces" "$log_file"
	{
		for iface in /sys/class/net/*; do
			ifconfig "$(basename "$iface")"
			ip a sh dev "$(basename "$iface")"
			printf "\n\n"
		done
	} >>"$log_file" 2>/dev/null

	troubleshoot_init_log "Tunnels" "$log_file"
	troubleshoot_add_log "$(ip tun)" "$log_file"

	is_executable "brctl" && {
		troubleshoot_init_log "Bridges" "$log_file"
		troubleshoot_add_log "$(brctl show)" "$log_file"
	}

	troubleshoot_init_log "Routing table" "$log_file"
	troubleshoot_add_log "$(route -n -e)" "$log_file"

	troubleshoot_init_log "DHCP leases" "$log_file"
	[ -f "/tmp/dhcp.leases" ] && dhcp_list_data=$(cat /tmp/dhcp.leases)
	troubleshoot_add_log "${dhcp_list_data:-no DHCP leases..}" "$log_file"

	troubleshoot_init_log "ARP Data" "$log_file"
	troubleshoot_add_log "$(cat /proc/net/arp)" "$log_file"

	ubus list network.interface &>/dev/null && {
		troubleshoot_init_log "Network interface dump" "$log_file"
		troubleshoot_add_log "$(ubus -t 30 call network.interface dump)" "$log_file"
	}
}

vpns_hook() {
	local log_file="${PACK_DIR}vpns.log"

	is_executable "wg" && local wg_show="$(wg show)"
	[ -n "$wg_show" ] && {
		troubleshoot_init_log "Wireguard Status" "$log_file"
		troubleshoot_add_log "$wg_show" "$log_file"
	}
}

dynamic_routes_status_call() {
	local service="$1" call="$2" log_file="$3" port
	case "$service" in
		zebra)  port=2601 ;;
		ripd)   port=2602 ;;
		ospfd)  port=2604 ;;
		bgpd)   port=2605 ;;
		nhrpd)  port=2610 ;;
		eigrpd) port=2613 ;;
		*)      return 1 ;;
	esac

	# this connects to the dynamic routing service using a hardcoded pass, otherwise FRR does not allow any connectons to it.
	# Password has nothing to do with the system itself and service is only reachable via localhost
	local status_call=$(
		( echo admin01; echo enable; echo admin01; echo "$call";) 2>/dev/null | # feeds command to nc
		nc 127.0.0.1 "$port" 2> /dev/null | # runs command to specified service port listening on localhost
		awk '/# '"$call"'/{f=1;next} f' | # gets everything below executed call
		awk '/# $/{exit} 1' | # finishes before "# "
		sed -E 's/(password|enable password) .+/\1 VALUE_REMOVED_FOR_SECURITY_REASONS/' | # obfuscates passwords
		sed 's/\r//g' # converts carriage return to unix
	)
	troubleshoot_add_log "#################################" "$log_file"
	troubleshoot_add_log "$status_call" "$log_file"
	troubleshoot_add_log "#################################" "$log_file"
}
dynamic_routes_hook() {
	local services="zebra bgpd ripd ospfd eigrpd nhrpd"
	for service in $services; do
		pidof "$service" >/dev/null || continue
		local log_file="${PACK_DIR}${service}.log"
		troubleshoot_init_log "$(echo "$service" | awk '{print toupper($0)}') running configuration (show running-config)" "$log_file"
		dynamic_routes_status_call "$service" "show running-config" "$log_file"
		case "$service" in
			zebra)
				troubleshoot_init_log "ZEBRA ip routes (show ip route)" "$log_file"
				dynamic_routes_status_call "$service" "show ip route" "$log_file"
				;;
			bgpd)
				troubleshoot_init_log "BGP Neighbor information (show bgp neighbors)" "$log_file"
				dynamic_routes_status_call "$service" "show bgp neighbors" "$log_file"
				troubleshoot_init_log "BGP summary (show bgp summary)" "$log_file"
				dynamic_routes_status_call "$service" "show bgp summary" "$log_file"
				;;
			ripd)
				troubleshoot_init_log "RIP route information (show ip rip)" "$log_file"
				dynamic_routes_status_call "$service" "show ip rip" "$log_file"
				troubleshoot_init_log "RIP status information (show ip rip status)" "$log_file"
				dynamic_routes_status_call "$service" "show ip rip status" "$log_file"
				;;
			ospfd)
				troubleshoot_init_log "OSPF route information (show ip ospf route)" "$log_file"
				dynamic_routes_status_call "$service" "show ip ospf route" "$log_file"
				troubleshoot_init_log "OSPF neighbor information (show ip ospf neighbor)" "$log_file"
				dynamic_routes_status_call "$service" "show ip ospf neighbor" "$log_file"
				troubleshoot_init_log "OSPF database information (show ip ospf database)" "$log_file"
				dynamic_routes_status_call "$service" "show ip ospf database" "$log_file"
				;;
			eigrpd)
				troubleshoot_init_log "EIGRP interface information (show ip eigrp interfaces)" "$log_file"
				dynamic_routes_status_call "$service" "show ip eigrp interfaces" "$log_file"
				troubleshoot_init_log "EIGRP neighbors information (show ip eigrp neighbors)" "$log_file"
				dynamic_routes_status_call "$service" "show ip eigrp neighbors" "$log_file"
				troubleshoot_init_log "EIGRP topology information (show ip eigrp topology)" "$log_file"
				dynamic_routes_status_call "$service" "show ip eigrp topology" "$log_file"
				;;
			nhrpd)
				troubleshoot_init_log "NHRP cache information (show ip nhrp cache)" "$log_file"
				dynamic_routes_status_call "$service" "show ip nhrp cache" "$log_file"
				troubleshoot_init_log "NHRP NHS information (show ip nhrp nhs)" "$log_file"
				dynamic_routes_status_call "$service" "show ip nhrp nhs" "$log_file"
				troubleshoot_init_log "NHRP shortcut information (show ip nhrp shortcut)" "$log_file"
				dynamic_routes_status_call "$service" "show ip nhrp shortcut" "$log_file"
				troubleshoot_init_log "DMVPN information (show dmvpn)" "$log_file"
				dynamic_routes_status_call "$service" "show dmvpn" "$log_file"
				;;
			*)
				return 1 ;;
		esac
	done
}

troubleshoot_hook_init interfaces_hook
troubleshoot_hook_init network_hook
troubleshoot_hook_init firewall_hook
troubleshoot_hook_init vpns_hook
troubleshoot_hook_init dynamic_routes_hook
