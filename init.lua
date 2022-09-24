--@name sfc3
--@server
--@include ./client.lua
--@clientmain ./client.lua
--@include ./shared.lua
local sfc3 = dofile('./shared.lua')

function sfc3.tprint(target, ...)
	net.start(sfc3.ID_NET)
		net.writeUInt(sfc3.NET_PRINT, sfc3.NET_BITS)
		for i=1, select('#', ...) do
			local v = select(i, ...)
			if v == nil then
				break
			elseif type(v) == 'Color' then
				net.writeBit(1)
				net.writeUInt(v[1], 8)
				net.writeUInt(v[2], 8)
				net.writeUInt(v[3], 8)
			else
				net.writeBit(0)
				net.writeString(v)
			end
		end
	net.send(target)
end
function sfc3.tprintf(target, ...)
	return sfc3.tprint(target, string.format(...))
end
function sfc3.print(...)
	return sfc3.tprint(nil, ...)
end

local command_prefix_short = "$"
local command_prefix = string.format("%s%d ", command_prefix_short, chip():entIndex())
local commands, command_help = {}, {}
sfc3.commands = commands
sfc3.command_help = command_help
commands.help = function(sender, command, parameters, is_team)
	if parameters ~= '' then
		local help = command_help[parameters]
		if help == nil then
			return false, "No such command %q."
		end
		sfc3.tprintf(sender, "Help for %q: %s", parameters, help)
		return true
	end
	local commands_list = {}
	for k in pairs(commands) do
		table.insert(commands_list, k)
	end
	table.sort(commands_list)
	commands_list = table.concat(commands_list, ", ")
	sfc3.tprintf(sender, "Available commands: %s", commands_list)
	return true
end
command_help.help = "Get documentation for command, or list all commands if none specified."
commands.man = commands.help
command_help.man = command_help.help

--@include ./sh_luadev.lua
dofile('./sh_luadev.lua')(sfc3)
--@include ./sv_luadev.lua
dofile('./sv_luadev.lua')(sfc3)

--@include ./sv_goto.lua
dofile('./sv_goto.lua')(sfc3)

hook.add('PlayerSay', sfc3.ID_HOOK, function(sender, message, is_team)
	local short = false
	if string.sub(message, 1, #command_prefix) == command_prefix then
		message = string.sub(message, #command_prefix+1)
	elseif sender == owner() and string.sub(message, 1, #command_prefix_short) == command_prefix_short then
		message = string.sub(message, #command_prefix_short+1)
		short = true
	else
		return
	end
	local first_space = string.find(message, ' ', nil, true)
	local command = string.lower(first_space == nil and message or string.sub(message, 1, first_space-1))
	if short and tonumber(command) ~= nil then
		return
	end
	local command_func = commands[command]
	if command_func ~= nil then
		local parameters = first_space == nil and "" or string.sub(message, first_space+1)
		local success, retval = command_func(sender, command, parameters, is_team)
		if not success then
			if type(retval) == 'table' then
				retval = rawget(retval, 'message')
			end
			retval = tostring(retval)
			sfc3.tprint(sender, retval)
		end
		return ""
	--elseif short then
		--return
	end
	sfc3.tprintf(sender, "Unknown command %q.", command)
	return ""
end)

hook.add('ClientInitialized', sfc3.ID_HOOK, function(ply)
	if ply ~= owner() then
		return
	end
	sfc3.tprintf(ply, "Run \"%shelp\" (chip owner only) or \"%shelp\" for commands.", command_prefix_short, command_prefix)
end)
