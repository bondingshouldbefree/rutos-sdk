#!/bin/sh

event_juggler_hook() {

    /bin/ubus list event_juggler.* &>/dev/null || return 0

	local log_file="${PACK_DIR}event_juggler.log"

	troubleshoot_init_log "Event juggler" "$log_file"
	for event in $(/bin/ubus list event_juggler.* 2>/dev/null); do
		troubleshoot_add_log "$(/bin/ubus -t 4 call $event dump)" "$log_file"
	done
}

troubleshoot_hook_init event_juggler_hook
