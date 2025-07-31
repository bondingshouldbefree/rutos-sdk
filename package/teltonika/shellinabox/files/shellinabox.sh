#!/bin/sh
title=""
paragraph=""
shell_cert="/var/run/shellinabox/certificate.pem"
shell_banner="/var/run/shellinabox/shellinabox.banner"
uhttpd_cert=$(uci -q get uhttpd.main.cert)
uhttpd_key=$(uci -q get uhttpd.main.key)
key_type=$(uci get uhttpd.defaults.key_type)
enable=$(uci -q get cli.status.enable)
wan_deny=0
wan_access=0
echo "$SERVER_ADDR" | grep -q -E '^192\.168\.|^10\.|^172\.(1[6-9]|2[0-9]|3[0-1])\.|^127\.' || {
	wan_access=$(uci -q get cli.status._cliWanAccess)
	[ "$wan_access" -eq "1" ] || wan_deny=1
}

if [ "$enable" -eq "1" ] && [ "$wan_deny" -eq "0" ]; then
	port=$(uci -q get cli.status.port)
	if [ "$wan_access" -eq "1" ]; then
		wan_port=$(uci -q get cli.status.wan_port)
		[ -n "$wan_port" ] && port="$wan_port"
	fi
	if [ -z "$port" ]; then
		port="4200-4220"
		uci -q set cli.status.port="$port"
		uci -q commit cli
	fi
	shell_limit=$(uci -q get cli.status.shell_limit)
	if [ -z "$shell_limit" ]; then
		shell_limit="5"
		uci -q set cli.status.shell_limit="$shell_limit"
		uci -q commit cli
	fi
	shells=$(ps | grep -v grep | grep -c shellinaboxd)
	if [ "$shells" -lt "$shell_limit" ]; then
		banner_opt=""
		banner_enabled="$(uci -q get system.banner.enabled)"
		if [ -n "$banner_enabled" ] && [ "$banner_enabled" -eq 1 ]; then
			echo -e "*** $(uci -q get system.banner.title) ***" > $shell_banner
			echo -e "\n$(uci -q get system.banner.message)" >> $shell_banner
			banner_opt="--banner="$shell_banner""
		fi
		if [ -n "$HTTPS" ]; then
			tmp_cert_file=$(mktemp)

			if openssl rsa -in "$uhttpd_key" -check 2>/dev/null > /dev/null; then
				cp "$uhttpd_key" "$tmp_cert_file"
			elif openssl ec -in "$uhttpd_key" -check 2>/dev/null > /dev/null; then
				openssl ec -in "$uhttpd_key" -outform PEM 2>/dev/null > "$tmp_cert_file"
			else
				openssl dsa -in "$uhttpd_key" -outform PEM 2>/dev/null > "$tmp_cert_file"
			fi

			if grep -q "[^[:print:][:blank:]]" "$uhttpd_cert"; then
				openssl x509 -inform DER -in "$uhttpd_cert" -outform PEM >> "$tmp_cert_file"
			else
				cat "$uhttpd_cert" >> "$tmp_cert_file"
			fi

			mv "$tmp_cert_file" "$shell_cert"
			chown shellinabox:shellinabox "$shell_cert"
			exec 3<"$shell_cert"
			/usr/sbin/shellinaboxd --disable-ssl-menu --cgi="${port}" --cert-fd=3 $banner_opt
		else
			/usr/sbin/shellinaboxd -t --cgi="${port}" $banner_opt
		fi
	else
		title="Too many active shell instances!"
		paragraph="Too many active shell instances! Close some shell instances and try again."
	fi
else
	title="CLI not enabled!"
	paragraph="CLI not enabled! Enable CLI and try again."
fi

rm -f "$shell_banner"

if [ -n "$title" ] && [ -n "$paragraph" ]; then
echo "Content-type: text/html"
echo ""
cat <<EOT
<!DOCTYPE html>
<html>
<head>
        <title>${title}</title>
</head>
<body>
        <p>${paragraph}</p>
</body>
</html>
EOT
fi
