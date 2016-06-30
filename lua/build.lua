function clone_build_button(orig)
    if orig._type == df.interface_button_construction_building_selectorst then
        local btn = df.interface_button_construction_building_selectorst:new()

        --btn.building=bld
        btn.building_type = orig.building_type
        btn.building_subtype=orig.building_subtype
        btn.custom_type = orig.custom_type

        return btn
    end
end

local lastbldcmd = -1

--luacheck: in=number
function build(idx)
    local btn = building_btns[idx] --as:df.interface_button_construction_building_selectorst

    lastbldcmd = idx

    local x = df.global.cursor.x
    local y = df.global.cursor.y
    local z = df.global.window_z

    df.global.ui.main.mode = df.ui_sidebar_mode.Build
    btn:click()

    if x ~= -30000 then
        df.global.cursor.x = x
        df.global.cursor.y = y

        local ws = screen_main()
        if z > 0 then
            df.global.cursor.z = z - 1
            gui.simulateInput(ws, 'CURSOR_UP_Z')        
        else
            df.global.cursor.z = z + 1
            gui.simulateInput(ws, 'CURSOR_DOWN_Z')
        end
    end
end

function build_get_errors()
    local ret = {}

    for i,err in ipairs(df.global.ui_build_selector.errors) do
        table.insert(ret, err.value)
    end

    return ret
end

--luacheck: in=bool
function build_confirm(fast)
    local ws = dfhack.gui.getCurViewscreen()
    --todo: check that we're in the right mode

    gui.simulateInput(ws, 'SELECT')
    
    -- Automatically select first (closest) item(s); break if wrong mode or nothing to select
    if istrue(fast) then
        if df.global.ui.main.mode == df.ui_sidebar_mode.Build and df.global.ui_build_selector.building_type ~= -1 and df.global.ui_build_selector.stage == 2 then
            local continue
            repeat
                continue = false
                for i,choice in ipairs(df.global.ui_build_selector.choices) do
                    if choice:getNumCandidates() > 0 then
                        df.global.ui_build_selector.sel_index = i
                        gui.simulateInput(ws, 'SELECT')
                        
                        if df.global.ui_build_selector.building_type == -1 then
                            if lastbldcmd ~= -1 then
                                build(lastbldcmd)
                            else
                                df.global.ui.main.mode = 0
                            end
                            
                            return {}
                        else
                            continue = true
                        end
                    end
                end
            until not continue
        end
    end

    return build_req_get(true) or {} --todo: or nil ?
end

--luacheck: in=bool
function build_req_get(grouped)
    if df.global.ui.main.mode == df.ui_sidebar_mode.Build and df.global.ui_build_selector.building_type ~= -1 and df.global.ui_build_selector.stage == 2 then
        if istrue(grouped) ~= istrue(df.global.ui_build_selector.is_grouped) then
            gui.simulateInput(screen_main(), 'BUILDING_EXPAND_CONTRACT')
        end

        local choices = {}
        for i,choice in ipairs(df.global.ui_build_selector.choices) do
            local title = dfhack.df2utf(utils.call_with_string(choice, 'getName'))
            table.insert(choices, { title, choice:getUsedCount(), choice:getNumCandidates(), choice.distance })
        end

        local req = df.global.ui_build_selector.requirements[df.global.ui_build_selector.req_index].count_required
        local max = df.global.ui_build_selector.requirements[df.global.ui_build_selector.req_index].count_max
        local provided = df.global.ui_build_selector.requirements[df.global.ui_build_selector.req_index].count_provided

        return { choices, req, max, provided }
    end

    return nil
end

--luacheck: in=number,bool,bool
function build_req_choose(idx, on, all)
    local ws = dfhack.gui.getCurViewscreen()

    --todo: check that we're in the right mode
    --todo: client should update counts itself, just return finished or not

    df.global.ui_build_selector.sel_index = idx

    on = istrue(on)
    all = istrue(all)

    if on then
        gui.simulateInput(ws, (all and 'SELECT_ALL' or 'SELECT'))
    else
        gui.simulateInput(ws, (all and 'DESELECT_ALL' or 'DESELECT'))
    end

    -- If we're done selecting materials, repeat the last build command - useful when placing many buildings like beds
    if df.global.ui_build_selector.building_type == -1 then
        if lastbldcmd ~= -1 then
            build(lastbldcmd)
        else
            df.global.ui.main.mode = df.ui_sidebar_mode.Default
        end

        return mp.NIL
    else
        return build_req_get(df.global.ui_build_selector.is_grouped)
    end
end

