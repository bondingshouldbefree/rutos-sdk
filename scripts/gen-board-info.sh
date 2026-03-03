#!/usr/bin/env bash

CONF_PATH="$1"
ROOT_PATH="$2"
SAVE_FILE="$3"

. "$2/lib/functions.sh" 2>/dev/null
. "$2/lib/functions/uci-defaults.sh" 2>/dev/null
. "$2/usr/share/libubox/jshn.sh" 2>/dev/null

# declare device properties
declare -A device_properties=(
    # option name = exported variable,option name,delimiter,inside data delimiter,data type,uci func
    [features]="DEVICE_FEATURES,features, ,,array,ucidef_set_hwinfo"
    [initial_support_version]="INITIAL_VERSION,option, ,,array,ucidef_set_release_version"
    [check_path]="PATH_CHECK,option,;,y,array,ucidef_check_path"
    [usb_jack_path]="USB_JACK,option, ,,single,ucidef_set_usb_jack"
    [usb_jack_path_low_speed]="USB_JACK_LOW_SPEED,option, ,,single,ucidef_set_usb_jack_low_speed"
    [lan_iface_opt]="LAN_OPT,option,;,,single,ucidef_set_interface_lan"
    [wan_iface_opt]="WAN_OPT,option,;,,single,ucidef_set_interface_wan"
    [switch_conf]="SWITCH_CONF,option,;,,single,ucidef_add_switch"
    [net_conf]="NETWORK_OPTIONS,option,;,y,array,ucidef_set_network_options"
    [interface_conf]="INTERFACE_CONF,option,;,y,array,ucidef_set_interface"
    [wlan_bssid_limit]="WLAN_BSSID_LIMIT,option,;,y,array,ucidef_add_wlan_bssid_limit"
    [poe_conf]="POE_CONF,option,;,,single,ucidef_set_poe"
    [poe_chip]="POE_CHIP,option,;,y,array,ucidef_set_poe_chip"
    [serial_capabilities]="SERIAL_CAPABILITIES,option,;,y,array,ucidef_add_serial_capabilities"
    [dot1x_server_capabilities]="DOT1X_SERVER_CAPABILITIES,option,;,,single,ucidef_add_dot1x_server_capabilities"
    [eol]="EOL,option,;,,single,ucidef_add_eol"
)

# get list of included devices
INCLUDED_DEVICES=$(grep CONFIG_INCLUDED_DEVICES "$CONF_PATH" | cut -d '=' -f2 | tr -d '"')

# fetch device info
DEVICE_NUMBER=0

for device in $INCLUDED_DEVICES; do
    declare -A "properties_$device"

    for property in "${!device_properties[@]}"; do
        IFS=',' read -r var_name opt_name delim _ _ _ <<< "${device_properties[$property]}"
        value="$(./scripts/target-metadata.pl "$opt_name" tmp/.targetinfo "$device" "$property")"

        [ -n "$value" ] || continue

        if [ -n "${!var_name}" ]; then
           declare "$var_name"="${!var_name}${delim}$value"
        else
           declare "$var_name"="$value"
        fi

        eval "properties_${device}[$property]=\"\$value\""
    done

    DEVICE_NUMBER=$((DEVICE_NUMBER + 1))
done

filter_common_values() {
    local data="$1"
    local delim="$2"
    local devnum="$3"
    local in_delim="$4"
    local processed_data

    [ "$in_delim" = "y" ] && in_delim=","

    processed_data=$(echo "$data" | \
        tr "$delim$in_delim" "\n" | \
        sed 's/^[ \t]*//' | \
        sort | \
        uniq -c | \
        awk -v devnum="$devnum" '$1 == devnum {sub(/^[ \t]*[0-9]+[ \t]+/, ""); print}')

    [ -n "$in_delim" ] && \
        processed_data=$(echo "$processed_data" | paste -sd "$in_delim" -)

    echo $processed_data

}

# prepare to generate board.json
json_init

for prop in "${!device_properties[@]}"; do
    IFS=',' read -r var_name _ delim in_delim dt ds <<< "${device_properties[$prop]}"

    [ -n "${!var_name}" ] || continue

    declare "COMMON_$var_name=$(filter_common_values "${!var_name}" "$delim" "$DEVICE_NUMBER" "$in_delim")"

    common_var_name="COMMON_$var_name"

    case $dt in
        array)
            [ "$in_delim" = "y" ] && in_delim="," || in_delim=" "
            IFS="$in_delim" read -ra args <<< "${!common_var_name}"
            for opt in "${args[@]}"; do
                eval "$ds $opt"
            done
        ;;
        single)
            [ -n "${!common_var_name}" ] && {
                eval "$ds ${!common_var_name}"
            }
        ;;
    esac
done

# prepare to generate board.d script
BOARDSH=""

for device in $INCLUDED_DEVICES; do
    declare -n device_properties_ref="properties_$device"

    # create case section for a device
    BOARDSH+="\t$(echo "$device*)" | rev | cut -d'_' -f1 | rev | tr '[:lower:]' '[:upper:]')\n"

    for prop in "${!device_properties[@]}"; do
        IFS=',' read -r var_name _ _ in_delim dt ds <<< "${device_properties[$prop]}"
        common_var_name="COMMON_$var_name"

        case $dt in
            array)
                [ "$in_delim" = "y" ] && in_delim="," || in_delim=" "
                IFS="$in_delim" read -ra args <<< "${device_properties_ref[$prop]}"
                for opt in "${args[@]}"; do
                    # trim
                    opt=$(echo "$opt" | awk '{$1=$1; print}')
                    echo "${!common_var_name}" | tr "$in_delim" '\n' | grep -qx "$opt" && continue
                    BOARDSH+="\t\t$ds $opt\n"
                done
            ;;
            single)
                [ -n "${device_properties_ref[$prop]}" ] && \
                    [ "${!common_var_name}" != "${device_properties_ref[$prop]}" ] && \
                    BOARDSH+="\t\t$ds ${device_properties_ref[$prop]}\n"
            ;;
        esac
    done

    # finalize device case
    BOARDSH+="\t\t;;\n"

    unset device_properties_ref
done

# finalize board.json generation
BJSON="$(json_dump -i)"

echo "$BJSON" | jq -e 'length == 0' > /dev/null 2>&1 && {
    rm -f "$ROOT_PATH/etc/board.d/2-board_json_tpl"
    exit 0
}

[ "$SAVE_FILE" ] && {
    printf "%b\n" "$BJSON" > "$ROOT_PATH/etc/board.json"
    sed -i 's|## DEVICE_CUSTOM_OPTIONS ##|'"$BOARDSH"'|g' "$ROOT_PATH/etc/board.d/2-board_json_tpl"
    mv "$ROOT_PATH/etc/board.d/2-board_json_tpl" "$ROOT_PATH/etc/board.d/1-board_json"
}
