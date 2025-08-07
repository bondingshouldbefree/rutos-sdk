#!/bin/bash

shopt -s globstar nullglob

prep_f_list() {
	local f=$1
	local dir=$2
	local pattern=$3

	del() {
		sed -i "/${2//\//\\\/}/d" "$1"
	}

	[[ -f $f ]] && {
		rm -f "$f".tmp
		cp "$f" "$f".tmp
		return
	}

	# Default behavior - find all images and package indexes
	find "$dir" -type f -name "$pattern" >"$f".tmp
	printf "Warning: File list '%s' not found, will sign all files:\n%s\n" "$f" "$(cat "$f".tmp)"
	del() { :; }

}

# directory where to search for packages
TOP_PKG_DIR="${TOP_DIR:-./bin}"
# directory where to search for images
TOP_DIR="${TOP_DIR:-./bin/targets}"
# key to sign images
BUILD_KEY="${BUILD_KEY:-key-build}"
# remove other signatures (added by e.g. buildbot)
REMOVE_OTHER_SIGNATURES="${REMOVE_OTHER_SIGNATURES:-1}"

unsigned_fws_f=./tmp/unsigned_fws
unsigned_pkgs_f=./tmp/unsigned_pkgs

prep_f_list "$unsigned_fws_f" "$TOP_DIR" '*_WEBUI.bin'
while read -r image; do
	# check if image supports metadata
	fwtool -i /dev/null "$image" || continue

	# remove all previous signatures
	[ -z "$REMOVE_OTHER_SIGNATURES" ] || while true; do
		fwtool -t -s /dev/null "$image" || break
	done

	# run same operation as build root does for signing
	cp "$BUILD_KEY.ucert" "$image.ucert"
	chmod u+w "$image.ucert"
	usign -S -m "$image" -s "$BUILD_KEY" -x "$image.sig"
	ucert -A -c "$image.ucert" -x "$image.sig"
	fwtool -S "$image.ucert" "$image" && del "$unsigned_fws_f" "$image"

	rm "$image.sig" "$image.ucert"
done <"$unsigned_fws_f".tmp

prep_f_list "$unsigned_pkgs_f" "$TOP_PKG_DIR" 'Packages'
while read -r pkg; do
	usign -S -m "$pkg" -s "$BUILD_KEY" && del "$unsigned_pkgs_f" "$pkg"
done <"$unsigned_pkgs_f".tmp