--luacheck: in=
function build_req_cancel()
    local ws = dfhack.gui.getCurViewscreen()
    --todo: check that we're in the right mode

    gui.simulateInput(ws, 'LEAVESCREEN')

    if lastbldcmd ~= -1 then
        build(lastbldcmd)
    else
        df.global.ui.main.mode = df.ui_sidebar_mode.Default
    end
end

--luacheck: in=
function build_req_done()
    local ws = dfhack.gui.getCurViewscreen()
    --todo: check that we're in the right mode

    gui.simulateInput(ws, 'BUILDING_ADVANCE_STAGE')

    -- If we're done selecting materials, repeat the last build command - useful when placing many buildings like beds
    if df.global.ui_build_selector.building_type == -1 then
        if lastbldcmd ~= -1 then
            build(lastbldcmd)
        else
            df.global.ui.main.mode = df.ui_sidebar_mode.Default
        end

        return mp.NIL
    else
        return build_req_get(df.global.ui_build_selector.is_grouped)
    end
end

--luacheck: in=
function build_has_options()
    local btype = df.global.ui_build_selector.building_type
    local bsub = df.global.ui_build_selector.building_subtype

    return btype == df.building_type.Bridge or btype == df.building_type.AxleHorizontal or btype == df.building_type.ScrewPump
     or btype == df.building_type.Rollers or btype == df.building_type.WaterWheel
     or (btype == df.building_type.Trap and (bsub == 1 or bsub == 5)) --pressure plate, track stop
end

local track_stop_friction_values = { 10, 50, 500, 10000, 50000 }

--luacheck: in=
function build_options_get()
    if df.global.ui.main.mode == df.ui_sidebar_mode.Zones then
         local zonemode = df.global.ui_sidebar_menus.zone.mode
         --local selzone = df.global.ui_sidebar_menus.zone.selected
         --local selzone_name = selzone and ('Activity Zone #'..tostring(selzone.zone_num)) or  mp.NIL
         --local selzone_id = selzone and selzone.id or mp.NIL
         return { df.building_type.Civzone, zonemode --[[, selzone_name, selzone_id]] }
    end

    if df.global.ui.main.mode ~= df.ui_sidebar_mode.Build or df.global.ui_build_selector.building_type == -1 or df.global.ui_build_selector.stage ~= 1 then
        return
    end

    local btype = df.global.ui_build_selector.building_type

    local ret
    if btype == df.building_type.Bridge or btype == df.building_type.AxleHorizontal
        or btype == df.building_type.ScrewPump or btype == df.building_type.WaterWheel then
        ret = { btype, df.global.world.selected_direction }
    
    elseif btype == df.building_type.Rollers then
        -- Roller speeds are 10000-50000
        local speed = df.global.ui_build_selector.speed / 10000
        ret = { btype, df.global.world.selected_direction, speed }

    elseif btype == df.building_type.Trap and df.global.ui_build_selector.building_subtype == 1 then --pressure plate
        local pi = df.global.ui_build_selector.plate_info
        ret = { btype, 1, pi.flags.whole, pi.water_min, pi.water_max, pi.magma_min, pi.magma_max, pi.track_min, pi.track_max, pi.unit_min, pi.unit_max }

    elseif btype == df.building_type.Trap and df.global.ui_build_selector.building_subtype == 5 then --track stop
        local _,__,friction = utils.binsearch(track_stop_friction_values, df.global.ui_build_selector.friction)
        local dir = 0
        if istrue(df.global.ui_build_selector.use_dump) then
            local dx = df.global.ui_build_selector.dump_x_shift
            local dy = df.global.ui_build_selector.dump_y_shift

            if dx == 0 and dy == -1 then
                dir = 1
            elseif dx == 0 and dy == 1 then
                dir = 2
            elseif dx == 1 and dy == 0 then
                dir = 3
            elseif dx == -1 and dy == 0 then
                dir = 4
            end
        end

        ret = { btype, 5, friction - 1, dir }
    end

    return ret
end

function fix_build_size(vertical)
    local w = df.global.world.building_width
    local h = df.global.world.building_height
    local size = w > h and w or h
    if vertical then
        df.global.world.building_width = 1
        df.global.world.building_height = size
    else
        df.global.world.building_width = size
        df.global.world.building_height = 1
    end
end

