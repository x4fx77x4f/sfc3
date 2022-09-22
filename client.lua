--@name sfc3
--@client
--@include ./shared.lua
local sfc3 = dofile('./shared.lua')

setName(sfc3.output_prefix..chip():getChipName())

if player() == owner() then
	function sfc3.print(...)
		return print(sfc3.output_prefix_color, sfc3.output_prefix, sfc3.output_color, ...)
	end
else
	function sfc3.print(...)
		if canPrintLocal ~= nil and canPrintLocal() then
			return printLocal(sfc3.output_prefix_color, sfc3.output_prefix, sfc3.output_color, ...)
		elseif render.isHUDActive() then
			return pcall(printHud, sfc3.output_prefix_color, sfc3.output_prefix, sfc3.output_color, ...)
		end
	end
end
sfc3.net_incoming[sfc3.NET_PRINT] = function(length)
	local t, i = {}, 0
	while true do
		i = i+1
		length = length-1
		if length < 0 then
			break
		elseif net.readBit() == 1 then
			length = length-8*3
			if length < 0 then
				break
			end
			local r = net.readUInt(8)
			local g = net.readUInt(8)
			local b = net.readUInt(8)
			t[i] = Color(r, g, b)
		else
			local s = net.readString()
			length = length-(#s+1)*8
			t[i] = s
		end
	end
	return sfc3.print(unpack(t))
end

--@include ./sh_luadev.lua
dofile('./sh_luadev.lua')(sfc3)
--@include ./cl_luadev.lua
dofile('./cl_luadev.lua')(sfc3)
