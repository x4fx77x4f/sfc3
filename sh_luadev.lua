return function(sfc3)
	function sfc3.luadev_eval(identifier, code, executor, print_result)
		local func, err = loadstring(' '..code, "Validation")
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
			if type(err) == 'table' then
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
end
