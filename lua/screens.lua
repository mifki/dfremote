function screen_main()
    return df.global.gview.view.child
end

local function save_state()
    --todo: save cursor pos
    return { mode=df.global.ui.main.mode }
end

local function restore_state(state)
    --todo: restore cursor pos
    df.global.ui.main.mode = state.mode
end

function execute_with_main_mode(mode, fn, active_and_no_reset)
    local ws = screen_main()
    if active_and_no_reset and ws.child then
        error(errmsg_wrongscreen(ws))
    end

    local state = save_state()
    df.global.ui.main.mode = mode

    local ok,ret = pcall(fn, ws)

    if not active_and_no_reset or not ok then
        restore_state(state)
    end

    if not ok then
        error (ret)
    end
    return ret  
end

function execute_with_selected_zone(bldid, fn)
    local zone = df.building.find(bldid)
    if not zone then
        error('no zone with id '..tostring(bldid))
    end

    if df.global.ui.main.mode == df.ui_sidebar_mode.Zones and
       df.global.ui_sidebar_menus.zone.selected and df.global.ui_sidebar_menus.zone.selected.id == bldid then
        return fn(screen_main(), zone)
    end

    return execute_with_main_mode(df.ui_sidebar_mode.Zones, function(ws) 
        building_focus(zone, ws)

        return fn(ws, zone)
    end)
end

