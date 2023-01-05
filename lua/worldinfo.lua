--luacheck: in=
function civilizations_get_list()
    local ret = {}

    --todo: can just create the screen instead?
    execute_with_world_screen(function(ws)
        gui.simulateInput(ws, K'CIV_CIVS')

        for i,v in ipairs(ws.entities) do
            local name = translatename(v.name, false)
            local name_eng = translatename(v.name, true)

            local race = df.global.world.raws.creatures.all[v.race]
            local site_gov = v.type == df.historical_entity_type.SiteGovernment

            table.insert(ret, { name, v.id, name_eng, race.name[2], site_gov })
        end
    end)

    return ret
end

--luacheck: in=number
function civilization_get_info(civid)
    local civ = df.historical_entity.find(civid)
    if not civ then
        error('no civ '..tostring(civid))
    end

    local civsws = df.viewscreen_civlistst:new()
    civsws.page = 0
    civsws.entities:insert(0, civ)
    gui.simulateInput(civsws, K'SELECT')
    df.delete(civsws)

    local ws = dfhack.gui.getCurViewscreen() --as:df.viewscreen_entityst
    if ws._type ~= df.viewscreen_entityst then
        error('failed to switch to civ info screen')
    end
    ws.breakdown_level = df.interface_breakdown_types.STOPSCREEN

    local leaders = {}
    for i,v in ipairs(ws.important_leader_nemesis) do
        local fig = v.figure
        local name = hfname(fig)

        local race = df.global.world.raws.creatures.all[fig.race]
        local prof = dfhack.units.getCasteProfessionName(fig.race, fig.caste, fig.profession, false)

        local pos = ''
        -- that's where game gets the position to display from
        for j,w in ipairs(fig.entity_links) do
            if w._type == df.histfig_entity_link_positionst then
                local w = w --as:df.histfig_entity_link_positionst
                for m,ass in ipairs(ws.entity.positions.assignments) do
                    if ass.id == w.assignment_id then
                        for k,p in ipairs(ws.entity.positions.own) do
                            if p.id == ass.position_id then
                                pos = fig.sex == 0 and p.name_female[0] or p.name_male[0]
                                if #pos == 0 then
                                    pos = p.name[0]
                                end

                                break
                            end
                        end

                        break
                    end
                end

                break
            end
        end

        table.insert(leaders, { name, fig.id, race.name[0], prof, pos })
    end

    local agreements = {}
    for i,v in ipairs(ws.agreements) do
        local type = v.type
        local title = ''

        local site = df.world_site.find(df.global.ui.site_id)
        local site_title = translatename(site.name, false)

        if type == df.meeting_event_type.ExportAgreement or type == df.meeting_event_type.ImportAgreement then
            if type == df.meeting_event_type.ExportAgreement then
                title = 'Exports to ' .. site_title
            elseif type == df.meeting_event_type.ImportAgreement then
                title = 'Imports from ' .. site_title
            end

            local year = v.year
            local month = math.floor(v.ticks / TU_PER_MONTH)
            local day = math.floor((v.ticks-month*TU_PER_MONTH) / TU_PER_DAY) + 1

            local b = day % 10
            local suf = math.floor((day % 100) / 10) == 1 and 'th' or b == 1 and 'st' or b == 2 and 'nd' or b == 3 and 'rd' or 'th'

            local datestr = day .. suf .. ' ' .. MONTHS[month+1] .. ', ' .. year
    
            table.insert(agreements, { title, i, type, datestr })
        end
    end

    return { leaders, agreements }
end

--luacheck: in=number,number
function civilization_get_agreement(civid, idx)
    local civ = df.historical_entity.find(civid)
    if not civ then
        error('no civ '..tostring(civid))
    end

    local civsws = df.viewscreen_civlistst:new()
    civsws.page = 0
    civsws.entities:insert(0, civ)
    gui.simulateInput(civsws, K'SELECT')
    df.delete(civsws)

    local ws = dfhack.gui.getCurViewscreen() --as:df.viewscreen_entityst
    ws.breakdown_level = df.interface_breakdown_types.STOPSCREEN

    local agreement = ws.agreements[idx]
    local ret = nil

    if agreement.type == df.meeting_event_type.ImportAgreement then
        ret = process_buy_agreement(agreement.buy_prices)
    elseif agreement.type == df.meeting_event_type.ExportAgreement then
        ret = process_sell_agreement(ws.entity.id, agreement.sell_prices)
    end

    return { ret, agreement.type }
