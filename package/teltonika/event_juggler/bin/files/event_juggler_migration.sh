#!/bin/sh

[ -e /etc/config/iojuggler ] || [ -e /etc/config/events_reporting ] || exit 0

. /lib/functions.sh
. /lib/config/uci.sh

PACKAGE_NAME="event_juggler"
COUNT=1
LAST_ACTION_ID=0

list_find() {
	local list=$1
	local value=$2

	for v in $list; do
		[ "$v" = "$value" ] && return 0
	done

	return 1
}

uci_add_list_safe() {
	local config=$1
	local section=$2
	local option=$3
	local value=$4

	local list

	list=$(uci_get "$config" "$section" "$option")

	[ -n "$list" ] && {
		list_find "$list" "$value" && return
	}

	uci_add_list "$config" "$section" "$option" "$value"
}

move_base64_text() {
	local dest=$1
	local sec=$2
	local option=$3

	which openssl > /dev/null || return 1
	config_get text "$sec" text
	[ -n "$text" ] && text=$(echo -n "$text" | openssl enc -base64 -d -A)

	uci_set "$PACKAGE_NAME" "$dest" "$option" "$text"
}

move_option() {
	local dest=$1
	local sec=$2
	local old_option=$3
	local new_option=$4
	local value

	config_get value "$sec" "$old_option"
	uci_set "$PACKAGE_NAME" "$dest" "${new_option:-$old_option}" "$value"
}

move_list_cb() {
	local value=$1
	local dest=$2
	local new_option=$3
	local prefix=$4

	uci_add_list "$PACKAGE_NAME" "$dest" "$new_option" "${prefix:+${prefix}_}${value}"
}

move_list_ext() {
	local dest=$1
	local sec=$2
	local option=$3
	local new_option=$4
	local prefix=$5

	config_list_foreach "$sec" "$option" move_list_cb "$dest" "$new_option" "$prefix"
}

move_list() {
	move_list_ext "$1" "$2" "$3" "$3" "$4"
}

migrate_action_dout() {
	local inver copy
	local sec=$1
	local id=$2

	config_get invert "$sec" invert "0"
	config_get copy "$sec" copy
	
	uci_set "$PACKAGE_NAME" "$id" plugin out
	if [ "$invert" -eq 1 ]; then
		uci_set "$PACKAGE_NAME" "$id" "out_mode" "invert"
	elif [ -n "$copy" ]; then
		uci_set "$PACKAGE_NAME" "$id" "out_mode" "copy"
		uci_set "$PACKAGE_NAME" "$id" "out_copy" "$copy"

	else
		uci_set "$PACKAGE_NAME" "$id" "out_mode" "set"
	fi

	move_option "$id" "$sec" dest out_dest
	move_option "$id" "$sec" state out_state
	move_option "$id" "$sec" revert out_revert
	move_option "$id" "$sec" maintain out_maintain
}

migrate_action_sim_switch() {
	local sec=$1
	local id=$2

	uci_set "$PACKAGE_NAME" "$id" plugin sim_switch
	move_option "$id" "$sec" write_to_config sim_write
	move_option "$id" "$sec" flip sim_flip
	move_option "$id" "$sec" target sim_number
	move_option "$id" "$sec" modem_id sim_modem_id
}

migrate_action_exec() {
	local sec=$1
	local id=$2
	local path new_path bname

	uci_set "$PACKAGE_NAME" "$id" plugin exec
	move_option "$id" "$sec" ui_file_path exec_file_type
	move_option "$id" "$sec" arguments exec_arguments
	move_option "$id" "$sec" info_modem_id exec_info_modem_id

	config_get path "$sec" path
	[ -n "$path" ] && {
		[ -e "$path" ] || return 1

		bname=$(basename $path | sed "s/cbid.iojuggler.$sec.upload//")
		if [ -n "$bname" ]; then
			new_path="/etc/vuci-uploads/cbid.iojuggler.$id.upload${bname}"
			mv "$path" "$new_path"
		else
			new_path="$path"
		fi

		uci_set "$PACKAGE_NAME" "$id" exec_path "$new_path"
	}
}

migrate_action_profile() {
	local sec=$1
	local id=$2

	uci_set "$PACKAGE_NAME" "$id" plugin profile
	move_option "$id" "$sec" profile
}

migrate_action_rms() {
	local sec=$1
	local id=$2

	uci_set "$PACKAGE_NAME" "$id" plugin rms
	move_option "$id" "$sec" rms_on
}

