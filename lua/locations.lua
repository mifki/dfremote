function location_find_by_id(id)
    local site = df.world_site.find(df.global.ui.site_id)

    --todo: use binsearch if it's sorted
    for i,loc in ipairs(site.buildings) do
        if loc.id == id then
            return loc
        end
    end

    return nil
end

function location_restriction_mode(loc)
    local allow_outsiders = loc.flags.AllowVisitors
    local allow_residents = loc.flags.AllowResidents
    local only_members = loc.flags.OnlyMembers

    return only_members and 3 or (allow_outsiders and 0 or (allow_residents and 1 or 2))
end

--luacheck: in=
function locations_get_list()
    return execute_with_locations_screen(function(ws)
        local site = df.world_site.find(df.global.ui.site_id)

        local list = {}

        for j,loc in ipairs(ws.locations) do
            if loc then
                local ltype = loc:getType()
                local mode = location_restriction_mode(loc)

                local item = { locname(loc), loc.id, ltype, mode }

                if ltype == df.abstract_building_type.TEMPLE then
                    local loc = loc --as:df.abstract_building_templest
                    local deity_type = loc.deity_type
                    local deity_name = mp.NIL

                    if deity_type == df.temple_deity_type.Deity then
                        local deity = df.historical_figure.find(loc.deity_data.Deity)
                        deity_name = deity and hfname(deity, true) or mp.NIL

                    elseif deity_type == df.temple_deity_type.Religion then
                        local entity = df.historical_entity.find(loc.deity_data.Religion)
                        deity_name = entity and translatename(entity.name, true) or mp.NIL
                    end

                    -- make these a subarray
                    table.insert(item, deity_type)
                    table.insert(item, deity_name)

                elseif ltype == df.abstract_building_type.GUILDHALL then
                    local loc = loc --as:df.abstract_building_guildhall
                    local prof = loc.contents.profession
                    local guild = profession_find_guild(prof)

                    -- make these a subarray
                    table.insert(item, df.profession.attrs[prof].caption)
                    table.insert(item, guild and translatename(guild.name,true) or mp.NIL)
                end

                table.insert(list, item)
            end
        end

        return { list, { translatename(site.name, true) } }
    end)
end

local function count_buildings_in_location(loc, count_type)
    local cnt = 0
    
    for i,v in ipairs(loc.contents.building_ids) do
        local bld = df.building.find(v)

        if bld then
            local btype = bld:getType()
            if btype == count_type then
                cnt = cnt + 1
            end

            for j,bld2 in ipairs(bld.children) do
                if bld2:getType() == count_type then
                    cnt = cnt + 1
                end
            end            
        end
    end

    return cnt
end

local occupation_names = {
    [df.occupation_type.TAVERN_KEEPER]  = 'Tavern Keeper',
    [df.occupation_type.PERFORMER]      = 'Performer',
    [df.occupation_type.SCHOLAR]        = 'Scholar',
    [df.occupation_type.MERCENARY]      = 'Mercenary',
    [df.occupation_type.MONSTER_SLAYER] = 'Monster Slayer',
    [df.occupation_type.SCRIBE]         = 'Scribe',
    [df.occupation_type.MESSENGER]      = 'Messenger'
}

local occupation_is_assignable = {
    [df.occupation_type.TAVERN_KEEPER]  = true,
    [df.occupation_type.PERFORMER]      = true,
    [df.occupation_type.SCHOLAR]        = true,
    [df.occupation_type.MERCENARY]      = false,
    [df.occupation_type.MONSTER_SLAYER] = false,
    [df.occupation_type.SCRIBE]         = true,
    [df.occupation_type.MESSENGER]      = true
}

