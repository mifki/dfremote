function depot_can_trade(bld)
    for i,v in ipairs(df.global.ui.caravans) do
        if v.trade_state == 2 and v.time_remaining > 0 then
            for i,job in ipairs(bld.jobs) do
                if job.job_type == df.job_type.TradeAtDepot then
                    local worker_ref = dfhack.job.getGeneralRef(job, df.general_ref_type.UNIT_WORKER) --as:df.general_ref_unit_workerst
                    local worker = worker_ref and df.unit.find(worker_ref.unit_id)
                    return worker
                        and worker.pos.z == bld.z
                        and worker.pos.x >= bld.x1 and worker.pos.x <= bld.x2
                        and worker.pos.y >= bld.y1 and worker.pos.y <= bld.y2
                        or false
                end
            end
        
        break
        end
    end

    return false
end

function depot_can_movegoods()
    for i,v in ipairs(df.global.ui.caravans) do
        if v.trade_state == 1 or (v.trade_state == 2 and v.time_remaining > 0) then
            return true
        end
    end
    
    return false
end

--luacheck: in=
function depot_movegoods_get()
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        error('wrong screen '..tostring(ws._type))
    end

    if df.global.ui.main.mode ~= 17 or df.global.world.selected_building == nil then
        error('no selected building')
    end

    local bld = df.global.world.selected_building
    if bld:getType() ~= df.building_type.TradeDepot then
        error('not a depot')
    end

    gui.simulateInput(ws, K'BUILDJOB_DEPOT_BRING')

    local movegoodsws = dfhack.gui.getCurViewscreen() --as:df.viewscreen_layer_assigntradest
    if movegoodsws._type ~= df.viewscreen_layer_assigntradest then
        error('can not switch to move goods screen')
    end

    gui.simulateInput(movegoodsws, K'ASSIGNTRADE_SORT')

    local ret = {}
    
    for i,info in ipairs(movegoodsws.info) do
        local title = itemname(info.item, 0, true)
        table.insert(ret, { title, info.distance, info.status })
    end

    return ret
end

--luacheck: in=
function depot_movegoods_get2()
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        error('wrong screen '..tostring(ws._type))
    end

    if df.global.ui.main.mode ~= 17 or df.global.world.selected_building == nil then
        error('no selected building')
    end

    local bld = df.global.world.selected_building
    if bld:getType() ~= df.building_type.TradeDepot then
        error('not a depot')
    end

    gui.simulateInput(ws, K'BUILDJOB_DEPOT_BRING')

    local movegoodsws = dfhack.gui.getCurViewscreen() --as:df.viewscreen_layer_assigntradest
    if movegoodsws._type ~= df.viewscreen_layer_assigntradest then
        error('can not switch to move goods screen')
    end

    gui.simulateInput(movegoodsws, K'ASSIGNTRADE_SORT')

    local ret = {}
    
    for i,info in ipairs(movegoodsws.info) do
        local title = itemname(info.item, 0, true)
        table.insert(ret, { title, info.item.id, info.status, info.status }) -- .distance
    end

    return ret
end

--luacheck: in=number,number
function depot_movegoods_set(idx, status)
    local ws = dfhack.gui.getCurViewscreen() --as:df.viewscreen_layer_assigntradest

    if ws._type ~= df.viewscreen_layer_assigntradest then
        return
    end
        
    if type(status) == 'boolean' then
        status = status and 1 or 0
    end

    ws.info[idx].status = status
end