migrate_action_http() {
	local sec=$1
	local id=$2
	local ui_params

	uci_set "$PACKAGE_NAME" "$id" plugin http
	move_option "$id" "$sec" url http_url
	move_option "$id" "$sec" post http_post
	move_list_ext "$id" "$sec" headers http_header
	move_option "$id" "$sec" verify http_verify
	move_option "$id" "$sec" info_modem_id http_info_modem_id

	config_get ui_params "$sec" ui_params 0
	uci_set "$PACKAGE_NAME" "$id" http_ui_params "$ui_params"
	if [ "$ui_params" -eq "1" ]; then
		move_base64_text "$id" "$sec" http_text
	else
		move_list_ext "$id" "$sec" params http_params
	fi
}

migrate_action_mqtt() {
	local sec=$1
	local id=$2

	uci_set "$PACKAGE_NAME" "$id" plugin mqtt
	move_option "$id" "$sec" tls mqtt_tls
	move_option "$id" "$sec" tls_type mqtt_tls_type
	move_option "$id" "$sec" certfile mqtt_certfile
	move_option "$id" "$sec" keyfile mqtt_keyfile
	move_option "$id" "$sec" cafile mqtt_cafile
	move_option "$id" "$sec" password mqtt_password
	move_option "$id" "$sec" username mqtt_username
	move_option "$id" "$sec" remote_port mqtt_port
	move_option "$id" "$sec" remote_addr mqtt_remote_addr
	move_option "$id" "$sec" qos mqtt_qos
	move_option "$id" "$sec" topic mqtt_topic
	move_option "$id" "$sec" keepalive mqtt_keepalive
	move_option "$id" "$sec" tls_insecure mqtt_tls_insecure
	move_option "$id" "$sec" psk mqtt_psk
	move_option "$id" "$sec" identity mqtt_identity
	move_option "$id" "$sec" info_modem_id mqtt_info_modem_id
	move_base64_text "$id" "$sec" mqtt_text
}

migrate_action_sms() {
	local sec=$1
	local id=$2

	uci_set "$PACKAGE_NAME" "$id" plugin sms
	move_option "$id" "$sec" phone sms_phone
	move_option "$id" "$sec" phone_group sms_group
	move_option "$id" "$sec" send_modem_id sms_modem_id
	move_option "$id" "$sec" info_modem_id sms_info_modem_id
	move_base64_text "$id" "$sec" sms_text
}

migrate_action_smtp() {
	local sec=$1
	local id=$2

	uci_set "$PACKAGE_NAME" "$id" plugin smtp
	move_option "$id" "$sec" email_group smtp_email_group
	move_option "$id" "$sec" subject smtp_subject
	move_list_ext "$id" "$sec" recipients smtp_recipients
	move_option "$id" "$sec" info_modem_id smtp_info_modem_id
	move_base64_text "$id" "$sec" smtp_text
}

migrate_condition_io() {
	local sec=$1
	local id=$2

	uci_set "$PACKAGE_NAME" "$id" plugin io
	move_option "$id" "$sec" name io_cond_name
	move_option "$id" "$sec" state io_cond_state
	move_option "$id" "$sec" acl io_cond_acl
	move_option "$id" "$sec" min io_cond_min
	move_option "$id" "$sec" max io_cond_max
	move_option "$id" "$sec" not io_cond_not
}

migrate_range_to_list() {
	local id=$1
	local option=$2
	local start=$3
	local end=$4
	local size=$5

	[ -n "$start" ] || return 1
	[ -n "$end" ] || return 1

	[ "$start" = "$end" ] && {
		uci_add_list "$PACKAGE_NAME" "$id" "$option" "$start"

		return
	}
	
	if [ "$start" -gt "$end" ]; then
		for i in $(seq "$start" "$size"); do
			uci_add_list "$PACKAGE_NAME" "$id" "$option" "$i"
		done

		for i in $(seq 0 "$end"); do
			uci_add_list "$PACKAGE_NAME" "$id" "$option" "$i"
		done
	else
		for i in $(seq "$start" "$end"); do
			uci_add_list "$PACKAGE_NAME" "$id" "$option" "$i"
		done
	fi
}

migrate_time_value() {
	local id=$1
	local start=$2
	local end=$3

	uci_set "$PACKAGE_NAME" "$id" "time_cond_start_time" "$start"
	uci_set "$PACKAGE_NAME" "$id" "time_cond_end_time" "$end"
}

