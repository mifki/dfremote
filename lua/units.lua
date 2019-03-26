function unit_creature_name(unit)
    local prof = unit.profession
    local raw = df.creature_raw.find(unit.race)

    if prof == df.profession.CHILD then
        return raw.general_child_name[0]
    elseif prof == df.profession.BABY then
        return raw.general_baby_name[0]
    else
        return raw.name[0]
    end
end

--xxx: DFHack's Units::isCitizen() skips melancholy and raving units while they are actually citizens
function unit_iscitizen(unit)
    if unit.mood == df.mood_type.Berserk or
       unit_testflagcurse(unit, 'CRAZED') or unit_testflagcurse(unit, 'OPPOSED_TO_LIFE') or
       unit.enemy.undead or
       unit.flags3.ghostly or
       unit.flags1.marauder or unit.flags1.active_invader or unit.flags1.invader_origin or
       unit.flags1.forest or
       unit.flags1.merchant or unit.flags1.diplomat then
        return false
    end
           
    if unit.flags1.tame then
        return true
    end
            
    if unit.flags2.underworld or unit.flags2.resident or
       unit.flags2.visitor_uninvited or unit.flags2.visitor or
       unit.civ_id == -1 or
       unit.civ_id ~= df.global.ui.civ_id then
        return false
    end
    
    return true
end

function unit_get_effects(unit)
    local ret = {}

    local c1 = unit.counters
    local c2 = unit.counters2

    if c1.winded > 0 then
        table.insert(ret, { 'Winded', 7 })
    end

    if c1.stunned > 0 then
        table.insert(ret, { 'Stunned', 11 })
    end

    if c1.unconscious > 0 then
        table.insert(ret, { 'Unconscious', 15 })
    end

    --todo: below
    if c1.suffocation > 0 then
    end
    if c1.webbed > 0 then
    end

    if c1.pain >= 100 then
        table.insert(ret, { 'Extreme Pain', 14 })
    elseif c1.pain >= 50 then
        table.insert(ret, { 'Pain', 6 })
    end

    if c1.nausea > 0 then
        table.insert(ret, { 'Nauseous', 10 })
    end

    if c1.dizziness > 0 then
        table.insert(ret, { 'Dizzy', 11 })
    end


    if c2.paralysis > 0 then
        table.insert(ret, { 'Paralyzed', 11 })
    end

    if c2.numbness > 0 then
        table.insert(ret, { 'Numb', 3 })
    end

    if c2.fever > 0 then
        table.insert(ret, { 'Fever', 12 })
    end

    if c2.exhaustion > 6000 then
        table.insert(ret, { 'Exhausted', 14 })
    elseif c2.exhaustion > 4000 then
        table.insert(ret, { 'Over-Exerted', 14 })
    elseif c2.exhaustion >= 2000 then
        table.insert(ret, { 'Tired', 14 })
    end


    if c2.hunger_timer >= 50000 then
        table.insert(ret, { 'Hungry', 6 })
    end

    if c2.thirst_timer >= 50000 then
        table.insert(ret, { 'Dehydrated', 12 })
    elseif c2.thirst_timer >= 25000 then
        table.insert(ret, { 'Thirsty', 9 })
    end

    if c2.sleepiness_timer >= 150000 then
        table.insert(ret, { 'Very Drowsy', 12 })
    elseif c2.sleepiness_timer >= 57600 then
        table.insert(ret, { 'Drowsy', 9 })
    end

    return ret
end

--luacheck: in=number
function unit_query_selected(unitid)
    local unit
    if not unitid or unitid == -1 or unitid == 0 then
        local ws = screen_main()
        if ws._type ~= df.viewscreen_dwarfmodest then
            error(errmsg_wrongscreen(ws))
        end

        if df.global.ui.main.mode ~= df.ui_sidebar_mode.ViewUnits or df.global.ui_selected_unit == -1 then
            error('no selected unit')
        end

        unit = df.global.world.units.active[df.global.ui_selected_unit]
    else
        unit = df.unit.find(unitid)

        if not unit then
            error('no unit '..tostring(unitid))
        end
    end

    local uname = unitname(unit, false)
    local uname_en = unitname(unit, true)

    local prof = unit_fullprof(unit)
    local profcolor = dfhack.units.getProfessionColor(unit)

    local jobtitle, jobcolor = unit_jobtitle(unit, false)

    local is_citizen = unit_iscitizen(unit) 
    local can_edit_labors = is_citizen and unit.profession ~= df.profession.CHILD and unit.profession ~= df.profession.BABY

    local histfig = df.historical_figure.find(unit.hist_figure_id)
    local has_kills = histfig and histfig.info.kills ~= nil

    local flags = packbits(is_citizen, can_edit_labors, has_kills)

    local effects = unit_get_effects(unit)

    local custom_name = unit.name.nickname
    local custom_prof = unit.custom_profession

    local positions = {}
    if is_citizen then
        for i,v in ipairs(df.global.ui.main.fortress_entity.positions.assignments) do
            if v.histfig == unit.hist_figure_id then
                for j,w in ipairs(df.global.ui.main.fortress_entity.positions.own) do
                    if w.id == v.position_id then
                        local posname = capitalize(w.name[0])
                        table.insert(positions, posname)
                    end
                end
            end
        end
    end

    local num_inventory = #unit.inventory
    local num_spatters = #unit.body.spatters
    local num_assigned_animals = #unit_get_assigned_animals(unit.id)

    return { uname, uname_en, unit.id, unit.sex, prof, profcolor, jobtitle, jobcolor, flags, effects,
             custom_name, custom_prof, positions, num_assigned_animals, num_inventory, num_spatters }
end

function unit_get_squad(unit)
    return unit.military.squad_id ~= -1 and df.squad.find(unit.military.squad_id) or nil
end

