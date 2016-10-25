--luacheck: in=
function hauling_get_routes()
	local ret = {}

	for i,route in ipairs(df.global.ui.hauling.routes) do
		local name = routename(route)

		table.insert(ret, { name, route.id })
	end

	return ret
end

--luacheck: in=number
function hauling_route_info(id)
	local route = df.hauling_route.find(id)

	if not route then
		error('no route '..tostring(id))
	end

	local stops = {}
	for i,v in ipairs(route.stops) do
		--todo: df.global.ui.hauling.view_bad
		table.insert(stops, { stopname(v), v.id })
	end

	return { routename(route), route.id, stops }
end

--luacheck: in=number
function hauling_route_delete(id)
	execute_with_hauling_menu(function(ws)
		for i,v in ipairs(df.global.ui.hauling.view_routes) do
			if v.id == id then
				df.global.ui.hauling.cursor_top = i
				gui.simulateInput(ws, K'D_HAULING_REMOVE')
				return true
			end
		end
	end)	
end

--luacheck: in=number,number
function hauling_route_remove_stop(routeid, stopid)
	execute_with_hauling_menu(function(ws)
		for i,v in ipairs(df.global.ui.hauling.view_stops) do
			if v.id == stopid and df.global.ui.hauling.view_routes[i].id == routeid then
				df.global.ui.hauling.cursor_top = i
				gui.simulateInput(ws, K'D_HAULING_REMOVE')
				return true
			end
		end
	end)
end