migrate_condition_time() {
	local type value interval
	local sec=$1
	local id=$2
  
	uci_set "$PACKAGE_NAME" "$id" plugin time
	move_option "$id" "$sec" type time_old_type
	move_option "$id" "$sec" not time_cond_not
	move_option "$id" "$sec" month_override  time_cond_month_override
	move_option "$id" "$sec" ui_timetype

	config_get type $sec type
	[ -n "$type" ] || return 1

	config_get interval $sec ui_timetype 0
	if [ "$interval" -eq "1" ]; then
		config_get value $sec interval1
		config_get value2 $sec interval2
	else
		config_get value $sec value
		value2=$value
	fi

	[ -n "$value" ] && [ -n "$value2" ] || return 1

	case $type in
		minute)
			type="monthday"
			migrate_time_value "$id" "*:${value}" "*:${value2}"
			;;
		hour)
			[ "$interval" -eq "1" ] || {
				value="${value}:00"
				value2="${value2}:59"
			}

			type="monthday"
			migrate_time_value "$id" "$value" "$value2"
			;;
		weekday)
			migrate_range_to_list "$id" "time_cond_wday" "$value" "$value2" 6
			migrate_time_value "$id" "00:00" "23:59"
			;;
		monthday)
			migrate_range_to_list "$id" "time_cond_day" "$value" "$value2" 31
			migrate_time_value "$id" "00:00" "23:59"
			;;
		yearday)
			uci_set "$PACKAGE_NAME" "$id" "time_cond_start_yday" "${value}"
			uci_set "$PACKAGE_NAME" "$id" "time_cond_end_yday" "${value2}"
			migrate_time_value "$id" "00:00" "23:59"
			;;
	esac

	uci_set "$PACKAGE_NAME" "$id" time_cond_day_type "$type"
}

migrate_condition_bool() {
	local sec=$1
	local id=$2

	uci_set "$PACKAGE_NAME" "$id" plugin bool
	move_option "$id" "$sec" operator bool_operator
	move_option "$id" "$sec" not bool_not	
	move_list_ext "$id" "$sec" conditions bool_conditions condition
}

migrate_event_io() {
	local sec=$1
	local id=$2

	uci_set "$PACKAGE_NAME" "$id" plugin io
	move_option "$id" "$sec" name io_name
	move_option "$id" "$sec" trigger io_trigger
	move_option "$id" "$sec" inside io_inside
	move_option "$id" "$sec" acl io_acl
	move_option "$id" "$sec" min io_min
	move_option "$id" "$sec" max io_max
}

migrate_action_cb() {
	local sec=$1
	local type id

	config_get type $sec type
	config_get id $sec id
	[ -z "$id" ] && return 1
	[ "$LAST_ACTION_ID" -lt "$id" ] && LAST_ACTION_ID=$id

	id="action_${id}"
	uci_add "$PACKAGE_NAME" action "$id" || {
		echo "Failed to add action"

		return 1
	}

	move_option "$id" "$sec" ui_name name
	move_option "$id" "$sec" delay
	move_list "$id" "$sec" conditions condition
	uci_set "$PACKAGE_NAME" "$id" enabled 1
	uci_set "$PACKAGE_NAME" "$id" io_juggler 1

	case $type in
		dout)
			migrate_action_dout "$sec" "$id"
			;;
		sim_switch)
			migrate_action_sim_switch "$sec" "$id"
			;;
		script)
			migrate_action_exec "$sec" "$id"
			;;
		profile)
			migrate_action_profile "$sec" "$id"
			;;
		rms)
			migrate_action_rms "$sec" "$id"
			;;
		shutdown)
			uci_set "$PACKAGE_NAME" "$id" plugin shutdown
			;;
		reboot)
			uci_set "$PACKAGE_NAME" "$id" plugin reboot
			;;
		http)
			migrate_action_http "$sec" "$id"
			;;
		mqtt)
			migrate_action_mqtt "$sec" "$id"
			;;
		wifi)
			uci_set "$PACKAGE_NAME" "$id" plugin wifi
			move_option "$id" "$sec" wifi_on
			;;
		sms)
			migrate_action_sms "$sec" "$id"
			;;
		email)
			migrate_action_smtp "$sec" "$id"
			;;
		poweroff)
			uci_set "$PACKAGE_NAME" "$id" plugin shutdown
			;;
		*)
			echo "Unknown action type: $type"
			;;
	esac
}

