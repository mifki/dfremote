--luacheck: in=
function hauling_get_routes()
	return execute_with_hauling_menu(function(ws)
		local ret = {}

		for i,route in ipairs(df.global.ui.hauling.routes) do
			local name = routename(route)

			local bad = false
			for j,w in ipairs(df.global.ui.hauling.view_bad) do
				if df.global.ui.hauling.view_routes[j] == route and istrue(w) then
					bad = true
					break
				end
			end

			table.insert(ret, { name, route.id, bad })
		end

		return ret
	end)
end

--luacheck: in=number
function hauling_route_info(id)
	local route = df.hauling_route.find(id)

	if not route then
		error('no route '..tostring(id))
	end

	return execute_with_hauling_menu(function(ws)
		local stops = {}
		for i,v in ipairs(df.global.ui.hauling.view_stops) do
			if v and df.global.ui.hauling.view_routes[i] == route then
				table.insert(stops, { stopname(v), v.id, istrue(df.global.ui.hauling.view_bad[i]) })
			end
		end

		local vehicle_info
		if #route.vehicle_ids > 0 then
			--todo: can be > 1 vehicle ?!
			local vehicle = df.vehicle.find(route.vehicle_ids[0])
			local vehicle_item = vehicle and df.item.find(vehicle.item_id)
			if vehicle_item then
				local vehicle_stop_id = route.vehicle_stops[0] ~= -1 and route.stops[route.vehicle_stops[0]].id or -1

				local on_stop = false

				local contained_volume = 0
				for i,ref in ipairs(vehicle_item.general_refs) do
					if ref._type == df.general_ref_contains_itemst then
						local item = df.item.find(ref.item_id)
						if item then
							contained_volume = contained_volume + item:getVolume()
						end
					end
				end

				local fullness = math.ceil(contained_volume / 50000 * 100)

				vehicle_info = { itemname(vehicle_item, 1, true), vehicle_item.id, vehicle_stop_id, on_stop, fullness }
			end
		end

		return { routename(route), route.id, stops, vehicle_info or mp.NIL }
	end)
end

--luacheck: in=number,number
function hauling_stop_info(routeid, stopid)
	local route = df.hauling_route.find(routeid)

	if not route then
		error('no route '..tostring(routeid))
	end

	local _,stop = utils.linear_index(route.stops, stopid, 'id')

	if not stop then
		error('no stop '..tostring(stopid))
	end

	local conditions = {}
	for i,v in ipairs(stop.conditions) do
		table.insert(conditions, { v.direction, v.mode, v.load_percent, v.timeout/1200, v.flags.whole });
	end

	local stockpiles = {}
	for i,v in ipairs(stop.stockpiles) do
		local bld = df.building.find(v.building_id)
		local name = bld and bldname(bld) or '#unknown stockpile#' --todo: handle -1 differently?

		table.insert(stockpiles, { name, v.building_id, v.mode.whole });
	end

	return { stopname(stop), stop.id, conditions, stockpiles }
end

--luacheck: in=number,number,number
function hauling_stop_delete_condition(routeid, stopid, idx)
	local route = df.hauling_route.find(routeid)

	if not route then
		error('no route '..tostring(routeid))
	end

	for i,stop in ipairs(route.stops) do
		if stop.id == stopid then
			stop.conditions:erase(idx)
			return true
		end
	end

	error('no stop '..tostring(stopid))
end

--luacheck: in=number,number,number
function hauling_stop_delete_link(routeid, stopid, idx)
	local route = df.hauling_route.find(routeid)

	if not route then
		error('no route '..tostring(routeid))
	end

	for i,stop in ipairs(route.stops) do
		if stop.id == stopid then
			stop.stockpiles:erase(idx)
			--[[for j,link in ipairs(stop.stockpiles) do
				if link.building_id == buildingid then
					stop.stockpiles:erase(j)
					return true
				end
			end]]

			error('no stockpile link '..tostring(buildingid))
		end
	end

	error('no stop '..tostring(stopid))
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
function hauling_stop_add()
	local ws = dfhack.gui.getCurViewscreen()
	if ws._type ~= df.viewscreen_dwarfmodest then
		error(errmsg_wrongscreen(ws))
	end

    if df.global.ui.main.mode ~= df.ui_sidebar_mode.Hauling then
    	error('invalid mode '..tostring(df.global.ui.main.mode))
    end

    local hauling = df.global.ui.hauling
        
    if hauling.routes == 0 then
    	error('no routes')
    end

    --todo: don't add two stops in one place

    gui.simulateInput(ws, K'D_HAULING_NEW_STOP')

    return true
