#!/bin/sh

siteman_hook() {
	local log_file="${PACK_DIR}site_manager.log"
    local enabled

    config_load "siteman"
    config_get_bool enabled "general" "enabled" "0"
    [ "$enabled" = "1" ] || return 0

	troubleshoot_init_log "Devices" "$log_file"
	ubus list site_manager.device &>/dev/null || {
            troubleshoot_add_log "UBUS method was not found" "$log_file"
    }

    troubleshoot_add_log "$(ubus -t 4 call site_manager.device list '{"verbose": true}')" "$log_file"
}

troubleshoot_hook_init siteman_hook