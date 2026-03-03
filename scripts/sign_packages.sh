#!/usr/bin/env bash
set -e

[[ -s $1 ]] || {
	echo "'$1' does not exist or is empty" >&2
	exit 1
}

usign=$(which usign 2>/dev/null) || usign=${STAGING_DIR_HOST:-$PWD/staging_dir/host}/bin/usign
key="${BUILD_KEY:-$PWD/key-build}"

while read -r file; do
	dir="$(dirname "$file")"
	base="$(basename "$file")"
	"$usign" -S -m "$file" -s "$key" -x "$dir/${base%.*}.sig"
done <"$1"

exit 0