--luacheck: in=number,number
function build_options_set(option, value)
    if df.global.ui.main.mode == df.ui_sidebar_mode.Zones then
         local oldzonemode = df.global.ui_sidebar_menus.zone.mode
         local started = (oldzonemode == df.ui_sidebar_menus.T_zone.T_mode.Rectangle and df.global.selection_rect.start_x ~= -30000) or df.global.ui_building_in_resize

         if option == 1 then
            if oldzonemode ~= value then
                df.global.ui_sidebar_menus.zone.mode = value

                if oldzonemode == 0 and value ~= 0 or oldzonemode ~= 0 and value == 0 then
                    df.global.selection_rect.start_x = -30000
                    df.global.ui_building_in_resize = false

                    -- In flow modes, zone already exists by this time, so we need to delete it
                    if oldzonemode ~= 0 then
                        local zone = df.global.ui_sidebar_menus.zone.selected
                        if zone then
                            dfhack.buildings.deconstruct(df.global.ui_sidebar_menus.zone.selected)
                            df.global.ui_sidebar_menus.zone.selected = nil
                        end
                    end
                else
                    -- Need to update display after flow / floor flow change
                    local ws = dfhack.gui.getCurViewscreen()
                    gui.simulateInput(ws, 'SECONDSCROLL_DOWN')
                    gui.simulateInput(ws, 'SECONDSCROLL_UP')
                end
            end
         end

         return
    end

    if df.global.ui.main.mode ~= df.ui_sidebar_mode.Build or df.global.ui_build_selector.building_type == -1 or df.global.ui_build_selector.stage ~= 1 then
        return
    end

    local btype = df.global.ui_build_selector.building_type

    if btype == df.building_type.Bridge or btype == df.building_type.AxleHorizontal 
        or btype == df.building_type.Rollers or btype == df.building_type.ScrewPump
        or btype == df.building_type.WaterWheel then
        if option == 1 then
            df.global.world.selected_direction = value

            if btype == df.building_type.AxleHorizontal or btype == df.building_type.WaterWheel then
                fix_build_size(value == 0)
            elseif btype == df.building_type.Rollers --[[or btype == df.building_type.ScrewPump]] then
                fix_build_size(value == 0 or value == 2)
            end

            if btype == df.building_type.Bridge or btype == df.building_type.ScrewPump then
                -- Placing requirements differ depending on direction, need to force update errors
                local ws = dfhack.gui.getCurViewscreen()
                gui.simulateInput(ws, 'CURSOR_DOWN_Z')
                gui.simulateInput(ws, 'CURSOR_UP_Z')
            end
        end
    end

    if btype == df.building_type.Trap and df.global.ui_build_selector.building_subtype == 5 then --track stop
        if option == 1 then
            df.global.ui_build_selector.friction = track_stop_friction_values[value+1]
        elseif option == 2 then
            if value == 0 then
                df.global.ui_build_selector.use_dump = 0
                df.global.ui_build_selector.dump_x_shift = 0
                df.global.ui_build_selector.dump_y_shift = 0
            elseif value == 1 then
                df.global.ui_build_selector.use_dump = 1
                df.global.ui_build_selector.dump_x_shift = 0
                df.global.ui_build_selector.dump_y_shift = -1
            elseif value == 2 then
                df.global.ui_build_selector.use_dump = 1
                df.global.ui_build_selector.dump_x_shift = 0
                df.global.ui_build_selector.dump_y_shift = 1
            elseif value == 3 then
                df.global.ui_build_selector.use_dump = 1
                df.global.ui_build_selector.dump_x_shift = 1
                df.global.ui_build_selector.dump_y_shift = 0
            elseif value == 4 then
                df.global.ui_build_selector.use_dump = 1
                df.global.ui_build_selector.dump_x_shift = -1
                df.global.ui_build_selector.dump_y_shift = 0
            end
        end
    end


    if btype == df.building_type.Rollers and option == 2 then
        -- Roller speeds are 10000-50000
        df.global.ui_build_selector.speed = value * 10000
    end

    return true
end

--luacheck: in=number[]
function build_set_trap_options(info)
    local btype = df.global.ui_build_selector.building_type
    if btype == df.building_type.Trap and df.global.ui_build_selector.building_subtype == 1 then --pressure plate
        local pi = df.global.ui_build_selector.plate_info

        pi.flags.whole = info[3]
        pi.water_min = info[4]
        pi.water_max = info[5]
        pi.magma_min = info[6]
        pi.magma_max = info[7]
        pi.track_min = info[8]
        pi.track_max = info[9]
        pi.unit_min = info[10]
        pi.unit_max = info[11]

        local ws = dfhack.gui.getCurViewscreen()
        gui.simulateInput(ws, 'CURSOR_DOWN_Z')
        gui.simulateInput(ws, 'CURSOR_UP_Z')

    --xxx: not used
    elseif btype == df.building_type.Trap and df.global.ui_build_selector.building_subtype == 5 then --track stop
    end
end