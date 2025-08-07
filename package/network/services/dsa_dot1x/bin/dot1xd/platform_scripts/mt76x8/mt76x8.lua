local uci = require("uci").cursor()
local fs = require("nixio.fs")
local util = require("vuci.util")
local json = require("luci.jsonc")
local DATA_DIR = "/tmp/run/dot1x_server/state"

if not fs.access(DATA_DIR) then
	fs.mkdirr(DATA_DIR)
end

local vlans = {}
vlans = {
	get_current_vlan = function(pid)
		local vid = nil
		uci:foreach("network", "switch_vlan", function(s)
			local ports = util.split(s.ports, ' ')
			if util.contains(ports, tostring(pid)) then
				vid = s.vlan
				return false
			end
		end)
		return vid
	end,
	vid_to_sid = function(vid)
		local sid = nil
		uci:foreach("network", "switch_vlan", function(s)
			if tostring(s.vlan) == tostring(vid) then
				sid = s[".name"]
				return false
			end
		end)
		return sid
	end,
	update_vlan = function(pid, vid)
		local sid = vlans.vid_to_sid(vid)
		if not sid then return false end

		local curr = tostring(vlans.get_current_vlan(pid))
		local curr_sid = vlans.vid_to_sid(curr)
		if curr and curr_sid then
			local ports = uci:get("network", curr_sid, "ports")
			local split_ports = util.split(ports, " ")
			local new_ports = {}
			for _, p in ipairs(split_ports) do
				if p ~= tostring(pid) then
					new_ports[#new_ports+1] = p
				end
			end
			local new_str = table.concat(new_ports, " ")
			uci:set("network", curr_sid, "ports", new_str)
			util.exec(string.format("swconfig dev switch0 vlan '%s' set ports '%s'", curr, new_str))
		end

		local ports_list = uci:get("network", sid, "ports")
		if uci:get("network", sid, "isolation") == '1' then ports_list = "6t" end

		local new_str = ports_list.." "..pid
		uci:set("network", sid, "ports", new_str)
		-- reloading network from this script takes too long and triggers a reload loop for dot1x
		util.exec(string.format("swconfig dev switch0 port '%s' set pvid %s", pid, vid))
		util.exec(string.format("swconfig dev switch0 vlan '%s' set ports '%s'", vid, new_str))
		util.exec("swconfig dev switch0 set apply")
		uci:commit("network")
		return true
	end
}

local tc_templates = {
	clear_port_rules = {
		"tc filter del dev eth0 ingress prio *srcmac_prio* flower 2> /dev/null",
		"tc filter del dev eth0 ingress prio 1 handle *port_isolation_handle* flower 2> /dev/null",
		"tc filter del dev eth0 ingress prio 2 handle *port_isolation_handle* flower 2> /dev/null"
	},
	block_port = {
		"tc qdisc add dev eth0 clsact 2> /dev/null",
		"tc filter add dev eth0 ingress protocol 802.1Q prio 1 handle *port_isolation_handle* flower vlan *iso_vid*"
			.." vlan_ethtype 0x888e action mirred ingress redir dev *dummy*",
		"tc filter add dev eth0 ingress protocol 802.1Q prio 2 handle *port_isolation_handle* flower vlan *iso_vid* action drop",
		"tc filter del dev *dummy* egress 2> /dev/null",
		"tc filter add dev *dummy* egress matchall action vlan push id *iso_vid* action mirred egress mirror dev eth0"
	},
	unblock_port = {
		"tc qdisc add dev eth0 clsact 2> /dev/null",
		"tc filter del dev *dummy* egress 2> /dev/null",
		"tc filter add dev *dummy* egress matchall action vlan push id *req_vid* action mirred egress mirror dev eth0"
	},
	teardown = {
		"ip link del dev *dummy*"
	},
	make_template_list = function(port_cfg)
		local isolation_vlan = nil
		uci:foreach("network", "switch_vlan", function(s)
			if s.isolation == '1' then
				local ports = util.split(string.gsub(s.ports, " $", ""), ' ')
				if util.contains(ports, tostring(port_cfg.pid)) or #ports < 2 then
					isolation_vlan = s.vlan
					return false
				end
			end
		end)
		local list = {
			srcmac_prio = 10+port_cfg.pid,
			port_isolation_handle = port_cfg.pid+1,
			dummy = port_cfg.name,
			iso_vid = isolation_vlan,
			req_vid = port_cfg.requested_vlan
		}
		return list
	end,
	run_template = function(template, replace_list)
		local custom = ""
		for _, line in ipairs(template) do
			custom = custom..line.."\n"
		end
		for k, v in pairs(replace_list) do
			custom = string.gsub(custom, "%*"..tostring(k).."%*", tostring(v))
		end
		util.exec(custom)
	end
}

local port_actions = {
	unblock_port = function(port_cfg)
		local template_values = tc_templates.make_template_list(port_cfg)
		local port_events = util.ubus("port_events", "show")
		local mac_rules = {}
		for _, port in ipairs(port_events.ports) do
			if tonumber(port.num) == port_cfg.pid then
				local entries = port.topology or {}
				if port_cfg.user_mac then
					-- in case port_events does not return any values
					entries[#entries+1] = {MAC = port_cfg.user_mac}
				end
				for _, topo_entry in ipairs(entries) do
					mac_rules[#mac_rules+1] = "tc filter add dev eth0 ingress protocol 802.1Q"
					.." prio *srcmac_prio* flower vlan *req_vid* vlan_ethtype 0x888e src_mac "
					..tostring(topo_entry.MAC).." action mirred ingress redir dev *dummy*"
				end
			end
		end
		if not vlans.update_vlan(tostring(port_cfg.pid), tostring(port_cfg.requested_vlan)) then
			return false
		end
		tc_templates.run_template(tc_templates.clear_port_rules, template_values)
		tc_templates.run_template(tc_templates.unblock_port, template_values)
		tc_templates.run_template(mac_rules, template_values)
		return true
	end,

	block_port = function(port_cfg)
		local template_values = tc_templates.make_template_list(port_cfg)
		if not vlans.update_vlan(tostring(port_cfg.pid), tostring(template_values.iso_vid)) then
			return false
		end
		tc_templates.run_template(tc_templates.clear_port_rules, template_values)
		tc_templates.run_template(tc_templates.block_port, template_values)
		return true
	end,

	teardown_port = function(port_cfg)
		local template_replace_list = tc_templates.make_template_list(port_cfg)
		tc_templates.run_template(tc_templates.clear_port_rules, template_replace_list)
		tc_templates.run_template(tc_templates.teardown, template_replace_list)
		local port_file = DATA_DIR.."/"..port_cfg.name
		fs.remove(port_file)
		return true
	end
}

local function read_port_file(port_name)
	local function init_port(name)
		local port = {}
		port.name = name
		uci:foreach("dot1x", "port", function(s)
			if s.iface == name then
				port.pid = tonumber(s.port_index)
			end
		end)
		return port
	end
	local port_file = DATA_DIR.."/"..port_name
	if not fs.access(port_file) then return init_port(port_name) end
	local contents = fs.readfile(port_file) or ""
	return json.parse(contents) or init_port(port_name)
end

local function write_port_file(port, config)
	local port_file = DATA_DIR.."/"..port
	local cfg_str = json.stringify(config or {}) or ""
	fs.writefile(port_file, cfg_str)
end

local args = arg

local commands = {}
commands = {
	toggle_controlled_port = function(port_cfg)
		if args[3] ~= "true" and args[3] ~= "false" then
			print("usage: toggle_controlled_port [port] [bool] [user_mac]")
			os.exit(1)
		end
		port_cfg.blocked = args[3] == "true"
		port_cfg.user_mac = not port_cfg.blocked and args[4]
		return true
	end,
	assign_vlan = function(port_cfg)
		if not tonumber(args[3]) then
			print("usage: assign_vlan [port] [vid]")
			os.exit(1)
		end
		local valid_vlans = {}
		uci:foreach("network", "switch_vlan", function(s)
			if s.isolation == "1" then return end
			valid_vlans[#valid_vlans+1] = tostring(s.vlan)
		end)
		if not util.contains(valid_vlans, tostring(args[3])) then
			print("invalid vlan "..args[3])
			os.exit(1)
		end
		port_cfg.requested_vlan = args[3]
		return true
	end,
	get_port_state = function(port_cfg)
		print(port_cfg.blocked and "UNAUTHORIZED" or "AUTHORIZED")
		return false
	end,
	teardown_port = function(port_cfg)
		port_actions.teardown_port(port_cfg)
		return false
	end
}

local function up_dev(dev)
	uci:foreach("network", "interface", function(s)
		if s.device ~= dev then return end
		local if_name = s[".name"]
		util.exec("ifup "..if_name)
	end)
end

local function sync()
	for config in fs.dir(DATA_DIR) do
		local port_cfg = read_port_file(config)
		if port_cfg.blocked then
			if not port_actions.block_port(port_cfg) then
				error("Failed!")
			end
		elseif port_cfg.requested_vlan then
			if port_actions.unblock_port(port_cfg) then
				local vid = port_cfg.requested_vlan or "1"
				up_dev("eth0."..vid) -- up interfaces using this dev directly
				uci:foreach("network", "device", function (b)
					-- up interfaces using this dev through a bridge
					local ports = b.ports or {}
					if not util.contains(ports, "eth0."..vid) then return end
					up_dev(b.name)
				end)
			else
				error("Failed!")
			end
		end
	end
end

local port_commands = { "toggle_controlled_port", "assign_vlan", "get_port_state", "teardown_port" }
local valid_commands = { "toggle_controlled_port", "assign_vlan", "get_port_state", "teardown_port", "sync"}

local help = [[Usage:
	toggle_controlled_port [port] [bool]    set port to the 802.1x authorized state
	get_port_state [port]                   get port 802.1x auth state
	assign_vlan [port] [vlan]               move port to vlan
	teardown_port [port]                    remove all tc rules related to port
	sync                                    apply configuration
]]

local function invalid_cmd_exit()
	print(help)
	os.exit(1)
end

if not fs.access(DATA_DIR) then
	fs.mkdirr(DATA_DIR)
end

if #args < 1 then invalid_cmd_exit() end
local cmd=args[1]

local function validate_port_arg()
	if #args < 2 or not args[2]  or #args[2] < 1 then invalid_cmd_exit() end
	local port = args[2]
	local valid_ports = {}
	uci:foreach("dot1x", "port", function (s)
		table.insert(valid_ports, s.iface)
	end)
	if util.contains(valid_ports, port) then
		return
	end
	print(string.format("invalid port '%s', valid ports are: { '%s' }", port,
		table.concat(valid_ports, "', '")))
	invalid_cmd_exit()
end

if not util.contains(valid_commands, cmd) then invalid_cmd_exit() end

if util.contains(port_commands, cmd) then
	validate_port_arg()
	local port_cfg = read_port_file(args[2])
	local save = commands[cmd](port_cfg)
	if save then write_port_file(args[2], port_cfg) end
else
	if #args ~= 1 then invalid_cmd_exit() end
	sync()
end
