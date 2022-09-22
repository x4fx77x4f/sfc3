return function(sfc3)
	sfc3.net_incoming[sfc3.NET_EVAL] = function(length)
		local identifier = net.readUInt(32)
		local executor = net.readEntity()
		local print_result = net.readBool()
		local length = net.readUInt(16)
		local code = net.readData(length)
		local success, result, syntax = sfc3.eval(identifier, code, executor, print_result)
		if not success then
			if syntax then
				net.start(sfc3.ID_NET)
					net.writeUInt(sfc3.NET_EVAL_RETURN_SYNTAX, sfc3.NET_BITS)
					net.writeUInt(identifier, 32)
					local length = #result
					net.writeUInt(length, 16)
					net.writeData(result, length)
				net.send()
			else
				net.start(sfc3.ID_NET)
					net.writeUInt(sfc3.NET_EVAL_RETURN_ERROR, sfc3.NET_BITS)
					net.writeUInt(identifier, 32)
					local length = #result
					net.writeUInt(length, 16)
					net.writeData(result, length)
				net.send()
			end
		elseif print_result then
			net.start(sfc3.ID_NET)
				net.writeUInt(sfc3.NET_EVAL_RETURN, sfc3.NET_BITS)
				net.writeUInt(identifier, 32)
				local length = #result
				net.writeUInt(length, 16)
				net.writeData(result, length)
			net.send()
		end
	end
end
