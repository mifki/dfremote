function find_fortress_squads()
    local eid = df.global.ui.main.fortress_entity.id

    local ret = {}
    for i,v in ipairs(df.global.world.squads.all) do
        if v.entity_id == eid then
            table.insert(ret, v)
        end
    end

    return ret
end

function squad_id2idx(id)
    local sqidx = -1
    for i,v in ipairs(find_fortress_squads()) do
        if v.id == id then
            return i - 1
        end
    end

    return -1    
end

function squad_num_soldiers(squad)
    local numsoldiers = 0
    
    for i,pos in ipairs(squad.positions) do
        if pos.occupant ~= -1 then
            numsoldiers = numsoldiers + 1
        end
    end

    return numsoldiers
end

function squad_order_title(squad)
    --todo: handle other order types
    --todo: sometimes .title needs updating somehow

    local ordertitle = ''
    
    if #squad.orders > 0 then
        local ordertype = squad.orders[0]:getType()
        if ordertype == df.squad_order_type.MOVE then
            ordertitle = 'Station'
        elseif ordertype == df.squad_order_type.KILL_LIST then
            ordertitle = squad.orders[0].title
        end
    end

    return ordertitle
end

function squads_get_list()
    local squads = {}
    local leaders = {}

    execute_with_military_screen(function(ws)
        for i,squad in ipairs(ws.squads.list) do
            if squad then
                local name = squadname(squad)
                local alert_name = alertname(df.global.ui.alerts.list[squad.cur_alert_idx])
                
                table.insert(squads, { name, squad.id, 1, alert_name, squad_order_title(squad), squad_num_soldiers(squad) })

            -- leader without a squad (or just an unassigned position)
            else
                local pos = ws.squads.leader_positions[i]
                local ass = ws.squads.leader_assignments[i]

                local posname = pos.name[0]

                local hf = df.historical_figure.find(ass.histfig)
                local unit = hf and df.unit.find(hf.unit_id)
                local uname = unit and unitname(unit) or mp.NIL

                table.insert(leaders, { posname, ass.id, 0, uname })
            end
        end
    end)

    return { squads, leaders }
end

function squads_get_info()
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        error('wrong screen')
    end

    if df.global.ui.main.mode ~= 1 then
        df.global.ui.main.mode = 0
        gui.simulateInput(ws, 'D_SQUADS')
        --return nil
    end

	-- this is to update order titles in some cases
	ws:logic()
	ws:render()    

    local squads = {}

    for i,squad in ipairs(df.global.ui.squads.list) do
    	local name = squadname(squad)

        --todo: handle other order types
    	local ordertitle = ''
    	if #squad.orders > 0 then
    		local ordertype = squad.orders[0]:getType()
    		if ordertype == df.squad_order_type.MOVE then
    			ordertitle = 'Station'
			elseif ordertype == df.squad_order_type.KILL_LIST then
    			ordertitle = squad.orders[0].title
    		end
    	end

    	local numsoldiers = 0
    	for i,pos in ipairs(squad.positions) do
    		if pos.occupant ~= -1 then
    			numsoldiers = numsoldiers + 1
    		end
    	end

    	table.insert(squads, { name, squad.id, ordertitle, squad.cur_alert_idx, numsoldiers })
    end

    local alerts = {}
    for i,alert in ipairs(df.global.ui.alerts.list) do
    	local name = alertname(alert)

    	table.insert(alerts, { name, alert.id })
    end

    return { squads, alerts }
end

--todo: support multiple squads in the following commands
function squads_cancel_order(idx)
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        return
    end

    if df.global.ui.main.mode ~= 1 then
        return
    end

    for i=0,#df.global.ui.squads.sel_squads-1 do
        df.global.ui.squads.sel_squads[i] = false
    end
    df.global.ui.squads.sel_squads[idx] = true

    gui.simulateInput(ws, 'D_SQUADS_CANCEL_ORDER')

    return true
end

function squads_order_move(idx)
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        return
    end

    if df.global.ui.main.mode ~= 1 then
        return
    end

    for i=0,#df.global.ui.squads.sel_squads-1 do
    	df.global.ui.squads.sel_squads[i] = false
    end
    df.global.ui.squads.sel_squads[idx] = true

    df.global.ui.squads.in_move_order = true

    return true
end

function squads_order_attack_list(idx)
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        return
    end

    if df.global.ui.main.mode ~= 1 then
        return
    end

    for i=0,#df.global.ui.squads.sel_squads-1 do
    	df.global.ui.squads.sel_squads[i] = false
    end
    df.global.ui.squads.sel_squads[idx] = true

    gui.simulateInput(ws, 'D_SQUADS_KILL')
    ws:logic()
    gui.simulateInput(ws, 'D_SQUADS_KILL_LIST')

    return true
end

