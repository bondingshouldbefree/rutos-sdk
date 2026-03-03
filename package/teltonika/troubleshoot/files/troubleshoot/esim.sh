#!/bin/sh

pretty_print() {
	local json_data="$1" log_file="$2" count i profile
	count=$(echo "$json_data" | jsonfilter -e '@.response[*]' | wc -l)
	i=0
	troubleshoot_add_log "PROFILES" "$log_file"
	troubleshoot_add_log "[" "$log_file"
	while [ $i -lt "$count" ]; do
		profile=$(echo "$json_data" | jsonfilter -e "@.response[$i]")
		troubleshoot_add_log "\t $profile" "$log_file"
		i=$((i + 1))
	done
	troubleshoot_add_log "]" "$log_file"
}

esim_hook() {
	local log_file="${PACK_DIR}esim.log" mdm modem resp res eid
	troubleshoot_init_log "eSIM INFORMATION" "$log_file"
	#iterating each modem ubus object
	for mdm in $(ubus list | grep "gsm.modem"); do
		modem=${mdm##*.}
                troubleshoot_add_log "INFO for $modem" "$log_file"
		resp=$(timeout 10 lpac "$modem" "get-eid" 2>/dev/null | tail -n 1)
		if [ -z "$resp" ]; then
			troubleshoot_add_log "No eSIM detected" "$log_file"        
			continue
		fi
		res="$(jsonfilter -s "$resp" -e '@.result')"
		if [ "$res" = "0" ]; then
			eid="$(jsonfilter -s "$resp" -e '@.response.eid')"
			troubleshoot_add_log "EID $eid" "$log_file"
			resp=$(timeout 10 lpac "$modem" "get-profiles" 2>/dev/null | tail -n 1)
			res="$(jsonfilter -s "$resp" -e '@.result')"
			if [ "$res" = "0" ]; then
				pretty_print "$resp" "$log_file"                       
			else
				troubleshoot_add_log "Failed to get profiles" "$log_file"
			fi
		else
			troubleshoot_add_log "No eSIM detected" "$log_file"        
		fi        
	done
}

troubleshoot_hook_init esim_hook