end

local invasion_type_strings = {
    [df.army_controller_invasion_order.T_type.Raze] = 'Raze',
    [df.army_controller_invasion_order.T_type.TakeOver] = 'Take Over',
    [df.army_controller_invasion_order.T_type.Occupy] = 'Seize',
    [df.army_controller_invasion_order.T_type.DemandTribute] = 'Demand Tribute from',
    [df.army_controller_invasion_order.T_type.Raid] = 'Raid',
    [df.army_controller_invasion_order.T_type.Explore] = 'Explore',
    [df.army_controller_invasion_order.T_type.Pillage] = 'Pillage',
}

function missiontitle(mission)
    local type = mission.type
    if type == df.army_controller.T_type.InvasionOrder then
        local site = df.world_site.find(mission.site_id)
        local site_name = site and translatename(site.name, true) or '#invalid site#'

        return (invasion_type_strings[mission.data.InvasionOrder.type] or 'Raid') .. ' ' .. site_name

    elseif type == df.army_controller.T_type.Quest then
        local artifact = df.artifact_record.find(mission.data.Quest.artifact_id)
        local artname = artifact and translatename(artifact.name, true) or '#invalid artifact#'

        return 'Recover ' .. artname

    elseif type == df.army_controller.T_type.Rescue then
        local hf = df.historical_figure.find(mission.data.Rescue.histfig)
        return 'Rescue ' .. hfname(hf, true)

    elseif type == df.army_controller.T_type.Request then
        local site = df.world_site.find(mission.site_id)
        local site_name = site and translatename(site.name, true) or '#invalid site#'

        return 'Make Request of ' .. site_name
    end

    return '#unknown mission type#'
end

-- function mission_travel_status(mission)
--     local type = mission.type

--     local here = {}
--     local travelling = {}

--     if type == df.army_controller.T_type.Request then
--         for i,v in ipairs(mission.messengers) do
--             local occ = df.occupation.find(v)
--             if occ then
--                 local hf = df.historical_figure.find(occ.histfig_id)
--                 if hf then
--                     local out = df.unit.find(hf.unit_id) == nil
--                     local name = hfname(hf)

--                     table.insert(out and travelling or here, name)
--                 end
--             end
--         end
--     else
--         for i,v in ipairs(mission.squads) do
--             local squad = df.squad.find(v)
--             if squad then
--                 local leader_hfid = squad.positions[0].occupant
--                 local hf = leader_hfid ~= -1 and df.historical_figure.find(leader_hfid)

--                 if hf then
--                     local out = df.unit.find(hf.unit_id) == nil
--                     local name = hfname(hf)

--                     table.insert(out and travelling or here, name)                    
--                 end
--             end
--         end
--     end

--     return here, travelling
-- end

function mission_actors(mission)
    local ret = {}

    local type = mission.type
    if type == df.army_controller.T_type.Request then
        for i,v in ipairs(mission.messengers) do
            local occ = df.occupation.find(v)
            if occ then
                local hf = df.historical_figure.find(occ.histfig_id)
                if hf then
                    --todo: no idea if this check is correct
                    local unit = df.unit.find(hf.unit_id)
                    local out = unit == nil or unit.flags1.left or not unit.flags1.important_historical_figure

                    table.insert(ret, { hfname(hf), out })
                end
            end
        end
    else
        for i,v in ipairs(mission.squads) do
            local squad = df.squad.find(v)
            if squad then
                local leader_hfid = squad.positions[0].occupant
                local hf = leader_hfid ~= -1 and df.historical_figure.find(leader_hfid)

                if hf then
                    --todo: no idea if this check is correct
                    local unit = df.unit.find(hf.unit_id)
                    local out = unit == nil or unit.flags1.left or not unit.flags1.important_historical_figure

                    table.insert(ret, { squadname(squad), out })
                end
            end
        end
    end

    return ret
