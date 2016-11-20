function have_noble(code)
    local pos_id = -1

    for i,v in ipairs(df.global.ui.main.fortress_entity.positions.own) do
        if v.code == code then
            pos_id = v.id
            break
        end
    end

    if pos_id ~= -1 then
        for i,v in ipairs(df.global.ui.main.fortress_entity.positions.assignments) do
            if v.position_id == pos_id then
                if v.histfig ~= -1 then
                    return true
                end
            end
        end
    end

    return false
end

function find_noble(code)
    local assid = nil
    local k = code:find(',')
    if k then
        assid = tonumber(code:sub(k+1))
        code = code:sub(1, k-1)
    end

    local pos = find_position(code)
    if not pos then
        return nil
    end

    local ass = nil

    for i,v in ipairs(df.global.ui.main.fortress_entity.positions.assignments) do
        if v.position_id == pos.id and (not assid or assid == v.id) then
            ass = v
            break
        end
    end

    if not ass then
        local civ = df.historical_entity.find(df.global.ui.civ_id)
        for i,v in ipairs(civ.positions.assignments) do
            if v.position_id == pos.id and (not assid or assid == v.id) then
                ass = v
                break
            end
        end
    end

    if ass then
        if ass.histfig ~= -1 then
            local hf = df.historical_figure.find(ass.histfig)
            if hf.unit_id ~= -1 then
                return df.unit.find(hf.unit_id)
            end
        end
    end        

    return nil
end

function find_position(code)
    for i,v in ipairs(df.global.ui.main.fortress_entity.positions.own) do
        if v.code == code then
            return v
        end
    end

    local civ = df.historical_entity.find(df.global.ui.civ_id)
    for i,v in ipairs(civ.positions.own) do
        if v.code == code then
            return v
        end
    end

    return nil    
end

function have_broker_appraisal()
    local broker = find_noble('BROKER')

    if not broker then
        return false
    end

    for i,v in ipairs(broker.status.current_soul.skills) do
        if v.id == df.job_skill.APPRAISAL then
            return true
        end
    end

    return false
end

room_type_table = { --as:{qidx:number,no:string}[]
    [df.building_bedst] = { qidx = 2, no='No Bedroom' },
    [df.building_tablest] = { qidx = 3, no='No Dining Room'},
    [df.building_chairst] = { qidx = 4, no='No Office' },
    [df.building_coffinst] = { qidx = 5, no='No Tomb' },
}

room_quality_table = {
    { 1, 'Meager Quarters', 'Meager Dining Room', 'Meager Office', 'Grave' },
    { 100, 'Modest Quarters', 'Modest Dining Room', 'Modest Office', "Servant's Burial Chamber" },
    { 250, 'Quarters', 'Dining Room', 'Office', 'Burial Chamber' },
    { 500, 'Decent Quarters', 'Decent Dining Room', 'Decent Office', 'Tomb' },
    { 1000, 'Fine Quarters', 'Fine Dining Room', 'Splendid Office', 'Fine Tomb' },
    { 1500, 'Great Bedroom', 'Great Dining Room', 'Throne Room', 'Mausoleum' },
    { 2500, 'Grand Bedroom', 'Grand Dining Room', 'Opulent Throne Room', 'Grand Mausoleum' },
    { 10000, 'Royal Bedroom', 'Royal Dining Room', 'Royal Throne Room', 'Royal Mausoleum' }
}

local function find_owned_room(unit, t, req)
    local info = room_type_table[t]

    local maxq = 0

    for i,bld in ipairs(unit.owned_buildings) do
        if bld._type == t then
            if info and bld.is_room then
                local quality = bld:getRoomValue(unit)
                if quality > maxq then
                    maxq = quality
                end
            end
        end
    end

    for i,v in ripairs_tbl(room_quality_table) do
        if maxq >= v[1] then
            return v[info.qidx], maxq
        end
    end

    return req and info.no or nil, 0
end

local function count_owned_buildings(unit, t)
    local cnt = 0
    for i,bld in ipairs(unit.owned_buildings) do
        for i,bld2 in ipairs(bld.children) do
            if bld2._type == t then
                cnt = cnt + 1
            end
        end
    end

    return cnt
end