--luacheck: in=number
function location_get_info(id)
    -- site-wide occupations
    -- if id == -1 then
    --     local site = df.world_site.find(df.global.ui.site_id)
    --     local group_id = df.global.ui.group_id

    --     local occupations = {} --as:{1:string,2:number,3:number,4:string,5:number}[]
        
    --     for i,occ in ipairs(df.global.world.occupations.all) do
    --         if occ.group_id == group_id and occ.unit_id ~= -1 then
    --             local unit = df.unit.find(occ.unit_id)
    --             local unitname = unitname(unit)

    --             local pos = #occupations + 1
    --             for j,v in ipairs(occupations) do
    --                 --[[if v[5] == -1 and occ.type == v[3] then
    --                     pos = occ.unit_id == -1 and 0 or j
    --                     break
    --                 end]]
    --                 if v[3] > occ.type then
    --                     pos = j
    --                     break
    --                 end
    --             end             

    --             table.insert(occupations, pos, { occupation_names[occ.type], occ.id, occ.type, unitname, occ.unit_id })
    --         end
    --     end

    --     return { translatename(site.name), -1, occupations }
    -- end

    return execute_with_locations_screen(function(ws)
        for j,loc in ipairs(ws.locations) do
            if (not loc and id == -1) or (loc and loc.id == id) then
                local occupations = {} --as:{1:string,2:number,3:number,4:string,5:number}[]
                
                for i,occ in ipairs(ws.occupations) do
                    if occ then
                        local unit = occ.unit_id ~= -1 and df.unit.find(occ.unit_id) or nil
                        local unitname = occ.unit_id ~= -1 and unitname(unit) or mp.NIL

                        -- grouping by occupation type, and not allowing >1 unassigned occupation of one type
                        local pos = #occupations + 1
                        -- for j,v in ipairs(occupations) do --as:{1:string,2:number,3:number,4:string,5:number}
                        --     if v[5] == -1 and occ.type == v[3] then
                        --         pos = occ.unit_id == -1 and 0 or j
                        --         break
                        --     end
                        --     if v[3] > occ.type then
                        --         pos = j
                        --         break
                        --     end
                        -- end

                        --todo: how to get this from ui? game doesn't seem to check occupation type for this
                        local assignable = occupation_is_assignable[occ.type]

                        if pos > 0 then
                            table.insert(occupations, pos, { occupation_names[occ.type], { 0, occ.id }, -1, unitname, occ.unit_id, assignable })
                        end

                    elseif ws.unk_4[i] then
                        local assignment = df.reinterpret_cast(df.entity_position_assignment, ws.unk_4[i])
                        local position = df.reinterpret_cast(df.entity_position, ws.unk_3[i])

                        local hf = assignment.histfig ~= -1 and df.historical_figure.find(assignment.histfig) or nil
                        local unitname = assignment.histfig ~= -1 and hfname(hf) or mp.NIL

                        table.insert(occupations, { capitalize(position.name[0]), { 1, assignment.id }, -1, unitname, -1, true })
                    end
                end

                -- site
                if id == -1 then
                    local site = df.world_site.find(df.global.ui.site_id)
                    return { translatename(site.name), -1, -1, -1, {}, occupations, {}, mp.NIL }
                end

                local ltype = loc:getType()

                local info = {}
                local params = {}
                local value_info = mp.NIL
                if ltype == df.abstract_building_type.LIBRARY then
                    local loc = loc --as:df.abstract_building_inn_tavernst
                    local count_written = ws.unk_1[j]
                    local count_paper = loc.contents.count_paper

                    info = {
                        count_buildings_in_location(loc, df.building_type.Bookcase), count_written,
                        count_buildings_in_location(loc, df.building_type.Box), count_paper,
                        count_buildings_in_location(loc, df.building_type.Table), count_buildings_in_location(loc, df.building_type.Chair)
                    }

                    params = { loc.contents.desired_copies, loc.contents.desired_paper }

                elseif ltype == df.abstract_building_type.INN_TAVERN then
                    local loc = loc --as:df.abstract_building_libraryst
                    local count_goblets = loc.contents.count_goblets
                    local count_instruments = loc.contents.count_instruments
                    local dance_area = { ws.dance_floor_x[j], ws.dance_floor_y[j] }

                    local rented_rooms = 0
                    local total_rooms = 0
                    
                    for i,v in ipairs(loc.contents.building_ids) do
                        local bld = df.building.find(v)

                        if bld then
                            local btype = bld:getType()
                            if btype == df.building_type.Bed then
                                total_rooms = total_rooms + 1
                                if bld.owner_id ~= -1 then
                                    rented_rooms = rented_rooms + 1
                                end
                            end
                        end
                    end     

                    info = {
                        count_buildings_in_location(loc, df.building_type.Box),
                        count_goblets, count_instruments,
                        rented_rooms, total_rooms,
                        dance_area,
                    }

                    params = { loc.contents.desired_goblets, loc.contents.desired_instruments }

                elseif ltype == df.abstract_building_type.TEMPLE then
                    local loc = loc --as:df.abstract_building_templest
                    local count_instruments = loc.contents.count_instruments
                    local dance_area = { ws.dance_floor_x[j], ws.dance_floor_y[j] }

                    local deity_type = loc.deity_type
                    local deity_name = mp.NIL

                    if deity_type == df.temple_deity_type.Deity then
                        local deity = df.historical_figure.find(loc.deity_data.Deity)
                        deity_name = deity and hfname(deity, true) or mp.NIL

                    elseif deity_type == df.temple_deity_type.Religion then
                        local entity = df.historical_entity.find(loc.deity_data.Religion)
                        deity_name = entity and translatename(entity.name, true) or mp.NIL
                    end                    

                    info = {
                        count_buildings_in_location(loc, df.building_type.Box), count_instruments,
                        dance_area, deity_type, deity_name,
                    }

                    params = { loc.contents.desired_instruments }

                    local tier = loc.contents.location_tier
                    local tier_name = tier >= 2 and 'Temple complex' or (tier == 1 and 'Temple' or 'Shrine')
                    local next = tier >= #df.global.d_init.temple_value_levels and -1 or df.global.d_init.temple_value_levels[tier]
                    value_info = { loc.contents.location_value, tier_name, next }

                elseif ltype == df.abstract_building_type.GUILDHALL then
                    local loc = loc --as:df.abstract_building_guildhall
                    local prof = loc.contents.profession
                    local guild = profession_find_guild(prof)

                    info = { df.profession.attrs[prof].caption, guild and translatename(guild.name,true) or mp.NIL }

                    params = {}

                    local tier = loc.contents.location_tier
                    local tier_name = tier >= 2 and 'Grand guildhall' or (tier == 1 and 'Guildhall' or 'Meeting place')
                    local next = tier >= #df.global.d_init.guildhall_value_levels and -1 or df.global.d_init.guildhall_value_levels[tier]
                    value_info = { loc.contents.location_value, tier_name, next }
                end

                local mode = location_restriction_mode(loc)

                return { locname(loc), loc.id, ltype, mode, info, occupations, params, value_info }
            
            else
                gui.simulateInput(ws, K'STANDARDSCROLL_DOWN')
            end
        end

        error('no location '..tostring(id))     
    end)
