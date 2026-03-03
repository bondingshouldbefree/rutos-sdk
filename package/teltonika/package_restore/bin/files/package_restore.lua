#!/usr/bin/env lua
-- Copyright (C) 2024 Teltonika

local fs = require "nixio.fs"
local nixio = require "nixio"
local util = require "vuci.util"
local opkg = require "vuci.opkg"
local OpkgPkg = require "vuci.opkg_pkg"
local o_utils = require "vuci.opkg_utils"

local PACKAGE_FILE = "/etc/package_restore.txt"
local BACKUP_PACKAGES = "/etc/backup_packages/"
local FAILED_PACKAGES = "/etc/package_restore/failed_packages"
local THIRD_PARTY_FEEDS = "/etc/opkg/openwrt/distfeeds.conf"
local TLT_PACKAGES = "/var/opkg-lists/tlt_packages"
local TIME_OF_SLEEP = 10
local MAX_RETRIES = 3
local PKG_REBOOT = false
local PKG_NET_RESTART = false

local qt = util.shellquote

local app_names_with_tlt_names = {}
local function add_to_failed_packages(app_name)
	local f = io.open(FAILED_PACKAGES, "a+")
	if f then
		local line = app_names_with_tlt_names[app_name]
		if line then
			f:write(line .. "\n")
		end
		f:close()
	end
end

local function trigger_pkg_event_msg(pkg, type)
	opkg._trigger_pkg_event({ 
		package = pkg.app_name,
		name = (pkg and pkg.get and pkg:get("tlt_name")) or nil,
		messages = (pkg and pkg.get_pkg_msgs and pkg:get_pkg_msgs()) or nil,
		type = type
	})
end

-- handles file locking when calling opkg to avoid opkg lock conflicts with api
local function opkg_cmd(cmd, packages, options)
	while fs.access("/var/lock/opkg.lock") do
		nixio.nanosleep(TIME_OF_SLEEP)
	end

	local ok, lock_file = opkg.acquire_lock()
	assert(ok, "lock error")

	local code, res = o_utils.opkg_call(cmd, packages, options)

	lock_file:lock("ulock")
	lock_file:close()

	return code
end

local function opkg_install(packages, options)
	return opkg_cmd("install", packages, options)
end

local function opkg_update(options)
	return opkg_cmd("update", nil, options)
end


local function file_cleanup(file)
	util.perror("Cleaning up file " .. file)
	local f = io.open(file, "w")

	if not f then
		util.perror("Failed to open file " .. file)
		return
	end

	f:write("")
	f:close()
end

local function __DBG(fmt, ...)
	local msg = fmt:format(...)
	util.perror("> " .. msg)
end

local function DBG(fmt, ...)
	return
end

for i, v in ipairs(arg) do
	if v == "--debug" or v == "-d" then
		DBG = __DBG
	end
end

-------------- BACKUP PACKAGE INSTALL -----------------------
DBG("Starting backup package installation")
local backup_pkgs = {}

for file in fs.glob(BACKUP_PACKAGES .. "*.ipk") do
	util.exec("tar x -zf %s -C %s ./control.tar.gz" % {qt(file), BACKUP_PACKAGES})
	util.exec("tar x -zf %s -C %s ./control" % {BACKUP_PACKAGES .. "control.tar.gz", BACKUP_PACKAGES})
	if (fs.readfile(BACKUP_PACKAGES .. "control") or ""):find("tlt_name", nil, true) then
		-- main pkg has tlt_name, it must be first in the list to install correctly
		table.insert(backup_pkgs, 1, file)
		DBG("Backup package found: %s", file)
	else
		table.insert(backup_pkgs, file)
		DBG("3rd party backup package found: %s", file)
	end
end

if #backup_pkgs > 0 then
	util.perror("Installing backup packages")
	opkg_install(backup_pkgs)
	util.exec("rm -rf %s 2> /dev/null" % BACKUP_PACKAGES)
	opkg._trigger_pkg_event()
	opkg._restart_services()
end

--------------- MAIN PACKAGE INSTALL -----------------------
local pkg_text = util.trim(fs.readfile(PACKAGE_FILE) or "")
if #pkg_text == 0 then
	util.perror("Nothing to install")
	os.exit(0)
end

local third_party_pkg_names = {}
local app_names = {}
for _, line in ipairs(util.split(pkg_text)) do
	DBG("Processing line: " .. line)
	local pkg_name, tlt_name = line:match("^(.-)%s%-%s(.+)$")
	if not pkg_name then
		pkg_name = line
		tlt_name = nil
	end

	if pkg_name and tlt_name then
		app_names_with_tlt_names[pkg_name] = line
		table.insert(app_names, pkg_name)
		DBG("Preparing to install package: %s", pkg_name)
	else
		table.insert(third_party_pkg_names, line)
		DBG("Preparing to install 3rd party package: %s", line)
	end
