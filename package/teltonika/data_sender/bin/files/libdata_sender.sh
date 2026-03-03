. /lib/functions.sh

PLUGIN_FOUND=0

plugin_find_cb() {
    local sec="$1"
    local name="$2"
    local plugin

    config_get plugin "$sec" plugin
    [ -z "$plugin" ] && return

    [ "$plugin" = "$name" ] && PLUGIN_FOUND=1
}

ds_find_plugin() {
    local name="${1}"

    [ -z "$name" ] && return

	config_load data_sender
	config_foreach plugin_find_cb input "$name"

    [ "$PLUGIN_FOUND" -eq 1 ] && {
        PLUGIN_FOUND=0
        
        return 0
    }

    return 1
}

ds_remove_plugin_cfg() {
    local plugin_data="$1"

    [ -z "$plugin_data" ] && return 0
    config_load data_sender
  
    clear_collection() {
        local plugin_name="${plugin_data%%-*}"
        local plugin_type="${plugin_data#*-}"
        local no_inputs=true
        local coll_id="$1"

        delete_input() {
            config_get plugin "$1" plugin ""
            if [[ "$plugin" == "$plugin_name" ]]; then
                ubus call api delete "{ \"path\": \"/data_to_server/data/config/$1\" }"
            else
                no_inputs=false
            fi
        }
        
        if [[ "$plugin_type" != "in" ]]; then
            config_get output_id "$coll_id" output ""
            # handle plugin renaming ubus => azure, etc...
            local output_plugin=$(ubus call api get "{ \"path\": \"/data_to_server/collections/servers/config/$output_id\" }" | jsonfilter -e '@.http_body.data.plugin')
            if [[ "$output_plugin" == "$plugin_name" ]]; then
                ubus call api delete "{ \"path\": \"/data_to_server/collections/config/$coll_id\" }"
                return 0
            fi
        fi

        if [[ "$plugin_type" != "out" ]]; then
            config_list_foreach "$coll_id" input delete_input
            [ "$no_inputs" = true ] && ubus call api delete "{ \"path\": \"/data_to_server/collections/config/$coll_id\" }"
        fi
    }
  
    config_foreach clear_collection "collection"

    uci_commit data_sender 2> /dev/null
    /etc/init.d/data_sender reload 2> /dev/null
}
