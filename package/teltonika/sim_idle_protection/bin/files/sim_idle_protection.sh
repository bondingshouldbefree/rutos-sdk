#!/bin/sh

. /usr/share/libubox/jshn.sh
. /lib/functions.sh

NAME=$(basename $0)
MAX_INSTANCE_RETRIES=180
MAX_WAIT_RETRIES=70
WAIT_SLEEP=2

# Error status
PING_SUCCESS=0
ERR_NETWORK_CONFIG_FAIL=100
ERR_SIM_IDLE_CONFIG_FAIL=101
ERR_PING_FAIL=102
ERR_CONN_FAIL=104
ERR_DISCONN_FAIL=105
MOBIFD_OBJ_NOT_FOUND=106
NO_SUITALBE_INTERFACES_FOUND=107
NO_SUITALBE_ACTIVE_INTERFACES_FOUND=108
NO_ACTIVE_SIM_FOUND=109
FLOCK_FAILED=110
WRONG_SIM=111

ESIM_ARG=0
SIM_ARG=0
MODEM_ARG=0
MODEM_OBJ=-1

INITIAL_SIM=0
INITIAL_ESIM=0
CURRENT_ACTIVE_SIM=0
CURRENT_ACTIVE_ESIM=0

# Interface name for pinging
MOBILE_INTERFACE_L3_DEVICE=0

usage() {
    local error="$1"
    [ -n "$error" ] && echo "$0: Invalid or insufficient arguments provided." 1>&2

    echo "Usage: $0 -s <SIM> -m <MODEM_USB_ID> -p [ESIM_PROFILE_ID]"
    echo
    echo "  -s <SIM>               SIM identifier (sim1, sim2, ...)"
    echo "  -m <MODEM_USB_ID>      Modem USB ID (1-1, 3-1, ...)"
    echo "  -p [ESIM_PROFILE_ID]   eSIM profile ID (0, 1, ...)"
    echo
    echo "Example: $0 -s sim1 -m 3-1 -p 0"
    exit 1
}

logprint() {
    logger -t "($$) $NAME" "$1"
}

log() {
    ubus call log write_ext "{
        \"event\": \"$1\",
        \"sender\": \"Sim Idle Protection\",
        \"table\": 2,
        \"write_db\": 1
    }"
}

# Get mobifd/gsmd interface used on port
find_mobifd_object() {
    local arg="$(ubus list gsm.modem*)"
    for object in $arg; do
        json_init
        json_load "$(ubus call $object info)"
        json_get_var usb_id usb_id

        if [ "$usb_id" == "$MODEM_ARG" ]; then
            MODEM_OBJ=$(echo $object | tail -c 2)
            break
        fi
    done

    [ $MODEM_OBJ -lt 0 ] && finish $MOBIFD_OBJ_NOT_FOUND
}

# Wait for GSM to report connectivity
wait_for_connection() {
    local count=0
    local state=$(gsmctl -j -O $MODEM_ARG)
    while [ "$state" = "Disconnected" ]; do
        state=$(gsmctl -j -O $MODEM_ARG)
        count=$((count + 1))
        sleep $WAIT_SLEEP
        [ $count -eq $MAX_WAIT_RETRIES ] && finish $ERR_CONN_FAIL
    done
}

# Wait for GSM to report disconnect
wait_for_disconnect() {
    local count=0
    local state=$(gsmctl -j -O $MODEM_ARG)
    while [ "$state" != "Disconnected" ]; do
        state=$(gsmctl -j -O $MODEM_ARG)
        count=$((count + 1))
        sleep $WAIT_SLEEP
        [ $count -eq $MAX_WAIT_RETRIES ] && finish $ERR_DISCONN_FAIL
    done
}

wait_for_interface() {
    local count=0
    local status=1
    logprint "Finding suitable interface"
    while [ "$status" != "0" ]; do
        found_up_interface
        [ "$?" == "1" ] || status=0
        count=$((count + 1))
        sleep $WAIT_SLEEP
        [ $count -eq $MAX_WAIT_RETRIES ] && finish $NO_SUITALBE_ACTIVE_INTERFACES_FOUND
    done
}

# Get current active sim card slot
get_active_sim_info() {
    json_init
    json_load "$(ubus call gsm.modem$MODEM_OBJ info)"
    json_select cache
    json_get_var CURRENT_ACTIVE_SIM sim
    json_get_var CURRENT_ACTIVE_ESIM esim_profile_id
    CURRENT_ACTIVE_ESIM=${CURRENT_ACTIVE_ESIM:-0} # Set default value to 0 in case there's no opt
    [ -z "$CURRENT_ACTIVE_SIM" ] && finish $NO_ACTIVE_SIM_FOUND
}