end


--luacheck: in=
function missions_list()
    local ret = {}

    --todo: can just create the screen instead?
    execute_with_world_screen(function(ws)
        gui.simulateInput(ws, K'CIV_MISSIONS')

        for i,v in ipairs(ws.missions) do
            local title = missiontitle(v)
            local actors = {}
            local editable = false

            if v.type == df.army_controller.T_type.Request then
                for j,occ in ipairs(ws.messengers) do
                    if occ.histfig_id ~= -1 and occ.army_controller_id == v.id then
                        local name = hfname(df.historical_figure.find(occ.histfig_id))
                        local travelling = istrue(ws.messengers_travelling[j])

                        if not travelling then
                            editable = true
                        end

                        table.insert(actors, { name, travelling })
                    end
                end

                if #v.messengers == 0 then
                    editable = true
                end            

            else
                for j,squad in ipairs(ws.squads) do
                    if squad.positions[0].occupant ~= -1 and squad.army_controller_id == v.id then
                        local name = squadname(squad)
                        local travelling = istrue(ws.squads_travelling[j])

                        if not travelling and squad.army_controller_id == v.id then
                            editable = true
                        end                

                        table.insert(actors, { name, travelling })
                    end
                end

                if #v.squads == 0 then
                    editable = true
                end            
            end

            table.insert(ret, { title, v.id, v.type, actors, editable })
        end
    end)

    return ret
end

--types: 0:raid, 1:pillage, 2:raze, 3:one-time tribute, 4:ongoing tribute, 5:conquer and occupy, 6:demand surrender and occupy, 7:take over, 8:explore
--flags: free captives, release prisoners, take treasures, loot other, steal livestock

--luacheck: in=number
function mission_get(id)
    local mission = df.army_controller.find(id)
    if not mission then
        error('no mission ' .. tostring(id))
    end

    return execute_with_world_screen(function(ws)
        gui.simulateInput(ws, K'CIV_MISSIONS')

        local title = missiontitle(mission)
        local details = mp.NIL
        local actors = {}
        local editable = false

        if mission.type == df.army_controller.T_type.Request then
            for j,occ in ipairs(ws.messengers) do
                local travelling = istrue(ws.messengers_travelling[j])
                local sq_mission = df.army_controller.find(occ.army_controller_id)

                local ordertitle, ordertype
                if occ.army_controller_id == mission.id then
                    ordertype = 2
                    ordertitle = 'On this mission'
                elseif sq_mission then
                    ordertype = 1
                    ordertitle = missiontitle(sq_mission)
                else
                    ordertype = 0
                    ordertitle = 'No specific orders'
                end

                local name = occ.histfig_id == -1 and 'Messenger (unfilled)' or hfname(df.historical_figure.find(occ.histfig_id))

                if not travelling and occ.army_controller_id == mission.id then
                    editable = true
                end

                table.insert(actors, { name, occ.id, travelling, ordertitle, ordertype })
            end

            if #mission.messengers == 0 then
                editable = true
            end            

        else
            for j,squad in ipairs(ws.squads) do
                local travelling = istrue(ws.squads_travelling[j])
                local sq_mission = df.army_controller.find(squad.army_controller_id)

                local ordertitle, ordertype
                if squad.army_controller_id == mission.id then
                    ordertype = 2
                    ordertitle = 'On this mission'
                elseif sq_mission then
                    ordertype = 1
                    ordertitle = missiontitle(sq_mission)
                else
                    ordertype = 0
                    ordertitle = squad_order_title(squad)
                    if #ordertitle == 0 then
                        ordertitle = 'No specific orders'
                    end
                end

                if not travelling and squad.army_controller_id == mission.id then
                    editable = true
                end                

                table.insert(actors, { squadname(squad), squad.id, travelling, ordertitle, ordertype })
            end

            if #mission.squads == 0 then
                editable = true
            end            
        end

        local mtype = mission.type
        if mtype == df.army_controller.T_type.InvasionOrder then
            local data = mission.data.InvasionOrder
            local inv_type = data.type
            local inv_flags = data.flags

            local our_type = -1
            local our_flags = 0

            if inv_type == df.army_controller_invasion_order.T_type.Raze then
                our_type = 2
            elseif inv_type == df.army_controller_invasion_order.T_type.TakeOver then
                our_type = 7
            elseif inv_type == df.army_controller_invasion_order.T_type.Occupy then
                our_type = inv_flags.DemandSurrender and 6 or 5
            elseif inv_type == df.army_controller_invasion_order.T_type.DemandTribute then
                our_type = inv_flags.OngoingTribute and 4 or 3
            elseif inv_type == df.army_controller_invasion_order.T_type.Raid then
                our_type = 0
            elseif inv_type == df.army_controller_invasion_order.T_type.Explore then
                our_type = 8
            elseif inv_type == df.army_controller_invasion_order.T_type.Pillage then
                our_type = 1
            end

            our_flags = packbits(inv_flags.FreeCaptives, inv_flags.ReleaseOtherPrisoners, inv_flags.TakeImportantTreasures, inv_flags.LootOtherItems, inv_flags.StealLivestock)

            details = { our_type, our_flags }
        end

        return { title, mission.id, mtype, details, actors, editable }
    end)
