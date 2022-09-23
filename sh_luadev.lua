return function(sfc3)
	function sfc3.luadev_loadstring(code, name)
		local func, err = loadstring(code, name)
		if func ~= nil and not isfunction(func) then
			func, err = nil, func
		end
		if func == nil then
			if istable(err) then
				err = rawget(err, 'message')
			end
			err = tostring(err)
		end
		return func, err
	end
	function sfc3.luadev_retval(success, ...)
		if not success then
			local err = ...
			if istable(err) then
				err = rawget(err, 'message')
			end
			err = tostring(err)
			return success, err
		end
		local t = {}
		for i=1, select('#', ...) do
			t[i] = tostring(select(i, ...))
		end
		return success, table.concat(t, "\t")
	end
	function sfc3.luadev_eval(identifier, code, executor, print_result)
		local name, func, err = "Validation"
		if print_result then
			func, err = sfc3.luadev_loadstring('return '..code, name)
		end
		if func == nil then
			func, err = sfc3.luadev_loadstring(' '..code, name)
		end
		if func == nil then
			return false, err, true
		end
		local success, retval = sfc3.luadev_retval(pcall(func))
		if not success then
			return false, retval
		end
		if print_result then
			return true, retval
		end
		return true
	end
end
