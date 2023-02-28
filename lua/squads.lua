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
    local ordertitle = ''
    
    if #squad.orders > 0 then
        ordertitle = utils.call_with_string(squad.orders[0], 'getDescription')
    end

    return dfhack.df2utf(ordertitle)
end

--luacheck: in=
function squads_reset()
    local squadsui = df.global.ui.squads

    squadsui.in_move_order = false
    squadsui.in_kill_order = false
    squadsui.in_kill_list = false
    squadsui.in_kill_rect = false
    squadsui.in_select_indiv = false
    squadsui.rect_start.x = -30000 -- probably not req.
    
    -- game resets selected squads, no need to
end

--luacheck: in=number
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

--luacheck: in=
function squads_get_info()
    return execute_with_main_mode(df.ui_sidebar_mode.Default, function(ws)
        squads_reset()
        gui.simulateInput(ws, K'D_SQUADS')

    	-- this is to update order titles in some cases
    	ws:logic()
    	ws:render()    
    
        local squads = {}
    
        for i,squad in ipairs(df.global.ui.squads.list) do
        	local name = squadname(squad)
        	local ordertitle = squad_order_title(squad)
    
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
    end)
end

function squads_cancel_order(id)
    local sqidx = squad_id2idx(id)
    if sqidx == -1 then
        error('no squad '..tostring(id))
    end    

    return execute_with_main_mode(df.ui_sidebar_mode.Default, function(ws)
        squads_reset()
        gui.simulateInput(ws, K'D_SQUADS')

        df.global.ui.squads.sel_squads[sqidx] = true
    
        gui.simulateInput(ws, K'D_SQUADS_CANCEL_ORDER')

        return true
    end)
end

--luacheck: in=number
function squads_order_move(id)
    local sqidx = squad_id2idx(id)
    if sqidx == -1 then
        error('no squad '..tostring(id))
    end    

    return execute_with_main_mode(df.ui_sidebar_mode.Default, function(ws)
        squads_reset()
        gui.simulateInput(ws, K'D_SQUADS')

        df.global.ui.squads.sel_squads[sqidx] = true

        gui.simulateInput(ws, K'D_SQUADS_MOVE')
    
        return true
    end, true)
end

--luacheck: in=number
function squads_attack_list_get(id)
    local function _process()
        local ret = {}
    
        for i,unit in ipairs(df.global.ui.squads.kill_targets) do
        	local name = unit_fulltitle(unit)
        	table.insert(ret, { name, unit.id })
        end
    
        return ret
    end
    
    -- already in target selection after attack in region mode
    if df.global.ui.squads.in_kill_list and df.global.ui.squads.in_kill_rect then
    	return _process()
    end
    
    local sqidx = squad_id2idx(id)
    if sqidx == -1 then
        error('no squad '..tostring(id))
    end    

    return execute_with_main_mode(df.ui_sidebar_mode.Default, function(ws)
        squads_reset()
        gui.simulateInput(ws, K'D_SQUADS')

        df.global.ui.squads.sel_squads[sqidx] = true
    
        gui.simulateInput(ws, K'D_SQUADS_KILL')
        ws:logic()
        gui.simulateInput(ws, K'D_SQUADS_KILL_LIST')

        return _process()
    end)
end

--luacheck: in=number,number[]
function squads_attack_list_confirm(id, targetids)
    local function _process(ws)
        local targets = {}
        for i,v in ipairs(targetids) do
            targets[v] = true
        end
    
        for i,unit in ipairs(df.global.ui.squads.kill_targets) do
            df.global.ui.squads.sel_kill_targets[i] = targets[unit.id] and true or false
        end

    	gui.simulateInput(ws, K'SELECT')
    end
    
    -- already in target selection after attack in region mode
    if df.global.ui.squads.in_kill_list and df.global.ui.squads.in_kill_rect then
    	_process(screen_main())
    	df.global.ui.main.mode = df.ui_sidebar_mode.Default
    	
    	return true
    end
    
    local sqidx = squad_id2idx(id)
    if sqidx == -1 then
        error('no squad '..tostring(id))
    end    

    return execute_with_main_mode(df.ui_sidebar_mode.Default, function(ws)
        gui.simulateInput(ws, K'D_SQUADS')

        df.global.ui.squads.sel_squads[sqidx] = true
    
        gui.simulateInput(ws, K'D_SQUADS_KILL')
        ws:logic()
        gui.simulateInput(ws, K'D_SQUADS_KILL_LIST')

        _process(ws)
    
        return true
    end)
end

--luacheck: in=number
function squads_order_attack_rect(id)
    local sqidx = squad_id2idx(id)
    if sqidx == -1 then
        error('no squad '..tostring(id))
    end    

    return execute_with_main_mode(df.ui_sidebar_mode.Default, function(ws)
        squads_reset()
        gui.simulateInput(ws, K'D_SQUADS')
    
        df.global.ui.squads.sel_squads[sqidx] = true
    
        gui.simulateInput(ws, K'D_SQUADS_KILL')
        ws:logic()
        gui.simulateInput(ws, K'D_SQUADS_KILL_RECT')

        return true
    end, true)
end

--luacheck: in=number
function squads_order_attack_map(id)
    local sqidx = squad_id2idx(id)
    if sqidx == -1 then
        error('no squad '..tostring(id))
    end    

    return execute_with_main_mode(df.ui_sidebar_mode.Default, function(ws)
        squads_reset()
        gui.simulateInput(ws, K'D_SQUADS')

        df.global.ui.squads.sel_squads[sqidx] = true

        gui.simulateInput(ws, K'D_SQUADS_KILL')

        return true
    end, true)