end

--todo: is it safe to set this values directly, or better use screen?
--luacheck: in=number,number[]
function mission_set_details(id, details)
    local mission = df.army_controller.find(id)
    if not mission then
        error('no mission ' .. tostring(id))
    end

    local mtype = mission.type
    if mtype == df.army_controller.T_type.InvasionOrder then
        local data = mission.data.InvasionOrder

        local new_type = details[1]
        local new_flags = details[2]

        -- reset non-raid flags
        data.flags.OneTimeTribute = false
        data.flags.OngoingTribute = false
        data.flags.DemandSurrender = false

        -- no need to handle Explore here as it can't be set manually
        if new_type == 0 then
            data.type = df.army_controller_invasion_order.T_type.Raid
        elseif new_type == 1 then
            data.type = df.army_controller_invasion_order.T_type.Pillage
        elseif new_type == 2 then
            data.type = df.army_controller_invasion_order.T_type.Raze
        elseif new_type == 3 then
            data.type = df.army_controller_invasion_order.T_type.DemandTribute
            data.flags.OneTimeTribute = true
        elseif new_type == 4 then
            data.type = df.army_controller_invasion_order.T_type.DemandTribute
            data.flags.OngoingTribute = true
        elseif new_type == 5 then
            data.type = df.army_controller_invasion_order.T_type.Occupy
        elseif new_type == 6 then
            data.type = df.army_controller_invasion_order.T_type.Occupy
            data.flags.DemandSurrender = true
        end

        if data.type == df.army_controller_invasion_order.T_type.Raze or
           data.type == df.army_controller_invasion_order.T_type.Raid or
           data.type == df.army_controller_invasion_order.T_type.Pillage or
           data.type == df.army_controller_invasion_order.T_type.Explore then
            data.flags.FreeCaptives = hasbit(new_flags, 0)
            data.flags.ReleaseOtherPrisoners = hasbit(new_flags, 1)
            data.flags.TakeImportantTreasures = hasbit(new_flags, 2)
            data.flags.LootOtherItems = hasbit(new_flags, 3)
            data.flags.StealLivestock = hasbit(new_flags, 4)
        end

        return true
    end

    error('wrong mission type ' .. tostring(id) .. ' ' .. tostring(mtype)) 
end

--luacheck: in=number,number
function mission_toggle_actor(id, actorid)
    return execute_with_world_screen(function(ws)
        gui.simulateInput(ws, K'CIV_MISSIONS')

        for i,v in ipairs(ws.missions) do
            if v.id == id then
                gui.simulateInput(ws, K'SELECT')

                if v.type == df.army_controller.T_type.Request then
                    for j,occ in ipairs(ws.messengers) do
                        if occ.id == actorid then
                            ws.messenger_idx = j
                            gui.simulateInput(ws, K'SELECT')
                            return true
                        end
                    end
                else
                    for j,squad in ipairs(ws.squads) do
                        if squad.id == actorid then
                            ws.squad_idx = j
                            gui.simulateInput(ws, K'SELECT')
                            return true
                        end
                    end
                end

                error('no squad ' .. tostring(actorid))
            end

            gui.simulateInput(ws, K'STANDARDSCROLL_DOWN')
        end

        error('no mission ' .. tostring(id))
    end)
