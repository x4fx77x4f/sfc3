--@name sfc3
--@server
--@include ./client.lua
--@clientmain ./client.lua
--@include ./shared.lua
local sfc3 = dofile('./shared.lua')

function sfc3._print(...)
	return print(sfc3.output_prefix_color, sfc3.output_prefix, sfc3.output_color, ...)
end
function sfc3._printf(...)
	return sfc3._print(string.format(...))
end
function sfc3._print_target(target, ...)
	net.start(sfc3.NET)
		net.writeUInt(sfc3.NET_PRINT, sfc3.NET_BITS)
		local j = select('#', ...)
		net.writeUInt(j, 8)
		for i=1, j do
			local v = select(i, ...)
			if v == nil then
				break
			elseif type(v) == 'Color' then
				net.writeBit(1)
				net.writeColor(v, false)
			else
				net.writeBit(0)
				net.writeString(v)
			end
		end
	net.send(target)
end
function sfc3._printf_target(target, ...)
	return sfc3._print_target(target, string.format(...))
end

local command_prefix_short = "$"
local command_prefix = string.format("%s%d ", command_prefix_short, chip():entIndex())
local commands

local LUADEV_SERVER = {}
local luadev_pending = {}
sfc3._luadev_pending = luadev_pending
local function command_luadev(sender, targets, code, print_result, silent)
	local server = false
	if #targets == 0 then
		return false, "No targets."
	elseif sender ~= owner() then
		for i=1, #targets do
			if targets[i] ~= sender then
				return false, "Only the chip owner can run code anywhere but on themselves."
			end
		end
	else
		for i=#targets, 1, -1 do
			if targets[i] == LUADEV_SERVER then
				server = true
				table.remove(targets, i)
			end
		end
	end
	local t = {}
	if silent then
		table.insert(t, "(silent) ")
	end
	table.insert(t, team.getColor(sender:getTeam()))
	table.insert(t, sender:getName())
	table.insert(t, sfc3.output_color)
	table.insert(t, "@")
	if server then
		table.insert(t, sfc3.color_server)
		table.insert(t, "server")
		if #targets > 0 then
			table.insert(t, sfc3.output_color)
			table.insert(t, ",")
		end
	end
	for i=1, #targets do
		if i ~= 1 then
			table.insert(t, sfc3.output_color)
			table.insert(t, ",")
		end
		local target = targets[i]
		table.insert(t, team.getColor(target:getTeam()))
		table.insert(t, target == sender and "themselves" or target:getName())
	end
	table.insert(t, sfc3.output_color)
	table.insert(t, ": "..code)
	sfc3._print_target(silent and sender or nil, unpack(t))
	local identifier = math.random(0, 2^32-1)
	local pending = {
		executor = sender,
		print_result = print_result,
	}
	luadev_pending[identifier] = pending
	if #targets > 0 then
		for i=1, #targets do
			pending[targets[i]] = true
		end
		net.start(sfc3.NET)
			net.writeUInt(sfc3.NET_EVAL, sfc3.NET_BITS)
			net.writeUInt(identifier, 32)
			net.writeEntity(sender)
			net.writeBool(print_result)
			local length = #code
			net.writeUInt(length, 16)
			net.writeData(code, length)
		net.send(targets)
	end
	if server then
		local success, result, syntax = sfc3.eval(identifier, code, executor, print_result)
		if not success then
			if syntax then
				sfc3._print_target(sender, "Syntax error from ", sfc3.color_server, "server", sfc3.output_color, ": "..result)
			else
				sfc3._print_target(sender, "Runtime error from ", sfc3.color_server, "server", sfc3.output_color, ": "..result)
			end
		elseif print_result then
				sfc3._print_target(sender, "Return from ", sfc3.color_server, "server", sfc3.output_color, ": "..result)
		end
	end
	return true
end
local function consume_pending(identifier, sender)
	local pending = luadev_pending[identifier]
	if pending == nil then
		return nil
	end
	local authorized = pending[sender]
	if not authorized then
		return nil
	end
	pending[sender] = nil
	return pending
