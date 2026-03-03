#!/bin/sh

. /lib/functions.sh

WDIR="/var/run/preboot"
CRONTAB_FILE=/etc/crontabs/preboot
CMD="/usr/sbin/ping_reboot.sh"

check_rules() {
    config_get enabled "$1" "enable" "0"
    [ "$enabled" -ne 1 ] && return

    config_get ping_port_type "$1" "ping_port_type" ""
    [ "$ping_port_type" = "ping_ip" ] && $CMD -p "$1" & # launch port mapping in background

    config_get time "$1" "time" "0"
    [ -e "${WDIR}/fail_counter_${1}" ] && 
            echo -n "" > "${WDIR}/fail_counter_${1}"

    case "${time}" in
    "30")
        echo "0,30 * * * * $CMD $1" >>${CRONTAB_FILE}
        ;;
    "60")
        echo "0 */1 * * * $CMD $1" >>${CRONTAB_FILE}
        ;;
    "120")
        echo "0 */2 * * * $CMD $1" >>${CRONTAB_FILE}
        ;;
    *)
        echo "*/$time * * * * $CMD $1" >>${CRONTAB_FILE}
        ;;
    esac
}

config_load 'ping_reboot'
config_foreach check_rules 'ping_reboot'
/etc/init.d/cron restart