migrate_condition_cb() {
	local sec=$1
	local type id new_sec

	config_get type $sec type
	[ -z "$type" ] && return 1

	config_get id $sec id
	[ -z "$id" ] && return 1

	new_sec="condition_${id}"
	uci_add "$PACKAGE_NAME" condition "$new_sec" || {
		echo "Failed to add condition"

		return 1
	}

	uci_set "$PACKAGE_NAME" "$new_sec" enabled 1
	uci_set "$PACKAGE_NAME" "$new_sec" io_juggler 1
	move_option "$new_sec" "$sec" ui_name name

	case $type in
		io|analog)
			migrate_condition_io "$sec" "$new_sec"
			;;
		minute|hour|weekday|monthday|yearday)
			migrate_condition_time "$sec" "$new_sec" "$type"
			;;
		bool)
			migrate_condition_bool "$sec" "$new_sec"
			;;
		*)
			echo "Unknown condition type: $type"
			;;
	esac
}

migrate_event_cb() {
	local sec=$1
	local cond actions v enabled

	id="event_$COUNT"

	uci_add "$PACKAGE_NAME" event "$id" || {
		echo "Failed to add event"

		return 1
	}

	uci_set "$PACKAGE_NAME" "$id" name "$id"
	uci_set "$PACKAGE_NAME" "$id" io_juggler 1
	move_option "$id" "$sec" wait
	move_option "$id" "$sec" ui_name
	move_option "$id" "$sec" enabled
	migrate_event_io "$sec" "$id"
	move_list "$id" "$sec" conditions condition
	move_list "$id" "$sec" actions action


	COUNT=$((COUNT + 1))
}

migrate_general_cb() {
	local sec=$1
	local enabled

	config_get enabled $sec enabled
	uci_set "$PACKAGE_NAME" general enabled "$enabled"
}

#Events Reporting functions

migrate_er_smtp_action() {
	local sec=$1
	local id=$2

	uci_set "$PACKAGE_NAME" "$id" plugin smtp
	move_option "$id" "$sec" emailgroup smtp_email_group
	move_option "$id" "$sec" subject smtp_subject
	move_option "$id" "$sec" message smtp_text
	move_option "$id" "$sec" info_modem_id smtp_info_modem_id
	move_list_ext "$id" "$sec" recipEmail smtp_recipients
}

migrate_er_sms_action() {
	local sec=$1
	local id=$2
	local recipient_format

	uci_set "$PACKAGE_NAME" "$id" plugin sms
	move_option "$id" "$sec" message sms_text
	move_option "$id" "$sec" info_modem_id sms_info_modem_id
	move_option "$id" "$sec" send_modem_id sms_modem_id

	config_get recipient_format $sec recipient_format
	[ -n "$recipient_format" ] || return 1

	uci_set "$PACKAGE_NAME" "$id" sms_recipient_format "$recipient_format"

	case $recipient_format in
		single)
			move_option "$id" "$sec" telnum sms_phone
			;;
		group)
			move_option "$id" "$sec" group sms_group
			;;
	esac
}

migrate_er_log_event() {
	local sec=$1
	local id=$2

	uci_set "$PACKAGE_NAME" "$id" plugin log
	move_option "$id" "$sec" event log_event
	move_option "$id" "$sec" eventMark log_event_mark
}

migrate_er_startup_event() {
	local sec=$1
	local id=$2
	local event_mark

	uci_set "$PACKAGE_NAME" "$id" plugin boot
	config_get event_mark "$sec" "eventMark"
	[ -n "$event_mark" ] || return 0

	case $event_mark in
		"Device startup completed")
			uci_set "$PACKAGE_NAME" "$id" boot_mode power_on
			;;
		"unexpected shutdown")
			uci_set "$PACKAGE_NAME" "$id" boot_mode reboot
			;;
		*)
			uci_set "$PACKAGE_NAME" "$id" boot_mode all
			;;
	esac
}