end

--luacheck: in=number,number
function location_occupation_get_candidates(locid, occtypeid)
    local occtype = occtypeid[1]
    local occid = occtypeid[2]

    return execute_with_locations_screen(function(ws)
        for i,loc in ipairs(ws.locations) do
            if (not loc and locid == -1) or (loc and loc.id == locid) then
                for j,occ in ipairs(ws.occupations) do
                    if (occtype == 0 and occ and occid == occ.id) or
                       (occtype == 1 and ws.unk_4[j] and df.reinterpret_cast(df.entity_position_assignment, ws.unk_4[j]).id == occid) then
                        ws.menu = df.viewscreen_locationsst.T_menu.Occupations
                        ws.occupation_idx = j
                        gui.simulateInput(ws, K'SELECT')

                        local ret = {}
                        for k,unit in ipairs(ws.units) do
                            if unit then
                                --xxx: temp fix for an app bug
                                table.insert(ret, { unit_fulltitle(unit), tostring(unit.id) })
                            else
                                --xxx: temp fix for an app bug
                                table.insert(ret, { 'Nobody', tostring(-1) })
                            end
                        end

                        return ret
                    end
                end

                error('no occupation ' .. tostring(occid))
            end

            gui.simulateInput(ws, K'STANDARDSCROLL_DOWN')
        end

        error('no location ' .. tostring(locid))
    end)
