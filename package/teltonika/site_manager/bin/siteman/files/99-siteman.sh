#!/bin/sh

[ -s "/etc/config/siteman_wireless" ] && return 0

touch /etc/config/siteman_wireless

default_pass=$(/sbin/mnf_info --wifi_pass 2>/dev/null)
[ -n "$default_pass" ] || return 0

mac=$(/sbin/mnf_info --mac 2>/dev/null)
[ -n "$mac" ] || return 0

uci -q batch <<EOF
    set siteman_wireless.default_radio0=wifi-iface
    add_list siteman_wireless.default_radio0.device=radio0
    set siteman_wireless.default_radio0.enabled=1
    set siteman_wireless.default_radio0.network=lan
    set siteman_wireless.default_radio0.mode=ap
    set siteman_wireless.default_radio0.wifi_id=wifi0
    set siteman_wireless.default_radio0.encryption=psk2
    set siteman_wireless.default_radio0.dm_group_id=1
    set siteman_wireless.default_radio0.key="$default_pass"
    set siteman_wireless.default_radio0.ssid="Teltonika_${mac:0,-4}"
    commit siteman_wireless
EOF