end

--luacheck: in=number,number
function hauling_stop_delete(routeid, stopid)
	return execute_with_hauling_menu(function(ws)
		for i,v in ipairs(df.global.ui.hauling.view_stops) do
			if v and v.id == stopid and df.global.ui.hauling.view_routes[i].id == routeid then
				df.global.ui.hauling.cursor_top = i
				gui.simulateInput(ws, K'D_HAULING_REMOVE')
				return true
			end
		end
	end)
end

--luacheck: in=
function hauling_stop_delete_current()
	local ws = dfhack.gui.getCurViewscreen()
	if ws._type ~= df.viewscreen_dwarfmodest then
		error(errmsg_wrongscreen(ws))
	end

    if df.global.ui.main.mode ~= df.ui_sidebar_mode.Hauling then
    	error('invalid mode '..tostring(df.global.ui.main.mode))
    end

    local hauling = df.global.ui.hauling
        
    if not hauling.view_stops[hauling.cursor_top] then
    	error('no stop selected')
    end

    --todo: make sure the same route stays selected after deleting a stop
    local was_last = hauling.cursor_top == #hauling.view_stops-1 or not hauling.view_stops[hauling.cursor_top+1]

    gui.simulateInput(ws, K'D_HAULING_REMOVE')

    if hauling.view_stops[hauling.cursor_top] and not was_last then
    	hauling.cursor_top = hauling.cursor_top - 1
    end

    return true
end

--luacheck: in=number
function hauling_vehicle_get_choices(routeid)
	return execute_with_hauling_menu(function(ws)
		for i,v in ipairs(df.global.ui.hauling.view_routes) do
			if v.id == routeid then
				df.global.ui.hauling.cursor_top = i
				gui.simulateInput(ws, K'D_HAULING_VEHICLE')
				if not df.global.ui.hauling.in_assign_vehicle then
					error('could not switch to vehicle assign mode')
				end
				
				local ret = {}
				for i,vehicle in ipairs(df.global.ui.hauling.vehicles) do
					if not vehicle then
						table.insert(ret, { 'None', -1, -1, mp.NIL })
					
					else
						local item = df.item.find(vehicle.item_id)
						local itemname = item and itemname(item, 1, true)
						local assigned_route = vehicle.route_id ~= -1 and df.hauling_route.find(vehicle.route_id)

						table.insert(ret, { itemname, vehicle.id, item.id, assigned_route and routename(assigned_route) or mp.NIL })
					end
				end

				return ret
			end

			error('no route with id '..tostring(routeid))
		end
	end)
end

--luacheck: in=number,number
function hauling_vehicle_assign(routeid, vehicleid)
	return execute_with_hauling_menu(function(ws)
		for i,v in ipairs(df.global.ui.hauling.view_routes) do
			if v.id == routeid then
				df.global.ui.hauling.cursor_top = i
				gui.simulateInput(ws, K'D_HAULING_VEHICLE')
				if not df.global.ui.hauling.in_assign_vehicle then
					error('could not switch to vehicle assign mode')
				end
				
				local ret = {}
				for j,vehicle in ipairs(df.global.ui.hauling.vehicles) do
					if (not vehicle and vehicleid == -1) or (vehicle and vehicle.id == vehicleid) then
						df.global.ui.hauling.cursor_vehicle = j
						gui.simulateInput(ws, K'SELECT')
						return true
					end
				end

				error('no vehicle with id '..tostring(vehicleid))
			end
		end

		error('no route with id '..tostring(routeid))
	end)
end

--luacheck: in=
function hauling_route_add()
	return execute_with_hauling_menu(function(ws)
		gui.simulateInput(ws, K'D_HAULING_NEW_ROUTE')
	end)
end

--luacheck: in=number,string
function hauling_route_set_name(id,name)
	local route = df.hauling_route.find(id)

	if not route then
		error('no route '..tostring(id))
	end

	route.name = name
end