function squads_order_attack_rect(idx)
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        return
    end

    if df.global.ui.main.mode ~= 1 then
        return
    end

    for i=0,#df.global.ui.squads.sel_squads-1 do
    	df.global.ui.squads.sel_squads[i] = false
    end
    df.global.ui.squads.sel_squads[idx] = true

    gui.simulateInput(ws, 'D_SQUADS_KILL')
    ws:logic()
    gui.simulateInput(ws, 'D_SQUADS_KILL_RECT')

    return true
end


function squads_order_attack_map(idx)
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        return
    end

    if df.global.ui.main.mode ~= 1 then
        return
    end

    for i=0,#df.global.ui.squads.sel_squads-1 do
    	df.global.ui.squads.sel_squads[i] = false
    end
    df.global.ui.squads.sel_squads[idx] = true

    gui.simulateInput(ws, 'D_SQUADS_KILL')

    return true
end


function squads_attack_list_get(idx)
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        return
    end

    if df.global.ui.main.mode ~= 1 then
        return
    end

    local squadsui = df.global.ui.squads

    if not squadsui.in_kill_list then
    	return
    end

    local ret = {}

    for i,t in ipairs(squadsui.kill_targets) do
    	local name = unit_creature_name(t)
    	table.insert(ret, { name, squadsui.sel_kill_targets[i] })
    end

    return ret
end

function squads_attack_list_confirm(idxs)
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        return
    end

    if df.global.ui.main.mode ~= 1 then
        return
    end

    local squadsui = df.global.ui.squads

    if not squadsui.in_kill_list then
    	return
    end

    for i=0,#df.global.ui.squads.sel_kill_targets-1 do
    	df.global.ui.squads.sel_kill_targets[i] = false
    end

    for i,idx in pairs(idxs) do
	    df.global.ui.squads.sel_kill_targets[idx] = true
	end

	gui.simulateInput(ws, 'SELECT')

    return true
end

function squad_set_alert(id, alertid, retain)
    local sqidx = squad_id2idx(id)
    if sqidx == -1 then
        return
    end    

    local idx = alert_id2index(alertid)
    if idx == -1 then
        return
    end

    execute_with_military_screen(function(ws)
        gui.simulateInput(ws, 'D_MILITARY_ALERTS')
        ws.layer_objects[0].cursor = idx
        ws.layer_objects[0].active = false
        ws.layer_objects[1].cursor = sqidx
        ws.layer_objects[1].active = true
        gui.simulateInput(ws, istrue(retain) and 'D_MILITARY_ALERTS_SET_RETAIN' or 'D_MILITARY_ALERTS_SET')
    end)

    return true
end

function squads_reset()
    local squadsui = df.global.ui.squads

    squadsui.in_kill_order = false
    squadsui.in_kill_list = false
    squadsui.in_kill_rect = false
    squadsui.in_select_indiv = false
    squadsui.rect_start.x = -30000 -- probably not req.
end

function squad_disband(id)
    return execute_with_military_screen(function(ws)
        local sqidx = -1
        for i,v in ipairs(ws.squads.list) do
            if v and v.id == id then
                sqidx = i
                break
            end
        end

        if sqidx == -1 then
            return
        end

        if sqidx > 0 then
            ws.layer_objects[0].cursor = sqidx-1
            gui.simulateInput(ws, 'STANDARDSCROLL_DOWN')            
        end

        gui.simulateInput(ws, 'D_MILITARY_DISBAND_SQUAD')
        return true
    end)
end

function squad_set_supplies(id, water, food)
    local squad = df.squad.find(id)
    if not squad then
        return
    end

    squad.carry_water = water
    squad.carry_food = food

    df.global.ui.equipment.update.backpack = true    
    df.global.ui.equipment.update.flask = true
end

function squad_set_name(id, name)
    local squad = df.squad.find(id)
    if not squad then
        return
    end

    squad.alias = name
end

function squad_get_info(id)
    local squad = df.squad.find(id)
    if not squad then
        return
    end

    local name = squadname(squad)
    local origname = dfhack.df2utf(dfhack.TranslateName(squad.name, true))
    local alert_name = alertname(df.global.ui.alerts.list[squad.cur_alert_idx])

    local members = {}

    for i,pos in ipairs(squad.positions) do
        if pos.occupant ~= -1 then
            local hf = df.historical_figure.find(pos.occupant)
            local unit = hf and df.unit.find(hf.unit_id)

            -- just in case
            if unit then
                table.insert(members, { unit_fulltitle(unit), unit.id, i })
            else
                table.insert(members, { '#unknown unit#', -1 })
            end
        end
    end    

    return { name, squad.id, origname, alert_name, members, squad.carry_water, squad.carry_food, squad.cur_alert_idx }    
end

