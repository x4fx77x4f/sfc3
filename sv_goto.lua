return function(sfc3)
	local commands = sfc3.commands
	local command_help = sfc3.command_help
	
	local seat_pos = Vector(0, 0, 0)
	sfc3.goto_seat_pos = seat_pos
	local seat = prop.createSeat(seat_pos, Angle(), 'models/hunter/plates/plate.mdl', true)
	sfc3.goto_seat = seat
	
	local goto_stacks = {}
	sfc3.goto_stacks = goto_stacks
	timer.create(sfc3.ID_TIMER..'_goto_stacks_gc', 10, 0, function()
		for sender in pairs(goto_stacks) do
			if not sender:isValid() or next(sender) == nil then
				goto_stacks[sender] = nil
			end
		end
	end)
	
	local goto_targets = {
		chip = chip(),
		there = function(sender)
			return true, sender:getEyeTrace().HitPos
		end,
	}
	sfc3.goto_targets = goto_targets
	local function goto_target_parse(parameter, sender)
		local target
		if string.sub(parameter, 1, 1) == '#' then
			parameter = string.sub(parameter, 2)
			local parser = goto_targets[parameter]
			if parser == nil then
				local index = tonumber(parameter)
				if index ~= nil then
					target = entity(index)
				else
					return false, string.format("No such target %q.", parameter)
				end
			end
			if type(parser) == 'function' then
				local success
				success, target = parser(sender)
				if not success then
					return success, target
				end
			else
				target = parser
			end
		else
			local candidates = find.playersByName(parameter, false, false)
			if #candidates == 0 then
				return false, string.format("No players with name matching %q.", parameter)
			elseif #candidates > 1 then
				return false, string.format("%d players with name matching %q.", #candidates, parameter)
			end
			target = candidates[1]
		end
		if type(target) == 'Entity' and not isValid(target) then
			return false, "Invalid entity."
		end
		return true, target
	end
	sfc3.goto_target_parse = goto_target_parse
	
	local function goto_cmd(sender, target)
		local angles = sender:getEyeAngles()
		seat:setPos(target)
		seat:use()
		seat:ejectDriver()
		seat:setPos(seat_pos)
		pcall(sender.getEyeAngles, sender, angles)
	end
	commands['goto'] = function(sender, commands, parameters, is_team)
		if sender ~= owner() then
			return false, "Not authorized."
		end
		if parameters == nil or parameters == '' then
			return false, "Malformed parameters."
		end
		local success, target = goto_target_parse(parameters, sender)
		if not success then
			return success, target
		end
		sfc3.tprintf(sender, "Target: %q", tostring(target))
		if type(target) == 'Entity' or type(target) == 'Player' then
			target = target:getPos()
		end
		local stack = goto_stacks[sender]
		if stack == nil then
			stack = {}
			goto_stacks[sender] = stack
		end
		table.insert(stack, sender:getPos())
		return pcall(goto_cmd, sender, target)
	end
	command_help['goto'] = "Teleport yourself to the specified target."
	commands['return'] = function(sender, commands, parameters, is_team)
		if sender ~= owner() then
			return false, "Not authorized."
		end
		local stack = goto_stacks[sender]
		if stack == nil then
			return false, "No previous position."
		end
		local target = table.remove(stack)
		if not next(stack) then
			goto_stacks[sender] = nil
		end
		return pcall(goto_cmd, sender, target)
	end
	command_help['return'] = "Teleport yourself back to your previous position."
end
