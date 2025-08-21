#!/bin/sh

[ -n "$INCLUDE_ONLY" ] || {
	. /lib/functions.sh
	. /lib/netifd/netifd-proto.sh
	init_proto "$@"
}

append_args() {
	while [ $# -gt 0 ]; do
		append cmdline "'${1//\'/\'\\\'\'}'"
		shift
	done
}

proto_openconnect_init_config() {
	proto_config_add_string "server"
	proto_config_add_string "ca_cert"
	proto_config_add_string "user_cert"
	proto_config_add_string "user_key"
	proto_config_add_int "port"
	proto_config_add_string "uri"
	proto_config_add_int "mtu"
	proto_config_add_int "juniper"
	proto_config_add_int "reconnect_timeout"
	proto_config_add_string "vpn_protocol"
	proto_config_add_boolean "pfs"
	proto_config_add_boolean "no_dtls"
	proto_config_add_string "interface"
	proto_config_add_string "username"
	proto_config_add_string "serverhash"
	proto_config_add_string "authgroup"
	proto_config_add_string "usergroup"
	proto_config_add_string "password"
	proto_config_add_string "password2"
	proto_config_add_string "token_mode"
	proto_config_add_string "token_secret"
	proto_config_add_string "token_script"
	proto_config_add_string "os"
	proto_config_add_string "csd_wrapper"
	proto_config_add_string "proxy"
	proto_config_add_array 'form_entry:regex("[^:]+:[^=]+=.*")'
	proto_config_add_string "script"
	no_device=1
	available=1
}

proto_openconnect_add_form_entry() {
	[ -n "$1" ] && append_args --form-entry "$1"
}

proto_openconnect_setup() {
	local config="$1"
	local tmpfile="/tmp/openconnect-server.$$.tmp"

	json_get_vars \
		authgroup \
		csd_wrapper \
		form_entry \
		interface \
		juniper \
		vpn_protocol \
		mtu \
		no_dtls \
		os \
		password \
		password2 \
		pfs \
		port \
		proxy \
		reconnect_timeout \
		server \
		uri \
		serverhash \
		token_mode \
		token_script \
		token_secret \
		usergroup \
		username \
		script \
		ca_cert \
		user_cert \
		user_key

	ifname="opc-$config"

	proto_set_user openconnect

	logger -t openconnect "initializing..."

	[ -n "$interface" ] && {
		local trials=5

		[ -n $uri ] && server=$(echo $uri | awk -F[/:] '{print $4}')

		logger -t "openconnect" "adding host dependency for $server at $config"
		while resolveip -t 10 "$server" > "$tmpfile" && [ "$trials" -gt 0 ]; do
			sleep 5
			trials=$((trials - 1))
		done

		if [ -s "$tmpfile" ]; then
			for ip in $(cat "$tmpfile"); do
				logger -t "openconnect" "adding host dependency for $ip at $config"
				proto_add_host_dependency "$config" "$ip" "$interface"
			done
		fi
		rm -f "$tmpfile"
	}

	[ -n "$port" ] && port=":$port"
	[ -z "$uri" ] && uri="$server$port"

	append_args "$uri" -i "$ifname" --non-inter --syslog
	[ -n "$script" ] && append_args --script "$script"
	[ "$pfs" = 1 ] && append_args --pfs
	[ "$no_dtls" = 1 ] && append_args --no-dtls
	[ -n "$mtu" ] && append_args --mtu "$mtu"

	# get key paths from config
	[ -f "$ca_cert" ] && {
		append_args --cafile "$ca_cert"
		append_args --no-system-trust
	}
	[ -f "$user_cert" ] && {
		append_args -c "$user_cert"
	}
	[ -f "$user_key" ] && {
		local tpm_handle
		local key_path="$user_key"
		tpm_handle="$(/bin/tpm2_importer "$key_path" get_handle 2> /dev/null)" && key_path="handle:$tpm_handle"
		append_args --sslkey "$key_path"
	}

	[ "${juniper:-0}" -gt 0 ] && [ -z "$vpn_protocol" ] && {
		vpn_protocol="nc"
	}

	[ -n "$vpn_protocol" ] && {
		append_args --protocol "$vpn_protocol"
	}

	[ -n "$serverhash" ] && {
		append_args "--servercert=$serverhash"
		append_args --no-system-trust
	}
	[ -n "$authgroup" ] && append_args --authgroup "$authgroup"
	[ -n "$usergroup" ] && append_args --usergroup "$usergroup"
	[ -n "$username" ] && append_args -u "$username"
	[ -n "$password" ] || [ "$token_mode" = "script" ] && {
		umask 077
		mkdir -p /var/etc
		pwfile="/var/etc/openconnect-$config.passwd"
		[ -n "$password" ] && {
			echo "$password" > "$pwfile"
			[ -n "$password2" ] && echo "$password2" >> "$pwfile"
		}
		[ "$token_mode" = "script" ] && {
			$token_script >> "$pwfile" 2> /dev/null || {
				logger -t openconenct "Cannot get password from script '$token_script'"
				proto_setup_failed "$config"
			}
		}
		chown openconnect:openconnect "$pwfile"
		append_args --passwd-on-stdin
	}

	[ -n "$token_mode" -a "$token_mode" != "script" ] && append_args "--token-mode=$token_mode"
	[ -n "$token_secret" ] && append_args "--token-secret=$token_secret"
	[ -n "$os" ] && append_args "--os=$os"
	[ -n "$csd_wrapper" ] && [ -x "$csd_wrapper" ] && append_args "--csd-wrapper=$csd_wrapper"
	[ -n "$proxy" ] && append_args "--proxy=$proxy"
	[ -n "$reconnect_timeout" ] && append_args "--reconnect-timeout=$reconnect_timeout"

	json_for_each_item proto_openconnect_add_form_entry form_entry

	proto_export INTERFACE="$config"
	logger -t openconnect "executing 'openconnect $cmdline'"
	ip tuntap add "$ifname" mode tun user openconnect
	if [ -f "$pwfile" ]; then
		eval "proto_run_command '$config' openconnect-wrapper '$pwfile' $cmdline"
	else
		eval "proto_run_command '$config' openconnect $cmdline"
	fi
}

proto_openconnect_teardown() {
	local config="$1"

	pwfile="/var/etc/openconnect-$config.passwd"

	rm -f $pwfile
	logger -t openconnect "bringing down openconnect"
	proto_kill_command "$config" 2
	sleep 5
	ip link del "opc-$config"
}

[ -n "$INCLUDE_ONLY" ] || {
	add_protocol openconnect
}
