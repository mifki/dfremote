function waypoint_find_by_id(id)
	return utils.binsearch(df.global.ui.waypoints.points, id, 'id')
end

function route_find_by_id(id)
	return utils.binsearch(df.global.ui.waypoints.routes, id, 'id')
end

--luacheck: in=
function waypoints_mode_points()
	--todo: use reset_main()
    df.global.ui.main.mode = df.ui_sidebar_mode.Default

    local ws = dfhack.gui.getCurViewscreen()
    gui.simulateInput(ws, K'D_NOTE')	
end

--luacheck: in=bool
function waypoints_get_points(full)
	local ret = {}
	
	full = istrue(full)

	for i,v in ipairs(df.global.ui.waypoints.points) do
		local name = pointname(v)

		local dx = v.pos.x - df.global.cursor.x
		local dy = v.pos.y - df.global.cursor.y
		local dz = v.pos.z - df.global.cursor.z

		if full then
			table.insert(ret, { name, v.id, v.comment, df.global.cursor.x ~= -30000 and { dx,dy,dz } or mp.NIL })
		else
			table.insert(ret, { name, v.id })
		end
	end

	return ret	
end

--luacheck: in=
function waypoints_nearest_point()
	if df.global.cursor.x == -30000 then
		return nil
	end

	local dist = 999999
	local pt = nil

	for i,v in ipairs(df.global.ui.waypoints.points) do
		local dx = v.pos.x - df.global.cursor.x
		local dy = v.pos.y - df.global.cursor.y
		local dz = v.pos.z - df.global.cursor.z

		local d = math.abs(dx*dx+dy*dy+dz*dz)
		if d < dist then
			dist = d
			pt = v
		end
	end

	if pt then
		local dx = pt.pos.x - df.global.cursor.x
		local dy = pt.pos.y - df.global.cursor.y
		local dz = pt.pos.z - df.global.cursor.z

		return { pointname(pt), pt.id, pt.comment, { dx,dy,dz } }
	end

	return nil
end

--luacheck: in=
function waypoints_nearest_and_all()
	return { waypoints_nearest_point() or mp.NIL, waypoints_get_points(true) }
end

