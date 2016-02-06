function alert_id2index(id)
    for i,v in ipairs(df.global.ui.alerts.list) do
        if v.id == id then
            return i
        end
    end

    return -1
end

function alert_find_by_id(id)
    for i,v in ipairs(df.global.ui.alerts.list) do
        if v.id == id then
            return v
        end
    end

    return nil
end

function alerts_get_list()
    local list = {}

    for i,v in ipairs(df.global.ui.alerts.list) do
        local squads = find_fortress_squads()
        local num_alert_squads = 0
        for j,w in ipairs(squads) do
            if w.cur_alert_idx == i then
                num_alert_squads = num_alert_squads + 1
            end
        end

        --todo: don't need v.name here ?
        table.insert(list, { alertname(v), v.id, v.name, num_alert_squads, #v.burrows })
    end

    return { list, df.global.ui.alerts.civ_alert_idx }
end

function alerts_set_civ(id)
    local idx = alert_id2index(id)
    if idx == -1 then
        return
    end

    df.global.ui.alerts.civ_alert_idx = idx

    return true
end

function alerts_add()
    execute_with_military_screen(function(ws)
        gui.simulateInput(ws, 'D_MILITARY_ALERTS')
        gui.simulateInput(ws, 'D_MILITARY_ALERTS_ADD')
    end)
end

function alert_delete(id)
    -- disallow to delete Inactive alert
    if id == 0 then
        return
    end
    
    local idx = alert_id2index(id)
    if idx == -1 then
        return
    end

    execute_with_military_screen(function(ws)
        gui.simulateInput(ws, 'D_MILITARY_ALERTS')
        ws.layer_objects[0].cursor = idx
        gui.simulateInput(ws, 'D_MILITARY_ALERTS_DELETE')
        gui.simulateInput(ws, 'MENU_CONFIRM')
    end)

    return true
end

function alert_get_info(id)
    local idx = alert_id2index(id)
    if idx == -1 then
        return
    end

    local alert = df.global.ui.alerts.list[idx]

    local squads = {}
    for i,squad in ipairs(find_fortress_squads()) do
        local name = squadname(squad)
        local enabled = squad.cur_alert_idx == idx

        table.insert(squads, { name, squad.id, enabled })
    end
    
    local burrows = {}
    for i,burrow in ipairs(df.global.ui.burrows.list) do
        local name = burrowname(burrow)
        local enabled = utils.binsearch(alert.burrows, burrow.id) ~= nil

        table.insert(burrows, { name, burrow.id, enabled })
    end    

    return { alertname(alert), alert.id, alert.name, squads, burrows }
end

function alert_set_burrow(id, burrowid, enabled)
    local alert = alert_find_by_id(id)
    if not alert then
        error('no alert '..tostring(id))
    end

    if istrue(enabled) then
        utils.insert_sorted(alert.burrows, burrowid)
    else
        utils.erase_sorted(alert.burrows, burrowid)
    end    
end

function alert_set_name(id, name)
    local alert = alert_find_by_id(id)
    if not alert then
        error('no alert '..tostring(id))
    end

    alert.name = name

    return true
end
