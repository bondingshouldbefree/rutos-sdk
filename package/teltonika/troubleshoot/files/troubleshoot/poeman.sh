poe_hook() {
    local log_file="${PACK_DIR}poe.log"
    local poeman_info poeman_dump
    local poe="$(jsonfilter -i /etc/board.json -e '$.hwinfo.poe')"

    is_executable "poeman" && [ "$poe" = "true" ] || return
    poeman_dump="$(ubus -t 2 call poeman dump 2>/dev/null)"
    [ -n "$poeman_dump" ] && {
        troubleshoot_init_log "PoE Dump" "$log_file"
        troubleshoot_add_log "$poeman_dump" "$log_file"
    }

    poeman_info="$(ubus -t 2 call poeman info 2>/dev/null)"
    [ -n "$poeman_info" ] && {
        troubleshoot_init_log "PoE Info" "$log_file"
        troubleshoot_add_log "$poeman_info" "$log_file"
    }

    [ -z "$poeman_dump" ] && [ -z "$poeman_info" ] && {
        local poeman="$(poeman -c)"
        troubleshoot_init_log "PoE Faults" "$log_file"
        troubleshoot_add_log "$poeman" "$log_file"
    }
}

troubleshoot_hook_init poe_hook