function unit_get_order(unit)
    local squad = unit_get_squad(unit)

    if not squad then
        return nil
    end

    if #squad.orders > 0 then
        return squad.orders[0]
    end

    local pos = squad.positions[unit.military.squad_position]

    if #pos.orders > 0 then
        return pos.orders[0]
    end

    local month = math.floor(df.global.cur_year_tick / 33600)
    
    if #squad.schedule <= squad.cur_alert_idx then
        return nil
    end
    
    local sched_orders = squad.schedule[squad.cur_alert_idx][month].orders
    
    if #sched_orders > 0 then
        return sched_orders[0].order
    end

    return nil
end

local TRAINING_LEVELS = {
    'Semi-Wild',    -- Semi-wild
    'Trained',            -- Trained
    '-Trained-',            -- Well-trained
    '+Trained+',            -- Skillfully trained
    '*Trained*',            -- Expertly trained
    dfhack.df2utf(string.char(240))..'Trained'..dfhack.df2utf(string.char(240)),    -- Exceptionally trained
    dfhack.df2utf(string.char(15))..'Trained'..dfhack.df2utf(string.char(15)),        -- Masterully Trained
    'Tame',                -- Domesticated
    '',                        -- undefined
    '',                        -- wild/untameable
}

local reason_titles = {
    'not_following_order',
    'activity_cancelled',
    'no_barracks',
    'improper_barracks',
    'no activity',
    'cannot_individually_drill',
    'does_not_exist',
    'no_archery_target',
    'improper_building',
    'unreachable location',
    'invalid location',
    'no reachable valid target',
    'no_burrow',
    'not_in_squad',
    'no_patrol_route',
    'no_reachable_point_on_route',
    'invalid_order'
}

--[[
        def unit_isfortmember(u)
            # RE from viewscreen_unitlistst ctor
            return false if df.gamemode != :DWARF or
                    u.mood == :Berserk or
                    unit_testflagcurse(u, :CRAZED) or
                    unit_testflagcurse(u, :OPPOSED_TO_LIFE) or
                    u.enemy.undead or
                    u.flags3.ghostly or
                    u.flags1.marauder or u.flags1.active_invader or u.flags1.invader_origin or
                    u.flags1.forest or
                    u.flags1.merchant or u.flags1.diplomat
            return true if u.flags1.tame
            return false if u.flags2.underworld or u.flags2.resident or
                    u.flags2.visitor_uninvited or u.flags2.visitor or
                    u.civ_id == -1 or
                    u.civ_id != df.ui.civ_id
            true
        end

        def unit_category(u)
            return if u.flags1.left or u.flags1.incoming
            # return if hostile & unit_invisible(u) (hidden_in_ambush or caged+mapblock.hidden or caged+holder.ambush
            return :Dead if u.flags1.dead
            return :Dead if u.flags3.ghostly # hostile ?
            return :Others if !unit_isfortmember(u)
            casteflags = u.race_tg.caste[u.caste].flags if u.caste >= 0
            return :Livestock if casteflags and (casteflags[:PET] or casteflags[:PET_EXOTIC])
            return :Citizens if unit_testflagcurse(u, :CAN_SPEAK)
            :Livestock
            # some other stuff with ui.race_id ? (jobs only?)
        end
]]

function is_onbreak(unit)
    for i,v in pairs(unit.status.misc_traits) do
        if v.id == df.misc_trait_type.OnBreak then
            return true
        end
    end

    return false
end

function is_hidden(unit)
    local x,y,z = dfhack.units.getPosition(unit)
    local pos = {x=x, y=y, z=z}

    local bx = bit32.rshift(pos.x, 4)
    local by = bit32.rshift(pos.y, 4)
    local block = df.global.world.map.block_index[bx][by][pos.z]
    local d = block.designation[unit.pos.x%16][unit.pos.y%16]
    
    return d.hidden
end

function unit_testflagcurse(unit, flagname)
    if unit.curse.rem_tags1[flagname] then
        return false
    end

    if unit.curse.add_tags1[flagname] then
        return true
    end

    if unit.caste >= 0 then
        return df.global.world.raws.creatures.all[unit.race].caste[unit.caste].flags[flagname]
    end

    return false
end

function unit_fullprof(unit)
    local prof = unitprof(unit)

    if unit.enemy.undead then
        if #C_unit_corpse_name(unit) == 0 then
            prof = prof .. ' Corpse'
        else
            prof = dfhack.df2utf(C_unit_corpse_name(unit)):utf8capitalize() -- reanimated body parts use this string instead
        end
    end
  
    if unit.curse.name_visible and #unit.curse.name > 0 then
        prof = prof .. ' ' ..unit.curse.name
    end

    local ownerid = unit.relationship_ids[df.unit_relationship_type.Pet]
    local owner = (ownerid ~= -1) and df.unit.find(ownerid) or nil

    if not owner and unit.flags1.tame then
        prof = 'Stray ' .. prof
    end

    if unit.flags3.ghostly then
        prof = 'Ghostly ' .. prof
    end

    if unit.flags1.tame then
        prof = prof .. ' (' .. TRAINING_LEVELS[unit.training_level+1] .. ')'
    end

    return prof    
end

