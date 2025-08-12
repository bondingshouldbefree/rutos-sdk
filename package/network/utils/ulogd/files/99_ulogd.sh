#!/bin/sh

. /lib/functions.sh

#Changing file and logfile paths due to root access removal

config_load ulogd
config_get file emu1 file
config_get logfile global logfile

[ -n "$file" ] && [ "$file" = "/var/log/ulogd_wifi.log" ] && {
	uci -q set ulogd.emu1.file=/var/run/ulogd/ulogd_wifi.log
}

[ -n "$logfile" ] && [ "$logfile" = "/var/log/ulogd.log" ] && {
	uci -q set ulogd.global.logfile=syslog
}

uci -q commit ulogd