end
if #app_names == 0 and #third_party_pkg_names == 0 then
	util.perror("No packages to install")
	os.exit(0)
end

while true do
	if o_utils.opkg_server_reachable() then
		opkg_update()
		if fs.access(TLT_PACKAGES) then
			local tlt_packages_stat = fs.stat(TLT_PACKAGES)
			local size = tlt_packages_stat and tlt_packages_stat.size or 0
			if size > 0 then break end
		end
	end
	nixio.nanosleep(TIME_OF_SLEEP)
end

do
	local retries = 0
	local pkg_list = {}
	while true do
		-- sometimes pkg list file doesn't appear instantly after opkg update - need to try a few times
		pkg_list = o_utils.get_pkg_list_by_app_name()
		retries = retries + 1
		if next(pkg_list) or retries >= 10 then
			break
		end
		nixio.nanosleep(3)
	end
end

local packages = {}
for _, app_name in ipairs(app_names) do
	util.perror("Validating package: " .. app_name)
	local pkg = OpkgPkg.get_available_pkg(app_name)
	if pkg then
		if pkg:is_installed() then
			util.perror("Package " .. pkg.app_name .. " is already installed")
			pkg:_remove_pkg_from_pkg_restore()
		else
			table.insert(packages, pkg)
		end
	else
		util.perror("Package " .. app_name .. " not found in opkg")
		add_to_failed_packages(app_name)
		trigger_pkg_event_msg({app_name = app_name}, opkg.PKG_TYPES.PENDING_ERRORED)
	end
end

-- Reverse the packages array in place
local i, j = 1, #packages
while i < j do
	packages[i], packages[j] = packages[j], packages[i]
	i = i + 1
	j = j - 1
end

for i = 1, MAX_RETRIES do -- retry pkg install 3 times in case pkg install fails
	for j = #packages, 1, -1 do
		(function ()
			local pkg = packages[j]
			local ok, err_code = pkg:_validate_pkg_online_install()
			if not ok then
				if i == MAX_RETRIES then
					add_to_failed_packages(pkg.app_name)
					trigger_pkg_event_msg(pkg, opkg.PKG_TYPES.PENDING_ERRORED)
				end
				return --continue
			end
			util.perror("Installing package %s" % pkg.app_name)
			ok, err_code = pkg:_install_package_online()
			if not ok then
				if i == MAX_RETRIES then
					add_to_failed_packages(pkg.app_name)
					trigger_pkg_event_msg(pkg, opkg.PKG_TYPES.PENDING_ERRORED)
				end
				return --continue
			end
			trigger_pkg_event_msg(pkg, opkg.PKG_TYPES.INSTALLED)
			table.remove(packages, j)
			opkg._restart_services()
			if pkg:get("pkg_reboot") == "1" or pkg:get("pkg_reboot") == true then PKG_REBOOT = true end
			if pkg:get("pkg_network_restart") == "1" or pkg:get("pkg_network_restart") == true then PKG_NET_RESTART = true end

			pkg:_remove_pkg_from_pkg_restore()
		end)()
	end
end

--------------- 3RD PARTY PACKAGE INSTALL -----------------------
local uci = require "vuci.uci".cursor()
local third_party_pkg = uci:get("package_restore" , "package_restore", "3rd_party_pkg") == "1"
if third_party_pkg then
	util.perror("3rd party packages installation started\n")
	while true do
		util.perror("Waiting for opkg update to finish...")
		opkg_update({"--force_feeds", THIRD_PARTY_FEEDS})
		if fs.access("/var/opkg-lists/openwrt_packages") then break end
		nixio.nanosleep(TIME_OF_SLEEP)
	end

	for _, pkg_name in ipairs(third_party_pkg_names) do
		util.perror("Installing package " .. pkg_name)
		local is_installed = opkg.pkg_installed(pkg_name)
		if not is_installed then
			opkg_install(pkg_name, {"--force_feeds", THIRD_PARTY_FEEDS})
			if not opkg.pkg_installed(pkg_name) then
				util.perror("Failed to install package " .. pkg_name)
			end
		end
		opkg._remove_pkg_from_pkg_restore(pkg_name)
	end
end

file_cleanup(PACKAGE_FILE)
if PKG_NET_RESTART then
	util.ubus("rc", "init", { action = "restart", name = "network" })
end
if PKG_REBOOT then
	util.ubus("rpc-sys", "reboot", { safe = true })
end

util.perror("Package installation finished")