--luacheck: in=number,bool
function hauling_route_start_edit(id, zoom)
	zoom = istrue(zoom)

	for i,route in ipairs(df.global.ui.hauling.view_routes) do
		if route.id == id then
			return execute_with_hauling_menu(function(ws)
				df.global.ui.hauling.cursor_top = i

				if zoom and #route.stops > 0 then
					local minx = 999
					local miny = 999
					local maxx = 0
					local maxy = 0
					local bz = route.stops[0].pos.z

					for j,stop in ipairs(route.stops) do
						local pos = stop.pos
						if pos.z == bz then
							if pos.x < minx then
								minx = pos.x
							end
							if pos.x > maxx then
								maxx = pos.x
							end
							if pos.y < miny then
								miny = pos.y
							end
							if pos.y > maxy then
								maxy = pos.y
							end
						end
					end

					local cx = math.floor((minx+maxx)/2)
					local cy = math.floor((miny+maxy)/2)

					recenter_view(cx, cy, bz)	
				end

				return true
			end, true)
		end
	end
	
	error('no route '..tostring(id))
end

--luacheck: in=
function hauling_route_end_edit()
	reset_main()
end

--luacheck: in=number,number,number
function hauling_reorder_stops(id, fromidx, toidx)
	local route = df.hauling_route.find(id)
	if not route then
		error('no hauling route '..tostring(id))
	end

	--todo: use UI ?

	--todo: can be > 1 vehicle ?!
	local vehicle_stop = route.stops[route.vehicle_stops[0]]

	local stop = route.stops[fromidx]
    route.stops:erase(fromidx)
    route.stops:insert(toidx, stop)

    route.vehicle_stops[0] = utils.linear_index(route.stops, vehicle_stop)

    return true
end

hauling_linking_source = nil

function restore_after_hauling_linking()
    hauling_linking_source = nil
end

--luacheck: in=number,number
function hauling_stop_linking_begin(routeid, stopid)
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        error(errmsg_wrongscreen(ws))
    end

	local route = df.hauling_route.find(routeid)
	if not route then
		error('no hauling route '..tostring(routeid))
	end

	local _,stop = utils.linear_index(route.stops, stopid, 'id')

	if not stop then
		error('no stop '..tostring(stopid))
	end

	query_building()
    hauling_linking_source = { routeid=route.id, stopid=stop.id }

    return true	
end

--luacheck: in=
function hauling_stop_linking_ok()
    if not hauling_linking_source then
        error('not linking hauling stop')
    end

    local bld = df.global.world.selected_building
    if bld._type ~= df.building_stockpilest then
    	error('not a stockpile '..tostring(bld))
    end

	local route = df.hauling_route.find(hauling_linking_source.routeid)
	if not route then
		error('no hauling route '..tostring(hauling_linking_source.routeid))
	end

	local _,stop = utils.linear_index(route.stops, hauling_linking_source.stopid, 'id')

	if not stop then
		error('no stop '..tostring(stopid))
	end    

    local link = df.route_stockpile_link:new()
    link.building_id = bld.id
    link.mode.take = true

    stop.stockpiles:insert('#', link)

    df.global.ui.main.mode = df.ui_sidebar_mode.Default

    local ret = { hauling_linking_source.routeid, hauling_linking_source.stopid }
    restore_after_hauling_linking()
    return ret
end

--luacheck: in=
function hauling_stop_linking_cancel()
    if not hauling_linking_source then
        error('not linking hauling stop')
    end

    df.global.ui.main.mode = df.ui_sidebar_mode.Default

    local ret = { hauling_linking_source.routeid, hauling_linking_source.stopid }
    restore_after_hauling_linking()
    return ret
end

function hauling_stop_edit_item_settings(routeid, stopid)
	stockpile_editing_settings = nil
	
	local route = df.hauling_route.find(routeid)
	if not route then
		error('no hauling route '..tostring(routeid))
	end

	local _,stop = utils.linear_index(route.stops, stopid, 'id')

	if not stop then
		error('no stop '..tostring(stopid))
	end

	stockpile_editing_settings = stop.settings

	return true
end

--print(pcall(function()return json:encode(hauling_get_routes())end))
--print(pcall(function()return json:encode(hauling_route_info(1))end))
--print(pcall(function()return json:encode(hauling_vehicle_get_choices(2))end))
--print(pcall(function()return json:encode(hauling_vehicle_assign(2,48))end))
--print(pcall(function()return json:encode(hauling_route_new())end))
--print(pcall(function()return json:encode(hauling_route_set_name(130,''))end))
-- print(pcall(function()return json:encode(hauling_route_start_edit(2,true))end))
