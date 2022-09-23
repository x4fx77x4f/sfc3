return function(sfc3)
	function sfc3.luadev_loadstring(code, name)
		local func, err = loadstring(code, name)
		if func ~= nil and not isfunction(func) then
			func, err = nil, func
		end
		return func, err
	end
	function sfc3.luadev_eval(identifier, code, executor, print_result)
		local func, err
		if print_result then
			func, err = sfc3.luadev_loadstring('return '..code, "Validation")
		end
		if func == nil then
			func, err = sfc3.luadev_loadstring(' '..code, "Validation")
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
