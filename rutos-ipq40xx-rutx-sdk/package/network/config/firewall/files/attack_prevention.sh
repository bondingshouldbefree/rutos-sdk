#! /bin/sh
. /lib/functions.sh

add_limit_rules() {
	config_get limit "$1" "limit"
	config_get limit_burst "$1" "limit_burst"
	config_get limit_log_overlimit "$1" limit_log_overlimit
	config_get name "$1" "name"

	[ -n "$limit" ] || return

	[ "$name" = "Allow-Ping" ] && {
		iptables -I INPUT -p icmp -m icmp --icmp-type 8 -m comment --comment "!fw3: Reject ICMP" -j REJECT
		[ -n "$limit_log_overlimit" ] && [ "$limit_log_overlimit" -eq 1 ] && iptables -I INPUT -p icmp -m icmp --icmp-type 8 -m limit --limit 1/sec -m comment --comment "!fw3: Allow-Ping overlimit " -j LOG --log-prefix "Allow-Ping overlimit "
		iptables -I INPUT -p icmp -m icmp --icmp-type 8 -m limit --limit $limit --limit-burst $limit_burst -m comment --comment "!fw3: Limit ICMP" -j ACCEPT
	}
}

config_load firewall
config_foreach add_limit_rules rule