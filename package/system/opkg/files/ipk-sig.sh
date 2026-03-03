#!/bin/sh

rnd=$(cat /proc/sys/kernel/random/uuid)
sig="/tmp/.$rnd.sig"
check_f=/tmp/.$rnd.control+data
# shellcheck disable=2064
trap "rm -f $sig $check_f" INT TERM EXIT

ipk=$1
shasum=$2

[ -z "$ipk" ] && exit 1

tar -xzOf "$ipk" ./control+data.sig >"$sig" || exit 2

OK=$(tar -xzOf "$ipk" ./control.tar.gz ./data.tar.gz | tee "$check_f" | usign -V -m - -P /etc/opkg/keys -x "$sig" 2>&1) || exit 3
[ -z "$shasum" ] || echo "$shasum  $check_f" | sha256sum -c >/dev/null || exit 4
[ -z "$OK" ] || echo "$OK" >&2