migrate_er_signal_event() {
	local sec=$1
	local id=$2
	local threshold=0
	local event_mark 

	config_get event_mark $sec eventMark
	[ -n "$event_mark" ] || return 1

	if [ "$event_mark" = "all" ]; then
		uci_add_list "$PACKAGE_NAME" "$id" "gsm_signal_range" "-49,0"
		uci_add_list "$PACKAGE_NAME" "$id" "gsm_signal_range" "-59,-50"
		uci_add_list "$PACKAGE_NAME" "$id" "gsm_signal_range" "-74,-60"
		uci_add_list "$PACKAGE_NAME" "$id" "gsm_signal_range" "-92,-75"
		uci_add_list "$PACKAGE_NAME" "$id" "gsm_signal_range" "-97,-93"
		uci_add_list "$PACKAGE_NAME" "$id" "gsm_signal_range" "-112,-98"
		uci_add_list "$PACKAGE_NAME" "$id" "gsm_signal_range" "-130,-113"
	else
		threshold=$(echo "$event_mark" | \
			awk '{for (i=1; i<=NF; i++) if ($i ~ /^-?[0-9]+$/) print $i}')
		[ -n "$threshold" ] || threshold=-40

		case $threshold in
			-50) uci_add_list "$PACKAGE_NAME" "$id" "gsm_signal_range" "-59,-50" ;;
			-60) uci_add_list "$PACKAGE_NAME" "$id" "gsm_signal_range" "-74,-60" ;;
			-75) uci_add_list "$PACKAGE_NAME" "$id" "gsm_signal_range" "-92,-75" ;;
			-93) uci_add_list "$PACKAGE_NAME" "$id" "gsm_signal_range" "-97,-93" ;;
			-98) uci_add_list "$PACKAGE_NAME" "$id" "gsm_signal_range" "-112,-98" ;;
			-113) uci_add_list "$PACKAGE_NAME" "$id" "gsm_signal_range" "-130,-113" ;;
			*) uci_add_list "$PACKAGE_NAME" "$id" "gsm_signal_range" "-49,0" ;;
		esac
	fi

	uci_set "$PACKAGE_NAME" "$id" plugin gsm
	uci_set "$PACKAGE_NAME" "$id" gsm_event rssi_value
	uci_set "$PACKAGE_NAME" "$id" gsm_signal_trigger range
	move_option "$id" "$sec" info_modem_num gsm_modem_id
}

migrate_rule_cb() {
	local sec=$1
	local action event

	config_get event $sec event
	[ -n "$event" ] || return 1

	id="event_$COUNT"

	uci_add "$PACKAGE_NAME" event "$id" || {
		echo "Failed to add event"

		return 1
	}

	LAST_ACTION_ID=$((LAST_ACTION_ID + 1))

	uci_set "$PACKAGE_NAME" "$id" name "$id"
	uci_set "$PACKAGE_NAME" "$id" events_reporting 1
	move_option "$id" "$sec" enable enabled
	uci_add_list_safe "$PACKAGE_NAME" "$id" actions "action_${LAST_ACTION_ID}"

	case $event in
		"Signal strength")
			migrate_er_signal_event "$sec" "$id"
			;;
		Startup)
			migrate_er_startup_event "$sec" "$id"
			;;
		*)
			migrate_er_log_event "$sec" "$id"
			;;
	esac
	

	id="action_${LAST_ACTION_ID}"
	uci_add "$PACKAGE_NAME" action "$id" || {
		echo "Failed to add event"

		return 1
	}

	uci_set "$PACKAGE_NAME" "$id" name "$id"
	uci_set "$PACKAGE_NAME" "$id" enabled 1
	uci_set "$PACKAGE_NAME" "$id" events_reporting 1

	config_get action $sec action
	[ -z "$action" ] && return 1

	case $action in
		sendEmail)
			migrate_er_smtp_action "$sec" "$id"
			;;
		sendSMS)
			migrate_er_sms_action "$sec" "$id"
			;;
		sendRMS)
			
			;;
	esac
	
	COUNT=$((COUNT + 1))
}

#Mirgrate iojugger > event_juggler
config_load iojuggler
config_foreach migrate_event_cb input
config_foreach migrate_condition_cb condition
config_foreach migrate_action_cb action
config_foreach migrate_general_cb general

#Migrate events_reporting > event_juggler
config_load events_reporting
config_foreach migrate_rule_cb rule

#Keep the old config until a stable version is released
#rm -rf /etc/config/iojuggler
#rm -rf /etc/config/events_reporting
mv /etc/config/iojuggler /etc/config/iojuggler.bak 2>/dev/null
mv /etc/config/events_reporting /etc/config/events_reporting.bak 2>/dev/null

uci commit "$PACKAGE_NAME"
