function worldgen_status()
    local ws = dfhack.gui.getCurViewscreen()

    if ws._type == df.viewscreen_export_regionst or ws.parent._type == df.viewscreen_export_regionst then
        return { 'saving' }
    end

    if ws._type ~= df.viewscreen_new_regionst then
        error('wrong screen '..tostring(ws._type))
    end

    if ws.unk_b4 ~= 0 then
        return { 'loading' }
    end

    if (istrue(ws.simple_mode) or istrue(ws.in_worldgen)) and not worldgen_params then
        error('wrong state')
    end

    local state = df.global.world.worldgen_status.state
    local year = state >= 9 and df.global.cur_year or -1

    if istrue(ws.worldgen_paused) then
        local can_use_world = state >= 9
        
        return { 'paused', year, world_name or mp.NIL, world_name_eng or mp.NIL, can_use_world }
    end

    if istrue(ws.worldgen_rejected) then
        local reason = ''

        for i=7,df.global.gps.dimx-2 do
            local char = df.global.gps.screen[(i*df.global.gps.dimy+2)*4]

            if (char == 32 and reason:byte(#reason) == 32) then
                break
            end

            reason = reason .. string.char(char)
        end

        reason = reason:sub(1, #reason-1)
        return { 'rejected', reason:lower() }
    end

    local wd = df.global.world.world_data
    local world_name = wd and dfhack.df2utf(dfhack.TranslateName(wd.name))
    local world_name_eng = wd and dfhack.TranslateName(wd.name, true)

    if df.global.world.worldgen_status.state == 10 then
        return { 'done', year, world_name, world_name_eng }
    end

    return { 'processing', year, world_name or mp.NIL, world_name_eng or mp.NIL, state }
end

function worldgen_accept()
    local ws = dfhack.gui.getCurViewscreen()

    if ws._type ~= df.viewscreen_new_regionst then
        error('wrong screen '..tostring(ws._type))
    end

    if istrue(ws.worldgen_paused) then
        gui.simulateInput(ws, 'WORLD_GEN_USE')
    elseif df.global.world.worldgen_status.state == 10 then
        gui.simulateInput(ws, 'SELECT')        
    end

    return true
end

function worldgen_cancel()
    local ws = dfhack.gui.getCurViewscreen()

    if ws._type ~= df.viewscreen_new_regionst then
        error('wrong screen '..tostring(ws._type))
    end

    -- Loading raws, can't cancel
    if ws.unk_b4 ~= 0 then
        return
    end

    if istrue(ws.simple_mode) or istrue(ws.in_worldgen) then
        if worldgen_params then
            worldgen_params = nil
        end

        return
    end

    if not istrue(ws.worldgen_paused) and df.global.world.worldgen_status.state ~= 10 then
        gui.simulateInput(ws, 'SELECT')
    end

    gui.simulateInput(ws, 'WORLD_GEN_ABORT')
end

function worldgen_continue()
    local ws = dfhack.gui.getCurViewscreen()    

    if ws._type ~= df.viewscreen_new_regionst or not istrue(ws.worldgen_paused) then
        return
    end

    gui.simulateInput(ws, 'WORLD_GEN_CONTINUE')
end

function worldgen_resolve_rejected(action)
    local ws = dfhack.gui.getCurViewscreen()

    if action == 1 then
        gui.simulateInput(ws, 'WORLD_PARAM_REJECT_CONTINUE')
    elseif action == 2 then
        gui.simulateInput(ws, 'WORLD_PARAM_REJECT_ABORT')
    elseif action == 3 then
        gui.simulateInput(ws, 'WORLD_PARAM_REJECT_ALLOW_THIS')
    elseif action == 4 then
        gui.simulateInput(ws, 'WORLD_PARAM_REJECT_ALLOW_ALL')
    end
end

local function find_parent_civ(civ)
    for i,v in ipairs(civ.entity_links) do
        if v._type == df.entity_entity_link and v.type == df.entity_entity_link_type.PARENT then
            return df.historical_entity.find(v.target)
        end
    end
end

local function site_type_name(site)
    local t = site.type

    if t == df.world_site_type.PlayerFortress or t == df.world_site_type.MountainHalls then
        --todo: or only for MountainHalls ?
        return istrue(site.is_mountain_halls) and 'mountain halls' or (istrue(site.is_fortress) and 'fortress' or 'hillocks')
    elseif t == df.world_site_type.DarkFortress then
        return site.flags.Town and 'dark fortress' or 'dark pits'
    elseif t == df.world_site_type.Cave then
        return 'cave'
    elseif t == df.world_site_type.ForestRetreat then
        return 'forest retreat'
    elseif t == df.world_site_type.Town then
        return site.flags.Town and 'town' or 'hamlet'
    elseif t == df.world_site_type.ImportantLocation then
        return 'important location'
    elseif t == df.world_site_type.LairShrine then
        return 'lair'
    elseif t == df.world_site_type.Fortress then
        return (site.subtype_info and site.subtype_info.is_tower) and 'tower' or 'fortress'
    elseif t == df.world_site_type.Camp then
        return 'camp'
    elseif t == df.world_site_type.Monument then
        return 'monument'
    end

    return '!unknown site type!'
end

--todo: conditions for reclaimable are wrong
function worldgen_get_world_info()
    local races = { ['DWARF']=0, ['GOBLIN']=0, ['ELF']=0, ['HUMAN']=0, ['KOBOLD']=0 }
    local pops = {}
    local reclaimable = {}

    -- Find race idx for the races we're interested in; don't know how to do this properly
    for i,v in ipairs(df.global.world.raws.creatures.all) do
        local id = v.creature_id
        if races[id] then
            pops[i] = { pop=0, civs={} }
            races[id] = i
        end
    end

    -- Process sites
    for i,site in ipairs(df.global.world.world_data.sites) do
        local owner = df.historical_entity.find(site.cur_owner_id)

        -- Add this site to owner's civ
        if owner then
            local race = owner.race
            local pop = pops[race]

            local owner_civ = find_parent_civ(owner) --df.historical_entity.find(site.civ_id)
            --[[if not owner_civ or owner_civ.id ~= site.civ_id then
                if site_type_name(site) == 'fortress' and #site.inhabitants == 0 then
                    table.insert(reclaimable, site)
                end
            end]]

            if pop then
                local owner_civ = find_parent_civ(owner) --df.historical_entity.find(site.civ_id)
        
                --todo: what to check here?
                if owner_civ and owner_civ.next_member_idx > 0 --[[and owner_civ.flags.named_civ]] then
                    local key = owner_civ and owner_civ.id or -1
                    local tciv = pop.civs[key]
                    if not tciv then
                        local civname = owner_civ and dfhack.df2utf(dfhack.TranslateName(owner_civ.name, true)) or nil
                        tciv = { id=owner_civ.id, name=civname, sites={} }
                        pop.civs[key] = tciv
                    end
                    table.insert(tciv.sites, site)
                end
            end

        --[[else
            if site_type_name(site) == 'fortress' and #site.inhabitants == 0 then
                table.insert(reclaimable, site)
            end]]
        end

        -- Calculate civ population
        for j,v in ipairs(site.inhabitants) do
            local t = pops[v.race]
            if t then
                t.pop = t.pop + v.count
            end
        end

        for j,v in ipairs(site.nemesis) do
            local n = df.nemesis_record.find(v)
            if n then
                local fig = n.figure
                local t = fig and pops[fig.race]
                if t then
                    t.pop = t.pop + 1
                end
            end
        end        
    end

    -- Now we need to add alive civs without sites
    for i,v in ipairs(df.global.world.entities.all) do
        local pop = pops[v.race]

        if pop and --[[not find_parent_civ(v) and]] v.flags.named_civ and not pop.civs[v.id] and v.next_member_idx > 0 then
            local tciv = { id=v.id, name=dfhack.df2utf(dfhack.TranslateName(v.name, true)), sites={} }
            pop.civs[v.id] = tciv
        end

        ::next::
    end    

    local ret = ''

    --todo: no-civ sites must go last
    for i,v in ipairs({'DWARF', 'HUMAN', 'ELF', 'GOBLIN', 'KOBOLD' }) do
        local race_id = races[v]
        local race = df.global.world.raws.creatures.all[race_id]
        local t = pops[race_id]

        ret = ret .. '[P][C:7:0:1]' .. capitalize(race.name[1])
        ret = ret .. '[C:7:0:0]' .. ' - Population ' .. tostring(t.pop)

        for j,civ in pairs(t.civs) do
            ret = ret .. '[P][C:7:0:0]' .. (civ.name and ('    civ. [C:6:0:1]' .. civ.name) or '    [C:6:0:1]---')
            for k,site in ipairs(civ.sites) do 
                local name = dfhack.df2utf(dfhack.TranslateName(site.name, false))
                local name_eng = dfhack.df2utf(dfhack.TranslateName(site.name, true))
                local type_name = site_type_name(site)
                ret = ret .. '[B][C:7:0:1]' .. '    ' .. name .. ', "' .. name_eng .. '", ' .. type_name
            end
        end

        --[[if v == 'DWARF' and #reclaimable > 0 then
            ret = ret .. '[P][C:6:0:1]Reclaimable'
            for k,site in ipairs(reclaimable) do 
                local name = dfhack.TranslateName(site.name, false)
                local name_eng = dfhack.TranslateName(site.name, true)
                local type_name = site_type_name(site)
                ret = ret .. '[B][C:7:0:1]' .. '    ' .. name .. ', "' .. name_eng .. '", ' .. type_name
            end            
        end]]

        ret = ret .. '[B]'
    end

    return { ret }
end