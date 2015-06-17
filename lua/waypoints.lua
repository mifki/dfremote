function waypoints_point_find_by_id(id)
	return utils.binsearch(df.global.ui.waypoints.points, id, 'id')
end

function waypoints_mode_points()
    df.global.ui.main.mode = 0

    local ws = dfhack.gui.getCurViewscreen()
    gui.simulateInput(ws, 'D_NOTE')	
end

function waypoints_get_points(full)
	local ret = {}

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

function waypoints_nearest_point()
	if df.global.cursor.x == -30000 then
		return nil
	end

	local dist = 30000
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

function waypoints_nearest_and_all()
	return { waypoints_nearest_point() or mp.NIL, waypoints_get_points(true) }
end

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

function waypoints_place_point(name, comment)
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        return
    end

    if df.global.ui.main.mode ~= df.ui_sidebar_mode.NotesPoints then
    	return
    end

    local oldid = df.global.ui.waypoints.next_point_id
    gui.simulateInput(ws, 'D_NOTE_PLACE')

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
			gui.simulateInput(ws, 'D_NOTE_DELETE')
			break
		end
	end
end

function waypoints_zoom_to_point(id)
	local pt = waypoints_point_find_by_id(id)
	if not pt then
		return
	end

	recenter_view(pt.pos.x, pt.pos.y, pt.pos.z)
	df.global.cursor.x = pt.pos.x
	df.global.cursor.y = pt.pos.y
	df.global.cursor.z = pt.pos.z
end

function waypoints_get_routes()
	local ret = {}

	for i,v in ipairs(df.global.ui.waypoints.routes) do
		local name = routename(v)

		table.insert(ret, { name, v.id })
	end

	return ret
end

--print(pcall(function() return json:encode(waypoints_place_point('qq', 'zz')) end))