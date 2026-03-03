#!/bin/sh

. /lib/functions.sh

CRONTAB_FILE=/etc/crontabs/preboot
REBOOT_FILE="/usr/libexec/reboot_utils/wireless_reboot.lua"
[ -x "$REBOOT_FILE" ] || REBOOT_FILE="$(awk '/^dest root / { if ($3 != "/") print $3 }' /etc/opkg.conf)$REBOOT_FILE"

check_rules() {
	config_get enabled "$1" "enabled" "0"
	[ "$enabled" -ne 1 ] && return

	config_get time "$1" "time" "0"

	case "${time}" in
	"30")
		echo "0,30 * * * * $REBOOT_FILE $1 " >>${CRONTAB_FILE}
		;;
	"60")
		echo "0 */1 * * * $REBOOT_FILE $1 " >>${CRONTAB_FILE}
		;;
	"120")
		echo "0 */2 * * * $REBOOT_FILE $1 " >>${CRONTAB_FILE}
		;;
	*)
		echo "*/$time * * * * $REBOOT_FILE $1 " >>${CRONTAB_FILE}
		;;
	esac
}

config_load 'wireless_reboot'
config_foreach check_rules 'wireless_reboot'
/etc/init.d/cron restart
