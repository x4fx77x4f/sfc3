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
sfc3.net_incoming[sfc3.NET_PRINT] = function(length)
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

--@include ./sh_luadev.lua
dofile('./sh_luadev.lua')(sfc3)
--@include ./cl_luadev.lua
dofile('./cl_luadev.lua')(sfc3)