--luacheck: in=number,number,number,string,string
function waypoints_add_point(x, y, z, name, comment)
	local pt = df.ui.T_waypoints.T_points:new()

	pt.id = df.global.ui.waypoints.next_point_id
	pt.name = name
	pt.comment = comment or ''
	
	pt.pos.x = x
	pt.pos.y = y
	pt.pos.z = z

	pt.tile = 33
	pt.fg_color = 11
	pt.bg_color = 1

	df.global.ui.waypoints.points:insert(#df.global.ui.waypoints.points, pt)
	df.global.ui.waypoints.next_point_id = df.global.ui.waypoints.next_point_id + 1
end

--luacheck: in=string,string
function waypoints_place_point(name, comment)
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        return
    end

    --todo: convert to screen_
    if df.global.ui.main.mode ~= df.ui_sidebar_mode.NotesPoints then
    	return
    end

    local oldid = df.global.ui.waypoints.next_point_id
    gui.simulateInput(ws, K'D_NOTE_PLACE')

    -- protection from updating wrong point if a new one wasn't placed
    if oldid == df.global.ui.waypoints.next_point_id then
    	return
    end

    local pt = df.global.ui.waypoints.points[df.global.ui.waypoints.cur_point_index]
	pt.name = name
	pt.comment = comment or ''

	pt.tile = 33
	pt.fg_color = 11
	pt.bg_color = 1	
end

-- points may be referenced from squad orders, let's not try deleting them ourselves and use game ui instead
--luacheck: in=number
function waypoints_delete_point(id)
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        return
    end

    if df.global.ui.main.mode ~= df.ui_sidebar_mode.NotesPoints then
    	return
    end

	for i,v in ipairs(df.global.ui.waypoints.points) do
		if v.id == id then
			df.global.ui.waypoints.cur_point_index = i
			gui.simulateInput(ws, K'D_NOTE_DELETE')
			break
		end
	end
end

--luacheck: in=number
function waypoints_zoom_to_point(id)
	local pt = waypoint_find_by_id(id)
	if not pt then
		return
	end

	recenter_view(pt.pos.x, pt.pos.y, pt.pos.z)
	df.global.cursor.x = pt.pos.x
	df.global.cursor.y = pt.pos.y
	df.global.cursor.z = pt.pos.z
end

--luacheck: in=number,string,string
function waypoints_set_name_comment(id, name, comment)
	local pt = waypoint_find_by_id(id)
	if not pt then
		return
	end

	pt.name = name or ''
	pt.comment = comment or ''
end

--luacheck: in=bool
function routes_get_list(withpoints)
	allpoints = istrue(allpoints)
	
	local ret = {}

	for i,route in ipairs(df.global.ui.waypoints.routes) do
		local name = routename(route)

		if withpoints then
			local pts = {}
			
			for j,v in ipairs(route.points) do
				local pt = waypoint_find_by_id(v)
				table.insert(pts, pt and pointname(pt) or '#invalid waypoint#')
			end

			table.insert(ret, { name, route.id, pts })

		else
			table.insert(ret, { name, route.id })
		end
	end

	return ret
end

--luacheck: in=
function routes_add_route()
	local route = df.ui.T_waypoints.T_routes:new()

	route.id = df.global.ui.waypoints.next_route_id

	df.global.ui.waypoints.routes:insert(#df.global.ui.waypoints.routes, route)
	df.global.ui.waypoints.next_route_id = df.global.ui.waypoints.next_route_id + 1	
end

-- routes may be referenced from squad orders, let's not try deleting them ourselves and use game ui instead
--luacheck: in=number
function route_delete(id)
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        return
    end

    --todo: convert to screen_
    if df.global.ui.main.mode ~= df.ui_sidebar_mode.NotesPoints then
    	return
    end

    df.global.ui.main.mode = df.ui_sidebar_mode.NotesRoutes
    df.global.ui.waypoints.in_edit_waypts_mode = false

	for i,v in ipairs(df.global.ui.waypoints.routes) do
		if v.id == id then
			df.global.ui.waypoints.sel_route_idx = i
			gui.simulateInput(ws, K'D_NOTE_ROUTE_DELETE')
			break
		end
	end

	df.global.ui.main.mode = df.ui_sidebar_mode.NotesPoints
end

--luacheck: in=number,string
function route_set_name(id, name)
	local route = route_find_by_id(id)
	if not route then
		return
	end

	route.name = name or ''
end

--luacheck: in=number
function route_get_info(id)
	local route = route_find_by_id(id)
	if not route then
		return
	end
	
	local pts = {}
	
	for i,v in ipairs(route.points) do
		local pt = waypoint_find_by_id(v)
		table.insert(pts, { pt and pointname(pt) or '#invalid point#', v })
	end

	return { routename(route), route.id, pts }
end

--luacheck: in=number,number[]
function route_add_points(id, ptids)
	local route = route_find_by_id(id)
	if not route then
		return
	end

	for i,v in ipairs(ptids) do
		--todo: check point id here?
		route.points:insert(#route.points, v)
	end
end

--luacheck: in=number,number,number
function route_reorder_points(id, fromidx, toidx)
	local route = route_find_by_id(id)
	if not route then
		return
	end
	
	local ptid = route.points[fromidx]
    route.points:erase(fromidx)
    route.points:insert(toidx, ptid)
end

--luacheck: in=number,number
function route_delete_point(id, ptid)
	local route = route_find_by_id(id)
	if not route then
		return
	end
	
	for i,v in ipairs(route.points) do
		if v == ptid then
			route.points:erase(i)
			return true
		end
	end
end

--print(pcall(function() return json:encode(waypoints_place_point('qq', 'zz')) end))