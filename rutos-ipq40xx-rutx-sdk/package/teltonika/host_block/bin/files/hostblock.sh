#!/bin/sh
# Copyright (C) 2017 Teltonika
. /lib/functions.sh

SCRIPT_NAME=$(basename $0)
NETWORK="$(uci -q get hostblock.config.network)"
[ "$NETWORK" = "all" ] && NETWORK=""

SERVER_CONF="/tmp/dnsmasq.d${NETWORK:+_}${NETWORK}/server"
SERVER_SNAP=""
ADDRESS_CONF="/tmp/dnsmasq.d${NETWORK:+_}${NETWORK}/address"
ADDRESS_SNAP=""
DEFAULT_DNS="8.8.8.8"
DEFAULT_BLOCKIPV4="255.255.255.255"
DEFAULT_BLOCKIPV6="::ffff:ffff:ffff"
SERVER_IP=""
FORCE_RESTART=0

help() {
	echo "Next Generation Host Blocker"
	echo "Usage: $SCRIPT_NAME enable|disable|restart"
}

is_exist() {
	local host
	config_get host "$1" "host"
	[ "$host" = "$2" ] && EXIST=1
}

add_cname() {
	local cname="$1"
	local host="$2"
	uci_add hostblock block
	uci_set hostblock @block[-1] enabled '1'
	uci_set hostblock @block[-1] host "$cname"
	uci_set hostblock @block[-1] phost "$host"
	uci_commit hostblock
}

check_cname() {
	local enabled host phost cname ncname icmp_host
	config_get_bool enabled "$1" "enabled"
	config_get icmp_host "config" "icmp_host" "$DEFAULT_DNS"

	[ "$enabled" -eq 1 ] || return

	config_get host "$1" "host"
	config_get phost "$1" "phost"
	config_get ncname "$1" "ncname" "0"

	[ -z "$host" ] || [ "$ncname" != "0" ] || [ -n "$phost" ] && return

	cname=$(nslookup "$host" "$icmp_host" | grep "Name:" | awk '{print $2}' | tail -1)
	[ -z "$cname" ] || [ "$cname" = "$host" ] && return

	EXIST=0
	config_foreach is_exist "block" "$cname"
	[ "$EXIST" = "0" ] && add_cname "$cname" "$host"
}

append_file_hosts() {
	cat "$1" | awk -v IP="$SERVER_IP" -F ";" \
		'{ if ($2 !~ /!.*/ && length($2) > 0){
			gsub(/\*/, "") ; print "server=/"$2"/"IP
		} }' >>$SERVER_CONF
}

append_host() {
	local enabled
	local host
	config_get_bool enabled "$1" "enabled"
	if [ "$enabled" -eq 1 ]; then
		config_get host "$1" "host"
		if [ -n "$host" ]; then
			host=$(echo "$host" | sed 's/*//g')
			echo "server=/$host/$SERVER_IP" >>"$SERVER_CONF"
		else
			logger -t "$SCRIPT_NAME" "No host specified"
		fi
	fi
}

enable_hb() {
	local enabled
	local mode
	local icmp_host

	config_load "hostblock"
	config_get_bool enabled "config" "enabled"
	config_get mode "config" "mode"
	config_get icmp_host "config" "icmp_host" "$DEFAULT_DNS"

	if [ $enabled -ne 1 ]; then
		return 1
	fi

	if [ "$mode" = "blacklist" ]; then
		SERVER_IP=""
	elif [ "$mode" = "whitelist" ]; then
		SERVER_IP="$icmp_host"
	else
		logger -t "$SCRIPT_NAME" "No mode specified"
		return 1
	fi

	: > "$SERVER_CONF"
	: > "$ADDRESS_CONF"
	: > "/tmp/dnsmasq.d/server"
	: > "/tmp/dnsmasq.d/address"

	config_foreach check_cname "block"
	config_load "hostblock"
	config_foreach append_host "block"
	[ -e "/etc/vuci-uploads/hosts" ] && append_file_hosts "/etc/vuci-uploads/hosts"

	echo "server=/rms.teltonika.lt/$icmp_host" >>"$SERVER_CONF"
	echo "server=/rut.teltonika.lt/$icmp_host" >>"$SERVER_CONF"

	if [ "$mode" = "whitelist" ]; then
		echo "address=/#/$DEFAULT_BLOCKIPV4" >>"$ADDRESS_CONF"
		echo "address=/#/$DEFAULT_BLOCKIPV6" >>"$ADDRESS_CONF"
	fi

	if [ -e /etc/luci-uploads/cbid.hostblock.config.site_blocking_hosts ]; then
		while read -r line || [[ -n "$line" ]]; do
			if [[ -n "$line" ]]; then
				#funkcija skirta nuimti perpildytas eilutes www antrastemis ir windows naujos eilutes simboli
				line=$(echo $line | sed 's/\r$//' | sed 's~http[s]*://[w\.]*~~g' | sed 's~/.*~~' | sed 's/*//g')
				echo "server=/$line/$SERVER_IP" >>"$SERVER_CONF"
			fi
		done </etc/luci-uploads/cbid.hostblock.config.site_blocking_hosts
	fi

	echo "HostBlock enabled"
	return 0
}