end

--luacheck: in=number,number,number
function location_occupation_assign(locid, occtypeid, unitid)
    --xxx: temp fix for an app bug
    unitid = tonumber(unitid)

    local occtype = occtypeid[1]
    local occid = occtypeid[2]    

    return execute_with_locations_screen(function(ws)
        for i,loc in ipairs(ws.locations) do
            if (not loc and locid == -1) or (loc and loc.id == locid) then
                for j,occ in ipairs(ws.occupations) do
                    if (occtype == 0 and occ and occid == occ.id) or
                       (occtype == 1 and ws.unk_4[j] and df.reinterpret_cast(df.entity_position_assignment, ws.unk_4[j]).id == occid) then
                        ws.menu = df.viewscreen_locationsst.T_menu.Occupations
                        ws.occupation_idx = j
                        gui.simulateInput(ws, K'SELECT')

                        for k,unit in ipairs(ws.units) do
                            if (unit and unit.id == unitid) or (not unit and unitid == -1) then
                                ws.unit_idx = k
                                gui.simulateInput(ws, K'SELECT')

                                return true
                            end
                        end

                        error('no unit ' .. tostring(unitid))
                    end
                end

                error('no occupation ' .. tostring(occid))
            end

            gui.simulateInput(ws, K'STANDARDSCROLL_DOWN')
        end

        error('no location ' .. tostring(locid))
    end)
end

--luacheck: in=number
function location_retire(id)
    return execute_with_locations_screen(function(ws)
        for i,loc in ipairs(ws.locations) do
            if loc and loc.id == id then
                gui.simulateInput(ws, K'LOCATION_RETIRE')
                return true
            end

            gui.simulateInput(ws, K'STANDARDSCROLL_DOWN')
        end

        error('no location ' .. tostring(locid))
    end)
end

--luacheck: in=number,number
function location_set_restriction(id, mode)
    local loc = location_find_by_id(id)
    if not loc then
        error('no location '..tostring(id))
    end

    if mode == 3 then
        loc.flags.AllowVisitors = false
        loc.flags.AllowResidents = false
        loc.flags.OnlyMembers = true
    elseif mode == 2 then
        loc.flags.AllowVisitors = false
        loc.flags.AllowResidents = false
        loc.flags.OnlyMembers = false
    elseif mode == 1 then
        loc.flags.AllowVisitors = false
        loc.flags.AllowResidents = true
        loc.flags.OnlyMembers = false
    elseif mode == 0 then
        loc.flags.AllowVisitors = true
        loc.flags.AllowResidents = true
        loc.flags.OnlyMembers = false
    end

    return true 
end

--luacheck: in=number,number,number
function location_set_parameter(id, idx, val)
    local loc = location_find_by_id(id)
    if not loc then
        error('no location '..tostring(id))
    end

    local ltype = loc:getType()

    if ltype == df.abstract_building_type.INN_TAVERN then
        local loc = loc --as:df.abstract_building_inn_tavernst
        if idx == 0 then
            loc.contents.desired_goblets = val
        elseif idx == 1 then
            loc.contents.desired_instruments = val
        end

    elseif ltype == df.abstract_building_type.LIBRARY then
        local loc = loc --as:df.abstract_building_libraryst
        if idx == 0 then
            loc.contents.desired_copies = val
        elseif idx == 1 then
            loc.contents.desired_paper = val
        end

    elseif ltype == df.abstract_building_type.TEMPLE then
        local loc = loc --as:df.abstract_building_templest
        if idx == 0 then
            loc.contents.desired_instruments = val
        end
    end 

    return true