local function noble_unit_reqs_level(unit)
    local ownsq = {}
    local b, c, q

    b,q = find_owned_room(unit, df.building_chairst, true)
    table.insert(ownsq, q)

    b,q = find_owned_room(unit, df.building_bedst, true)
    table.insert(ownsq, q)

    b,q = find_owned_room(unit, df.building_tablest, true)
    table.insert(ownsq, q)

    b,q = find_owned_room(unit, df.building_coffinst, true)
    table.insert(ownsq, q)

    c = count_owned_buildings(unit, df.building_boxst)
    table.insert(ownsq, c)

    c = count_owned_buildings(unit, df.building_cabinetst)
    table.insert(ownsq, c)

    c = count_owned_buildings(unit, df.building_weaponrackst)
    table.insert(ownsq, c)

    c = count_owned_buildings(unit, df.building_armorstandst)
    table.insert(ownsq, c)


    local reqsq = { 0, 0, 0, 0, 0, 0, 0, 0}

    local function process_pos(pos, reqsq)
        if pos.required_office > reqsq[1] then
            reqsq[1] = pos.required_office
        end

        if pos.required_bedroom > reqsq[2] then
            reqsq[2] = pos.required_bedroom
        end

        if pos.required_dining > reqsq[3] then
            reqsq[3] = pos.required_dining
        end

        if pos.required_tomb > reqsq[4] then
            reqsq[4] = pos.required_tomb
        end     

        if pos.required_boxes > reqsq[5] then
            reqsq[5] = pos.required_boxes
        end
        if pos.required_cabinets > reqsq[6] then
            reqsq[6] = pos.required_cabinets
        end
        if pos.required_racks > reqsq[7] then
            reqsq[7] = pos.required_racks
        end
        if pos.required_stands > reqsq[8] then
            reqsq[8] = pos.required_stands
        end        
    end

    for i,v in ipairs(df.global.ui.main.fortress_entity.positions.assignments) do
        if v.histfig == unit.hist_figure_id then
            for j,pos in ipairs(df.global.ui.main.fortress_entity.positions.own) do
                if pos.id == v.position_id then
                    process_pos(pos, reqsq)
                end
            end
        end
    end

    local civ = df.historical_entity.find(df.global.ui.civ_id)
    for i,v in ipairs(civ.positions.assignments) do
        if v.histfig == unit.hist_figure_id then
            for j,pos in ipairs(civ.positions.own) do
                if pos.id == v.position_id then
                    process_pos(pos, reqsq)
                end
            end
        end
    end

    local level = 0
    for i,v in ipairs(reqsq) do
        if v > 0 then
            if ownsq[i] == 0 then
                return 2
            elseif ownsq[i] < v then
                level = 1
            end
        end
    end    

    return level
end

