--todo: unused ?
function can_trade()
    if #df.global.ui.caravans then
        return false
    end

    local caravan = df.global.ui.caravans[0]
    if (caravan.trade_state ~= 1 and trade_state ~= 2) or caravan.time_remaining == 0 then
        return false
    end

    return true
end

function depot_movegoods_get()
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        return nil
    end

    if df.global.ui.main.mode ~= 17 or df.global.world.selected_building == nil then
        return
    end

    local bld = df.global.world.selected_building
    if bld:getType() ~= df.building_type.TradeDepot then
        return
    end

    gui.simulateInput(ws, 'BUILDJOB_DEPOT_BRING')

    ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_layer_assigntradest then
        return mp.NIL
    end

    gui.simulateInput(ws, 'ASSIGNTRADE_SORT')

    local ret = {}
    
    for i,info in ipairs(ws.info) do
        local title = itemname(info.item, 0, true)
        table.insert(ret, { title, info.distance, info.status })
    end

    return ret
end

function depot_movegoods_set(idx, status)
    local ws = dfhack.gui.getCurViewscreen()

    if ws._type ~= df.viewscreen_layer_assigntradest then
        return
    end

    ws.info[idx].status = status
end

function read_trader_reply()
    local reply = ''
    local mood = ''
    local start = false

    for j=1,df.global.gps.dimy-2 do
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
            for j=j+1,df.global.gps.dimy-2 do
                local ch = df.global.gps.screen[(2*df.global.gps.dimy+j)*4]
                
                if ch ~= 0 then
                    if ch == 219 then
                        break;
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

--todo: adultsize  !!
function item_price_for_caravan(item, caravan, pricetable)
    local value = dfhack.items.getValue(item)
    --todo: this is bad. should replicate getValue() from dfhack that will accept caravan argument
    value = value - item:getImprovementsValue(nil) + item:getImprovementsValue(caravan)

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

function item_or_container_value(item, caravan, pricetable, qty)
    local value = item_price_for_caravan(item, caravan, pricetable)
    if qty and qty > 0 then
        value = value / item.stack_size * qty
    end

    for i,ref in ipairs(item.general_refs) do
        if ref:getType() == df.general_ref_type.CONTAINS_ITEM then
            local item2 = df.item.find(ref.item_id)
            value = value + item_price_for_caravan(item2, caravan, pricetable)
        
        elseif ref:getType() == df.general_ref_type.CONTAINS_UNIT then
            local unit2 = df.unit.find(ref.unit_id)
            local creature_raw = df.creature_raw.find(unit2.race)
            local caste_raw = creature_raw.caste[unit2.caste]
            value = value + caste_raw.misc.petvalue
        end
    end

    return value
end

function depot_calculate_profit()
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_tradegoodsst then
        return nil
    end

    local trader_profit = 0
    for i,t in ipairs(ws.trader_selected) do
        if istrue(t) then
            trader_profit = trader_profit - item_or_container_value(ws.trader_items[i], ws.caravan, ws.caravan.buy_prices, ws.trader_count[i]) --nil --ws.caravan.sell_prices)
        end
    end
    for i,t in ipairs(ws.broker_selected) do
        if istrue(t) then
            trader_profit = trader_profit + item_or_container_value(ws.broker_items[i], ws.caravan, ws.caravan.buy_prices, ws.broker_count[i])
        end
    end
        
    return trader_profit    
end

local counteroffer
function depot_trade_overview()
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_tradegoodsst then
        if df.global.ui.main.mode ~= 17 or df.global.world.selected_building == nil then
            return nil
        end

        local bld = df.global.world.selected_building
        if bld:getType() ~= df.building_type.TradeDepot then
            return nil
        end
    
        gui.simulateInput(ws, 'BUILDJOB_DEPOT_TRADE')

        ws = dfhack.gui.getCurViewscreen()
        ws:logic()
        ws = dfhack.gui.getCurViewscreen()
        ws:logic() --probably not required
        ws:render() --to populate item lists

        if ws._type ~= df.viewscreen_tradegoodsst then
            return mp.NIL
        end        
    end

    --todo: include whether can seize/offer
    local trader_profit = depot_calculate_profit()
    local reply, mood = read_trader_reply()
    
    local can_seize = (ws.caravan.entity ~= df.global.ui.civ_id)
    local can_trade = not ws.is_unloading and not ws.caravan.flags.offended

    local have_appraisal = false
    for i,v in ipairs(ws.broker.status.current_soul.skills) do
        if v.id == df.job_skill.APPRAISAL then
            have_appraisal = true
            break
        end
    end    

    local flags = packbits(can_trade, can_seize, have_appraisal)

    --local counteroffer = mp.NIL
    if #ws.counteroffer > 0 then
        counteroffer = {}
        for i,item in ipairs(ws.counteroffer) do
            local title = itemname(item, 0, true)
            table.insert(counteroffer, { title })
        end

        gui.simulateInput(ws, 'SELECT')
    elseif not istrue(ws.has_offer) then
        counteroffer = mp.NIL
    end

    local ret = { dfhack.df2utf(ws.merchant_name), dfhack.df2utf(ws.merchant_entity), reply, mood, trader_profit, flags, counteroffer }

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

function depot_trade_get_items(their)
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_tradegoodsst then
        return nil
    end

    their = istrue(their)

    local items = their and ws.trader_items or ws.broker_items
    local sel = their and ws.trader_selected or ws.broker_selected
    local counts = their and ws.trader_count or ws.broker_count
    local prices = ws.caravan.buy_prices --their and nil or ws.caravan.buy_prices --ws.caravan.sell_prices

    local ret = {}

    for i,item in ipairs(items) do
        local title = itemname(item, 0, true)
        local value = item_or_container_value(item, ws.caravan, prices)

        local inner = is_contained(item)
        local entity_stolen = dfhack.items.getGeneralRef(item, df.general_ref_type.ENTITY_STOLEN)
        local stolen = entity_stolen and (df.historical_entity.find(entity_stolen.entity_id) ~= nil)
        local flags = packbits(inner, stolen, item.flags.foreign)

        --todo: use getStackSize() ?
        table.insert(ret, { title, value, item.weight, sel[i], flags, item.stack_size, counts[i] })
    end

    return ret
end

--todo: support passing many items at once
function depot_trade_set(their, idx, trade, qty)
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_tradegoodsst then
        return
    end

    their = istrue(their)

    local items = their and ws.trader_items or ws.broker_items
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

function depot_trade_dotrade()
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_tradegoodsst then
        return
    end

    gui.simulateInput(ws, 'TRADE_TRADE')

    --not sure these are needed
    ws:logic()
    ws:render()

    --todo: return the new depot_trade_overview info here?
    return true
end

function depot_trade_seize()
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_tradegoodsst then
        return
    end

    gui.simulateInput(ws, 'TRADE_SEIZE')

    --not sure these are needed
    ws:logic()
    ws:render()

    --todo: return the new depot_trade_overview info here?
    return true    
end

function depot_trade_offer()
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_tradegoodsst then
        return
    end

    gui.simulateInput(ws, 'TRADE_OFFER')

    --not sure these are needed
    ws:logic()
    ws:render()

    --todo: return the new depot_trade_overview info here?
    return true    
end

function depot_access()
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        return nil
    end

    reset_main()

    gui.simulateInput(ws, 'D_DEPOT')

    return df.global.ui.main.mode == df.ui_sidebar_mode.DepotAccess
end