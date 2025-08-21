#!/bin/sh

. /lib/functions.sh

CRONTAB_FILE='/etc/crontabs/preboot'
IDENTIFYING_STRING='# periodic_reboot'
REBOOT_SCRIPT='/usr/libexec/reboot_utils/periodic_reboot.sh'

get_month_last_day() {
    [ "$#" -ne 1 ] && return 0
    month=$1
    checked_day=0
    checked_day_multiplier=1
    while [ $checked_day -ne 1 ]
    do
        last_day=$checked_day
        checked_day=$(date +%d -d"$((`date +%Y`))-$month-27 00:00:$((86400*$checked_day_multiplier))")
        checked_day_multiplier=$((checked_day_multiplier+1))
    done
    return $last_day
}

generate_monthly_crontab_rule() {
    local time=$1
    local reboot=$2
    local month_day=$3
    local months=$4
    local force_last=$5
    local hour=$(echo "$time" | cut -d':' -f1)
    local minute=$(echo "$time" | cut -d':' -f2)

    [ -z "$hour" ] || [ -z "$minute" ] && {
        logger -t "periodic_reboot" "Invalid 'time' option"
        return
    }

    if [ "$force_last" -eq 1 ]; then
        # $months var contains integers delimeted by commas, parse it to an array
        months_arr=$(echo "$months" | awk -F',' '{ for( i=1; i<=NF; i++ ) print $i }')

        for month in $months_arr;
        do
            last_month_day=$(get_month_last_day $month; echo $?)
            if [ $month_day -gt $last_month_day ];
            then
                echo -e "$minute $hour $last_month_day $month * $reboot $IDENTIFYING_STRING" >> "$CRONTAB_FILE"
            else
                echo -e "$minute $hour $month_day $month * $reboot $IDENTIFYING_STRING" >> "$CRONTAB_FILE"
            fi
        done
    else
        echo -e "$minute $hour $month_day $months * $reboot $IDENTIFYING_STRING" >> "$CRONTAB_FILE"
    fi
}

generate_weekly_crontab_rule() {
    local time=$1
    local days=$2
    local reboot=$3
    local hour=$(echo "$time" | cut -d':' -f1)
    local minute=$(echo "$time" | cut -d':' -f2)

    [ -z "$hour" ] || [ -z "$minute" ] && {
        logger -t "periodic_reboot" "Invalid 'time' option"
        return
    }

    echo -e "$minute $hour * * $days $reboot $IDENTIFYING_STRING" >>"$CRONTAB_FILE"
}

generate_instance() {
    local enable
    local period="week"
    local time
    local days
    local months
    local month_day
    local force_last=0

    config_get enable "$1" enable 0
    [ "$enable" -eq 1 ] || return

    config_get period "$1" period
    case $period in
        week)
            config_get days "$1" days
            [[ -z "$days" ]] && logger -t "periodic_reboot" "No 'days' option" && return

            config_list_foreach "$1" "time" generate_weekly_crontab_rule "$days" "$REBOOT_SCRIPT $1"
        ;;
        month)
            config_get force_last "$1" force_last $force_last

            config_get month_day "$1" month_day
            [[ -z "$month_day" ]] && logger -t "periodic_reboot" "No 'month_day' option" && return
            config_get months "$1" months
            [[ -z "$months" ]] && logger -t "periodic_reboot" "No 'months' option" && return

            config_list_foreach "$1" "time" generate_monthly_crontab_rule "$REBOOT_SCRIPT $1" "$month_day" "$months" "$force_last"
        ;;
    esac
}

config_load periodic_reboot
config_foreach generate_instance "reboot_instance"
/etc/init.d/cron restart
