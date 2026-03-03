#!/usr/bin/env lua
-- Copyright (C) 2025 Teltonika

local SECTION = arg and arg[1] or ""
if SECTION == "" then
	io.stderr:write("Usage: wireless_reboot.lua <SECTION>\n")
	os.exit(2)
end

local uci = require "vuci.uci"
local util = require "vuci.util"
local jsonc = require "luci.jsonc"
local fs = require "nixio.fs"
local WDIR = "/var/run/preboot"
local REBOOT_COUNT_FILE = WDIR .. "/wireless_reboot_counter_" .. SECTION

local function log(msg)
	io.stderr:write(tostring(msg) .. "\n")
	os.execute("/usr/bin/logger -t wireless_reboot.lua %s" % util.shellquote(tostring(msg)))
end

local _s
local function get_cfg()
	if not _s then _s = uci:get_all("wireless_reboot", SECTION) end
	return _s
end

local function get_reboot_count()
	return tonumber(get_cfg().current_reboot_count or "") or 0
end

local function set_reboot_count(new_reboot_count)
	uci:set("wireless_reboot", SECTION, "current_reboot_count", tostring(new_reboot_count))
	uci:commit_without_event("wireless_reboot")
end

local function reboot_wireless(current_reboot_count)
	log("Rebooting wireless system, reboot number " .. tostring(current_reboot_count + 1))
	local res = util.ubus("wireless_reboot", "full_reset")
	if res.code ~= 0 then
		log("Failed to reboot wireless system. " .. jsonc.stringify(res))
		return false
	end
	set_reboot_count(current_reboot_count + 1)
	util.ubus("rpc-sys", "reboot", { args = { "-k" }, safe = true })
	return true
end

local function get_wireless_stats()
	return util.ubus("wireless_reboot", "get_stats")
end

local function is_reboot_count_reached(max_reboot_count)
	local reboot_count = get_reboot_count()
	if reboot_count == max_reboot_count then
		log("Maximum wireless reboot count reached, will no longer try to reboot wireless system. " ..
			jsonc.stringify({ reboot_count = reboot_count, max_reboot_count = max_reboot_count }))
	end
	return reboot_count >= max_reboot_count, reboot_count
end

local function main()
	fs.mkdirr(WDIR)
	local s = get_cfg()
	if not s then
		log(("Failed to load wireless_reboot section: %s"):format(SECTION))
		return 1
	end

	if s.enabled ~= "1" then return 0 end

	local cfg = {
		time = tonumber(s.time) or 0,
		reboot_count = tonumber(s.reboot_count) or 0,
		mcu_hang = tonumber(s.mcu_hang) or 0,
		beacon_stuck = tonumber(s.beacon_stuck) or 0,
	}
	for k, v in pairs(cfg) do
		if v <= 0 then
			log("Invalid configuration values: " .. jsonc.stringify(s))
			return 2
		end
	end

	local wireless_stats = get_wireless_stats()
	if not wireless_stats then
		log("Failed to get wireless stats")
		return 3
	end
	local reboot_count_reached, reboot_count = is_reboot_count_reached(cfg.reboot_count)

	if wireless_stats.mcu_hang >= cfg.mcu_hang or wireless_stats.beacon_stuck >= cfg.beacon_stuck then
		if reboot_count_reached then
			if cfg.reboot_count == reboot_count then
				set_reboot_count(reboot_count + 1) -- to avoid log spam
			end
			return 0
		end
		log("Threshold reached: " .. jsonc.stringify(wireless_stats))
		reboot_wireless(reboot_count)
		return 0
	elseif reboot_count > 0 then -- this means that previous wireless reboot helped, in that case reset reboot counter
		set_reboot_count(0)
	end
	return 0
end

local exit_code = main()
os.exit(exit_code)
