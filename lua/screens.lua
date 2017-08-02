function screen_main()
	return df.global.gview.view.child	
end

--todo: transitions are not always required

function execute_with_main_mode(mode, fn)
	local ws = screen_main()
	local q = df.global.ui.main.mode
	df.global.ui.main.mode = mode

	local ok,ret = pcall(fn, ws)

    df.global.ui.main.mode = q

	if not ok then
		error (ret)
	end
    return ret	
end

function execute_with_selected_zone(bldid, fn)
	if df.global.ui.main.mode == df.ui_sidebar_mode.Zones and
	   df.global.ui_sidebar_menus.zone.selected and df.global.ui_sidebar_menus.zone.selected.id == bldid then
		return fn(screen_main(), df.global.ui_sidebar_menus.zone.selected)
	end

	return execute_with_main_mode(df.ui_sidebar_mode.Zones, function(ws)
		local zone = df.building.find(bldid)

		-- we assume there will be a tile belonging to the zone on y1
		local x = zone.x1
		while x < zone.x2 do
			if zone.room.extents[x-zone.x1] > 0 then
				break
			end
			x = x + 1
		end

		df.global.cursor.x = x
	    df.global.cursor.y = zone.y1
	    df.global.cursor.z = zone.z-1
	    gui.simulateInput(ws, K'CURSOR_UP_Z')

	    return fn(ws, zone)
	end)
end

function execute_with_nobles_screen(reset, fn)
	return execute_with_main_mode(df.ui_sidebar_mode.Default, function(ws)
		gui.simulateInput(ws, K'D_NOBLES')
		local noblesws = dfhack.gui.getCurViewscreen() --as:df.viewscreen_layer_noblelistst
		--todo: check that we have switched to nobles screen
		--todo: why is this here? 
		if reset then
		    noblesws.mode = df.viewscreen_layer_noblelistst.T_mode.List
		    noblesws.layer_objects[0].active = true
		    noblesws.layer_objects[0].enabled = true
		    noblesws.layer_objects[1].active = false
		    noblesws.layer_objects[1].enabled = false
		end

		local ok,ret = pcall(fn, noblesws)

		-- nobles screen applies changes (noble replacement) only when destroyed,
		-- if we don't do it now, the app will refresh and load old data
		--noblesws.breakdown_level = df.interface_breakdown_types.STOPSCREEN
		noblesws.parent.child = nil
		noblesws:delete()

		if not ok then
			error (ret)
		end
		return ret
	end)
end

function execute_with_military_screen(fn)
	return execute_with_main_mode(df.ui_sidebar_mode.Default, function(ws)
		gui.simulateInput(ws, K'D_MILITARY')
		local milws = dfhack.gui.getCurViewscreen() --as:df.viewscreen_layer_militaryst

		local ok,ret = pcall(fn, milws)

		milws.breakdown_level = df.interface_breakdown_types.STOPSCREEN

		if not ok then
			error (ret)
		end
		return ret
	end)
end

function execute_with_units_screen(fn)
	return execute_with_main_mode(df.ui_sidebar_mode.Default, function(ws)
		gui.simulateInput(ws, K'D_UNITLIST')
		local unitsws = dfhack.gui.getCurViewscreen() --as:df.viewscreen_unitlistst

		local ok,ret = pcall(fn, unitsws)

		unitsws.breakdown_level = df.interface_breakdown_types.STOPSCREEN

		if not ok then
			error (ret)
		end
		return ret
	end)
end

function execute_with_jobs_screen(fn)
	return execute_with_main_mode(df.ui_sidebar_mode.Default, function(ws)
		gui.simulateInput(ws, K'D_JOBLIST')
		local jobsws = dfhack.gui.getCurViewscreen()

		local ok,ret = pcall(fn, jobsws)

		jobsws.breakdown_level = df.interface_breakdown_types.STOPSCREEN

		if not ok then
			error (ret)
		end
		return ret
	end)
end

status_pages = {
	Overview = -1,
	Animals = 0,
	Kitchen = 1,
	Stone = 2,
	Stocks = 3,
	Health = 4,
	Prices = 5,
	Currency = 6,
	Justice = 7,
}

function execute_with_status_page(pageid, fn)
	return execute_with_main_mode(df.ui_sidebar_mode.Default, function(ws)
		gui.simulateInput(ws, K'D_STATUS')
		local statusws = dfhack.gui.getCurViewscreen() --as:df.viewscreen_overallstatusst
		if statusws._type ~= df.viewscreen_overallstatusst then
			error('error switching to status screen '..tostring(statusws._type))
		end
		
		if pageid ~= -1 then
			statusws.visible_pages:insert(0,pageid)
		    gui.simulateInput(statusws, K'SELECT')
	    end
        
        local pagews = dfhack.gui.getCurViewscreen()
		local ok,ret = pcall(fn, pagews)
        
        pagews.breakdown_level = df.interface_breakdown_types.STOPSCREEN
        statusws.breakdown_level = df.interface_breakdown_types.STOPSCREEN

		if not ok then
			error (ret)
		end
        return ret
	end)
end

function execute_with_manager_screen(fn)
	local jobsws = df.viewscreen_joblistst:new()
	gui.simulateInput(jobsws, K'UNITJOB_MANAGER')
	jobsws:delete()

	local managerws = dfhack.gui.getCurViewscreen() --as:df.viewscreen_jobmanagementst

	local ok,ret = pcall(fn, managerws)

	managerws.breakdown_level = df.interface_breakdown_types.STOPSCREEN

	if not ok then
		error (ret)
	end
	return ret
end

