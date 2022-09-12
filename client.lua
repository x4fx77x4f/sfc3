--@name sfc3
--@client
--@include ./shared.lua
local sfc3 = dofile('./shared.lua')
if player() == owner() then
	function sfc3._print(...)
		return print(sfc3.output_prefix_color, sfc3.output_prefix, sfc3.output_color, ...)
	end
else
	function sfc3._print(...)
		if canPrintLocal ~= nil and canPrintLocal() then
			return printLocal(sfc3.output_prefix_color, sfc3.output_prefix, sfc3.output_color, ...)
		elseif render.isHUDActive() then
			return pcall(printHud, sfc3.output_prefix_color, sfc3.output_prefix, sfc3.output_color, ...)
		end
	end
end
function sfc3._printf(...)
	return sfc3._print(string.format(...))
end
net.receive(sfc3.NET, function(length)
	local id = net.readUInt(sfc3.NET_BITS)
	if id == sfc3.NET_EVAL then
		local identifier = net.readUInt(32)
		local executor = net.readEntity()
		local print_result = net.readBool()
		local length = net.readUInt(16)
		local code = net.readData(length)
		local success, result, syntax = sfc3.eval(identifier, code, executor, print_result)
		if not success then
			if syntax then
				net.start(sfc3.NET)
					net.writeUInt(sfc3.NET_EVAL_RETURN_SYNTAX, sfc3.NET_BITS)
					net.writeUInt(identifier, 32)
					local length = #result
					net.writeUInt(length, 16)
					net.writeData(result, length)
				net.send(SERVER and executor or nil)
			else
				net.start(sfc3.NET)
					net.writeUInt(sfc3.NET_EVAL_RETURN_ERROR, sfc3.NET_BITS)
					net.writeUInt(identifier, 32)
					local length = #result
					net.writeUInt(length, 16)
					net.writeData(result, length)
				net.send(SERVER and executor or nil)
			end
		elseif print_result then
			net.start(sfc3.NET)
				net.writeUInt(sfc3.NET_EVAL_RETURN, sfc3.NET_BITS)
				net.writeUInt(identifier, 32)
				local length = #result
				net.writeUInt(length, 16)
				net.writeData(result, length)
			net.send(SERVER and executor or nil)
		end
	elseif id == sfc3.NET_PRINT then
		local t = {}
		local j = net.readUInt(8)
		for i=1, j do
			if net.readBit() == 1 then
				t[i] = net.readColor(false)
			else
				t[i] = net.readString()
			end
		end
		return sfc3._print(unpack(t))
	end
end)