end

--luacheck: in=number
function location_assign_get_list(bldid)
    return execute_with_locations_for_building(bldid, function(ws, bld)
        local list = {}
        
        for i,loc in ipairs(df.global.ui_sidebar_menus.location.list) do
            if loc then
                table.insert(list, { locname(loc), loc.id, loc:getType() })
            end
        end

        return { list, bld.location_id }
    end)
end

--luacheck: in=number,number
function location_assign(bldid, locid)
    return execute_with_locations_for_building(bldid, function(ws, bld)
        if bld.location_id == locid then
            return true
        end

        for i,loc in ipairs(df.global.ui_sidebar_menus.location.list) do
            if (locid == -1 and not loc) or (loc and loc.id == locid) then
                df.global.ui_sidebar_menus.location.cursor = i
                gui.simulateInput(ws, K'SELECT')
                return true
            end
        end
    end)
end

function deity_count_worshippers(deity_id)
    local count = 0

    for j,unit in ipairs(df.global.world.units.active) do
        if unit_iscitizen(unit) then
            local hf = df.historical_figure.find(unit.hist_figure_id)
            if hf then
                for k,l in ipairs(hf.histfig_links) do
                    if l:getType() == df.histfig_hf_link_type.DEITY and l.target_hf == deity_id then
                        count = count + 1
                        break
                    end
                end
            end
        end
    end

    return count
end

function religion_count_worshippers(religion_id)
    local count = 0

    for j,unit in ipairs(df.global.world.units.active) do
        if unit_iscitizen(unit) then
            local hf = df.historical_figure.find(unit.hist_figure_id)
            if hf then
                for k,l in ipairs(hf.entity_links) do
                    if l:getType() == df.histfig_entity_link_type.MEMBER and l.entity_id == religion_id then
                        count = count + 1
                        break
                    end
                end
            end
        end
    end

    return count
end

function deity_get_spheres(hf)
    local spheres = {}

    if hf.info.spheres then
        for j,v in ipairs(hf.info.spheres.spheres) do
            table.insert(spheres, capitalize(df.sphere_type[v]:lower()))
        end
    end

    return spheres
end

--luacheck: in=number
function locations_add_get_deity_choices(bldid)
    return execute_with_locations_for_building(bldid, function(ws, bld)
        gui.simulateInput(ws, K'LOCATION_NEW')
        gui.simulateInput(ws, K'LOCATION_TEMPLE')

        local deities = {}
        local religions = {}

        for i,type in ipairs(df.global.ui_sidebar_menus.location.deity_type) do
            if type == df.temple_deity_type.Deity then
                local hf = df.historical_figure.find(df.global.ui_sidebar_menus.location.deity_data[i].Deity)
                if hf ~= nil then
                    local worshippers = deity_count_worshippers(hf.id)
                    local spheres = deity_get_spheres(hf)

                    table.insert(deities, { hfname(hf, true), type, hf.id, worshippers, spheres })
                end             

            elseif type == df.temple_deity_type.Religion then
                local entity = df.historical_entity.find(df.global.ui_sidebar_menus.location.deity_data[i].Religion)
                if entity then
                    -- there may be more deities, but the game seem to only take the first one
                    local deity = #entity.relations.deities > 0 and df.historical_figure.find(entity.relations.deities[0]) or nil

                    local deityname = deity and hfname(deity, true) or mp.NIL
                    local worshippers = religion_count_worshippers(entity.id)
                    local spheres = deity and deity_get_spheres(deity) or {}

                    table.insert(religions, { translatename(entity.name, true), type, entity.id, worshippers, spheres, deityname })
                end
            end
        end

        return { deities, religions }
    end)    
end

