local sfc3 = {}
_G.sfc3 = sfc3

sfc3.output_color = Color(191, 191, 191, 255)
sfc3.output_prefix = string.format("[%d] ", chip():entIndex())
sfc3.output_prefix_color = Color('#4d7bc8')
sfc3.color_menu = Color('#4caf50')
sfc3.color_client = Color('#dea909')
sfc3.color_server = Color('#03a9f4')

local function enum(prefix, enum)
	local bits = 1
	repeat
		bits = bits+1
	until 2^bits > #enum
	assert(bits <= 32, "number of values in enum cannot exceed 2^32")
	prefix = prefix..'_'
	sfc3[prefix..'BITS'] = bits
	for i=1, #enum do
		sfc3[prefix..enum[i]] = i-1
	end
end
sfc3._enum = enum
sfc3.NET = 'sfc3'
sfc3.HOOK = 'sfc3'
sfc3.TIMER = 'sfc3'
enum('NET', {
	'EVAL',
	'EVAL_RETURN',
	'EVAL_RETURN_SYNTAX',
	'EVAL_RETURN_ERROR',
	'PRINT',
})

function sfc3.eval(identifier, code, executor, print_result)
	local func, err = loadstring(code, "Validation")
	if func ~= nil and type(func) ~= 'function' then
		func, err = nil, func
	end
	if func == nil and print_result then
		func, err = loadstring('return '..code, "Validation")
		if func ~= nil and type(func) ~= 'function' then
			func, err = nil, func
		end
	end
	if func == nil then
		err = tostring(err)
		return false, err, true
	end
	local retvals = {pcall(func)}
	if not retvals[1] then
		err = retvals[2]
		if type(err) == 'table' then -- I hate that I have to do this
			err = rawget(err, 'message')
		end
		err = tostring(err)
		return false, err
	end
	if print_result then
		table.remove(retvals, 1)
		for i=1, #retvals do
			retvals[i] = tostring(retvals[i])
		end
		retvals = table.concat(retvals, "\t")
		return true, retvals
	end
	return true
end

return sfc3
