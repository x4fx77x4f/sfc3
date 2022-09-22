local sfc3 = {}
_G.sfc3 = sfc3

sfc3.output_color = Color(191, 191, 191, 255)
sfc3.output_prefix = string.format("[%d] ", chip():entIndex())
sfc3.output_prefix_color = Color('#4d7bc8')
sfc3.color_menu = Color('#4caf50')
sfc3.color_client = Color('#dea909')
sfc3.color_server = Color('#03a9f4')
function sfc3.printf(...)
	return sfc3.print(string.format(...))
end

local function enum(prefix, enum)
	local bits = 1
	while 2^bits < #enum do
		bits = bits+1
	end
	assert(bits <= 32, "number of values in enum cannot exceed 2^32")
	prefix = prefix..'_'
	sfc3[prefix..'BITS'] = bits
	for i=1, #enum do
		sfc3[prefix..enum[i]] = i-1
	end
end
sfc3.enum = enum
sfc3.ID_NET = 'sfc3'
sfc3.ID_HOOK = 'sfc3'
sfc3.ID_TIMER = 'sfc3'
enum('NET', {
	'PRINT',
	'LUADEV_EVAL',
	'LUADEV_RETURN',
	'LUADEV_ERROR_COMPILE',
	'LUADEV_ERROR_RUNTIME',
})
sfc3.net_incoming = {}
net.receive(sfc3.ID_NET, function(length, sender)
	if SERVER and not isValid(sender) then
		return
	end
	repeat
		length = length-sfc3.NET_BITS
		if length < 0 then
			return
		end
		local packet_type = net.readUInt(sfc3.NET_BITS)
		local packet_handler = sfc3.net_incoming[packet_type]
		if packet_handler == nil then
			break
		end
		length = packet_handler(length, sender)
	until length == nil
end)

return sfc3