function execute_with_selected_unit(unitid, fn)
    local unit = df.unit.find(unitid)
    if not unit then
        error('no unit with id '..tostring(unitid))
    end

    if df.global.ui.main.mode == df.ui_sidebar_mode.ViewUnits and
       df.global.world.units.active[df.global.ui_selected_unit].id == unitid then
        return fn(screen_main(), unit)
    end

    return execute_with_main_mode(df.ui_sidebar_mode.ViewUnits, function(ws) 
        unit_focus(unit, ws)

        return fn(ws, unit)
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
    -- military screen commits changes (squad creation) upon destruction, so that if the app creates a squad,
    -- and requests a list straight away, the screen will not have been destroyed yet, and a new screen won't
    -- show changes. so if the old screen is still there, reuse it
    local milws = dfhack.gui.getCurViewscreen() --as:df.viewscreen_layer_militaryst
    if milws._type == df.viewscreen_layer_militaryst and milws.breakdown_level == df.interface_breakdown_types.STOPSCREEN then
        local ok,ret = pcall(fn, milws)

        if not ok then
            error (ret)
        end

        return ret
    end

    return execute_with_main_mode(df.ui_sidebar_mode.Default, function(ws)
        gui.simulateInput(ws, K'D_MILITARY')
        local milws = dfhack.gui.getCurViewscreen() --as:df.viewscreen_layer_militaryst
        milws.breakdown_level = df.interface_breakdown_types.STOPSCREEN

        local ok,ret = pcall(fn, milws)

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
        unitsws.breakdown_level = df.interface_breakdown_types.STOPSCREEN

        local ok,ret = pcall(fn, unitsws)

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
        jobsws.breakdown_level = df.interface_breakdown_types.STOPSCREEN

        local ok,ret = pcall(fn, jobsws)

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
        statusws.breakdown_level = df.interface_breakdown_types.STOPSCREEN

        if statusws._type ~= df.viewscreen_overallstatusst then
            error('error switching to status screen '..tostring(statusws._type))
        end
        
        if pageid ~= -1 then
            statusws.visible_pages:insert(0,pageid)
            gui.simulateInput(statusws, K'SELECT')
        end
        
        local pagews = dfhack.gui.getCurViewscreen()
        pagews.breakdown_level = df.interface_breakdown_types.STOPSCREEN

        local ok,ret = pcall(fn, pagews)

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
    managerws.breakdown_level = df.interface_breakdown_types.STOPSCREEN

    local ok,ret = pcall(fn, managerws)

    if not ok then
        error (ret)
    end
    return ret
end

function execute_with_manager_orders_screen(fn)
    return execute_with_manager_screen(function(ws)
        gui.simulateInput(ws, K'MANAGER_NEW_ORDER')
        local ordersws = dfhack.gui.getCurViewscreen() --as:df.viewscreen_createquotast
        ordersws.breakdown_level = df.interface_breakdown_types.STOPSCREEN

        local ok,ret = pcall(fn, ordersws)

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
        locsws.breakdown_level = df.interface_breakdown_types.STOPSCREEN

        local ok,ret = pcall(fn, locsws)

        if not ok then
            error (ret)
        end
        return ret
    end)
end

function execute_with_world_screen(fn)
    return execute_with_main_mode(df.ui_sidebar_mode.Default, function(ws)
        gui.simulateInput(ws, K'D_CIVLIST')
        local locsws = dfhack.gui.getCurViewscreen() --as:df.viewscreen_civlistst
        locsws.breakdown_level = df.interface_breakdown_types.STOPSCREEN

        local ok,ret = pcall(fn, locsws)

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
        petitionsws.breakdown_level = df.interface_breakdown_types.STOPSCREEN

        if petitionsws._type ~= df.viewscreen_petitionsst then
            error(errmsg_wrongscreen(petitionsws))
        end

        local ok,ret = pcall(fn, petitionsws)

        if not ok then
            error (ret)
        end
        return ret
    end)
end

function execute_with_locations_for_building(bldid, fn)
    local bld = (bldid and bldid ~= -1) and df.building.find(bldid) or df.global.world.selected_building
    if not bld then
        error('no building/zone with id '..tostring(bldid))
    end

    --todo: if all rooms can now be added to locations, just check if it's a room
    if bld._type ~= df.building_civzonest and 
       bld._type ~= df.building_bedst and 
       bld._type ~= df.building_tablest and
       bld._type ~= df.building_display_furniturest and
       bld._type ~= df.building_statuest then
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

    if df.global.ui.main.mode ~= df.ui_sidebar_mode.QueryBuilding or df.global.world.selected_building == nil then
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

    local ok,ret = pcall(fn, ws, bld.jobs[idx]) 
    
    -- if a viewscreen_image_creatorst has automatically been open, close it
    local ws2 = dfhack.gui.getCurViewscreen()
    if ws2._type == df.viewscreen_image_creatorst then
        ws2.breakdown_level = df.interface_breakdown_types.STOPSCREEN
    end

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
        
        local detws = dfhack.gui.getCurViewscreen()
        if detws._type ~= df.viewscreen_workquota_detailsst then
            error('could not switch to order details screen '..tostring(detws._type))
        end

        --xxx: if an order has an image detail only, the order of screens will be weird:
        --xxx: manager->viewscreen_image_creatorst->viewscreen_workquota_detailsst
        --xxx: let's destroy the last screen now in that case, so that we always continue
        --xxx: either with a valid viewscreen_workquota_detailsst or with a viewscreen_image_creatorst
        if detws.parent._type == df.viewscreen_image_creatorst then
            detws = detws.parent
            detws.child:delete()
            detws.child = nil
        end

        local ok,ret = pcall(fn, detws) 
        
        detws.breakdown_level = df.interface_breakdown_types.STOPSCREEN

        if not ok then
            error (ret)
        end
        return ret
    end)
end

function execute_with_order_conditions(idx, fn)
    return execute_with_manager_screen(function(ws)
        --todo: check idx range
        ws.sel_idx = idx

        gui.simulateInput(ws, K'MANAGER_CONDITIONS')
        
        local condws = dfhack.gui.getCurViewscreen() --as:df.viewscreen_workquota_conditionst
        if condws._type ~= df.viewscreen_workquota_conditionst then
            error('could not switch to order conditions screen '..tostring(condws._type))
        end
        
        local ok,ret = pcall(fn, condws)        

        condws.breakdown_level = df.interface_breakdown_types.STOPSCREEN

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
        roomsws.breakdown_level = df.interface_breakdown_types.STOPSCREEN

        if roomsws._type ~= df.viewscreen_buildinglistst then
            error(errmsg_wrongscreen(roomsws))
        end

        local ok,ret = pcall(fn, roomsws)

        if not ok then
            error (ret)
        end
        return ret
    end)
end

function execute_with_hauling_menu(fn, active_and_no_reset)
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
    end, active_and_no_reset)
end

function execute_with_display_items_for_building(bldid, fn)
    local bld = (bldid and bldid ~= -1) and df.building.find(bldid) or df.global.world.selected_building
    if not bld then
        error('no building/zone with id '..tostring(bldid))
    end

    if bld._type ~= df.building_display_furniturest then
        error('wrong building type '..tostring(bldid)..' '..tostring(bld._type))
    end

    --todo: convert this to execute_with_selected
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        error(errmsg_wrongscreen(ws))
    end

    if df.global.ui.main.mode ~= df.ui_sidebar_mode.QueryBuilding or df.global.world.selected_building == nil then
        error('no selected building')
    end    

    gui.simulateInput(ws, K'BUILDJOB_DISPLAY_FURNITURE_SET')    

    local dispws = dfhack.gui.getCurViewscreen() --as:df.viewscreen_assign_display_itemst
    if dispws._type ~= df.viewscreen_assign_display_itemst then
        error('could not switch to display items screen '..tostring(dispws._type))
    end
    
    local ok,ret = pcall(fn, dispws, bld)       

    dispws.breakdown_level = df.interface_breakdown_types.STOPSCREEN

    if not ok then
        error (ret)
    end
    return ret
end