--todo: this should probably return the colour as well
function unit_fulltitle(unit)
    if not unit then
        return '#invalid unit#'
    end
    
    local uname = unitname(unit)
    local fullprof = unit_fullprof(unit)
    local fullname = (#uname>0 and uname .. ', ' or '') .. fullprof

    return fullname
end

local needs_for_event_types = {
    [df.activity_event_type.Socialize] = { df.need_type.Socialize, df.need_type.Excitement, df.need_type.BeCreative },
    [df.activity_event_type.Worship] = { df.need_type.PrayOrMedidate },
}

local function has_important_need(unit, need_types)
    for j,w in ipairs(need_types) do
        for i,v in ipairs(unit.status.current_soul.personality.needs) do
            if v.id == w and v.focus_level <= -10000 then
                return true
            end
        end
    end

    return false
end

function unit_jobtitle(unit, norepeatsuffix, activityonly)
    local meeting = unit.meeting
    if meeting.target_entity ~= -1 and meeting.target_role ~= -1 and not unit.job.current_job then
        if meeting.state == df.unit.T_meeting.T_state.FollowNoble or meeting.state == df.unit.T_meeting.T_state.DoMeeting then
            --todo: meeting.target_role is also checked but I don't know how to do it properly without hardcoding
            return 'Attend Meeting', 11, 0
        end
    end

    if #unit.social_activities > 0 and not unit.job.current_job then
        local actid = unit.social_activities[0]

        local act = df.activity_entry.find(actid)
        for i,ev in ripairs(act.events) do
            local participants = ev:getParticipantInfo()

            --todo: what is free_units and are all of free_units also in units? which one to use?
            if participants then
                for j,v in ipairs(participants.free_units) do
                    -- game shows the topmost event if no match found for the unit
                    if v == unit.id or i == 0 then
                        local jobtitle = actevname(ev, unit.id)
                        local jobcolor = 10
    
                        local need_types = needs_for_event_types[act.events[0]:getType()]
                        local important = need_types and has_important_need(unit, need_types)
                        
                        if important then
                            jobtitle = jobtitle .. '!'
                            jobcolor = 13
                        end
    
                        return jobtitle, jobcolor, 2
                    end
                end
            end
        end    
    end

    if activityonly then
        return nil
    end

    local onbreak = is_onbreak(unit)
    local jobtitle = unit.job.current_job and jobname(unit.job.current_job) or (onbreak and 'On Break' or 'No Job')
    local jobcolor = 11

    if unit.job.current_job and unit.job.current_job.flags['repeat'] and not norepeatsuffix then
        jobtitle = jobtitle .. '/R'
    elseif unit.job.current_job and unit.job.current_job.flags['by_manager'] and not norepeatsuffix then
        jobtitle = jobtitle .. '/O'
    end

    if not unit.job.current_job then
        if unit.profession == df.profession.CHILD or unit.profession == df.profession.BABY then
            return '', 0, 0
        end

        jobcolor = onbreak and 3 or 14
    end

    if not unit.job.current_job then
        if unit.profession ~= unit.profession2 then
            local o = unit_get_order(unit)

            if o then
                jobcolor = 6 + 8

                local rc = o:reasonCannot(unit)
                if rc ~= 0 then
                    jobtitle = 'Soldier (' .. reason_titles[rc+1] .. ')'
                    jobcolor = 6

                    --xxx: that's how it seems to be in the game - orders with reasons are always shown
                    --xxx: but for others the current activity is shown instead if exists
                    if o._type ~= df.squad_order_trainst then
                        return jobtitle, jobcolor, 1
                    end

                else
                    jobtitle = dfhack.df2utf(utils.call_with_string(o, 'getDescription'))    
                end

            end
        end

        if #unit.military.individual_drills > 0 then
            local act_id = unit.military.individual_drills[0]
            local act = df.activity_entry.find(act_id)
            
            if act and #act.events > 0 then
                local ev = act.events[#act.events-1]
                jobtitle = actevname(ev, unit.id)
                jobcolor = 10
            else
                --todo: else
            end
    
        else
            local s = unit_get_squad(unit)

            if s and s.cur_alert_idx ~= 0 then
                local sqpos = s.positions[unit.military.squad_position]
                local activities,events = C_squad_position_activities_events(sqpos)
                
                local act_id = -1
                local ev_id = -1

                for i,v in ripairs(events) do
                    if activities[i] ~= -1 and events[i] ~= -1  then
                        act_id = activities[i]
                        ev_id = events[i]
                        break
                    end
                end
                
                local act = df.activity_entry.find(act_id)
                local ev = act and utils.binsearch(act.events, ev_id, 'event_id')

                if ev then
                    jobtitle = actevname(ev, unit.id)
                    jobcolor = 14
                
                elseif unit.profession ~= unit.profession2 then
                    -- jobtitle = 'Soldier (no activity)'
                    -- jobcolor = 6
                end
            end
        end
    end
    
    return jobtitle, jobcolor, unit.job.current_job and 1 or 0
end

-- df.viewscreen_unitlist_page.Citizens, Livestock, Others, Dead
function unitlist_get_units(group)
    return execute_with_units_screen(function(ws)
        return ws.units[group]
    end)
end

local function unitlist_process_citizen(unit)
    local fullname = unit_fulltitle(unit)

    local jobtitle,jobcolor,jobkind  = unit_jobtitle(unit)

    local jobbldref = unit.job.current_job and dfhack.job.getGeneralRef(unit.job.current_job, df.general_ref_type.BUILDING_HOLDER) --as:df.general_ref_building_holderst
    local jobbld = jobbldref and df.building.find(jobbldref.building_id) or nil
    local can_goto_bld = jobbld and true or false
    local bldpos = jobbld and { jobbld.centerx, jobbld.centery, jobbld.z } or mp.NIL

    --todo: how to determine these?
    local can_cancel = false
    local can_suspend = false
    local can_repeat = false
    local can_remove_wrk = jobbld ~= nil and not unit.job.current_job.flags.special

    if jobbld and not unit.job.current_job.flags.special then
        local jt = unit.job.current_job.job_type

        if jt == df.job_type.ConstructBuilding then
            can_cancel = true
            can_suspend = true

        elseif jt == df.job_type.DestroyBuilding then
            can_cancel = true

        else
            if jobbld._type == df.building_furnacest or jobbld._type == df.building_workshopst then
                can_cancel = true
                can_suspend = true
                can_repeat = true
            end
        end
    end

    local jobrepeat = unit.job.current_job and unit.job.current_job.flags['repeat']
    
    local legendary = false
    for i,v in ipairs(unit.status.current_soul.skills) do
        if v.rating >= 15 then
            legendary = true
            break
        end
    end    

    local flags = packbits(can_goto_bld, can_cancel, can_suspend, can_repeat, can_remove_wrk, jobrepeat, legendary)

    local profcolor = dfhack.units.getProfessionColor(unit)

    return { fullname, unit.id, jobtitle, flags, pos2table(unit.pos), bldpos, profcolor, jobcolor, jobkind }
end

--luacheck: in=
function units_list_dwarves()
    return execute_with_units_screen(function(ws)
        local ret = {}

        for i,unit in ipairs(ws.units[0]) do
            table.insert(ret, unitlist_process_citizen(unit))
        end

        return { ret, { #ws.units[0], #ws.units[1], #ws.units[2], #ws.units[3] } }
    end)
end

--luacheck: in=
function units_list_livestock()
    return execute_with_units_screen(function(ws)
        local ret = {}
        
        for i,unit in ipairs(ws.units[1]) do
            local fullname = unit_fulltitle(unit)
            local right = TRAINING_LEVELS[unit.training_level+1]

            if unit.flags1.caged then
                right = right .. ' (Caged)'
            elseif unit.flags1.chained then
                right = right .. ' (Chained)'
            end

            local profcolor = dfhack.units.getProfessionColor(unit)            

            table.insert(ret, { fullname, unit.id, right, 0, pos2table(unit.pos), mp.NIL, profcolor, 1+8 })
        end
    
        return { ret, { #ws.units[0], #ws.units[1], #ws.units[2], #ws.units[3] } }
    end)
end

--luacheck: in=
function units_list_other()
    return execute_with_units_screen(function(ws)
        local ret = {}
        
        for i,unit in ipairs(ws.units[2]) do
            local fullname = unit_fulltitle(unit)
            local profcolor = dfhack.units.getProfessionColor(unit)                        
            local right, rightcolor

            if unit_testflagcurse(unit, 'CRAZED') or unit.mood == df.mood_type.Berserk then
                right = 'Berserk'
                rightcolor = 4+8
            elseif unit.flags3.ghostly or unit_testflagcurse(unit, 'OPPOSED_TO_LIFE') then
                profcolor = 15
                right = 'Undead'
                rightcolor = 8

            elseif unit.flags1.active_invader or unit.flags1.invader_origin then
                right = 'Invader'
                rightcolor = 4                
            elseif unit.flags1.diplomat and #df.global.ui.dip_meeting_info > 0 and df.global.ui.dip_meeting_info[0].diplomat_id == unit.hist_figure_id then
                right = 'Diplomat'
                rightcolor = 15
            elseif #df.global.ui.caravans > 0 and df.global.ui.caravans[0].entity == unit.civ_id then
                right = 'Merchant'
                rightcolor = 7
            elseif unit.flags1.forest or unit.flags1.merchant or unit.flags1.diplomat then
                right = 'Friendly'
                rightcolor = 2+8                

            -- elseif unit.civ_id ~= -1 then
            --     right = 'Hostile'
            --     rightcolor = 4

            else
                if unit.flags3[31] then
                    right = 'Guest'
                    rightcolor = 2+8
                elseif unit.flags2.visitor then
                    right = 'Visitor'
                    rightcolor = 2+8

                elseif df.global.world.raws.creatures.all[unit.race].underground_layer_min == 5 then
                    right = 'Underworld'
                    rightcolor = 4

                elseif unit.animal.population.region_x == -1 then
                    if unit.flags2.visitor_uninvited then
                        right = 'Uninvited Guest'
                        rightcolor = 4
                    elseif unit.flags2.resident then
                        right = 'Current Resident'
                        rightcolor = 4
                    else
                        right = 'Friendly'
                        rightcolor = 2+8                
                    end

                else
                    right = 'Wild Animal'
                    rightcolor = 2
                end
            end

            if unit.flags1.caged then
                if unit.flags1.active_invader or unit.flags1.invader_origin then
                    right = 'Caged Prisoner'
                else
                    right = right .. ' (Caged)'
                end
            elseif unit.flags1.chained then
                right = right .. ' (Chained)'
            end

            local activity,actcolor = unit_jobtitle(unit, false, true)
            if not activity and unit.flags3[31] then
                activity,actcolor = 'No Activity', 14
            end
            table.insert(ret, { fullname, unit.id, right, 0, pos2table(unit.pos), mp.NIL, profcolor, rightcolor, activity or mp.NIL, actcolor or 0 })
        end
    
        return { ret, { #ws.units[0], #ws.units[1], #ws.units[2], #ws.units[3] } }
    end)
end

--luacheck: in=
function units_list_dead()
    return execute_with_units_screen(function(ws)
        local ret = {}

        for i,unit in ipairs(ws.units[3]) do --ripairs(df.global.world.units.active) do --xxx: reverse because that's how it's in df
            local fullname = unit_fulltitle(unit)
            local missing = false
            if unit.civ_id == df.global.ui.civ_id then
                local incident = unit.counters.death_id ~= -1 and df.incident.find(unit.counters.death_id)
                missing = incident and not incident.flags.discovered
            end

            local profcolor = dfhack.units.getProfessionColor(unit)            
            local stcolor = missing and 7 or 13

            table.insert(ret, { fullname, unit.id, missing and "Missing" or "Deceased", 0, mp.NIL, mp.NIL, profcolor, stcolor })
        end

        ws.breakdown_level = df.interface_breakdown_types.STOPSCREEN

        return { ret, { #ws.units[0], #ws.units[1], #ws.units[2], #ws.units[3] } }
    end)
end

--luacheck: in=number
function unit_goto(unitid)
    local unit = df.unit.find(unitid)

    if not unit then
        return
    end

    local x,y,z = dfhack.units.getPosition(unit)

    df.global.ui.main.mode = df.ui_sidebar_mode.ViewUnits

    df.global.cursor.x = x
    df.global.cursor.y = y
    df.global.cursor.z = z - 1

    local ws = dfhack.gui.getCurViewscreen()
    --gui.simulateInput(ws, K'CURSOR_DOWN_Z')
    gui.simulateInput(ws, K'CURSOR_UP_Z')

    recenter_view(x, y, z)
end

--luacheck: in=number
function unit_goto_bld(unitid)
    local unit = df.unit.find(unitid)

    if not unit then
        return
    end

    local jobbldref = unit.job.current_job and dfhack.job.getGeneralRef(unit.job.current_job, df.general_ref_type.BUILDING_HOLDER) --as:df.general_ref_building_holderst
    local jobbld = jobbldref and df.building.find(jobbldref.building_id) or nil

    if not jobbld then
        return
    end

    --todo: reset main
    df.global.ui.main.mode = df.ui_sidebar_mode.QueryBuilding

    df.global.cursor.x = jobbld.centerx
    df.global.cursor.y = jobbld.centery
    df.global.cursor.z = jobbld.z-1

    local ws = dfhack.gui.getCurViewscreen()
    --gui.simulateInput(ws, K'CURSOR_DOWN_Z')
    gui.simulateInput(ws, K'CURSOR_UP_Z')

    recenter_view(jobbld.centerx, jobbld.centery, jobbld.z)
    --return {jobbld.centerx,jobbld.centery,jobbld.z}
end

--luacheck: in=number
function unit_follow(unitid)
    df.global.ui.follow_unit = unitid
end

--luacheck: in=number
function unit_job_removeworker(unitid)
    local unit = df.unit.find(unitid)
    if not unit then
        return false
    end

    if not unit.job.current_job then
        return false
    end

    return dfhack.job.removeWorker(unit.job.current_job, 100)
end

--luacheck: in=number
function unit_job_suspend(unitid)
    local unit = df.unit.find(unitid)
    if not unit then
        return false
    end

    if not unit.job.current_job then
        return false
    end

    -- value = istrue(value)

    -- if value then
        unit.job.current_job.flags.suspend = true
        dfhack.job.removeWorker(unit.job.current_job, 100)
    -- else
    --     unit.job.current_job.flags.suspend = false
    --     df.global.process_jobs = true
    -- end

    return true
end

--luacheck: in=number,bool
function unit_job_set_repeat(unitid, value)
    local unit = df.unit.find(unitid)
    if not unit then
        return false
    end

    if not unit.job.current_job then
        return false
    end

    unit.job.current_job.flags['repeat'] = istrue(value)

    return true
end

--luacheck: in=number
function unit_job_cancel(unitid)
    local unit = df.unit.find(unitid)
    if not unit then
        return false
    end

    local job = unit.job.current_job

    if not job then
        return false
    end

    -- remove from unit
    unit.job.current_job = nil

    -- remove from building
    local jobbldref = job and dfhack.job.getGeneralRef(job, df.general_ref_type.BUILDING_HOLDER) --as:df.general_ref_building_holderst
    local jobbld = jobbldref and df.building.find(jobbldref.building_id) or nil

    if jobbld then
        for i,v in ipairs(jobbld.jobs) do
            if v == job then
                jobbld.jobs:erase(i)
                break
            end
        end
    end

    -- unlink from world
    local link = job.list_link
    if link.prev then
        link.prev.next = link.next
    end
    if link.next then
        link.next.prev = link.prev
    end
    job.list_link = nil
    df.delete(link)

    -- delete object
    for i,v in ipairs(job.items) do
        df.delete(v)
    end
    for i,v in ipairs(job.specific_refs) do
        df.delete(v)
    end
    for i,v in ipairs(job.job_items) do
        df.delete(v)
    end
    for i,v in ipairs(job.general_refs) do
        df.delete(v)
    end
    
    df.delete(job)

    return true
end

--luacheck: in=number,bool
function unit_get_thoughts(unitid, is_histfig)
    if istrue(is_histfig) then
        local hf = df.historical_figure.find(unitid)
        if not hf then
            error('no hf '..tostring(unitid))
        end

        local dummyunit
        for i,v in ipairs(df.global.world.units.active) do
            if unit_iscitizen(v) then
                dummyunit = v
                break
            end
        end

        local unitws = df.viewscreen_unitst:new()
        unitws.unit = dummyunit
        gui.simulateInput(unitws, K'UNITVIEW_RELATIONSHIPS')
        df.delete(unitws)

        local relws = dfhack.gui.getCurViewscreen() --as:df.viewscreen_layer_unit_relationshipst
        relws.parent.child = nil
        relws.parent = nil
        relws.relation_unit:insert(0, nil)
        relws.relation_hf:insert(0, hf)
        relws.relation_unit_type:insert(0, 0)
        relws.relation_histfig_type:insert(0, 0)
        --relws.relation_textline:insert(0, '')
        gui.simulateInput(relws, K'UNITVIEW_RELATIONSHIPS_VIEW')
        df.delete(relws)

    else
        local unit = df.unit.find(unitid)
        if not unit then
            error('no unit '..tostring(unitid))
        end

        --xxx: this method creates an extra screen but doesn't require to check unit_iscitizen() and other flags we're unaware of
        local unitlistws = df.viewscreen_unitlistst:new()
        unitlistws.page = df.viewscreen_unitlist_page.Citizens
        unitlistws.cursor_pos[0] = 0
        unitlistws.units[0]:insert(0, unit)
        unitlistws.jobs[0]:insert(0, nil)
        
        gui.simulateInput(unitlistws, K'UNITJOB_VIEW_UNIT')

        local ws = dfhack.gui.getCurViewscreen()
        if ws._type == df.viewscreen_unitst then
            gui.simulateInput(ws, K'SELECT')
            ws.breakdown_level = df.interface_breakdown_types.STOPSCREEN
        end

        df.delete(unitlistws)

        --[[if not C_unit_dead(unit) and unit_iscitizen(unit) then
            local unitws = df.viewscreen_unitst:new()
            unitws.unit = unit
            gui.simulateInput(unitws, K'SELECT')

            df.delete(unitws)
        else
            local unitlistws = df.viewscreen_unitlistst:new()
            unitlistws.page = df.viewscreen_unitlist_page.Livestock
            unitlistws.cursor_pos[1] = 0
            unitlistws.units[1]:insert(0, unit)
            unitlistws.jobs[1]:insert(0, nil)
            gui.simulateInput(unitlistws, K'UNITJOB_VIEW')

            df.delete(unitlistws)
        end]]
    end

    local ws = dfhack.gui.getCurViewscreen() --as:df.viewscreen_textviewerst
    if ws._type ~= df.viewscreen_textviewerst then
        error('can not switch to thoughts screen')
    end
    
    local text = ''
    for i,v in ipairs(ws.src_text) do
        if #v.value > 0 then
            text = text .. dfhack.df2utf(v.value:gsub('%[P]', '[B]')) .. ' '
        end
    end
    
    text = text:gsub('  ', ' ')
    ws.breakdown_level = df.interface_breakdown_types.STOPSCREEN

    return { text }
end

local relations_unit = {
    { 'Pet', 10 },
    { 'Spouse', 12 },
    { 'Mother', 11 },
    { 'Father', 11 },
    { 'LastAttacker', 0 },
    { 'GroupLeader', 0 },
    { 'Dragee', 0 },
    { 'Dragger', 0 },
    { 'RiderMount', 0 },
    { 'Lover', 12 },
    { 'unk10', 0 },
    { 'unk11', 0 },
    { 'Child', 11 },
    { 'Friend', 15 },
    { 'Grudge', 13 },
    { 'Deity', 14 },
    { 'Long-term Acquaintance', 7 },
    { 'Passing Acquaintance', 7 },
    { 'Bonded', 15 },
    { 'Hero', 11 },
    { 'Considers Violent', 12 },
    { 'Considers Psychotic', 13 },
    { 'Good for Business', 14 },
    { 'Friendly Terms', 7 },
    { 'Considers Killer', 12 },
    { 'Considers Murderer', 13 },
    { 'Comrade', 15 },
    { 'Member of Respected Group', 14 },
    { 'Member of Hated Group', 13 },
    { 'Enemy Fighter', 13 },
    { 'Friendly Fighter', 15 },
    { 'Considers Bully', 12 },
    { 'Considers Brigand', 12 },
    { 'Loyal Soldier', 15 },
    { 'Considers Monster', 13 },    
    
    --todo: use correct colours for below
    { 'Considers Storyteller', 13 },
    { 'Considers Poet', 13 },
    { 'Considers Bard', 13 },
    { 'Considers Dancer', 13 },
    { 'Master', 13 },
    { 'Apprentice', 13 },
    { 'Companion', 13 },
    { 'Former Master', 13 },
    { 'Former Apprentice', 13 },
    { 'Considers Quarreler', 13 },
    { 'Considers Flatterer', 13 },
    { 'Hunter', 13 },
    { 'Protector Of The Weak', 13 },
}

local relations_hf = {
    { 'Mother', 11 },
    { 'Father', 11 },
    { 'Parent', 11 },
    { 'Husband', 12 },
    { 'Wife', 12 },
    { 'Spouse', 12 },
    { 'Eldest Son', 11 },
    { 'Second Eldest Son', 11 },
    { 'Third Eldest Son', 11 },
    { 'Fourth Eldest Son', 11 },
    { 'Fifth Eldest Son', 11 },
    { 'Sixth Eldest Son', 11 },
    { 'Seventh Eldest Son', 11 },
    { 'Eighth Eldest Son', 11 },
    { 'Ninth Eldest Son', 11 },
    { 'Tenth Eldest Son', 11 },
    { 'Son', 11 },
    { 'Youngest Son', 11 },
    { 'Only Son', 11 },
    { 'Eldest Daughter', 11 },
    { 'Second Eldest Daughter', 11 },
    { 'Third Eldest Daughter', 11 },
    { 'Fourth Eldest Daughter', 11 },
    { 'Fifth Eldest Daughter', 11 },
    { 'Sixth Eldest Daughter', 11 },
    { 'Seventh Eldest Daughter', 11 },
    { 'Eighth Eldest Daughter', 11 },
    { 'Ninth Eldest Daughter', 11 },
    { 'Tenth Eldest Daughter', 11 },
    { 'Daughter', 11 },
    { 'Only Daughter', 11 },
    { 'Youngest Daughter', 11 },
    { 'Eldest Child', 11 },
    { 'Second Eldest Child', 11 },
    { 'Third Eldest Child', 11 },
    { 'Fourth Eldest Child', 11 },
    { 'Fifth Eldest Child', 11 },
    { 'Sixth Eldest Child', 11 },
    { 'Seventh Eldest Child', 11 },
    { 'Eighth Eldest Child', 11 },
    { 'Ninth Eldest Child', 11 },
    { 'Tenth Eldest Child', 11 },
    { 'Child', 11 },
    { 'Youngest Child', 11 },
    { 'Only Child', 11 },
    { 'Paternal Grandmother', 3 },
    { 'Paternal Grandfather', 3 },
    { 'Maternal Grandmother', 3 },
    { 'Maternal Grandfather', 3 },
    { 'Grandmother', 3 },
    { 'Grandfather', 3 },
    { 'Grandparent', 3 },
    { 'Older Brother', 11 },
    { 'Older Sister', 11 },
    { 'Older Sibling', 11 },
    { 'Younger Brother', 11 },
    { 'Younger Sister', 11 },
    { 'Younger Sibling', 11 },
    { 'Cousin', 3 },
    { 'Aunt', 3 },
    { 'Uncle', 3 },
    { 'Niece', 3 },
    { 'Nephew', 3 },
    { 'Sibling', 3 },
    { 'Grandchild', 3 },
}

--luacheck: in=number
function unit_get_relationships(unitid)
    local unit = df.unit.find(unitid)
    if not unit then
        error('no unit '..tostring(unitid))
    end

    local unitws = df.viewscreen_unitst:new()
    unitws.unit = unit
    gui.simulateInput(unitws, K'UNITVIEW_RELATIONSHIPS')
    df.delete(unitws)    

    local ws = dfhack.gui.getCurViewscreen() --as:df.viewscreen_layer_unit_relationshipst
    if ws._type ~= df.viewscreen_layer_unit_relationshipst then
        error('can not switch to relationships screen')
    end

    local ret = {}

    for i,v in ipairs(ws.relation_unit) do
        local name, namecolor, id, can_view, can_zoom
        if v then
            name = unit_fulltitle(v)
            namecolor = dfhack.units.getProfessionColor(v)
            id = v.id
            can_view = true
            can_zoom = not C_unit_dead(v)
        else
            local hf = ws.relation_hf[i]
            name = hfname(hf)
            namecolor = 15
            id = hf.id
            can_view = hf.flags.deity --todo: maybe others?
            can_zoom = false
        end

        local rel_u = ws.relation_unit_type[i]
        local rel_hf = ws.relation_histfig_type[i]
        local rel = ((rel_hf ~= -1) and relations_hf[rel_hf+1] or relations_unit[rel_u+1]) or { '#unknown relation#', 7 }
        local flags = (v and 1 or 0) + (can_zoom and 2 or 0) + (can_view and 4 or 0)

        --todo: pass legendary skill status to flash the names
        table.insert(ret, { name, id, namecolor, rel[1], rel[2], flags, can_zoom and pos2table(v.pos) or mp.NIL })
    end

    ws.breakdown_level = df.interface_breakdown_types.STOPSCREEN

    return ret
end

local inventory_item_modes = {
    --[['Hauled',
    'Weapon',
    'Worn',
    'Piercing',
    'Flask',
    'WrappedAround',
    'StuckIn',
    'InMouth',
    'Pet', -- comment='Left shoulder, right shoulder, or head, selected randomly using pet_seed'/>
    'SewnInto',
    'Hauled']]

    'hauled',
    '##',
    '##',
    'in ##',
    '##',
    'wrapped around ##',
    'stuck in ##',
    '##',
    'pet', -- comment='Left shoulder, right shoulder, or head, selected randomly using pet_seed'/>
    'sewn into ##',
    'strapped to ##'
}

--luacheck: in=number
function unit_get_inventory(unitid)
    local unit = df.unit.find(unitid)
    if not unit then
        error('no unit '..tostring(unitid))
    end

    local ret = {}

    for i,v in ipairs(unit.inventory) do
        local item = v.item
        local title = itemname(item, 3, true)

        local frm = inventory_item_modes[v.mode+1]
        local part = (v.body_part_id ~= -1) and unit.body.body_plan.body_parts[v.body_part_id].name_singular[0].value or ''
        local where = frm and part and frm:gsub('##', part) or ''

        --xxx: let's show hauled items on top
        table.insert(ret, (v.mode == 0) and 1 or #ret+1, { title, item.id, where })
    end    

    return ret
end

--luacheck: in=number
function unit_get_inventory_and_spatters(unitid)
    local unit = df.unit.find(unitid)
    if not unit then
        error('no unit '..tostring(unitid))
    end

    local inv = {}
    local spatters = {}

    for i,v in ipairs(unit.inventory) do
        local item = v.item
        local title = itemname(item, 3, true)

        local frm = inventory_item_modes[v.mode+1]
        local part = (v.body_part_id ~= -1) and unit.body.body_plan.body_parts[v.body_part_id].name_singular[0].value or ''
        local where = frm and part and frm:gsub('##', part) or ''

        --xxx: let's show hauled items on top
        table.insert(inv, (v.mode == 0) and 1 or #inv+1, { title, item.id, where })
    end

    --todo: game shows "water covering" BUT "coating of <name>'s elf blood" for the same spatter size
    for i,v in ipairs(unit.body.spatters) do
        local mi = dfhack.matinfo.decode(v.mat_type, v.mat_index)
        if mi then
            local spattersize = ''
            for k,w in ripairs(item_spatter_sizes) do
                if v.size >= w[1] then
                    spattersize = ' ' .. w[2]
                    break
                end
            end

            local creatureprefix = mi.figure and (hfname(mi.figure) .. ' ') or ''

            local matprefix = #mi.material.prefix > 0 and (mi.material.prefix .. ' ') or ''
            local title = creatureprefix .. matprefix .. mi.material.state_name[v.mat_state] .. spattersize

            local part = (v.body_part_id ~= -1) and unit.body.body_plan.body_parts[v.body_part_id].name_singular[0].value or ''
            local where = part

            table.insert(spatters, { title, where })
        end
    end

    return { inv, spatters }
end

local skill_class_names = {
    'General',
    'Medical',
    'Personal',
    'Social',
    'Cultural',
    'Weapons',
    'Unarmed',
    'Attack',
    'Defense',
    'Other Mil.',
}

--luacheck: in=number
function unit_get_skills(unitid)
    local unit = df.unit.find(unitid)
    if not unit then
        error('no unit '..tostring(unitid))
    end

    local common_skills = {}
    local performance_skills = {}

    local tmp = {}
    for i,v in ipairs(skill_class_names) do
        table.insert(tmp, { v, {} })
    end

    local skills = unit.status.current_soul.skills

    for i,v in ipairs(skills) do
        local class = df.job_skill.attrs[v.id].type
        table.insert(tmp[class+1][2], { v.id, v.rating, istrue(v.rusty) })
    end

    for i,v in ipairs(tmp) do
        if #v[2] > 0 then
            table.insert(common_skills, v)
        end
    end

    local perf = unit.status.current_soul.performance_skills
    if perf then
        local tmp

        -- instruments
        tmp = {}
        for i,v in ipairs(perf.musical_instruments) do
            local inst = df.global.world.raws.itemdefs.instruments[v.id]
            table.insert(tmp, { dfhack.df2utf(inst.name):utf8capitalize(), { 0, v.id }, v.rating })
        end
        table.insert(performance_skills, tmp)

        -- poetic
        tmp = {}
        for i,v in ipairs(perf.poetic_forms) do
            local form = df.poetic_form.find(v.id)
            if form then
                table.insert(tmp, { dfhack.TranslateName(form.name, true), { 1, v.id }, v.rating })
            end
        end
        table.insert(performance_skills, tmp)

        -- musical
        tmp = {}
        for i,v in ipairs(perf.musical_forms) do
            local form = df.musical_form.find(v.id)
            if form then
                table.insert(tmp, { dfhack.TranslateName(form.name, true), { 2, v.id }, v.rating })
            end
        end
        table.insert(performance_skills, tmp)

        -- dance
        tmp = {}
        for i,v in ipairs(perf.dance_forms) do
            local form = df.dance_form.find(v.id)
            if form then
                table.insert(tmp, { dfhack.TranslateName(form.name, true), { 3, v.id }, v.rating })
            end
        end
        table.insert(performance_skills, tmp)
    end

    return { common_skills, performance_skills }
end

--luacheck: in=number
function unit_get_health(unitid)
    local unit = df.unit.find(unitid)
    if not unit then
        error('no unit '..tostring(unitid))
    end

    if not have_noble('CHIEF_MEDICAL_DWARF') then
        return { false }
    end

    local unitws = df.viewscreen_unitst:new()
    unitws.unit = unit
    gui.simulateInput(unitws, K'UNITVIEW_HEALTH')
    df.delete(unitws)

    local ws = dfhack.gui.getCurViewscreen() --as:df.viewscreen_layer_unit_healthst
    if ws._type ~= df.viewscreen_layer_unit_healthst then
        error('can not switch to health screen')
    end

    local ret = {}

    local page_names = { 'Status', 'Wounds', 'Treatment', 'History' }

    for j=0,3 do
        local text = ''

        for i,v in ipairs(ws.text[j]) do
            local line = dfhack.df2utf(v.value)
            if j == 1 and line == '---' then
                text = text .. '[P]'
            else
                if j == 1 and line:sub(1,1) == ' ' then
                    line = '\t' .. line:sub(2)
                elseif j == 3 then
                    if line:find('^%d') then
                        text = text .. '[P]'
                    else
                        line = line:gsub('^%s+-', '\t')
                    end
                end
                text = text .. '[B][C:' .. ws.text_fg[j][i] .. ':' .. ws.text_bg[j][i] .. ':' .. ws.text_bold[j][i] .. ']' .. line
            end
        end

        table.insert(ret, { page_names[j+1], text })
    end

    ws.breakdown_level = df.interface_breakdown_types.STOPSCREEN

    return { true, ret }
end

--luacheck: in=number,string,string
function unit_customize(unitid, nickname, profname)
    local unit = df.unit.find(unitid)
    if not unit then
        error('no unit '..tostring(unitid))
    end

    if nickname ~= nil then
        dfhack.units.setNickname(unit, nickname)
    end    

    if profname ~= nil then
        unit.custom_profession = profname
    end        

    return true
end

function unit_assigned_status(unit, bld)
    local x,y,z = dfhack.units.getPosition(unit)

    -- For caged and assigned to a zone animals game displays their assigned flag, not caged
    --todo: reverse because we don't want to find cage first, but this should be done properly
    for i,ref in ripairs(unit.general_refs) do
        local rtype = ref:getType()

        if rtype == df.general_ref_type.BUILDING_CIVZONE_ASSIGNED then
            local bld = ref:getBuilding() --as:df.building_civzonest
            local in_building = z == bld.z and x >= bld.x1 and x <= bld.x2 and y >= bld.y1 and y <= bld.y2
            local bit = bld.zone_flags.pit_pond and 2 or 1
            return bit32.lshift(1, bit) + (in_building and 1 or 0)
        end

        if rtype == df.general_ref_type.BUILDING_CHAIN then
            local bld = ref:getBuilding() --as:df.building_chainst
            local in_building = z == bld.z and x >= bld.room.x and x <= bld.room.x+bld.room.width and y >= bld.room.y and y <= bld.room.y+bld.room.height
            return bit32.lshift(1, 4) + (in_building and 1 or 0)
        end

        if unit.flags1.caged then
            return bit32.lshift(1, 3) + 1
        end
    end

    return 0
end

--luacheck: in=number
function unit_get_assigned_animals(unitid)
    local ret = {}

    for i,unit in ipairs(df.global.world.units.active) do
        if unit.civ_id == df.global.ui.civ_id and unit.flags1.tame and not C_unit_dead(unit) and not unit.flags1.forest then
            local work = (unit.profession == df.profession.TRAINED_WAR or unit.profession == df.profession.TRAINED_HUNTER)

            if work and unit.relationship_ids[df.unit_relationship_type.Pet] == unitid then
                local name = unit_fulltitle(unit)

                table.insert(ret, { name, unit.id, unit.sex })
            end
        end
    end

    return ret
end

--luacheck: in=number
function unit_get_assign_animal_choices(unitid)
    local ret = {}

    for i,unit in ipairs(df.global.world.units.active) do
        if unit.civ_id == df.global.ui.civ_id and unit.flags1.tame and not C_unit_dead(unit) and not unit.flags1.forest then
            local work = (unit.profession == df.profession.TRAINED_WAR or unit.profession == df.profession.TRAINED_HUNTER)

            if work and unit.relationship_ids[df.unit_relationship_type.Pet] == -1 then
                local name = unit_fulltitle(unit)

                table.insert(ret, { name, unit.id, unit.sex })
            end
        end
    end

    return ret
end

--luacheck: in=number,number[]
function unit_assign_animals(unitid, animalids)
    local unit = df.unit.find(unitid)
    if not unit then
        error('no unit '..tostring(unitid))
    end

    for i,v in ipairs(animalids) do
        local animal = df.unit.find(v)

        if animal then
            animal.relationship_ids[df.unit_relationship_type.Pet] = unit.id
        end
    end
end

--luacheck: in=number
function unit_get_kills(unitid)
local unit = df.unit.find(unitid)
    if not unit then
        error('no unit '..tostring(unitid))
    end
    
    --todo: use histfig.info.kills instead ?

    local unitws = df.viewscreen_unitst:new()
    unitws.unit = unit
    unitws.anon_1 = 1
    gui.simulateInput(unitws, K'UNITVIEW_KILLS')
    df.delete(unitws)

    local ws = dfhack.gui.getCurViewscreen() --as:df.viewscreen_textviewerst
    if ws._type ~= df.viewscreen_textviewerst then
        error('can not switch to kills screen')
    end
    ws.breakdown_level = df.interface_breakdown_types.STOPSCREEN

    local text = ''
    
    for i,v in ipairs(ws.src_text) do
        if #v.value > 0 then
            text = text .. dfhack.df2utf(v.value) .. ' '
        end
    end

    text = text:gsub('  ', ' ')

    return { text }
end

-- if screen_main()._type == df.viewscreen_dwarfmodest then
--     print(pcall(function() return json:encode(units_list_dwarves()) end))
-- end

-- print(pcall(function() return json:encode(unit_jobtitle(df.unit.find(655))) end))
