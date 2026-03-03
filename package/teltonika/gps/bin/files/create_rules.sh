#!/bin/sh

# Usage: create_rules.sh <config_name> <rules_file_path> [rule_prefix]
# Example: create_rules.sh avl /etc/gps/avl_rules_filled tavl_rule
#          create_rules.sh gps /etc/gps/gps_rules_filled https_tavl_rule

CONFIG_NAME="$1"
RULES_FILE="$2"
RULE_PREFIX="${3:-tavl_rule}"

. /lib/functions.sh
. /usr/share/libubox/jshn.sh

wait_for_iomand() {
    local retries=0
    local iomand_pid

    iomand_pid=$(pidof iomand)
    while [ -z "$iomand_pid" ] && [ $retries -lt 10 ]; do
        sleep 1
        iomand_pid=$(pidof iomand)
        retries=$((retries + 1))
    done

    return 0
}

should_skip_pin() {
    local io_type="$1"
    local io_name="$2"
    local io_status="$3"
    local device_family=$(mnf_info -n | cut -c1-4)

    [ "$io_type" = "relay" ] && return 1

    if [ "$device_family" != "TRB2" ]; then
        local io_bi_dir=$(echo "$io_status" | jsonfilter -e '@["bi_dir"]')
        local io_dir=$(echo "$io_status" | jsonfilter -e '@["direction"]')

        [ "$io_bi_dir" = "1" ] || [ "$io_dir" = "out" ] && return 1
    fi

    return 0
}

add_pin_rule() {
    local io_type="$1"
    local io_name="$2"
    local i=0

    while uci get "$CONFIG_NAME.@$RULE_PREFIX[$i]" >/dev/null 2>&1; do
        name=$(uci get "$CONFIG_NAME.@$RULE_PREFIX[$i].name" 2>/dev/null)
        [ "$name" = "$io_name" ] && return
        i=$((i + 1))
    done

    local section=$(uci add $CONFIG_NAME $RULE_PREFIX)
    uci set "$CONFIG_NAME.$section.type=$io_type"
    uci set "$CONFIG_NAME.$section.name=$io_name"
    uci set "$CONFIG_NAME.$section.enabled=0"

    [ "$io_type" = "acl" ] && uci set "$CONFIG_NAME.$section.acl=current"
}

fix_avl_rule() {
    local section=$(uci -X show avl | grep "mobile_home and roaming" | cut -d '.' -f 2)
    [ -z "$section" ] && return

    din=$(uci -q get ioman.din1)
    dio=$(uci -q get ioman.dio1)
    dio_fallback=$(uci show ioman | grep "direction='in'" | head -n 1 | cut -d '.' -f 2)
    [ -z "$din" ] && [ -z "$dio" ] && [ -z "$dio_fallback" ] && return

    uci set "avl.$section.io_type=gpio"
    uci set "avl.$section.din_status=high"
    uci set "avl.$section.ignore=0"

    if [ -n "$din" ]; then
        uci set "avl.$section.io_name=din1"
    elif [ -n "$dio" ]; then
        uci set "avl.$section.io_name=dio1"
    else
        uci set "avl.$section.io_name=$dio_fallback"
    fi
}

fill_rules() {
    wait_for_iomand

    local available_pins=$(ubus list ioman.*)

    echo "$available_pins" | while read -r pin; do
        local io_type=$(echo "$pin" | cut -d '.' -f 2)
        local io_name=$(echo "$pin" | cut -d '.' -f 3)
        local io_status=$(ubus call "ioman.$io_type.$io_name" status)

        should_skip_pin "$io_type" "$io_name" "$io_status"
        skip=$?
        [ $skip -eq 1 ] && continue

        add_pin_rule "$io_type" "$io_name"
    done

    add_pin_rule "mobile" "signal"

    [ "$CONFIG_NAME" = "avl" ] && {
        add_pin_rule "GPS" "HDOP"
        fix_avl_rule
    }

    uci_commit "$CONFIG_NAME"
}

if [ ! -f "$RULES_FILE" ]; then
    fill_rules
    mkdir -p "$(dirname "$RULES_FILE")" && touch "$RULES_FILE"
fi