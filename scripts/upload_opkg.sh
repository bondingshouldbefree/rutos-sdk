#!/usr/bin/env bash

days=''
PACKAGES_ROOT=/home/admin/opkg_packages

help_and_exit() {
	printf "Usage: upload_opkg.sh [-c [MONTHS]] [ -d | -p ] DEVICE

Options:
	-c | --cleanup DAYS	Cleanup packages that are older than DAYS (default: 15).
					DEVICE argument is not required, all devices will be cleaned up.
	-d | --demo		Upload to OPKG test server
	-p | --production	Upload to OPKG production server

Arguments:
	DEVICE			Target name, e.g. RUT36

SSH credentials that are needed in the environment:
	{PRODUCTION | TEST}_SSH_PRIVATE_KEY
	{PRODUCTION | TEST}_SSH_HOST_KEY
	{PRODUCTION | TEST}_SSH_USER_HOST
	{PRODUCTION | TEST}_SSH_PORT
"
	exit 1
}

check_missing() {
	for var in "${SSH_PRIVATE_KEY}" "${SSH_HOST_KEY}" "${SSH_USER_HOST}" "${SSH_PORT}"; do
		[[ -z ${!var} ]] && echo "$var"
	done
}

cleanup() {
	local path=${1}/
	local mtime=+${2:-15}

	local df_cmd="df --block-size=1 --output=used '$path' | tail -n1"
	local fmt='%7d MB'

	ssh -p "${!SSH_PORT}" "${!SSH_USER_HOST}" "\
		b=\"\$($df_cmd)\" ;\
		d=1048576 ;\
		find '$path' -maxdepth 1 -type d -mtime '$mtime' -exec rm -r {} + ;\
		find '$path' -name wiki -type d -exec rm -rf {} + ;\
		a=\"\$($df_cmd)\" ;\
		printf \"Before:  $fmt\\nAfter:   $fmt\\nCleaned: $fmt\\n\" \"\$((b / d))\" \"\$((a / d))\" \"\$(((b - a) / d))\"
	"
}

while [ $# -gt 0 ]; do
	case $1 in
	--cleanup | -c)
		days=$((2))
		[ $days -lt 1 ] && days=
		shift 1
		;;
	--production | -p)
		prefix=PRODUCTION
		;;
	--demo | -d)
		prefix=TEST
		;;
	-*)
		help_and_exit
		;;
	*)
		PLATFORM="${1^^}"
		;;
	esac
	shift 1
done

[[ -z $prefix ]] && help_and_exit

SSH_PRIVATE_KEY="${prefix}_SSH_PRIVATE_KEY"
SSH_HOST_KEY="${prefix}_SSH_HOST_KEY"
SSH_USER_HOST="${prefix}_SSH_USER_HOST"
SSH_PORT="${prefix}_SSH_PORT"

missing=$(check_missing)
[[ -n $missing ]] && {
	#shellcheck disable=2086 # Splitting of 'missing' is intended here
	printf "Environment variable not found: %s\n" $missing
	help_and_exit
}

eval "$(ssh-agent -s)"
trap "ssh-agent -k" exit
ssh-add <(echo "${!SSH_PRIVATE_KEY}")
mkdir -p ~/.ssh
echo "${!SSH_HOST_KEY}" >~/.ssh/known_hosts

[[ -n $days ]] && {
	[[ $prefix == PRODUCTION ]] && {
		printf "%s cleanup is not allowed!\n" "$prefix"
		exit 1
	}
	cleanup "$PACKAGES_ROOT" "$days"
	exit 0
}

TOPDIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")/..")
[[ -d ${TOPDIR}/bin/packages ]] || {
	echo "No packages found"
	exit 0
}

TAG=${CI_COMMIT_TAG:-$(git describe | awk -F "-pm" '{print $1}')}
CLIENT=$(grep 'CONFIG_TLT_VERSIONING_CLIENT' .config | cut -d'=' -f2 | tr -d '"')
HASH=$(echo -n "${CLIENT}/${TAG}/${PLATFORM}" | sha256sum | awk '{print $1}')
FOLDER="$PACKAGES_ROOT/${HASH}"
LINK="$PACKAGES_ROOT/packages/${CLIENT}/${TAG}"

echo "OPKG URL: http://$([[ $prefix == TEST ]] && echo 'test.')opkg.teltonika-networks.com/${HASH}"

echo "UPLOADING TO ${!SSH_USER_HOST#*@}:"
ssh -p "${!SSH_PORT}" "${!SSH_USER_HOST}" "rm -fr ${FOLDER:?}"
ssh -p "${!SSH_PORT}" "${!SSH_USER_HOST}" "mkdir -p ${FOLDER} ${LINK} && ln -fs ${FOLDER} ${LINK}/${PLATFORM}" || exit 1
find "${TOPDIR}/bin/packages/" -type d -name pm_packages | while read -r pkg_dir; do
	scp -P "${!SSH_PORT}" "${pkg_dir}"/* "${!SSH_USER_HOST}:/${FOLDER}/" || exit $?
done
