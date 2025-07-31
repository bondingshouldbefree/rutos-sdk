#!/bin/sh

. /lib/functions.sh

printf "\n \
  ${CLR_YELLOW}╭─────────────────────────────────╮${CLR_RESET}\n \
  ${CLR_YELLOW}│${CLR_RESET}                                 ${CLR_YELLOW}│${CLR_RESET}\n \
  ${CLR_YELLOW}│${CLR_RESET}   ${CLR_RED}READ-ONLY ROOTFS IS ENABLED${CLR_RESET}   ${CLR_YELLOW}│${CLR_RESET}\n \
  ${CLR_YELLOW}│${CLR_RESET}                                 ${CLR_YELLOW}│${CLR_RESET}\n \
  ${CLR_YELLOW}│${CLR_RESET}   ${CLR_CYAN}Enable tmpfs on rootfs:${CLR_RESET}       ${CLR_YELLOW}│${CLR_RESET}\n \
  ${CLR_YELLOW}│${CLR_RESET}    - run '${CLR_GREEN}rwrootfs${CLR_RESET}' command     ${CLR_YELLOW}│${CLR_RESET}\n \
  ${CLR_YELLOW}│${CLR_RESET}                                 ${CLR_YELLOW}│${CLR_RESET}\n \
  ${CLR_YELLOW}╰─────────────────────────────────╯${CLR_RESET}\n\n"

rwrootfs() {
	[ -d /old_root ] && {
		echo "/old_root already exists: unable to mount rw rootfs"
		return 1
	}

	show_msg() {
		local message="$1"
		local err="$2"
		local status="$3"

		if [ $status -eq 0 ]; then
			color="${CLR_GREEN}"
			err=""
		else
			color="${CLR_RED}"
			err="(Error: $err)"
		fi

		echo -e " ${color}*${CLR_RESET} $message ... $err"
	}

	echo " - Preparing rw rootfs on tmpfs..."

	echo " - Populating /tmp/overlay..."

	local out="$(mkdir -p /tmp/overlay/upper 2>&1)"
	show_msg "Creating /tmp/overlay/upper" "$out" "$?"

	out="$(mkdir -p /tmp/overlay/work 2>&1)"
	show_msg "Creating /tmp/overlay/work" "$out" "$?"

	out="$(mkdir -p /tmp/overlay/root 2>&1)"
	show_msg "Creating /tmp/overlay/root" "$out" "$?"

	out="$(mount -t overlay overlay \
		     -o lowerdir=/,upperdir=/tmp/overlay/upper,workdir=/tmp/overlay/work \
		     /tmp/overlay/root 2>&1)"
	show_msg "Mounting /tmp/overlay/root" "$out" "$?"

	out="$(mkdir -p /tmp/overlay/root/old_root 2>&1)"
	show_msg "Creating /tmp/overlay/root/old_root" "$out" "$?"

	out="$(pivot_root /tmp/overlay/root /tmp/overlay/root/old_root 2>&1)"
	show_msg "Switching root to /tmp/overlay/root" "$out" "$?"

	out="$(mount -t proc proc /proc 2>&1)"
	show_msg "Mounting /proc" "$out" "$?"

	out="$(mount -t sysfs sysfs /sys 2>&1)"
	show_msg "Mounting /sys" "$out" "$?"

	echo " - Moving mounts..."
	while IFS= read -r line; do
		local mnt=$(echo "$line" | awk '{print $2}')

		# skip non /old_root mounts
		echo "$mnt" | grep -q "^/old_root" || continue

		# leave old root alone
		[ "${mnt#/old_root/}" = "/old_root" ] && continue

		# skip /dev/pts
		[ "${mnt#/old_root}" = "/dev/pts" ] && continue

		out="$(mount --move "$mnt" "${mnt#/old_root}" 2>&1)"
		show_msg "Moving $mnt" "$out" "$?"
	done < /proc/mounts

	# fix angry wpad
	[ -e /etc/init.d/wpad ] && /etc/init.d/wpad restart

	cd ~
}