# Reset sim info to its initial state
reset_sim() {
    get_active_sim_info

    [[ $INITIAL_SIM != $CURRENT_ACTIVE_SIM || $INITIAL_ESIM != $CURRENT_ACTIVE_ESIM ]] && {
        logprint "Reloading mobifd to reset temporary SIM settings"
        ubus call mobifd.modem$MODEM_OBJ reload >/dev/null && wait_for_disconnect
    }
}

# Get l3_dev
get_l3_dev() {
    json_init
    json_load "$(ubus call network.interface.$1 status)"
    json_get_var MOBILE_INTERFACE_IS_UP up
    json_get_var MOBILE_INTERFACE_L3_DEVICE l3_device
}

# Load required options from sim_idle_protection config
sim_idle_config_load() {
    local sim_ping_m sim_ping_p sim_ping_e
    config_load "sim_idle_protection"

    [ -z "$CONFIG_SECTIONS" ] && finish $ERR_SIM_IDLE_CONFIG_FAIL

    for section in $CONFIG_SECTIONS; do
        config_get sim_ping_m $section modem
        config_get sim_ping_p $section position
        config_get sim_ping_e $section esim_profile

        sim_ping_e=${sim_ping_e:-0} # Set default value to 0

        if [[ "$sim_ping_m" == "$MODEM_ARG" && "$sim_ping_p" == "$SIM_ARG" && "$sim_ping_e" == "$ESIM_ARG" ]]; then
            config_get ping_ip $section host
            config_get ping_c $section count
            config_get ping_s $section packet_size
            config_get ping_t $section ip_type
            ping_t=$(echo $ping_t | tail -c 2)
            break
        fi
    done
}

# Found suitable interfaces from network config
found_suitable_interfaces() {
    config_load "network"

    [ -z "$CONFIG_SECTIONS" ] && finish $ERR_NETWORK_CONFIG_FAIL

    for section in $CONFIG_SECTIONS; do
        config_get cfgtype "$section" TYPE
        [ "$cfgtype" != "interface" ] && continue

        config_get sim "$section" sim
        [ -z "$sim" ] && continue

        config_get modem_id "$section" modem
        config_get pdptype "$section" pdptype
        config_get disabled "$section" disabled
        config_get esim_profile "$section" esim_profile

        esim_profile=${esim_profile:-0} # Set default value to 0

        [ "$sim" != "$SIM_ARG" ] || [ "$modem_id" != "$MODEM_ARG" ] || [ "$esim_profile" != "$ESIM_ARG" ] || [ -n "$disabled" ] && continue

        [ "$ping_t" == "4" ] && [[ "$pdptype" == "ip" || "$pdptype" == "ipv4v6" ]] && suitable_interface_list="$suitable_interface_list $section"
        [ "$ping_t" == "6" ] && [[ "$pdptype" == "ipv6" || "$pdptype" == "ipv4v6" ]] && suitable_interface_list="$suitable_interface_list $section"
    done

    [ -z "$suitable_interface_list" ] && finish $NO_SUITALBE_INTERFACES_FOUND
}

# Found active suitable interfaces
found_up_interface() {
    local status=1

    local all_interfaces=$(ubus list network.interface.* | xargs)

    for interface in $suitable_interface_list; do
        interface_obj="$interface"_"$ping_t"
        echo $all_interfaces | grep -q $interface_obj || continue
        get_l3_dev $interface_obj
        [ "$MOBILE_INTERFACE_IS_UP" != "1" ] && continue
        inter_ping_from_list="$inter_ping_from_list $MOBILE_INTERFACE_L3_DEVICE"
        status=0
    done

    return $status
}

# Simple ping method
ping_ip() {
    local status=1
    # If source interface is set to wwan and pining to 127.0.0.1 ping fails
    [ "$1" == "127.0.0.1" ] && interface=0 || interface=$5

    if ping -$4 $1 -W 1 -c $2 -s $3 -I $interface &>/dev/null
    then
        status=0
    fi

    return "$status"
}

# Ping from all active suitable interfaces
ping_ip_all() {
    local status=1

    wait_for_interface

    for inter in $inter_ping_from_list; do
        ping_ip "$ping_ip" "$ping_c" "$ping_s" "$ping_t" "$inter"

        [ "$?" == "1" ] && logprint "Failed to ping from interface $MOBILE_INTERFACE_L3_DEVICE" || status=0 && break
    done

    [ "$status" != "0" ] && finish $ERR_PING_FAIL
}