function profession_count_workers(prof)
    local count = 0

    for i,unit in ipairs(df.global.world.units.active) do
        if unit_iscitizen(unit) then
            if unit.profession == prof or df.profession.attrs[unit.profession].parent == prof then
                count = count + 1
            end
        end
    end

    return count
end

function guild_count_members(guild_id)
    local count = 0

    for i,unit in ipairs(df.global.world.units.active) do
        if unit_iscitizen(unit) then
            local hf = df.historical_figure.find(unit.hist_figure_id)
            if hf then
                for j,link in ipairs(hf.entity_links) do
                    if link:getType() == df.histfig_entity_link_type.MEMBER and link.entity_id == guild_id then
                        count = count + 1
                    end
                end
            end
        end
    end

    return count
end

function profession_find_guild(prof)
    local site = df.world_site.find(df.global.ui.site_id)
    for j,link in ipairs(site.entity_links) do
        local entity = df.historical_entity.find(link.entity_id)
        if entity and entity.type == df.historical_entity_type.Guild and #entity.guild_professions > 0 and entity.guild_professions[0].profession == prof then
            return entity
        end
    end

    return nil
end

--luacheck: in=number
function locations_add_get_profession_choices(bldid)
    return execute_with_locations_for_building(bldid, function(ws, bld)
        gui.simulateInput(ws, K'LOCATION_NEW')
        gui.simulateInput(ws, K'LOCATION_GUILDHALL')

        local ret = {}

        for i,v in ipairs(df.global.ui_sidebar_menus.location.profession) do
            local name = df.profession.attrs[v].caption
            local entity = profession_find_guild(v)
            local guild_info = entity and { translatename(entity.name,true), guild_count_members(entity.id) } or mp.NIL

            table.insert(ret, { name, i, profession_count_workers(v), guild_info })
        end

        return ret
    end)    
end

--luacheck: in=number,number,number
function locations_add(bldid, loctype, id1, id2)
    return execute_with_locations_for_building(bldid, function(ws, bld)
        gui.simulateInput(ws, K'LOCATION_NEW')

        if loctype == 1 then
            gui.simulateInput(ws, K'LOCATION_INN_TAVERN')
        elseif loctype == 2 then
            gui.simulateInput(ws, K'LOCATION_LIBRARY')
        elseif loctype == 3 then
            gui.simulateInput(ws, K'LOCATION_TEMPLE')

            local deitytype = id1
            local deityid = id2

            for i,type in ipairs(df.global.ui_sidebar_menus.location.deity_type) do
                if type == deitytype then
                    if type == df.temple_deity_type.None or
                        (type == df.temple_deity_type.Deity and df.global.ui_sidebar_menus.location.deity_data[i].Deity == deityid) or
                        (type == df.temple_deity_type.Religion and df.global.ui_sidebar_menus.location.deity_data[i].Religion == deityid) then

                        df.global.ui_sidebar_menus.location.cursor_deity = i
                        gui.simulateInput(ws, K'SELECT')
                        return true
                    end
                end
            end     

            error('no deity/religion ' .. tostring(deitytype) .. ' ' .. tostring(deityid))
        elseif loctype == 4 then
            gui.simulateInput(ws, K'LOCATION_GUILDHALL')

            local prof = id1

            for i,v in ipairs(df.global.ui_sidebar_menus.location.profession) do
                if v == prof then
                    df.global.ui_sidebar_menus.location.cursor_profession = i
                    gui.simulateInput(ws, K'SELECT')
                    return true
                end
            end     

            error('no profession ' .. tostring(prof))
        end        
    end)    
end

-- print(pcall(function() return json:encode(locations_get_list()) end))
-- print(pcall(function() return json:encode(location_get_info(2)) end))
-- print(pcall(function() return json:encode(location_occupation_get_candidates(2,108)) end))
-- print(pcall(function() return json:encode(location_assign(670,-1)) end))
-- print(pcall(function() return json:encode(locations_add_get_deity_choices(3)) end))
-- print(pcall(function() return json:encode(locations_add_get_profession_choices(572)) end))