end
local reserved_targets = {
	me = function(targets, sender)
		table.insert(targets, sender)
	end,
	all = function(targets, sender)
		local all_players = find.allPlayers()
		for i=1, #all_players do
			local ply = all_players[i]
			if not ply:isBot() then
				table.insert(targets, ply)
			end
		end
	end,
	them = function(targets, sender)
		local all_players = find.allPlayers()
		for i=1, #all_players do
			local ply = all_players[i]
			if not ply:isBot() and ply ~= sender then
				table.insert(targets, ply)
			end
		end
	end,
	this = function(targets, sender)
		local target = sender:getEyeTrace().Entity
		if isValid(target) and target:isPlayer() and not target:isBot() then
			table.insert(targets, target)
		else
			return "Invalid target."
		end
	end,
	server = function(targets, sender)
		table.insert(targets, LUADEV_SERVER)
	end,
}
reserved_targets.you = reserved_targets.this
local function parse_targets(parameters, sender)
	parameters = string.split(parameters, ',')
	local targets = {}
	for i=1, #parameters do
		local parameter = parameters[i]
		if string.sub(parameter, 1, 1) == '#' then
			parameter = string.sub(parameter, 2)
			local parser = reserved_targets[parameter]
			if parser == nil then
				return false, string.format("No such target %q.", parameter)
			end
			local problem = parser(targets, sender)
			if problem ~= nil then
				return false, problem
			end
		else
			local candidates = find.playersByName(parameter, false, false)
			if #candidates == 0 then
				return false, string.format("No players with name matching %q.", parameter)
			elseif #candidates > 1 then
				return false, string.format("%d players with name matching %q.", #candidates, parameter)
			end
			table.insert(targets, candidates[1])
		end
	end
	return true, targets
end
local function command_luadev_sc(sender, parameters, print_result, silent)
	local second_space = string.find(parameters, ' ', nil, true)
	local success, targets = parse_targets(string.sub(parameters, 1, second_space-1), sender)
	if not success then
		return success, targets
	end
	local code = string.sub(parameters, second_space+1)
	return command_luadev(sender, targets, code, print_result, silent)
end
commands = {
	help = function(sender, command, parameters, is_team)
		local commands_list = {}
		for k in pairs(commands) do
			table.insert(commands_list, k)
		end
		commands_list = table.concat(commands_list, ", ")
		sfc3._printf_target(sender, "Available commands: %s", commands_list)
		return true
	end,
	l = function(sender, command, parameters, is_team)
		return command_luadev(sender, {LUADEV_SERVER}, parameters, false)
	end,
	ls = function(sender, command, parameters, is_team)
		return command_luadev(sender, {LUADEV_SERVER, sender}, parameters, false)
	end,
	lm = function(sender, command, parameters, is_team)
		return command_luadev(sender, {sender}, parameters, false)
	end,
	lsc = function(sender, command, parameters, is_team)
		return command_luadev_sc(sender, parameters, false)
	end,
	p = function(sender, command, parameters, is_team)
		return command_luadev(sender, {LUADEV_SERVER}, parameters, true)
	end,
	ps = function(sender, command, parameters, is_team)
		return command_luadev(sender, {LUADEV_SERVER, sender}, parameters, true)
	end,
	pm = function(sender, command, parameters, is_team)
		return command_luadev(sender, {sender}, parameters, true)
	end,
	psc = function(sender, command, parameters, is_team)
		return command_luadev_sc(sender, parameters, true)
	end,
	l = function(sender, command, parameters, is_team)
		return command_luadev(sender, {LUADEV_SERVER}, parameters, false, true)
	end,
	sls = function(sender, command, parameters, is_team)
		return command_luadev(sender, {LUADEV_SERVER, sender}, parameters, false, true)
	end,
	slm = function(sender, command, parameters, is_team)
		return command_luadev(sender, {sender}, parameters, false, true)
	end,
	slsc = function(sender, command, parameters, is_team)
		return command_luadev_sc(sender, parameters, false, true)
	end,
	sp = function(sender, command, parameters, is_team)
		return command_luadev(sender, {LUADEV_SERVER}, parameters, true, true)
	end,
	sps = function(sender, command, parameters, is_team)
		return command_luadev(sender, {LUADEV_SERVER, sender}, parameters, true, true)
	end,
	spm = function(sender, command, parameters, is_team)
		return command_luadev(sender, {sender}, parameters, true, true)
	end,
	spsc = function(sender, command, parameters, is_team)
		return command_luadev_sc(sender, parameters, true, true)
	end,
}
sfc3.commands = commands

net.receive(sfc3.NET, function(length, sender)
	local id = net.readUInt(sfc3.NET_BITS)
	if id == sfc3.NET_EVAL_RETURN then
		local identifier = net.readUInt(32)
		local pending = consume_pending(identifier, sender)
		if pending == nil or not pending.print_result then
			return
		end
		local length = net.readUInt(16)
		local data = net.readData(length)
		sfc3._print_target(pending.executor, "Return from ", team.getColor(sender:getTeam()), sender:getName(), sfc3.output_color, ": "..data)
	elseif id == sfc3.NET_EVAL_RETURN_SYNTAX then
		local identifier = net.readUInt(32)
		local pending = consume_pending(identifier, sender)
		if pending == nil then
			return
		end
		local length = net.readUInt(16)
		local data = net.readData(length)
		sfc3._print_target(pending.executor, "Syntax error from ", team.getColor(sender:getTeam()), sender:getName(), sfc3.output_color, ": "..data)
	elseif id == sfc3.NET_EVAL_RETURN_ERROR then
		local identifier = net.readUInt(32)
		local pending = consume_pending(identifier, sender)
		if pending == nil then
			return
		end
		local length = net.readUInt(16)
		local data = net.readData(length)
		sfc3._print_target(pending.executor, "Runtime error from ", team.getColor(sender:getTeam()), sender:getName(), sfc3.output_color, ": "..data)
	end
end)

hook.add('PlayerSay', sfc3.HOOK, function(sender, message, is_team)
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
	local command_func = commands[command]
	if command_func ~= nil then
		local parameters = first_space == nil and "" or string.sub(message, first_space+1)
		local success, retval = command_func(sender, command, parameters, is_team)
		if not success then
			sfc3._print_target(sender, retval)
		end
		return ""
	--elseif short then
		--return
	end
	sfc3._printf_target(sender, "Unknown command %q.", command)
	return ""
end)

sfc3._printf("Run \"%shelp\" (chip owner only) or \"%shelp\" for commands.", command_prefix_short, command_prefix)