end

--luacheck: in=number,number,bool
function squad_set_alert(id, alertid, retain)
    local sqidx = squad_id2idx(id)
    if sqidx == -1 then
        error('no squad '..tostring(id))
    end    

    local idx = alert_id2index(alertid)
    if idx == -1 then
        error('no alert '..tostring(alertid))
    end

    execute_with_military_screen(function(ws)
        gui.simulateInput(ws, K'D_MILITARY_ALERTS')
        ws.layer_objects[0].cursor = idx   --hint:df.layer_object_listst
        ws.layer_objects[0].active = false
        ws.layer_objects[1].cursor = sqidx --hint:df.layer_object_listst
        ws.layer_objects[1].active = true
        gui.simulateInput(ws, istrue(retain) and K'D_MILITARY_ALERTS_SET_RETAIN' or K'D_MILITARY_ALERTS_SET')
    end)

    return true
end

--luacheck: in=number
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
            ws.layer_objects[0].cursor = sqidx-1 --hint:df.layer_object_listst
            gui.simulateInput(ws, K'STANDARDSCROLL_DOWN')            
        end

        gui.simulateInput(ws, K'D_MILITARY_DISBAND_SQUAD')
        return true
    end)
end

--luacheck: in=number,number,number
function squad_set_supplies(id, water, food)
    local squad = df.squad.find(id)
    if not squad then
        error('no squad '..tostring(id))
    end

    squad.carry_water = water
    squad.carry_food = food

    df.global.ui.equipment.update.backpack = true    
    df.global.ui.equipment.update.flask = true

    return true
end

--luacheck: in=number,string
function squad_set_name(id, name)
    local squad = df.squad.find(id)
    if not squad then
        error('no squad '..tostring(id))
    end

    squad.alias = name

    return true
end

--luacheck: in=number
function squad_get_info(id)
    local squad = df.squad.find(id)
    if not squad then
        error('no squad '..tostring(id))
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

--luacheck: in=number,number
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
            ws.layer_objects[0].cursor = sqidx-1 --hint:df.layer_object_listst
            gui.simulateInput(ws, K'STANDARDSCROLL_DOWN')            
        end

        ws.layer_objects[0].active = false
        ws.layer_objects[1].active = true
        ws.layer_objects[1].cursor = posidx --hint:df.layer_object_listst
        gui.simulateInput(ws, K'SELECT')
        return true
    end)
end

local function confirm_uniform(ws, uniformid)
    local uniidx
    if uniformid == -1 then
        uniidx = ws.layer_objects[57].num_entries - 1 --hint:df.layer_object_listst
    else
        uniidx = uniform_id2index(uniformid)
        if uniidx == -1 then
            return
        end
    end

    ws.layer_objects[57].cursor = uniidx --hint:df.layer_object_listst
    gui.simulateInput(ws, K'SELECT')

    return true    
end

--luacheck: in=number,number
function squad_create_with_leader(assid, uniformid)
    return execute_with_military_screen(function(ws)
        if assid == -1 then
            if #ws.squads.list == 0 or ws.num_squads < #ws.squads.list then
                for i,v in ipairs(ws.squads.list) do
                    if not v then
                        gui.simulateInput(ws, K'D_MILITARY_CREATE_SQUAD')
                        return confirm_uniform(ws, uniformid)                
                    end

                    gui.simulateInput(ws, K'STANDARDSCROLL_DOWN')
                end

                -- this should not be reached, but if that happened, scrolling down will reset back to the first item
                gui.simulateInput(ws, K'STANDARDSCROLL_DOWN')
            end

            for i,v in ipairs(ws.squads.can_appoint) do
                if istrue(v) then
                    gui.simulateInput(ws, K'D_MILITARY_CREATE_SUB_SQUAD')
                    return confirm_uniform(ws, uniformid)
                end

                gui.simulateInput(ws, K'STANDARDSCROLL_DOWN')            
            end
        else
            for i,ass in ipairs(ws.squads.leader_assignments) do
                if ass.id == assid then
                    gui.simulateInput(ws, K'D_MILITARY_CREATE_SQUAD')
                    return confirm_uniform(ws, uniformid)
                end

                gui.simulateInput(ws, K'STANDARDSCROLL_DOWN')            
            end
        end
    end)
end

--luacheck: in=number
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
            ws.layer_objects[0].cursor = sqidx-1 --hint:df.layer_object_listst
            gui.simulateInput(ws, K'STANDARDSCROLL_DOWN')            
        end

        ws.layer_objects[0].active = false
        ws.layer_objects[1].active = true
        for i,v in ipairs(ws.positions.assigned) do
            if v then
                gui.simulateInput(ws, K'STANDARDSCROLL_DOWN')
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

--luacheck: in=number,number[]
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
            ws.layer_objects[0].cursor = sqidx-1 --hint:df.layer_object_listst
            gui.simulateInput(ws, K'STANDARDSCROLL_DOWN')            
        end

        ws.layer_objects[0].active = false
        
        for i,v in ipairs(unitids) do
            ws.layer_objects[2].active = false
            ws.layer_objects[1].active = true

            for k=ws.layer_objects[1].cursor,9 do
                local w = ws.positions.assigned[k]
                if w then
                    gui.simulateInput(ws, K'STANDARDSCROLL_DOWN')            
                else
                    ws.layer_objects[1].active = false
                    ws.layer_objects[2].active = true

                    for j,unit in ipairs(ws.positions.candidates) do
                        if unit.id == v then
                            ws.layer_objects[2].cursor = j --hint:df.layer_object_listst
                            gui.simulateInput(ws, K'SELECT')        
                         
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