disable_hb() {
	: > "$SERVER_CONF"
	: > "$ADDRESS_CONF"
	: > "/tmp/dnsmasq.d/server"
	: > "/tmp/dnsmasq.d/address"
	echo "HostBlock disabled"
}

add_dns_redirect() {
	local cfg=$(uci -q add firewall redirect)
	uci -q batch <<-EOF
		set firewall.$cfg.enabled='0'
		set firewall.$cfg.target='DNAT'
		set firewall.$cfg.src='lan'
		set firewall.$cfg.dest='lan'
		add_list firewall.$cfg.proto='tcp'
		add_list firewall.$cfg.proto='udp'
		set firewall.$cfg.name='Redirect_DNS'
		set firewall.$cfg.dest_ip='192.168.1.1'
		set firewall.$cfg.src_dport='53'
		set firewall.$cfg.dest_port='53'
		rename firewall.$cfg='REDIR_DNS'
	EOF
}

enable_dns_redirect() {
	local dest_ip
	local zone="lan"

	if [ -n "$NETWORK" ]; then
		if [ "$NETWORK" = "hotspot" ]; then
			dest_ip=$(uci -q get chilli.@chilli[0].uamlisten)
			zone="hotspot"
		else
			dest_ip=$(uci -q get network."$NETWORK".ipaddr)
		fi
	else
		dest_ip=$(uci -q get network.lan.ipaddr)
	fi

	if [ -n "$dest_ip" ]; then
		if [ "$(uci -q get firewall.REDIR_DNS)" != "redirect" ]; then
			add_dns_redirect
		fi
		uci -q set firewall.REDIR_DNS.enabled=1
		uci -q set firewall.REDIR_DNS.dest_ip="$dest_ip"
		uci -q set firewall.REDIR_DNS.src="$zone"
		uci -q set firewall.REDIR_DNS.dest="$zone"
		uci -q delete firewall.REDIR_DNS.src_ip
		[ -n "$NETWORK" ] && [ "$NETWORK" != "hotspot" ] && {
			uci -q add_list firewall.REDIR_DNS.src_ip="${dest_ip%.*}.0/24"
		}
		uci -q commit firewall
		reload_firewall
	else
		disable_dns_redirect
	fi
}

disable_dns_redirect() {
	[ "$(uci -q get firewall.REDIR_DNS)" != "redirect" ] && return
	uci -q set firewall.REDIR_DNS.enabled=0
	uci -q commit firewall
	reload_firewall
}

reload_firewall() {
	ubus call service event "{ \"type\": \"config.change\", \"data\": { \"package\": \"firewall\" }}"
}

reload_dnsmasq() {
	ubus call service event "{ \"type\": \"config.change\", \"data\": { \"package\": \"dhcp\" }}"
}

config_snapshot() {
	if [ -e "$SERVER_CONF" ]; then
		SERVER_SNAP=$(md5sum "$SERVER_CONF")
	else
		SERVER_SNAP="0"
	fi

	if [ -e "$ADDRESS_CONF" ]; then
		ADDRESS_SNAP=$(md5sum "$ADDRESS_CONF")
	else
		ADDRESS_SNAP="0"
	fi
}

compare_snapshot() {
	local server_snap
	local address_snap
	local ret

	if [ -e "$SERVER_CONF" ]; then
		server_snap=$(md5sum "$SERVER_CONF")
	else
		server_snap="0"
	fi

	if [ -e "$ADDRESS_CONF" ]; then
		address_snap=$(md5sum "$ADDRESS_CONF")
	else
		address_snap="0"
	fi

	if [ "$server_snap" = "$SERVER_SNAP" ] &&
		[ "$address_snap" = "$ADDRESS_SNAP" ]; then
		ret=0
	else
		ret=1
	fi

	return $ret
}

if [ $# -ne 1 ]; then
	help
	exit
fi

service_enable() {
	config_snapshot
	enable_hb
	if [ $? -eq 0 ]; then
		enable_dns_redirect
	fi
}

service_disable() {
	config_snapshot
	disable_hb
	disable_dns_redirect
}

service_restart() {
	config_snapshot
	disable_hb
	enable_hb
	if [ $? -eq 0 ]; then
		enable_dns_redirect
	else
		disable_dns_redirect
	fi
}

case "$1" in
"enable")
	service_enable
	;;
"disable")
	service_disable
	;;
"restart")
	service_restart
	;;
*)
	help
	exit
	;;
esac

compare_snapshot
if [ $? -eq 1 ] || [ "$FORCE_RESTART" -eq 1 ]; then
	echo "Reloading dnsmasq"
	reload_dnsmasq
fi
