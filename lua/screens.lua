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
	return execute_with_main_mode(df.ui_sidebar_mode.Zones, function(ws)
		local zone = df.building.find(bldid)

		df.global.cursor.x = zone.x1
	    df.global.cursor.y = zone.y1
	    df.global.cursor.z = zone.z-1
	    gui.simulateInput(ws, 'CURSOR_UP_Z')

	    return fn(ws, zone)
	end)
end

function execute_with_nobles_screen(reset, fn)
	return execute_with_main_mode(df.ui_sidebar_mode.Default, function(ws)
		gui.simulateInput(ws, 'D_NOBLES')
		local noblesws = dfhack.gui.getCurViewscreen()

		--todo: why is this here? 
		if reset then
		    noblesws.mode = 0
		    noblesws.layer_objects[0].active = true
		    noblesws.layer_objects[0].enabled = true
		    noblesws.layer_objects[1].active = false
		    noblesws.layer_objects[1].enabled = false
		end

		local ok,ret = pcall(fn, noblesws)

		noblesws.breakdown_level = 2

		if not ok then
			error (ret)
		end
		return ret
	end)
end

function execute_with_military_screen(fn)
	return execute_with_main_mode(df.ui_sidebar_mode.Default, function(ws)
		gui.simulateInput(ws, 'D_MILITARY')
		local milws = dfhack.gui.getCurViewscreen()

		local ok,ret = pcall(fn, milws)

		milws.breakdown_level = 2

		if not ok then
			error (ret)
		end
		return ret
	end)
end

function execute_with_units_screen(fn)
	return execute_with_main_mode(df.ui_sidebar_mode.Default, function(ws)
		gui.simulateInput(ws, 'D_UNITLIST')
		local unitsws = dfhack.gui.getCurViewscreen()

		local ok,ret = pcall(fn, unitsws)

		unitsws.breakdown_level = 2

		if not ok then
			error (ret)
		end
		return ret
	end)
end

function execute_with_jobs_screen(fn)
	return execute_with_main_mode(df.ui_sidebar_mode.Default, function(ws)
		gui.simulateInput(ws, 'D_JOBLIST')
		local jobsws = dfhack.gui.getCurViewscreen()

		local ok,ret = pcall(fn, jobsws)

		jobsws.breakdown_level = 2

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
		gui.simulateInput(ws, 'D_STATUS')
		local statusws = dfhack.gui.getCurViewscreen()
		
		if pageid ~= -1 then
			statusws.visible_pages:insert(0,pageid)
		    gui.simulateInput(statusws, 'SELECT')
	    end
        
        local pagews = dfhack.gui.getCurViewscreen()
		local ok,ret = pcall(fn, pagews)
        
        pagews.breakdown_level = 2
        statusws.breakdown_level = 2

		if not ok then
			error (ret)
		end
        return ret
	end)
end

function execute_with_manager_screen(fn)
	local jobsws = df.viewscreen_joblistst:new()
	gui.simulateInput(jobsws, 'UNITJOB_MANAGER')
	jobsws:delete()

	local managerws = dfhack.gui.getCurViewscreen()

	local ok,ret = pcall(fn, managerws)

	managerws.breakdown_level = 2

	if not ok then
		error (ret)
	end
	return ret
end

function execute_with_manager_orders_screen(fn)
	return execute_with_manager_screen(function(ws)
		gui.simulateInput(ws, 'MANAGER_NEW_ORDER')
		local ordersws = dfhack.gui.getCurViewscreen()

		local ok,ret = pcall(fn, ordersws)

		ordersws.breakdown_level = 2

		if not ok then
			error (ret)
		end
		return ret
	end)
end

function execute_with_locations_screen(fn)
	return execute_with_main_mode(df.ui_sidebar_mode.Default, function(ws)
		gui.simulateInput(ws, 'D_LOCATIONS')
		local locsws = dfhack.gui.getCurViewscreen()

		local ok,ret = pcall(fn, locsws)

		locsws.breakdown_level = 2

		if not ok then
			error (ret)
		end
		return ret
	end)
end
