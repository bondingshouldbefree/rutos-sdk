-- stream.lua
local utl = require "vuci.util"
local fs = require "nixio.fs"
local uci = require("vuci.uci").cursor()
local mnf = require("vuci.hardware").get_mnf()

local SERVICE, UBUS_QUERY
local FW_IMAGE_PATH = "/var/run/iot/cud_firmware.bin"

function restart(r)
	local deviceId = r:value(2)
	c8y:send('108,'..deviceId..',SUCCESSFUL')
	utl.ubus("rpc-sys", "reboot", { safe = true, args = {"-C"}} )
end

function get_modem_query(modem)

	local modem_count = 0
	local modem_name, modem_query = nil

	modem_count = utl.ubus("gsm", "info", {})
	if modem_count == nil then
		do return nil end
	end

	modem_count = modem_count["mdm_stats"]["num_modems"]

	if modem_count == nil or modem_count == 0 then
		do return nil end
	end

	if modem_count == 1 or modem == nil or modem == '' then
		do return "gsm.modem0" end
	end

	for i=0, modem_count do
		modem_name = utl.ubus("gsm.modem"..i, "info", {})
		if modem_name["usb_id"] == modem then
				do return "gsm.modem"..i end
		end
	end

	return nil
end

function sysupgrade(r)
	local result
	local deviceId = r:value(2)
	local url = vuci.util.shellquote(r:value(3))
	local username = vuci.util.shellquote(uci:get("iot", SERVICE, "username"))
	local password = vuci.util.shellquote(uci:get("iot", SERVICE, "password"))

	c8y:send('108,'..deviceId..',EXECUTING')
	
	result = os.execute(string.format("curl -y 60 -u %s:%s %s -o %s", username, password, url, FW_IMAGE_PATH))
	if not result or result ~= 0 then
		srInfo('Failed to download firmware file')
		c8y:send('108,'..deviceId..',FAILED')
		fs.remove(FW_IMAGE_PATH)
		return
	end

	result = os.execute("/sbin/sysupgrade -T " .. FW_IMAGE_PATH)
	if not result or result ~= 0 then
		srInfo('Failed to verify firmware image file')
		c8y:send('108,'..deviceId..',FAILED')
		fs.remove(FW_IMAGE_PATH)
	else
		c8y:send('108,'..deviceId..',SUCCESSFUL')
		fork_exec("sleep 1; /etc/init.d/dropbear stop; /etc/init.d/uhttpd stop; sleep 1; /sbin/sysupgrade " .. FW_IMAGE_PATH)
	end
end

function init()

	local modem_id  = nil

	SERVICE = get_service()
	if not SERVICE then
		srError('Service not found')
		return 1
	end

	local device = uci:get("system", "system", "devicename") or ""
	if device == "" then
		device = mnf:get_name() or ""
		device = device:sub(1, 6)
	end
	local interval = uci:get("iot", SERVICE, "interval")
	
	srInfo('*** Stream Init ***')
	srInfo(SERVICE)
	
	-- set device name and type
	c8y:send('103,'..c8y.ID..','..device..',Router')
	c8y:send('111,'..c8y.ID..','..interval)

	modem_id = uci:get("iot", "cumulocity", "modem") or ""
	UBUS_QUERY = get_modem_query(modem_id)

	-- set imei, cellid and iccid first time
	mobileDataStream()

	-- create timer which will stream mobile info data
	local m_timer = c8y:addTimer(10 * 1000, 'mobileDataStream')
	m_timer:start()

	-- register restart handler
	c8y:addMsgHandler(502, 'restart')
	c8y:addMsgHandler(503, 'sysupgrade')
	
	return 0
end

function mobileDataStream()

	local signal_value = utl.ubus(UBUS_QUERY, "get_signal_query", {})
	signal_value = signal_value["rssi"] == nil and '0' or signal_value["rssi"]

	-- send mobile signal info
	c8y:send('105,'..c8y.ID..','.. string.gsub(signal_value, "%s", ""))
	
	--[[TODO: Move from UBUS file execution to direct calls, as all requests will be executed by a non-root user in the future.
	All required ACL rules for the 'iot' user are already defined in iot.json.]]
	local wantype = utl.ubus("file", "exec", { command="/sbin/wan_info", params={"state"} } )
	local wanip = utl.ubus("file", "exec", { command="/sbin/wan_info", params={"ip"} } )

	-- send wan info
	c8y:send('106,'..c8y.ID..','.. string.gsub(wanip.stdout, "%s", "") ..','.. string.gsub(wantype.stdout, "%s", ""))
end

function fork_exec(command)
	local pid = nixio.fork()
	if pid > 0 then
		return
	elseif pid == 0 then
		-- change to root dir
		nixio.chdir("/")

		-- patch stdin, out, err to /dev/null
		local null = nixio.open("/dev/null", "w+")
		if null then
			nixio.dup(null, nixio.stderr)
			nixio.dup(null, nixio.stdout)
			nixio.dup(null, nixio.stdin)
			if null:fileno() > 2 then
				null:close()
			end
		end

		-- replace with target command
		nixio.exec("/bin/sh", "-c", command)
	end
end

function get_service()
	local server = c8y.server
	local service

	uci:foreach("iot", "iot", function(s)
		if s["server"] and string.find(server, s["server"], nil, true) and
		   s["enabled"] == "1" then
			srInfo('Service found: '..s[".name"])
			service = s[".name"]
			return false
		end
	end)

	return service
end