--luacheck: in=
function nobles_get_positions()
    return execute_with_nobles_screen(true, function(ws)
        local ret = {}

        for i,info in ipairs(ws.info) do
            local unit = info.unit
            local unitname = unit and unitname(info.unit) or mp.NIL
            local unitid = unit and info.unit.id or -1

            --todo: properly set can_replace
            local ap = info.position.appointed_by_civ
            local can_replace = info.group == df.global.ui.main.fortress_entity.id and (#ap == 0 or ap[#ap-1] == df.global.ui.main.fortress_entity.id)
            
            local reqs_level = 0
            local has_demands = false
            local has_mandates = false

            if unit then
                reqs_level = noble_unit_reqs_level(unit)

                has_demands = #unit.status.demands > 0
            
                for i,v in ipairs(df.global.world.mandates) do
                    if v.unit.id == unitid then
                        has_mandates = true
                        break
                    end
                end
            end

            local flags = packbits(can_replace, has_demands, has_mandates)
            local code = info.position.code

            --xxx: it's a temporary (?) hack to support positions with multiple assignments
            if info.position.number == -1 then
                code = code .. ',' .. tostring(info.assignment and info.assignment.id or -1)
            end

            table.insert(ret, { dfhack.df2utf(info.position.name[0]):utf8capitalize(), code, unitname, unitid, flags, reqs_level })
        end

        local allmandates = noble_get_mandates()
        local alldemands = noble_get_demands()

        local becoming_capital
        gui.simulateInput(ws, K'NOBLELIST_CAPITAL')
        local cws = dfhack.gui.getCurViewscreen() --as:df.viewscreen_noblest
        if cws._type == df.viewscreen_noblest then
            cws.breakdown_level = df.interface_breakdown_types.STOPSCREEN
            becoming_capital = { true,
                df.global.ui.becoming_capital.desired_architecture, df.global.ui.tasks.wealth.architecture,
                df.global.ui.becoming_capital.desired_offerings, cws.become_capital_offerings}
        else
            becoming_capital = { false, 0,0,0,0 }
        end

        return { ret, df.global.ui.bookkeeper_settings, alldemands, allmandates, becoming_capital }
    end)
end

--luacheck: in=string
function nobles_get_candidates(code)
    return execute_with_nobles_screen(true, function(ws)
        local assid = nil
        local k = code:find(',')
        if k then
            assid = tonumber(code:sub(k+1))
            code = code:sub(1, k-1)
        end

        local posidx = -1
        for i,info in ipairs(ws.info) do
            if info.position.code == code then
                if not assid or assid == (info.assignment and info.assignment.id or -1) then
                    posidx = i
                    break
                end
            end
        end

        if posidx == -1 then
            error('no position '..tostring(code)..','..tostring(assid))
        end    

        ws.layer_objects[0]:setListCursor(posidx)
        gui.simulateInput(ws, K'NOBLELIST_REPLACE')

        local ret = {}
        for i,c in ipairs(ws.candidates) do
            local unit = c.unit
            local cname = unit and unitname(unit) or 'Leave Vacant'
            local cprof = unit and dfhack.units.getProfessionName(unit) or ''
            table.insert(ret, { cname, unit and unit.id or -1, capitalize(cprof) })
        end

        return ret
    end)
end

--todo: make this accept unit id
--luacheck: in=string,number
function nobles_replace(code, candidx)
    return execute_with_nobles_screen(true, function(ws)
        local assid = nil
        local k = code:find(',')
        if k then
            assid = tonumber(code:sub(k+1))
            code = code:sub(1, k-1)
        end

        local posidx = -1
        for i,info in ipairs(ws.info) do
            if info.position.code == code then
                if not assid or assid == (info.assignment and info.assignment.id or -1) then
                    posidx = i
                    break
                end
            end
        end

        if posidx == -1 then
            error('no position '..tostring(code)..','..tostring(assid))
        end    

        ws.layer_objects[0]:setListCursor(posidx)
        gui.simulateInput(ws, K'NOBLELIST_REPLACE')

        ws.layer_objects[1]:setListCursor(candidx)
        gui.simulateInput(ws, K'SELECT')
    end)
end

--luacheck: in=number
function bookkeeper_set_precision(precision)
    df.global.ui.bookkeeper_settings = precision
end

--luacheck: in=string,number
function noble_get_reqs(code, unitid)
    local unit = unitid and unitid ~= -1 and df.unit.find(unitid) or find_noble(code)
    if not unit then
        error('no unit '..tostring(code)..' '..tostring(unitid))
    end

    local owns = {}
    local ownsq = {}
    local b, c, q

    b,q = find_owned_room(unit, df.building_chairst, true)
    table.insert(owns, b) ; table.insert(ownsq, q)

    b,q = find_owned_room(unit, df.building_bedst, true)
    table.insert(owns, b) ; table.insert(ownsq, q)

    b,q = find_owned_room(unit, df.building_tablest, true)
    table.insert(owns, b) ; table.insert(ownsq, q)

    b,q = find_owned_room(unit, df.building_coffinst, true)
    table.insert(owns, b) ; table.insert(ownsq, q)


    c = count_owned_buildings(unit, df.building_boxst)
    table.insert(owns, c == 0 and 'No Chests' or (c .. (c > 1 and ' Chests' or ' Chest')))
    table.insert(ownsq, c)

    c = count_owned_buildings(unit, df.building_cabinetst)
    table.insert(owns, c == 0 and 'No Cabinets' or (c .. (c > 1 and ' Cabinets' or ' Cabinet')))
    table.insert(ownsq, c)

    c = count_owned_buildings(unit, df.building_weaponrackst)
    table.insert(owns, c == 0 and 'No Weapon Racks' or (c .. (c > 1 and ' Weapon Racks' or ' Weapon Rack')))
    table.insert(ownsq, c)

    c = count_owned_buildings(unit, df.building_armorstandst)
    table.insert(owns, c == 0 and 'No Armor Stands' or (c .. (c > 1 and ' Armor Stands' or ' Armor Stand')))
    table.insert(ownsq, c)

    local reqsq = { 0, 0, 0, 0, 0, 0, 0, 0}
    local reqs = { '', '', '', '', '', '', '', ''}

    local function process_pos(pos, reqsq, reqs)
        if pos.required_office > reqsq[1] then
            for i,v in ripairs_tbl(room_quality_table) do
                if pos.required_office >= v[1] then
                    reqs[1] = v[4]
                    break
                end
            end
            reqsq[1] = pos.required_office
        end

        if pos.required_bedroom > reqsq[2] then
            for i,v in ripairs_tbl(room_quality_table) do
                if pos.required_bedroom >= v[1] then
                    reqs[2] = v[2]
                    break
                end
            end
            reqsq[2] = pos.required_bedroom
        end

        if pos.required_dining > reqsq[3] then
            for i,v in ripairs_tbl(room_quality_table) do
                if pos.required_dining >= v[1] then
                    reqs[3] = v[3]
                    break
                end
            end
            reqsq[3] = pos.required_dining
        end

        if pos.required_tomb > reqsq[4] then
            for i,v in ripairs_tbl(room_quality_table) do
                if pos.required_tomb >= v[1] then
                    reqs[4] = v[5]
                    break
                end
            end
            reqsq[4] = pos.required_tomb
        end     

        if pos.required_boxes > reqsq[5] then
            reqs[5] = pos.required_boxes == 1 and '1 Chest' or pos.required_boxes .. ' Chests'
            reqsq[5] = pos.required_boxes
        end
        if pos.required_cabinets > reqsq[6] then
            reqs[6] = pos.required_cabinets == 1 and '1 Cabinet' or pos.required_cabinets .. ' Cabinets'
            reqsq[6] = pos.required_cabinets
        end
        if pos.required_racks > reqsq[7] then
            reqs[7] = pos.required_racks == 1 and '1 Weapon Rack' or pos.required_racks .. ' Weapon Racks'
            reqsq[7] = pos.required_racks
        end
        if pos.required_stands > reqsq[8] then
            reqs[8] = pos.required_stands == 1 and '1 Armor Stand' or pos.required_stands .. ' Armor Stands'
            reqsq[8] = pos.required_stands
        end
    end

    for i,v in ipairs(df.global.ui.main.fortress_entity.positions.assignments) do
        if v.histfig == unit.hist_figure_id then
            for j,pos in ipairs(df.global.ui.main.fortress_entity.positions.own) do
                if pos.id == v.position_id then
                    process_pos(pos, reqsq, reqs)
                end
            end
        end
    end

    local civ = df.historical_entity.find(df.global.ui.civ_id)
    for i,v in ipairs(civ.positions.assignments) do
        if v.histfig == unit.hist_figure_id then
            for j,pos in ipairs(civ.positions.own) do
                if pos.id == v.position_id then
                    process_pos(pos, reqsq, reqs)
                end
            end
        end
    end


    local reqinfo = {}
    for i,v in ipairs(reqsq) do
        if v > 0 then
            local c
            if ownsq[i] == 0 then
                c = 12
            elseif ownsq[i] < v then
                c = 14
            else
                c = 15
            end
            table.insert(reqinfo, { owns[i], reqs[i], c })
        
        elseif ownsq[i] > 0 then
            table.insert(reqinfo, { owns[i], '', 7 })
        end
    end

    local demands = noble_get_demands(unit.id)
    local mandates = noble_get_mandates(unit.id)

    return { unitname(unit), unit.id, reqinfo, demands, mandates }
end

--luacheck: in=number
function noble_get_mandates(unitid)
    local ret = {}

    for i,v in ipairs(df.global.world.mandates) do
        if not (unitid and unitid ~= -1 and v.unit.id ~= unitid) then
            --[[local q = df.reaction_product_itemst:new()

            q.item_type = v.item_type
            q.item_subtype = v.item_subtype
            q.mat_type = v.mat_type
            q.mat_index = v.mat_index
            
            local title = utils.call_with_string(q, 'getDescription')
            q:delete()

            title = title:sub(1, title:find(' %(')-1)
            title = dfhack.df2utf(title)]]

            local title = generic_item_name(v.item_type, v.item_subtype, -1, v.mat_type, v.mat_index, false)

            table.insert(ret, { title, v.mode, unit_fulltitle(v.unit), v.unit.id, v.amount_total, v.amount_remaining })
        end
    end

    return ret
end

--luacheck: in=number
function noble_get_demands(unitid)
    local ret = {}

    local function process_demands(unit, ret)
        for i,v in ipairs(unit.status.demands) do
            local title = generic_item_name(v.item_type, v.item_subtype, -1, v.mat_type, v.mat_index, true)

            table.insert(ret, { title, v.place, unit_fulltitle(unit), unit.id })
        end
    end

    if unitid then
        local unit = df.unit.find(unitid)
        if not unit then
            error('no unit '..tostring(unitid))
        end

        process_demands(unit, ret)

    else
        for i,v in ipairs(df.global.ui.main.fortress_entity.positions.assignments) do
            if v.histfig ~= -1 then
                local hf = df.historical_figure.find(v.histfig)
                if hf.unit_id ~= -1 then
                    local unit = df.unit.find(hf.unit_id)

                    if unit then
                        process_demands(unit, ret)
                    end
                end
            end
        end

    end

    return ret
end

--print(pcall(function() return json:encode(nobles_get_positions()) end))
--print(pcall(function() return json:encode(noble_get_demands()) end))
--print(pcall(function() return json:encode(noble_get_reqs('MAYOR')) end))
--print(pcall(function() return json:encode(noble_get_reqs('CAPTAIN_OF_THE_GUARD')) end))