function squad_remove_member(id, posidx)
    return execute_with_military_screen(function(ws)
        local sqidx = -1
        for i,v in ipairs(ws.squads.list) do
            if v and v.id == id then
                sqidx = i
                break
            end
        end

        if sqidx == -1 then
            return
        end

        if sqidx > 0 then
            ws.layer_objects[0].cursor = sqidx-1
            gui.simulateInput(ws, 'STANDARDSCROLL_DOWN')            
        end

        ws.layer_objects[0].active = false
        ws.layer_objects[1].active = true
        ws.layer_objects[1].cursor = posidx
        gui.simulateInput(ws, 'SELECT')
        return true
    end)
end

local function confirm_uniform(ws, uniformid)
    local uniidx
    if uniformid == -1 then
        uniidx = ws.layer_objects[57].num_entries - 1
    else
        uniidx = uniform_id2index(uniformid)
        if uniidx == -1 then
            return
        end
    end

    ws.layer_objects[57].cursor = uniidx
    gui.simulateInput(ws, 'SELECT')
    return true    
end

function squad_create_with_leader(assid, uniformid)
    return execute_with_military_screen(function(ws)
        if assid == -1 then
            if #ws.squads.list == 0 or (#ws.squads.list == 1 and not ws.squads.list[0]) then
                gui.simulateInput(ws, 'D_MILITARY_CREATE_SQUAD')
                return confirm_uniform(ws, uniformid)                
            end

            for i,v in ipairs(ws.squads.can_appoint) do
                if istrue(v) then
                    gui.simulateInput(ws, 'D_MILITARY_CREATE_SUB_SQUAD')
                    return confirm_uniform(ws, uniformid)
                else
                    gui.simulateInput(ws, 'STANDARDSCROLL_DOWN')            
                end
            end
        else
            for i,ass in ipairs(ws.squads.leader_assignments) do
                if ass.id == assid and not ws.squads.list[i] then
                    if i > 0 then
                        ws.layer_objects[0].cursor = i-1
                        gui.simulateInput(ws, 'STANDARDSCROLL_DOWN')            
                    end

                    gui.simulateInput(ws, 'D_MILITARY_CREATE_SQUAD')
                    return confirm_uniform(ws, uniformid)
                end
            end
        end
    end)
end

function squad_get_candidates(id)
    return execute_with_military_screen(function(ws)
        local sqidx = -1
        for i,v in ipairs(ws.squads.list) do
            if v and v.id == id then
                sqidx = i
                break
            end
        end

        if sqidx == -1 then
            return
        end

        if sqidx > 0 then
            ws.layer_objects[0].cursor = sqidx-1
            gui.simulateInput(ws, 'STANDARDSCROLL_DOWN')            
        end

        ws.layer_objects[0].active = false
        ws.layer_objects[1].active = true
        for i,v in ipairs(ws.positions.assigned) do
            if v then
                gui.simulateInput(ws, 'STANDARDSCROLL_DOWN')
            end
        end

        local ret = {}
        for i,unit in ipairs(ws.positions.candidates) do
            local name = unit_fulltitle(unit)

            --[[local skill = ws.positions.skill[ws.layer_objects[1].cursor]
            print('!!!!!!!!', skill)
            for j,v in ipairs(unit.status.current_soul.skills) do
                if v.id == skill then
                    print (v.rating)
                end
            end]]

            table.insert(ret, { name, unit.id })
        end

        return ret
    end)    
end

function squad_add_members(id, unitids)
    return execute_with_military_screen(function(ws)
        local sqidx = -1
        for i,v in ipairs(ws.squads.list) do
            if v and v.id == id then

                local numsoldiers = 0
                for j,pos in ipairs(v.positions) do
                    if pos.occupant ~= -1 then
                        numsoldiers = numsoldiers + 1
                    end
                end
                if numsoldiers >= 10 then
                    return
                end

                sqidx = i
                break
            end
        end

        if sqidx == -1 then
            return
        end

        if sqidx > 0 then
            ws.layer_objects[0].cursor = sqidx-1
            gui.simulateInput(ws, 'STANDARDSCROLL_DOWN')            
        end

        ws.layer_objects[0].active = false
        
        for i,v in ipairs(unitids) do
            ws.layer_objects[2].active = false
            ws.layer_objects[1].active = true

            for k=ws.layer_objects[1].cursor,9 do
                local w = ws.positions.assigned[k]
                if w then
                    gui.simulateInput(ws, 'STANDARDSCROLL_DOWN')            
                else
                    ws.layer_objects[1].active = false
                    ws.layer_objects[2].active = true

                    for j,unit in ipairs(ws.positions.candidates) do
                        if unit.id == v then
                            ws.layer_objects[2].cursor = j
                            gui.simulateInput(ws, 'SELECT')        
                         
                            break
                        end
                    end

                    break
                end
            end
        end

        return ret
    end)
end