end

--luacheck: in=number
function mission_remove(id)
    --todo: can just create the screen instead?
    return execute_with_world_screen(function(ws)
        gui.simulateInput(ws, K'CIV_MISSIONS')

        for i,v in ipairs(ws.missions) do
            if v.id == id then
                gui.simulateInput(ws, K'CIV_REMOVE_MISSION')
                return true
            end

            gui.simulateInput(ws, K'STANDARDSCROLL_DOWN')
        end

        error('no mission ' .. tostring(id))
    end)
end

--luacheck: in=
function world_artifacts_list()
    local ret = {}

    --todo: can just create the screen instead?
    execute_with_world_screen(function(ws)
        gui.simulateInput(ws, K'CIV_ARTIFACTS')

        for i,v in ipairs(ws.artifact_records) do
            local name = translatename(v.name, false)
            local name_eng = translatename(v.name, true)

            local race = df.global.world.raws.creatures.all[v.race]
            local site_gov = v.type == df.historical_entity_type.SiteGovernment

            table.insert(ret, { name, v.id, name_eng, race.name[2], site_gov })
        end
    end)

    return ret
end

--luacheck: in=
function world_people_list()
    local ret = {}

    --todo: can just create the screen instead?
    execute_with_world_screen(function(ws)
        gui.simulateInput(ws, K'CIV_PEOPLE')

        ws.people:insert(0,df.historical_figure.find(10));ws.people:insert(0,df.historical_figure.find(11));ws.people:insert(0,df.historical_figure.find(8694));

        for i,v in ipairs(ws.people) do
            if v then
                local name = hfname(v, true)

                local race = df.creature_raw.find(v.race)
                local caste = race.caste[v.caste]
                local caste_name = caste.caste_name[0]
                if #caste_name > 0 then
                    name = name .. ' the ' .. caste_name
                end

                local location = 'Location unknown'

                if v.info.whereabouts then
                    if v.info.whereabouts.site ~= -1 then
                        local site = df.world_site.find(v.info.whereabouts.site)
                        if site then
                            location = 'Last in ' .. translatename(site.name,true)
                        end
                    elseif v.info.whereabouts.region_id ~= -1 then
                        local region = df.world_region.find(v.info.whereabouts.region_id)
                        if region then
                            location = 'Last in ' .. translatename(region.name,true)
                        end
                    elseif v.info.whereabouts.underground_region_id ~= -1 then
                        location = 'Last in the depths of the world'

                    elseif v.info.whereabouts.army_id ~= -1 then
                        location = 'Last known to be travelling'
                    end
                end


                table.insert(ret, { name, v.id, location })
            end
        end
    end)

    return ret
end

--luacheck: in=
function world_people_rescue(id)
    --todo: can just create the screen instead?
    return execute_with_world_screen(function(ws)
        gui.simulateInput(ws, K'CIV_PEOPLE')

        ws.people:insert(0,df.historical_figure.find(10));ws.people:insert(0,df.historical_figure.find(11));ws.people:insert(0,df.historical_figure.find(8694));

        for i,v in ipairs(ws.people) do
            if v and v.id == id then
                gui.simulateInput(ws, K'CIV_RESCUE')

                if ws.page == df.viewscreen_civlistst.T_page.Missions and ws.mission_idx ~= -1 then
                    return { true, ws.missions[ws.mission_idx].id }
                end

                return { false }
            end

            gui.simulateInput(ws, K'STANDARDSCROLL_DOWN')
        end

        error('no person ' .. tostring(id))
    end)    
end

-- print(pcall(function() return json:encode(civilizations_get_list()) end))
-- print(pcall(function() return json:encode(civilization_get_info(75)) end))
-- print(pcall(function() return json:encode(civilization_get_agreement(75,1)) end))
-- print(pcall(function() return json:encode(civilization_get_agreement(75,0)) end))
-- print(pcall(function() return json:encode(missions_list()) end))
-- print(pcall(function() return json:encode(mission_remove(250039)) end))