function execute_with_manager_orders_screen(fn)
	return execute_with_manager_screen(function(ws)
		gui.simulateInput(ws, K'MANAGER_NEW_ORDER')
		local ordersws = dfhack.gui.getCurViewscreen() --as:df.viewscreen_createquotast

		local ok,ret = pcall(fn, ordersws)

		ordersws.breakdown_level = df.interface_breakdown_types.STOPSCREEN

		if not ok then
			error (ret)
		end
		return ret
	end)
end

function execute_with_locations_screen(fn)
	return execute_with_main_mode(df.ui_sidebar_mode.Default, function(ws)
		gui.simulateInput(ws, K'D_LOCATIONS')
		local locsws = dfhack.gui.getCurViewscreen() --as:df.viewscreen_locationsst

		local ok,ret = pcall(fn, locsws)

		locsws.breakdown_level = df.interface_breakdown_types.STOPSCREEN

		if not ok then
			error (ret)
		end
		return ret
	end)
end

function execute_with_petitions_screen(fn)
	return execute_with_main_mode(df.ui_sidebar_mode.Default, function(ws)
		gui.simulateInput(ws, K'D_PETITIONS')
		local petitionsws = dfhack.gui.getCurViewscreen() --as:df.viewscreen_petitionsst
		if petitionsws._type ~= df.viewscreen_petitionsst then
			error(errmsg_wrongscreen(petitionsws))
		end

		local ok,ret = pcall(fn, petitionsws)

		petitionsws.breakdown_level = df.interface_breakdown_types.STOPSCREEN

		if not ok then
			error (ret)
		end
		return ret
	end)
end

function execute_with_locations_for_building(bldid, fn)
    local bld = (bldid and bldid ~= -1) and df.building.find(bldid) or df.global.world.selected_building
    if not bld then
        error('no building/zone '..tostring(bldid))
    end

    if bld._type ~= df.building_civzonest and bld._type ~= df.building_bedst and bld._type ~= df.building_tablest then
	    error('wrong building type '..tostring(bldid)..' '..tostring(bld._type))
    end

    if not bld.is_room then
        error('not a room '..tostring(bldid))
    end

    if bld._type == df.building_civzonest then --as:bld=df.building_civzonest
	    if not bld.zone_flags.meeting_area then
	    	error('not a meeting area '..tostring(bld.zone_flags.whole))
	    end

	    return execute_with_selected_zone(bldid, function(ws)
			gui.simulateInput(ws, K'ASSIGN_LOCATION')
			local ok,ret = pcall(fn, ws, bld)
			df.global.ui.main.mode = df.ui_sidebar_mode.Zones

			if not ok then
				error (ret)
			end
			return ret
	    end)
	end

	--todo: convert this to execute_with_selected
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        error(errmsg_wrongscreen(ws))
    end

    if df.global.ui.main.mode ~= df.ui_sidebar_mode.QueryBuilding or df.global.world.selected_building == nil then
        error('no selected building')
    end    

	gui.simulateInput(ws, K'ASSIGN_LOCATION')    
	local ok,ret = pcall(fn, ws, bld)
	df.global.ui.main.mode = df.ui_sidebar_mode.QueryBuilding

	if not ok then
		error (ret)
	end
	return ret
end

function execute_with_job_details(bldid, idx, fn)
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        error(errmsg_wrongscreen(ws))
    end

    if df.global.ui.main.mode ~= 17 or df.global.world.selected_building == nil then
        error('no selected building')
    end

    local bld = df.global.world.selected_building
    --todo: check bld.id == bldid

    if idx < 0 or idx > #bld.jobs then
    	error('invalid job idx '..tostring(idx))
    end

    df.global.ui_workshop_job_cursor = idx

    gui.simulateInput(ws, K'BUILDJOB_DETAILS')
    
    --xxx: this is (temporarily?) done in calling fns to distinguish between error and no details when needed
    --[[if df.global.ui_sidebar_menus.job_details.job == nil then
    	error('could not transition to job detail settings')
    end]]

	local ok,ret = pcall(fn, ws) 
	
	df.global.ui_sidebar_menus.job_details.job = nil

	if not ok then
		error (ret)
	end
	return ret
end

function execute_with_order_details(idx, fn)
	return execute_with_manager_screen(function(ws)
		--todo: check idx range
	    ws.sel_idx = idx

	    gui.simulateInput(ws, K'MANAGER_DETAILS')
	    
	    local detws = dfhack.gui.getCurViewscreen() --as:df.viewscreen_workquota_detailsst
	    if detws._type ~= df.viewscreen_workquota_detailsst then
	    	error('could not switch to order details screen '..tostring(detws._type))
	    end

		local ok,ret = pcall(fn, detws) 
		
		detws.breakdown_level = df.interface_breakdown_types.STOPSCREEN

		if not ok then
			error (ret)
		end
		return ret
	end)
end

function execute_with_rooms_screen(fn)
	return execute_with_main_mode(df.ui_sidebar_mode.Default, function(ws)
		gui.simulateInput(ws, K'D_ROOMS')
		local roomsws = dfhack.gui.getCurViewscreen() --as:df.viewscreen_buildinglistst
		if roomsws._type ~= df.viewscreen_buildinglistst then
			error(errmsg_wrongscreen(roomsws))
		end

		local ok,ret = pcall(fn, roomsws)

		roomsws.breakdown_level = df.interface_breakdown_types.STOPSCREEN

		if not ok then
			error (ret)
		end
		return ret
	end)
end

function execute_with_hauling_menu(fn)
	return execute_with_main_mode(df.ui_sidebar_mode.Default, function(ws)
		gui.simulateInput(ws, K'D_HAULING')
		if df.global.ui.main.mode ~= df.ui_sidebar_mode.Hauling then
			error('error switching to hauling menu '..tostring(df.global.ui.main.mode))
		end

		local ok,ret = pcall(fn, ws)

		if not ok then
			error (ret)
		end
		return ret
	end)
end