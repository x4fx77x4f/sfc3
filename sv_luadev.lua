return function(sfc3)
	local commands = sfc3.commands
	local command_help = sfc3.command_help
	local LUADEV_SERVER = {}
	sfc3.LUADEV_SERVER = LUADEV_SERVER
	local LUADEV_EVERYONE = {}
	sfc3.LUADEV_EVERYONE = LUADEV_EVERYONE
	local luadev_pending = {}
	sfc3.luadev_pending = luadev_pending
	local function luadev_cmd(sender, targets, code, print_result, silent)
		local server, everyone = false, false
		if #targets == 0 then
			return false, "No targets."
		elseif sender ~= owner() then
			for i=1, #targets do
				if targets[i] ~= sender then
					return false, "Only the chip owner can run code anywhere but on themselves."
				end
			end
		else
			local lookup = {}
			for i=#targets, 1, -1 do
				local target = targets[i]
				if target == LUADEV_SERVER then
					table.remove(targets, i)
					server = true
				elseif target == LUADEV_EVERYONE then
					table.remove(targets, i)
					everyone = true
					local all_players = find.allPlayers()
					for j=1, #all_players do
						local ply = all_players[j]
						if not ply:isBot() and not lookup[ply] then
							table.insert(targets, ply)
						end
					end
				elseif lookup[target] then
					table.remove(targets, i)
				else
					lookup[target] = true
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
		if everyone then
			table.insert(t, sfc3.color_client)
			table.insert(t, "everyone")
		else
			for i=1, #targets do
				if i ~= 1 then
					table.insert(t, sfc3.output_color)
					table.insert(t, ",")
				end
				local target = targets[i]
				table.insert(t, team.getColor(target:getTeam()))
				table.insert(t, target == sender and "themselves" or target:getName())
			end
		end
		table.insert(t, sfc3.output_color)
		table.insert(t, ": "..code)
		sfc3.tprint(silent and sender or nil, unpack(t))
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
			net.start(sfc3.ID_NET)
				net.writeUInt(sfc3.NET_LUADEV_EVAL, sfc3.NET_BITS)
				net.writeUInt(identifier, 32)
				net.writeEntity(sender)
				net.writeBool(print_result)
				local length = #code
				net.writeUInt(length, 16)
				net.writeData(code, length)
			net.send(targets)
		end
		if server then
			local success, result, syntax = sfc3.luadev_eval(identifier, code, executor, print_result)
			if not success then
				if syntax then
					sfc3.tprint(sender, "Syntax error from ", sfc3.color_server, "server", sfc3.output_color, ": "..result)
				else
					sfc3.tprint(sender, "Runtime error from ", sfc3.color_server, "server", sfc3.output_color, ": "..result)
				end
			elseif print_result then
					sfc3.tprint(sender, "Return from ", sfc3.color_server, "server", sfc3.output_color, ": "..result)
			end
		end
		return true
	end
	sfc3.luadev_cmd = luadev_cmd
	local function luadev_pending_consume(identifier, sender)
		local pending = luadev_pending[identifier]
		if pending == nil then
			return nil
		end
		local authorized = pending[sender]
		if not authorized then
			return nil
		end
		pending[sender] = nil
		if next(pending) == nil then
			luadev_pending[identifier] = nil
		end
		return pending
	end
	sfc3.luadev_pending_consume = luadev_pending_consume
	timer.create(sfc3.ID_TIMER..'_luadev_pending_gc', 10, 0, function()
		for identifier, pending in pairs(luadev_pending) do
			local garbage = true
			for ply in pairs(pending) do
				if isValid(ply) then
					garbage = false
				end
			end
			if garbage then
				luadev_pending[identifier] = nil
			end
		end
	end)
	local luadev_targets = {
		me = function(targets, sender)
			table.insert(targets, sender)
		end,
		all = function(targets, sender)
			table.insert(targets, LUADEV_EVERYONE)
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
	sfc3.luadev_targets = luadev_targets
	luadev_targets.you = luadev_targets.this
	local function luadev_targets_parse(parameters, sender)
		parameters = string.split(parameters, ',')
		local targets = {}
		for i=1, #parameters do
			local parameter = parameters[i]
			if string.sub(parameter, 1, 1) == '#' then
				parameter = string.sub(parameter, 2)
				local parser = luadev_targets[parameter]
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
	sfc3.luadev_targets_parse = luadev_targets_parse
	local function luadev_cmd_sc(sender, parameters, print_result, silent)
		local second_space = string.find(parameters, ' ', nil, true)
		local success, targets = luadev_targets_parse(string.sub(parameters, 1, second_space-1), sender)
		if not success then
			return success, targets
		end
		local code = string.sub(parameters, second_space+1)
		return luadev_cmd(sender, targets, code, print_result, silent)
	end
	sfc3.luadev_cmd_sc = luadev_cmd_sc
	commands.l = function(sender, command, parameters, is_team)
		return luadev_cmd(sender, {LUADEV_SERVER}, parameters, false)
	end
	command_help.l = "Run code on server. Chip owner only."
	commands.ls = function(sender, command, parameters, is_team)
		return luadev_cmd(sender, {LUADEV_SERVER, sender}, parameters, false)
	end
	command_help.ls = "Run code on server and your own client. Chip owner only."
	commands.lm = function(sender, command, parameters, is_team)
		return luadev_cmd(sender, {sender}, parameters, false)
	end
	command_help.lm = "Run code on your own client."
	commands.lsc = function(sender, command, parameters, is_team)
		return luadev_cmd_sc(sender, parameters, false)
	end
	command_help.lsc = "Run code on specified clients."
	commands.p = function(sender, command, parameters, is_team)
		return luadev_cmd(sender, {LUADEV_SERVER}, parameters, true)
	end
	command_help.p = "Run code on server and print the result. Chip owner only."
	commands.ps = function(sender, command, parameters, is_team)
		return luadev_cmd(sender, {LUADEV_SERVER, sender}, parameters, true)
	end
	command_help.ps = "Run code on server and your own client and print the result. Chip owner only."
	commands.pm = function(sender, command, parameters, is_team)
		return luadev_cmd(sender, {sender}, parameters, true)
	end
	command_help.pm = "Run code on your own client and print the result."
	commands.psc = function(sender, command, parameters, is_team)
		return luadev_cmd_sc(sender, parameters, true)
	end
	command_help.psc = "Run code on specified clients and print the result."
	commands.sl = function(sender, command, parameters, is_team)
		return luadev_cmd(sender, {LUADEV_SERVER}, parameters, false, true)
	end
	command_help.sl = "Silently run code on server. Chip owner only."
	commands.sls = function(sender, command, parameters, is_team)
		return luadev_cmd(sender, {LUADEV_SERVER, sender}, parameters, false, true)
	end
	command_help.sls = "Silently run code on server and your own client. Chip owner only."
	commands.slm = function(sender, command, parameters, is_team)
		return luadev_cmd(sender, {sender}, parameters, false, true)
	end
	command_help.slm = "Silently run code on your own client."
	commands.slsc = function(sender, command, parameters, is_team)
		return luadev_cmd_sc(sender, parameters, false, true)
	end
	command_help.slsc = "Silently run code on specified clients."
	commands.sp = function(sender, command, parameters, is_team)
		return luadev_cmd(sender, {LUADEV_SERVER}, parameters, true, true)
	end
	command_help.sp = "Silently run code on server and print the result. Chip owner only."
	commands.sps = function(sender, command, parameters, is_team)
		return luadev_cmd(sender, {LUADEV_SERVER, sender}, parameters, true, true)
	end
	command_help.sps = "Silently run code on server and your own client and print the result. Chip owner only."
	commands.spm = function(sender, command, parameters, is_team)
		return luadev_cmd(sender, {sender}, parameters, true, true)
	end
	command_help.spm = "Silently run code on your own client and print the result."
	commands.spsc = function(sender, command, parameters, is_team)
		return luadev_cmd_sc(sender, parameters, true, true)
	end
	command_help.spsc = "Silently run code on specified clients and print the result."
	sfc3.net_incoming[sfc3.NET_LUADEV_RETURN] = function(length, sender)
		local identifier = net.readUInt(32)
		local pending = luadev_pending_consume(identifier, sender)
		if pending == nil or not pending.print_result then
			return
		end
		local length = net.readUInt(16)
		local data = net.readData(length)
		sfc3.tprint(pending.executor, "Return from ", team.getColor(sender:getTeam()), sender:getName(), sfc3.output_color, ": "..data)
	end
	sfc3.net_incoming[sfc3.NET_LUADEV_ERROR_COMPILE] = function(length, sender)
		local identifier = net.readUInt(32)
		local pending = luadev_pending_consume(identifier, sender)
		if pending == nil then
			return
		end
		local length = net.readUInt(16)
		local data = net.readData(length)
		sfc3.tprint(pending.executor, "Syntax error from ", team.getColor(sender:getTeam()), sender:getName(), sfc3.output_color, ": "..data)
	end
	sfc3.net_incoming[sfc3.NET_LUADEV_ERROR_RUNTIME] = function(length, sender)
		local identifier = net.readUInt(32)
		local pending = luadev_pending_consume(identifier, sender)
		if pending == nil then
			return
		end
		local length = net.readUInt(16)
		local data = net.readData(length)
		sfc3.tprint(pending.executor, "Runtime error from ", team.getColor(sender:getTeam()), sender:getName(), sfc3.output_color, ": "..data)
	end
end