# Print error messages and reset sim
finish() {
    local option="$1"

    case "$option" in
    "$ERR_NETWORK_CONFIG_FAIL")
        logprint "Failed to load network config file"
        log "Ping failed"
        reset_sim
        exit "$option"
        ;;
    "$ERR_SIM_IDLE_CONFIG_FAIL")
        logprint "Failed to load sim_idle_protection config file"
        log "Ping failed"
        reset_sim
        exit "$option"
        ;;
    "$ERR_PING_FAIL")
        logprint "Ping failed"
        log "Ping failed"
        reset_sim
        exit "$option"
        ;;
    "$ERR_CONN_FAIL")
        logprint "Failed to make mobile data connection"
        log "Ping failed"
        reset_sim
        exit "$option"
        ;;
    "$ERR_DISCONN_FAIL")
        logprint "Failed to disconnect from current SIM $INITIAL_SIM"
        log "Ping failed"
        reset_sim
        exit "$option"
        ;;
    "$MOBIFD_OBJ_NOT_FOUND")
        logprint "Could not find mobifd object"
        log "Ping failed"
        exit "$option"
        ;;
    "$NO_SUITALBE_INTERFACES_FOUND")
        log "There is no mobile IPv$ping_t interface found. Ping failed"
        logprint "There is no mobile IPv$ping_t interface found. Ping failed"
        reset_sim
        exit "$option"
        ;;
    "$NO_ACTIVE_SIM_FOUND")
        log "Ping failed"
        logprint "Could not get current active SIM slot"
        reset_sim
        exit "$option"
        ;;
    "$PING_SUCCESS")
        logprint "Successfully pinged from SIM $CURRENT_ACTIVE_SIM"
        log "Successfully pinged from SIM $CURRENT_ACTIVE_SIM"
        reset_sim
        exit "$option"
        ;;
    "$WRONG_SIM")
        log "Failed to change SIM slot"
        logprint "Failed to change SIM slot"
        reset_sim
        exit "$option"
        ;;
    "$FLOCK_FAILED")
        log "Ping failed"
        logprint "sim_idle_protection flock failed"
        exit "$option"
        ;;
    *)
        logprint "Unknown error"
        reset_sim
        exit "$option"
        ;;
    esac
}

main() {

    # Find mobifd object
    find_mobifd_object

    # Get current sim slot
    get_active_sim_info
    INITIAL_SIM=$CURRENT_ACTIVE_SIM
    INITIAL_ESIM=$CURRENT_ACTIVE_ESIM

    # Load sim_idle_protection config
    sim_idle_config_load

    # Check if there is suitable interface and it's enabled
    found_suitable_interfaces

    # If current SIM slot is not that need ping from
    if [[ "$SIM_ARG" != "$INITIAL_SIM" || "$ESIM_ARG" != "$INITIAL_ESIM" ]]; then
        logprint "Switching to sim$SIM_ARG"
        ubus call mobifd.modem$MODEM_OBJ switch_sim '{"sim_id":'$SIM_ARG', "esim_index":'$ESIM_ARG'}' >/dev/null
        wait_for_disconnect
    fi

    logprint "Waiting for sim$SIM_ARG connection"
    wait_for_connection

    get_active_sim_info
    [[ "$CURRENT_ACTIVE_SIM" -ne "$SIM_ARG" || "$CURRENT_ACTIVE_ESIM" -ne "$ESIM_ARG" ]] && finish $WRONG_SIM

    ping_ip_all
    finish $PING_SUCCESS
}

sim_idle_lock() {
    local status=1
	flock -n 700 &> /dev/null
	if [ "$?" != "0" ]; then
	    exec 700>"$LOCK_FILE"
		flock 700
		if [ "$?" != "0" ]; then
			status=0
		fi
	fi
	return $status
}

while getopts ":s:m:p:" o; do
    case "${o}" in
    s)
        [[ ! $OPTARG =~ ^sim[0-9]+$ ]] && usage 1 # Format: sim1, sim2...
        SIM_ARG=$(echo $OPTARG | sed 's/[^0-9]*//g') # Extract number from sim string
        ;;
    m)
        MODEM_ARG=$OPTARG
        ;;
    p)
        [[ ! $OPTARG =~ ^[0-9]+$ ]] && usage 1 # Format: 0, 1, 2...
        ESIM_ARG=$OPTARG
        ;;
    *)
        usage
        ;;
    esac
done

[ "$SIM_ARG" == "0" ] && usage
[ "$MODEM_ARG" == "0" ] && usage

LOCK_FILE=/tmp/lock/sim_idle_$MODEM_ARG.lock

# Check if another instance is running
sim_idle_lock && finish $FLOCK_FAILED

main

return 0
