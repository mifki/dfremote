function zone_create()
    df.global.ui.main.mode = 0

    local ws = dfhack.gui.getCurViewscreen()
    gui.simulateInput(ws, 'D_CIVZONE')
end

function zone_settings_get(bldid)
    local zone = (bldid and bldid ~= -1 and bldid ~= 0) and df.building.find(bldid) or df.global.ui_sidebar_menus.zone.selected
    if not zone then
        error('no zone found for id '..tostring(bldid))
    end

    local loc
    if df_ver >= 42 and zone.zone_flags.meeting_area and zone.location_id ~= -1 then
        loc = location_find_by_id(zone.location_id)
    end

    return { zonename(zone), zone.id, zone.zone_flags.whole, loc and locname(loc) or mp.NIL }
end

function zone_settings_set(bldid, option, value)
    local zone = df.building.find(bldid)

    if option >= 0 and option <= 31 then
        zone.zone_flags[option] = istrue(value)
        if istrue(value) then
            if option == df.building_civzonest.T_zone_flags.pen_pasture then
                zone.zone_flags.pit_pond = false
            elseif option == df.building_civzonest.T_zone_flags.pit_pond then
                zone.zone_flags.pen_pasture = false
            end
        end
    end
end

function zone_information_get(bldid, mode)
    local zone = df.building.find(bldid)

    if mode == df.building_civzonest.T_zone_flags.gather then
        return { zone.gather_flags.whole }
    end 

    if mode == df.building_civzonest.T_zone_flags.hospital then
        local counts = { [df.building_type.Bed]=0, [df.building_type.Table]=0, [df.building_type.TractionBench]=0, [df.building_type.Box]=0 }

        for i,bld in ipairs(df.global.world.buildings.all) do
            if bld.z == zone.z and not bld.is_room then
                if bld.x1 >= zone.x1 and bld.x1 <= zone.x2 and bld.y1 >= zone.y1 and bld.y1 <= zone.y2 then
                    counts[bld:getType()] = (counts[bld:getType()] or 0) + 1
                end
            end
        end

        local furniture = {
            counts[df.building_type.Bed], counts[df.building_type.Table],
            counts[df.building_type.TractionBench], counts[df.building_type.Box],        
        }

        local h = zone.hospital
        local supplies = {
            h.cur_thread, h.max_thread, 1500000, h.cur_cloth, h.max_cloth, 1000000,
            h.cur_splints, h.max_splints, 100, h.cur_crutches, h.max_crutches, 100,
            h.cur_plaster, h.max_plaster, 15000, h.cur_buckets, h.max_buckets, 100,
            h.cur_soap, h.max_soap, 15000
        }

        return { furniture, supplies }
    end

    if mode == df.building_civzonest.T_zone_flags.pen_pasture then
        local list = {}
        execute_with_selected_zone(bldid, function(ws)
            gui.simulateInput(ws, 'CIVZONE_PEN_OPTIONS')

            for i,unit in ipairs(df.global.ui_building_assign_units) do
                local title = unit_fulltitle(unit)
                local is_assigned = istrue(df.global.ui_building_assign_is_marked[i])
                local status = unit_assigned_status(unit, zone)
                table.insert(list, { title, unit.id, is_assigned, status })
            end
        end)
    
        return { list }
    end
    
    if mode == df.building_civzonest.T_zone_flags.pit_pond then
        local list = {}
        execute_with_selected_zone(bldid, function(ws)
            gui.simulateInput(ws, 'CIVZONE_POND_OPTIONS')

            for i,v in ipairs(df.global.ui_building_assign_type) do
                --xxx: this shouldn't happen, but was reported. bug in game? 
                if i >= #df.global.ui_building_assign_is_marked or i >= #df.global.ui_building_assign_units or i >= #df.global.ui_building_assign_items then
                    break
                end

                local title = '?something?'
                local obj = nil
                local is_assigned = istrue(df.global.ui_building_assign_is_marked[i])
                local status = 0

                --todo: should include unit sex for units
                if v == 0 then
                    obj = df.global.ui_building_assign_units[i]
                    title = unit_fulltitle(obj)
                    status = unit_assigned_status(obj, zone)
                elseif v == 1 then
                    obj = df.global.ui_building_assign_items[i]
                    title = itemname(obj, 0, true)
                    status = 0
                end

                table.insert(list, { title, obj and obj.id or -1, is_assigned, v, status })
            end
        end)

        return { list, zone.pit_flags.whole }
    end        

    return nil   
end

function zone_information_set(bldid, mode, option, value)
    local zone = df.building.find(bldid)
    if not zone or zone:getType() ~= df.building_type.Civzone then
        error('no zone or not a zone'..tostring(bldid))
    end

    if mode == df.building_civzonest.T_zone_flags.gather then
        zone.gather_flags[option] = istrue(value)

    elseif mode == df.building_civzonest.T_zone_flags.hospital then
        local h = zone.hospital
        if option == 1 then
            h.max_thread = value
        elseif option == 2 then
            h.max_cloth = value
        elseif option == 3 then
            h.max_splints = value
        elseif option == 4 then
            h.max_crutches = value
        elseif option == 5 then
            h.max_plaster = value
        elseif option == 6 then
            h.max_buckets = value
        elseif option == 7 then
            h.max_soap = value
        end
    end

    if mode == df.building_civzonest.T_zone_flags.pit_pond then
        if option == 1 then
            zone.pit_flags.is_pond = istrue(value)
        end
    end
end

function zone_assign(bldid, mode, objid, objtype, on)
    on = istrue(on)

    execute_with_selected_zone(bldid, function(ws)
        gui.simulateInput(ws, (mode == df.building_civzonest.T_zone_flags.pit_pond and 'CIVZONE_POND_OPTIONS' or 'CIVZONE_PEN_OPTIONS'))

        local vect = nil
        if objtype == 0 then
            vect = df.global.ui_building_assign_units
        elseif objtype == 1 then
            vect = df.global.ui_building_assign_items
        end

        if vect then
            for i,v in ipairs(vect) do
                if v and v.id == objid then
                    if istrue(df.global.ui_building_assign_is_marked[i]) ~= on then
                        df.global.ui_building_item_cursor = i
                        local ws = dfhack.gui.getCurViewscreen()
                        gui.simulateInput(ws, 'SELECT')
                    end

                    break            
                end
            end
        end

    end)
end

function zone_remove(bldid)
    execute_with_selected_zone(bldid, function(ws)
        df.global.ui_sidebar_menus.zone.remove = true
        gui.simulateInput(ws, 'CIVZONE_REMOVE_ZONE')
        df.global.ui_sidebar_menus.zone.remove = false
    end)
end