function read_trader_reply()
    local reply = ''
    local mood = ''
    local start = false

    for j=1,df.global.gps.dimy-3 do
        local empty = true

        for i=2,df.global.gps.dimx-2 do
            local char = df.global.gps.screen[(i*df.global.gps.dimy+j)*4]

            if not start then
                if string.char(char) == ':' then
                    start = true
                end
            else
                if char ~= 0 then
                    if char ~= 32 then
                        if empty and #reply > 0 and reply:byte(#reply) ~= 32 then
                            reply = reply .. ' '
                        end
                        empty = false
                    end

                    if not empty and not (char == 32 and reply:byte(#reply) == 32) then
                        reply = reply .. string.char(char)
                    end
                end
            end
        end

        if empty and #reply > 0 then
            for j=j+1,df.global.gps.dimy-3 do
                local ch = df.global.gps.screen[(2*df.global.gps.dimy+j)*4]
                
                if ch ~= 0 then
                    if ch == 219 then
                        break
                    end

                    for i=2,df.global.gps.dimx-2 do
                        local char = df.global.gps.screen[(i*df.global.gps.dimy+j)*4]

                        if not (char == 32 and mood:byte(#mood) == 32) then
                            mood = mood .. string.char(char)
                        end
                    end

                    break
                end
            end

            break
        end
    end    

    return dfhack.df2utf(reply), dfhack.df2utf(mood)
end

-- exact copy of Item::getValue() but also accepts caravan_state, race and quantity
function item_value_for_caravan(item, caravan, entity, creature, qty)
    local item_type = item:getType()
    local item_subtype = item:getSubtype()
    local mat_type = item:getMaterial()
    local mat_subtype = item:getMaterialIndex()

    -- Get base value for item type, subtype, and material
    local value
    if item_type == df.item_type.CHEESE then
        --todo: seems to be wrong in dfhack's getItemBaseValue() ?
        value = 10
    else
        value = dfhack.items.getItemBaseValue(item_type, item_subtype, mat_type, mat_subtype)
    end

    -- Apply entity value modifications
    if entity and creature and entity.entity_raw.sphere_alignment.WAR ~= 256 then
        -- weapons
        if item_type == df.item_type.WEAPON then
            local def = df.global.world.raws.itemdefs.weapons[item_subtype]
            if creature.adultsize >= def.minimum_size then
                value = value * 2
            end
        end

        -- armor gloves shoes helms pants
        --todo: why 7 ?
        if creature.adultsize >= 7 then
            if item_type == df.item_type.ARMOR or item_type == df.item_type.GLOVES or item_type == df.item_type.SHOES or item_type == df.item_type.HELM or item_type == df.item_type.PANTS then
                local def = item.subtype --hint:df.item_armorst
                if def.armorlevel > 0 or def.flags.METAL_ARMOR_LEVELS then
                    value = value * 2
                end
            end
        end

        -- shields
        if item_type == df.item_type.SHIELD then
            local def = item.subtype --hint:df.item_shieldst
            if def.armorlevel > 0 then
                value = value * 2
            end
        end

        -- ammo
        if item_type == df.item_type.AMMO then
            value = value * 2
        end

        -- quiver
        if item_type == df.item_type.QUIVER then
            value = value * 2
        end
    end

    -- Improve value based on quality
    local quality = item:getQuality()
    value = value * (quality + 1)
    if quality == 5 then
        value = value * 2
    end

    -- Add improvement values
    local impValue = item:getThreadDyeValue(caravan) + item:getImprovementsValue(caravan)
    if item_type == df.item_type.AMMO then -- Ammo improvements are worth less
        impValue = impValue / 30
    end
    value = value + impValue

    -- Degrade value due to wear
    local wear = item:getWear()
    if wear == 1 then
        value = value * 3 / 4
    elseif wear == 2 then
        value = value / 2
    elseif wear == 3 then
        value = value / 4
    end

    -- Ignore value bonuses from magic, since that never actually happens

    -- Artifacts have 10x value
    if item.flags.artifact_mood then
        value = value * 10
    end

    -- Boost value from stack size or the supplied quantity
    if qty and qty > 0 then
        value = value * qty
    else
        value = value * item:getStackSize()
    end
    -- ...but not for coins
    if item_type == df.item_type.COIN then
        value = value / 500
        if value < 1 then
            value = 1
        end
    end

    -- Handle vermin swarms
    if item_type == df.item_type.VERMIN or item_type == df.item_type.PET then
        local divisor = 1
        local creature = df.global.world.raws.creatures.all[mat_type]
        if creature and mat_subtype < #creature.caste then
            divisor = creature.caste[mat_subtype].misc.petvalue_divisor
        end
        if divisor > 1 then
            value = value / divisor
        end
    end

    return math.floor(value)
end

function item_price_for_caravan(item, caravan, entity, creature, qty, pricetable)
    local value = item_value_for_caravan(item, caravan, entity, creature, qty)

    if not pricetable then
        return value
    end

    local reqs = pricetable.items
    for i=0, #pricetable.items.item_type-1 do
        if item:getType() == reqs.item_type[i] and (reqs.item_subtype[i] == -1 or item:getSubtype() == reqs.item_subtype[i]) then
            local not_any = false
            for i,v in ipairs(reqs.mat_cats[i]) do
                if v then
                    not_any = true
                    break
                end
            end
            if not not_any or dfhack.matinfo.matches(dfhack.matinfo.decode(item.mat_type, item.mat_index), reqs.mat_cats[i]) then
                return math.floor(value * (pricetable.price[i]/128))
            end
        end
    end

    return value
end

function item_or_container_price_for_caravan(item, caravan, entity, creature, qty, pricetable)
    local value = item_price_for_caravan(item, caravan, entity, creature, qty, pricetable)
    --[[if qty and qty > 0 then
        value = value / item.stack_size * qty
    end]]

    for i,ref in ipairs(item.general_refs) do
        if ref:getType() == df.general_ref_type.CONTAINS_ITEM then
            local ref = ref --as:df.general_ref_contains_itemst
            local item2 = df.item.find(ref.item_id)
            value = value + item_price_for_caravan(item2, caravan, entity, creature, nil, pricetable)
        
        elseif ref:getType() == df.general_ref_type.CONTAINS_UNIT then
            local ref = ref --as:df.general_ref_contains_unitst
            local unit2 = df.unit.find(ref.unit_id)
            local creature_raw = df.creature_raw.find(unit2.race)
            local caste_raw = creature_raw.caste[unit2.caste]
            value = value + caste_raw.misc.petvalue
        end
    end

    return value
end

--luacheck: in=
function depot_calculate_profit()
    local ws = dfhack.gui.getCurViewscreen() --as:df.viewscreen_tradegoodsst
    if ws._type ~= df.viewscreen_tradegoodsst then
        error('wrong screen '..tostring(ws._type))
    end

    local creature = df.global.world.raws.creatures.all[ws.entity.race]    

    local trader_profit = 0
    for i,t in ipairs(ws.trader_selected) do
        if istrue(t) then
            trader_profit = trader_profit - item_or_container_price_for_caravan(ws.trader_items[i], ws.caravan, ws.entity, creature, ws.trader_count[i], ws.caravan.buy_prices) --nil --ws.caravan.sell_prices)
        end
    end
    for i,t in ipairs(ws.broker_selected) do
        if istrue(t) then
            trader_profit = trader_profit + item_or_container_price_for_caravan(ws.broker_items[i], ws.caravan, ws.entity, creature, ws.broker_count[i], ws.caravan.buy_prices)
        end
    end
        
    return trader_profit    
end

local counteroffer

--luacheck: in=
function depot_trade_overview()
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_tradegoodsst then
        if df.global.ui.main.mode ~= df.ui_sidebar_mode.QueryBuilding or df.global.world.selected_building == nil then
            error('no selected building')
        end

        local bld = df.global.world.selected_building
        if bld:getType() ~= df.building_type.TradeDepot then
            error('not a depot')
        end
    
        gui.simulateInput(ws, K'BUILDJOB_DEPOT_TRADE')

        ws = dfhack.gui.getCurViewscreen()
        ws:logic()
        ws = dfhack.gui.getCurViewscreen()
        ws:logic() --probably not required
        ws:render() --to populate item lists

        if ws._type ~= df.viewscreen_tradegoodsst then
            error('can not switch to trade screen')
        end        
    end

    local tradews = ws --as:df.viewscreen_tradegoodsst

    --todo: include whether can seize/offer
    local trader_profit = depot_calculate_profit()
    local reply, mood = read_trader_reply()
    
    local can_seize = (tradews.caravan.entity ~= df.global.ui.civ_id)
    local can_trade = not tradews.is_unloading and not tradews.caravan.flags.offended

    local have_appraisal = false
    for i,v in ipairs(tradews.broker.status.current_soul.skills) do
        if v.id == df.job_skill.APPRAISAL then
            have_appraisal = true
            break
        end
    end    

    local flags = packbits(can_trade, can_seize, have_appraisal)

    --local counteroffer = mp.NIL
    if #tradews.counteroffer > 0 then
        counteroffer = {}
        for i,item in ipairs(tradews.counteroffer) do
            local title = itemname(item, 0, true)
            table.insert(counteroffer, { title })
        end

        gui.simulateInput(tradews, K'SELECT')
    elseif not istrue(tradews.has_offer) then
        counteroffer = mp.NIL
    end

    local ret = { dfhack.df2utf(tradews.merchant_name), dfhack.df2utf(tradews.merchant_entity), reply, mood, trader_profit, flags, counteroffer }

    return ret
end

function is_contained(item)
    for i,ref in ipairs(item.general_refs) do
        if ref:getType() == df.general_ref_type.CONTAINED_IN_ITEM then
            return true
        end
    end

    return false
end

--luacheck: in=bool
function depot_trade_get_items(their)
    local ws = dfhack.gui.getCurViewscreen() --as:df.viewscreen_tradegoodsst
    if ws._type ~= df.viewscreen_tradegoodsst then
        error('wrong screen '..tostring(ws._type))
    end

    their = istrue(their)

    local items = their and ws.trader_items or ws.broker_items --as:df.item_actual[]
    local sel = their and ws.trader_selected or ws.broker_selected
    local counts = their and ws.trader_count or ws.broker_count
    local prices = ws.caravan.buy_prices --their and nil or ws.caravan.buy_prices --ws.caravan.sell_prices
    local creature = df.global.world.raws.creatures.all[ws.entity.race]

    local ret = {}

    for i,item in ipairs(items) do
        local title = itemname(item, 0, true)
        local value = item_or_container_price_for_caravan(item, ws.caravan, ws.entity, creature, nil, prices)

        local inner = is_contained(item)
        local entity_stolen = dfhack.items.getGeneralRef(item, df.general_ref_type.ENTITY_STOLEN) --as:df.general_ref_entity_stolenst
        local stolen = entity_stolen and (df.historical_entity.find(entity_stolen.entity_id) ~= nil)
        local flags = packbits(inner, stolen, item.flags.foreign)

        --todo: use getStackSize() ?
        table.insert(ret, { title, value, item.weight, sel[i], flags, item.stack_size, counts[i] })
    end

    return ret
end

--luacheck: in=bool
function depot_trade_get_items2(their)
    local ws = dfhack.gui.getCurViewscreen() --as:df.viewscreen_tradegoodsst
    if ws._type ~= df.viewscreen_tradegoodsst then
        error('wrong screen '..tostring(ws._type))
    end

    their = istrue(their)

    local items = their and ws.trader_items or ws.broker_items --as:df.item_actual[]
    local sel = their and ws.trader_selected or ws.broker_selected
    local counts = their and ws.trader_count or ws.broker_count
    local prices = ws.caravan.buy_prices --their and nil or ws.caravan.buy_prices --ws.caravan.sell_prices
    local creature = df.global.world.raws.creatures.all[ws.entity.race]

    local ret = {}

    for i,item in ipairs(items) do
        local title = itemname(item, 0, true)
        local value = item_or_container_price_for_caravan(item, ws.caravan, ws.entity, creature, nil, prices)

        local inner = is_contained(item)
        local entity_stolen = dfhack.items.getGeneralRef(item, df.general_ref_type.ENTITY_STOLEN) --as:df.general_ref_entity_stolenst
        local stolen = entity_stolen and (df.historical_entity.find(entity_stolen.entity_id) ~= nil)
        local flags = packbits(inner, stolen, item.flags.foreign)

        --todo: use getStackSize() ?
        table.insert(ret, { title, item.id, value, item.weight, sel[i], flags, item.stack_size, counts[i] })
    end

    return ret
end

--todo: support passing many items at once
--luacheck: in=bool,number,bool,number
function depot_trade_set(their, idx, trade, qty)
    local ws = dfhack.gui.getCurViewscreen() --as:df.viewscreen_tradegoodsst
    if ws._type ~= df.viewscreen_tradegoodsst then
        return
    end

    their = istrue(their)

    local items = their and ws.trader_items or ws.broker_items --as:df.item_actual[]
    local sel = their and ws.trader_selected or ws.broker_selected    
    local counts = their and ws.trader_count or ws.broker_count

    if istrue(trade) then
        if is_contained(items[idx]) then
            -- Go up find the container and deselect it
            for i=idx-1,0,-1 do
                if not is_contained(items[i]) then
                    sel[i] = 0
                    break
                end
            end
        else
            -- If selecting a container, deselect all individual items in it
            for i=idx+1,#items-1 do
                if is_contained(items[i]) then
                    sel[i] = 0
                    counts[i] = 0
                else
                    break
                end
            end            
        end

        sel[idx] = 1
        counts[idx] = items[idx].stack_size > qty and qty or 0
    else
        sel[idx] = 0
        counts[idx] = 0
    end

    return depot_calculate_profit()
end

--luacheck: in=
function depot_trade_dotrade()
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_tradegoodsst then
        return
    end

    gui.simulateInput(ws, K'TRADE_TRADE')

    --not sure these are needed
    ws:logic()
    ws:render()

    --todo: return the new depot_trade_overview info here?
    return true
end

--luacheck: in=
function depot_trade_seize()
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_tradegoodsst then
        return
    end

    gui.simulateInput(ws, K'TRADE_SEIZE')

    --not sure these are needed
    ws:logic()
    ws:render()

    --todo: return the new depot_trade_overview info here?
    return true    
end

--luacheck: in=
function depot_trade_offer()
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_tradegoodsst then
        return
    end

    gui.simulateInput(ws, K'TRADE_OFFER')

    --not sure these are needed
    ws:logic()
    ws:render()

    --todo: return the new depot_trade_overview info here?
    return true    
end

--luacheck: in=
function depot_access()
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        error('wrong screen '..tostring(ws._type))
    end

    reset_main()

    gui.simulateInput(ws, K'D_DEPOT')

    return df.global.ui.main.mode == df.ui_sidebar_mode.DepotAccess
end