#!/bin/sh

. /usr/share/libubox/jshn.sh

run_profile_cmd() {
	cmd="$1"
	shift
	output="$(/usr/sbin/profile.sh "$cmd" "$@" 2>/dev/null)"
	if [ $? -eq 0 ]; then
		echo "$output"
		return 0
	elif [ -n "$output" ]; then
		echo "$output"
		return 1
	else
		json_init
		json_add_string "error" "profile command failed"
		json_dump
		return 1
	fi
}

main() {
	case "$1" in
	list)
		json_init
		json_add_object "create"
		json_add_string "name"
		json_add_boolean "template"
		json_close_object
		json_add_object "change"
		json_add_string "name"
		json_add_boolean "force"
		json_close_object
		json_add_object "update"
		json_close_object
		json_add_object "remove"
		json_add_string "name"
		json_close_object
		json_add_object "diff"
		json_add_string "name"
		json_close_object
		json_add_object "list"
		json_close_object
		json_dump
		;;
	call)
		case "$2" in
		create)
			local input name template
			read input
			json_load "$input"
			json_get_var name name
			json_get_var template template
			if [ "$template" -eq 1 ]; then
				run_profile_cmd -b "$name" -t
			else
				run_profile_cmd -b "$name"
			fi
			;;
		change)
			local input name force
			read input
			json_load "$input"
			json_get_var name name
			json_get_var force force
			if [ "$force" -eq 1 ]; then
				run_profile_cmd -c "$name" -f
			else
				run_profile_cmd -c "$name"
			fi
			;;
		update)
			run_profile_cmd -u
			;;
		remove)
			local input name
			read input
			json_load "$input"
			json_get_var name name
			run_profile_cmd -r "$name"
			;;
		diff)
			local input name
			read input
			json_load "$input"
			json_get_var name name
			run_profile_cmd -d "$name"
			;;
		list)
			run_profile_cmd -l
			;;
		esac
		;;
	esac
}

main "$@"
