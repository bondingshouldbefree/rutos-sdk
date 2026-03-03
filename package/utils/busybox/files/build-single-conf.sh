#!/bin/sh
# This is a stripped version of make_single_applets.sh provded by the BusyBox.
#
# This script expects that the tree was built with the desired .config:
# in particular, it expects that include/applets.h is generated already.
#
# The script will try to rebuild each enabled applet in isolation.
# All other options which chose general bbox config, applet features, etc,
# are not modified for the builds.

# The list of all applet config symbols
test -f include/applets.h || { echo "No include/applets.h file"; exit 1; }
apps="`
grep ^IF_ include/applets.h \
| grep -v '^IF_FEATURE_' \
| sed 's/IF_\([A-Z0-9._-]*\)(.*/\1/' \
| grep -v '^BUSYBOX$' \
| sort | uniq
`"

# Take existing config
test -f .config || { echo "No .config file"; exit 1; }
cfg="`cat .config`"

# Make a config with all applet symbols off
allno="$cfg"
for app in $apps; do
	allno="`echo "$allno" | sed "s/^CONFIG_${app}=y\$/# CONFIG_${app} is not set/"`"
done
# remove "busybox" as well
allno="`echo "$allno" | sed "s/^CONFIG_BUSYBOX=y\$/# CONFIG_BUSYBOX is not set/"`"
# disable any CONFIG_script_DEPENDENCIES as well
allno="`echo "$allno" | sed "s/^\(CONFIG_.*_DEPENDENCIES\)=y\$/# \1 is not set/"`"
#echo "$allno" >.config_allno

trap 'test -f .config.SV && mv .config.SV .config && touch .config' EXIT

# Turn on each applet individually and build single-applet executable
# (give config names on command line to build only those)
test $# = 0 && set -- $apps
fail=0
for app; do
	# Only if it was indeed originally enabled...
	{ echo "$cfg" | grep -q "^CONFIG_${app}=y\$"; } || continue

	echo "Making ${app}..."
	mv .config .config.SV
	echo "CONFIG_${app}=y" >.config
	echo "$allno" | sed "/^# CONFIG_${app} is not set\$/d" >>.config

	if test x"${app}" != x"SH_IS_ASH" && test x"${app}" != x"SH_IS_HUSH"; then
		# $allno has all choices for "sh" aliasing set to off.
		# "sh" aliasing defaults to "ash", not none.
		# without this fix, "make oldconfig" sets it wrong,
		# resulting in NUM_APPLETS = 2 (the second applet is "sh")
		sed '/CONFIG_SH_IS_NONE/d' -i .config
		echo "CONFIG_SH_IS_NONE=y" >>.config
	fi

	if ! yes '' | make oldconfig >busybox_make_${app}.log 2>&1; then
		fail=$((fail+1))
		echo "Config error for ${app}"
	fi

	mv .config busybox_config_${app}
done
touch .config # or else next "make" can be confused
echo "Failures: $fail"
test $fail = 0 # set exitcode
