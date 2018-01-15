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
        error(errmsg_wrongscreen(ws))
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
        error(errmsg_wrongscreen(ws))
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
        table.insert(ret, { title, info.item.id, info.distance, info.status })
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

                        if char ~= 0 and not (char == 32 and mood:byte(#mood) == 32) then
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

local function _match_mat_vec(mat_vec, idx, mat_type, mat_index)
    return mat_type == mat_vec.mat_type[idx] and mat_index == mat_vec.mat_index[idx]
end
local function _match_basic_mat(mat_indices, idx, mat_type, mat_index)
    return mat_type == 0 and mat_index == mat_indices[idx]
end
local function _match_item_type_subtype(subtypes, idx, item_subtype)
    return item_subtype == subtypes[idx]
end

local item_type_to_sell_category = {
    [df.item_type.BAR] = { df.entity_sell_category.MetalBars, df.entity_sell_category.Miscellaneous },
    [df.item_type.SMALLGEM] = { df.entity_sell_category.SmallCutGems },
    [df.item_type.BLOCKS] = { df.entity_sell_category.StoneBlocks },
    [df.item_type.ROUGH] = { df.entity_sell_category.Glass },
    [df.item_type.BOULDER] = { df.entity_sell_category.Stone, df.entity_sell_category.Clay },
    [df.item_type.WOOD] = { df.entity_sell_category.Wood },
    [df.item_type.CHAIN] = { df.entity_sell_category.RopesPlant, df.entity_sell_category.RopesSilk, df.entity_sell_category.RopesYarn },
    [df.item_type.FLASK] = { df.entity_sell_category.FlasksWaterskins },
    [df.item_type.GOBLET] = { df.entity_sell_category.CupsMugsGoblets },
    [df.item_type.INSTRUMENT] = { df.entity_sell_category.Instruments },
    [df.item_type.TOY] = { df.entity_sell_category.Toys },
    [df.item_type.CAGE] = { df.entity_sell_category.Cages },
    [df.item_type.BARREL] = { df.entity_sell_category.Barrels },
    [df.item_type.BUCKET] = { df.entity_sell_category.Buckets },
    [df.item_type.WEAPON] = { df.entity_sell_category.Weapons, df.entity_sell_category.TrainingWeapons, df.entity_sell_category.DiggingImplements },
    [df.item_type.ARMOR] = { df.entity_sell_category.Bodywear },
    [df.item_type.SHOES] = { df.entity_sell_category.Footwear },
    [df.item_type.SHIELD] = { df.entity_sell_category.Shields },
    [df.item_type.HELM] = { df.entity_sell_category.Headwear },
    [df.item_type.GLOVES] = { df.entity_sell_category.Handwear },
    [df.item_type.BOX] = { df.entity_sell_category.BagsYarn, df.entity_sell_category.BagsLeather, df.entity_sell_category.BagsPlant, df.entity_sell_category.BagsSilk },
    [df.item_type.FIGURINE] = { df.entity_sell_category.Crafts },
    [df.item_type.AMULET] = { df.entity_sell_category.Crafts },
    [df.item_type.SCEPTER] = { df.entity_sell_category.Crafts },
    [df.item_type.AMMO] = { df.entity_sell_category.Ammo },
    [df.item_type.CROWN] = { df.entity_sell_category.Crafts },
    [df.item_type.RING] = { df.entity_sell_category.Crafts },
    [df.item_type.EARRING] = { df.entity_sell_category.Crafts },
    [df.item_type.BRACELET] = { df.entity_sell_category.Crafts },
    [df.item_type.GEM] = { df.entity_sell_category.LargeCutGems },
    [df.item_type.ANVIL] = { df.entity_sell_category.Anvils },
    [df.item_type.MEAT] = { df.entity_sell_category.Meat },
    [df.item_type.FISH] = { df.entity_sell_category.Fish },
    [df.item_type.FISH_RAW] = { df.entity_sell_category.Fish },
    [df.item_type.PET] = { df.entity_sell_category.Pets },
    [df.item_type.SEEDS] = { df.entity_sell_category.Seeds },
    [df.item_type.PLANT] = { df.entity_sell_category.Plants },
    [df.item_type.SKIN_TANNED] = { df.entity_sell_category.Leather },
    [df.item_type.PLANT_GROWTH] = { df.entity_sell_category.FruitsNuts, df.entity_sell_category.GardenVegetables },
    [df.item_type.THREAD] = { df.entity_sell_category.ThreadPlant, df.entity_sell_category.ThreadSilk, df.entity_sell_category.ThreadYarn },
    [df.item_type.CLOTH] = { df.entity_sell_category.ClothPlant, df.entity_sell_category.ClothSilk, df.entity_sell_category.ClothYarn,  },
    [df.item_type.PANTS] = { df.entity_sell_category.Legwear },
    [df.item_type.BACKPACK] = { df.entity_sell_category.Backpacks },
    [df.item_type.QUIVER] = { df.entity_sell_category.Quivers },
    [df.item_type.TRAPCOMP] = { df.entity_sell_category.TrapComponents },
    [df.item_type.DRINK] = { df.entity_sell_category.Drinks },
    [df.item_type.POWDER_MISC] = { df.entity_sell_category.Powders, df.entity_sell_category.Sand },
    [df.item_type.CHEESE] = { df.entity_sell_category.Cheese },
    [df.item_type.LIQUID_MISC] = { df.entity_sell_category.Extracts, df.entity_sell_category.Miscellaneous },
    [df.item_type.SPLINT] = { df.entity_sell_category.Splints },
    [df.item_type.CRUTCH] = { df.entity_sell_category.Crutches },
    [df.item_type.TOOL] = { df.entity_sell_category.Tools },
    [df.item_type.EGG] = { df.entity_sell_category.Eggs },
    [df.item_type.SHEET] = { df.entity_sell_category.Parchment },
}

local sell_category_matchers = {
    [df.entity_sell_category.Leather] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_mat_vec (entity.resources.organic.leather, idx, mat_type, mat_index)
    end,
    [df.entity_sell_category.ClothPlant] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_mat_vec (entity.resources.organic.fiber, idx, mat_type, mat_index)
    end,
    [df.entity_sell_category.ClothSilk] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_mat_vec (entity.resources.organic.silk, idx, mat_type, mat_index)
    end,

    [df.entity_sell_category.Crafts] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_mat_vec (entity.resources.misc_mat.crafts, idx, mat_type, mat_index)
    end,

    [df.entity_sell_category.Wood] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_mat_vec (entity.resources.organic.wood, idx, mat_type, mat_index)
    end,

    [df.entity_sell_category.MetalBars] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_basic_mat (entity.resources.metals, idx, mat_type, mat_index)
    end,
    [df.entity_sell_category.SmallCutGems] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_basic_mat (entity.resources.gems, idx, mat_type, mat_index)
    end,
    [df.entity_sell_category.LargeCutGems] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_basic_mat (entity.resources.gems, idx, mat_type, mat_index)
    end,
    [df.entity_sell_category.StoneBlocks] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_basic_mat (entity.resources.stones, idx, mat_type, mat_index)
    end,

    [df.entity_sell_category.Seeds] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_mat_vec (entity.resources.seeds, idx, mat_type, mat_index)
    end,

    [df.entity_sell_category.Anvils] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_mat_vec (entity.resources.metal.anvil, idx, mat_type, mat_index)
    end,

    [df.entity_sell_category.Weapons] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_item_type_subtype (entity.resources.weapon_type, idx, item_subtype)
    end,
    [df.entity_sell_category.TrainingWeapons] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_item_type_subtype (entity.resources.training_weapon_type, idx, item_subtype)
    end,
    [df.entity_sell_category.Ammo] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_item_type_subtype (entity.resources.ammo_type, idx, item_subtype)
    end,
    [df.entity_sell_category.TrapComponents] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_item_type_subtype (entity.resources.trapcomp_type, idx, item_subtype)
    end,
    [df.entity_sell_category.DiggingImplements] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_item_type_subtype (entity.resources.digger_type, idx, item_subtype)
    end,

    [df.entity_sell_category.Bodywear] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_item_type_subtype (entity.resources.armor_type, idx, item_subtype)
    end,
    [df.entity_sell_category.Headwear] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_item_type_subtype (entity.resources.helm_type, idx, item_subtype)
    end,
    [df.entity_sell_category.Handwear] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_item_type_subtype (entity.resources.gloves_type, idx, item_subtype)
    end,
    [df.entity_sell_category.Footwear] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_item_type_subtype (entity.resources.shoes_type, idx, item_subtype)
    end,
    [df.entity_sell_category.Legwear] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_item_type_subtype (entity.resources.pants_type, idx, item_subtype)
    end,
    [df.entity_sell_category.Shields] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_item_type_subtype (entity.resources.shield_type, idx, item_subtype)
    end,

    [df.entity_sell_category.Toys] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_item_type_subtype (entity.resources.toy_type, idx, item_subtype)
    end,
    [df.entity_sell_category.Instruments] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_item_type_subtype (entity.resources.instrument_type, idx, item_subtype)
    end,

    [df.entity_sell_category.Pets] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return mat_type == entity.resources.animals.pet_races[idx] and mat_index == entity.resources.animals.pet_castes[idx]
    end,

    [df.entity_sell_category.Drinks] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_mat_vec (entity.resources.misc_mat.booze, idx, mat_type, mat_index)
    end,
    [df.entity_sell_category.Cheese] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_mat_vec (entity.resources.misc_mat.cheese, idx, mat_type, mat_index)
    end,
    [df.entity_sell_category.Powders] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_mat_vec (entity.resources.misc_mat.powders, idx, mat_type, mat_index)
    end,
    [df.entity_sell_category.Extracts] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_mat_vec (entity.resources.misc_mat.extracts, idx, mat_type, mat_index)
    end,
    [df.entity_sell_category.Meat] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_mat_vec (entity.resources.misc_mat.meat, idx, mat_type, mat_index)
    end,

    [df.entity_sell_category.Fish] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return mat_type == entity.resources.fish_races[idx] and mat_index == entity.resources.fish_castes[idx]
    end,

    [df.entity_sell_category.Plants] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_mat_vec (entity.resources.plants, idx, mat_type, mat_index)
    end,

        --todo: FruitsNuts, GardenVegetables, MeatFishRecipes, OtherRecipes,

    [df.entity_sell_category.Stone] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_basic_mat (entity.resources.stones, idx, mat_type, mat_index)
    end,


    [df.entity_sell_category.Cages] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_mat_vec (entity.resources.misc_mat.cages, idx, mat_type, mat_index)
    end,
    
    [df.entity_sell_category.BagsLeather] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_mat_vec (entity.resources.organic.leather, idx, mat_type, mat_index)
    end,
    [df.entity_sell_category.BagsPlant] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_mat_vec (entity.resources.organic.fiber, idx, mat_type, mat_index)
    end,
    [df.entity_sell_category.BagsSilk] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_mat_vec (entity.resources.organic.silk, idx, mat_type, mat_index)
    end,
    
    [df.entity_sell_category.ThreadPlant] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_mat_vec (entity.resources.organic.fiber, idx, mat_type, mat_index)
    end,
    [df.entity_sell_category.ThreadSilk] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_mat_vec (entity.resources.organic.silk, idx, mat_type, mat_index)
    end,
    
    [df.entity_sell_category.RopesPlant] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_mat_vec (entity.resources.organic.fiber, idx, mat_type, mat_index)
    end,
    [df.entity_sell_category.RopesSilk] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_mat_vec (entity.resources.organic.silk, idx, mat_type, mat_index)
    end,
    
    [df.entity_sell_category.Barrels] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_mat_vec (entity.resources.misc_mat.barrels, idx, mat_type, mat_index)
    end,
    [df.entity_sell_category.FlasksWaterskins] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_mat_vec (entity.resources.misc_mat.flasks, idx, mat_type, mat_index)
    end,
    [df.entity_sell_category.Quivers] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_mat_vec (entity.resources.misc_mat.quivers, idx, mat_type, mat_index)
    end,
    [df.entity_sell_category.Backpacks] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_mat_vec (entity.resources.misc_mat.backpacks, idx, mat_type, mat_index)
    end,
    [df.entity_sell_category.Sand] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_mat_vec (entity.resources.misc_mat.sand, idx, mat_type, mat_index)
    end,
    [df.entity_sell_category.Glass] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_mat_vec (entity.resources.misc_mat.glass, idx, mat_type, mat_index)
    end,

    [df.entity_sell_category.Miscellaneous] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return item_type == entity.resources.wood_products.item_type[idx] and
               item_subtype == entity.resources.wood_products.item_subtype[idx] and
               mat_type == entity.resources.wood_products.material.mat_type[idx] and
               mat_index == entity.resources.wood_products.material.mat_index[idx]
    end,

    [df.entity_sell_category.Buckets] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_mat_vec (entity.resources.misc_mat.barrels, idx, mat_type, mat_index)
    end,
    [df.entity_sell_category.Splints] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_mat_vec (entity.resources.misc_mat.barrels, idx, mat_type, mat_index)
    end,
    [df.entity_sell_category.Crutches] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_mat_vec (entity.resources.misc_mat.barrels, idx, mat_type, mat_index)
    end,

    [df.entity_sell_category.Eggs] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return mat_type == entity.resources.egg_races[idx] and mat_index == entity.resources.egg_castes[idx]
    end,

    [df.entity_sell_category.BagsYarn] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_mat_vec (entity.resources.organic.wool, idx, mat_type, mat_index)
    end,
    [df.entity_sell_category.RopesYarn] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_mat_vec (entity.resources.organic.wool, idx, mat_type, mat_index)
    end,
    [df.entity_sell_category.ClothYarn] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_mat_vec (entity.resources.organic.wool, idx, mat_type, mat_index)
    end,
    [df.entity_sell_category.ThreadYarn] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_mat_vec (entity.resources.organic.wool, idx, mat_type, mat_index)
    end,

    [df.entity_sell_category.Tools] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_item_type_subtype (entity.resources.tool_type, idx, item_subtype)
    end,

    [df.entity_sell_category.Clay] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_mat_vec (entity.resources.misc_mat.clay, idx, mat_type, mat_index)
    end,

    --df.entity_sell_category.Parchment
    [df.entity_sell_category.Clay+1] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_mat_vec (entity.resources.organic.parchment, idx, mat_type, mat_index)
    end,
    
    --df.entity_sell_category.CupsMugsGoblets
    [df.entity_sell_category.Clay+2] = function(entity, idx, item_type, item_subtype, mat_type, mat_index)
        return _match_mat_vec (entity.resources.misc_mat.crafts, idx, mat_type, mat_index)
    end,
}

-- copy of Items::getValue() but also applies entity, race and caravan modifications, agreements adjustment, and custom qty
function item_value_for_caravan(item, caravan, entity, creature, adjustment, qty)
    local item_type = item:getType()
    local item_subtype = item:getSubtype()
    local mat_type = item:getMaterial()
    local mat_index = item:getMaterialIndex()

    -- Get base value for item type, subtype, and material
    local value
    if item_type == df.item_type.CHEESE then
        --todo: seems to be wrong in dfhack's getItemBaseValue() ?
        value = 10
    
    elseif item_type == df.item_type.SHEET then
        value = 5
        local mi = dfhack.matinfo.decode(mat_type, mat_index)
        if mi then
            value = value * mi.material.material_value
        end
    
    elseif item_type == df.item_type.INSTRUMENT and item_subtype < #df.global.world.raws.itemdefs.instruments then
        value = df.global.world.raws.itemdefs.instruments[item_subtype].value
        local mi = dfhack.matinfo.decode(mat_type, mat_index)
        if mi then
            value = value * mi.material.material_value
        end
    
    else
        value = dfhack.items.getItemBaseValue(item_type, item_subtype, mat_type, mat_index)
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
        impValue = math.floor(impValue / 30)
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

    value = math.floor(value*adjustment)

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
        if creature and mat_index < #creature.caste then
            divisor = creature.caste[mat_index].misc.petvalue_divisor
        end
        if divisor > 1 then
            value = value / divisor
        end
    end

    return math.floor(value)
end

function item_price_for_caravan(item, caravan, entity, creature, qty, pricetable_buy, pricetable_sell)
    local item_type = item:getType()
    local item_subtype = item:getSubtype()
    local mat_type = item:getMaterial()
    local mat_index = item:getMaterialIndex()

    local adjustment_buy = 1
    local adjustment_sell = 1

    if pricetable_buy then
        local reqs = pricetable_buy.items
        local matched
        for i,v in ipairs(reqs.item_type) do
            if item_type == reqs.item_type[i] and (reqs.item_subtype[i] == -1 or item_subtype == reqs.item_subtype[i]) then
                
                if reqs.mat_types[i] ~= -1 then
                    matched = (mat_type == reqs.mat_types[i] and mat_index == reqs.mat_indices[i])
                
                else
                    local any_cat = true
                    for i,v in ipairs(reqs.mat_cats[i]) do
                        if v then
                            any_cat = false
                            break
                        end
                    end

                    matched = any_cat or dfhack.matinfo.matches(dfhack.matinfo.decode(mat_type, mat_index), reqs.mat_cats[i])
                end

                if matched then
                    adjustment_buy = pricetable_buy.price[i] / 128
                    break
                end
            end
        end
    end

    if pricetable_sell then
        local sell_cats = item_type_to_sell_category[item_type]
        if sell_cats then
            for i,v in ipairs(sell_cats) do
                local matcher = sell_category_matchers[v]
                if matcher then
                    local matched = false
                    
                    for j,w in ipairs(pricetable_sell.price[v]) do
                        if w ~= 128 and matcher(entity, j, item_type, item_subtype, mat_type, mat_index) then
                            matched = true
                            adjustment_sell = w / 128
                            break
                        end
                    end

                    if matched then
                        break
                    end        
                end        
            end
        end
    end

    return item_value_for_caravan(item, caravan, entity, creature, math.max(adjustment_buy, adjustment_sell), qty)    
end

function item_or_container_price_for_caravan(item, caravan, entity, creature, qty, pricetable_buy, pricetable_sell)
    local value = item_price_for_caravan(item, caravan, entity, creature, qty, pricetable_buy, pricetable_sell)
    --[[if qty and qty > 0 then
        value = value / item.stack_size * qty
    end]]

    for i,ref in ipairs(item.general_refs) do
        if ref:getType() == df.general_ref_type.CONTAINS_ITEM then
            local ref = ref --as:df.general_ref_contains_itemst
            local item2 = df.item.find(ref.item_id)
            value = value + item_or_container_price_for_caravan(item2, caravan, entity, creature, nil, pricetable_buy, pricetable_sell)
        
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
        error(errmsg_wrongscreen(ws))
    end

    local creature = df.global.world.raws.creatures.all[ws.entity.race]    

    local trader_profit = 0
    for i,t in ipairs(ws.trader_selected) do
        if istrue(t) then
            trader_profit = trader_profit - item_or_container_price_for_caravan(ws.trader_items[i], ws.caravan, ws.entity, creature, ws.trader_count[i], ws.caravan.buy_prices, ws.caravan.sell_prices)
        end
    end
    for i,t in ipairs(ws.broker_selected) do
        if istrue(t) then
            trader_profit = trader_profit + item_or_container_price_for_caravan(ws.broker_items[i], ws.caravan, ws.entity, creature, ws.broker_count[i], ws.caravan.buy_prices, ws.caravan.sell_prices)
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
        error(errmsg_wrongscreen(ws))
    end

    their = istrue(their)

    local items = their and ws.trader_items or ws.broker_items --as:df.item_actual[]
    local sel = their and ws.trader_selected or ws.broker_selected
    local counts = their and ws.trader_count or ws.broker_count
    local creature = df.global.world.raws.creatures.all[ws.entity.race]

    local ret = {}

    for i,item in ipairs(items) do
        local title = itemname(item, 0, true)
        local value = item_or_container_price_for_caravan(item, ws.caravan, ws.entity, creature, nil, ws.caravan.buy_prices, ws.caravan.sell_prices)

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
        error(errmsg_wrongscreen(ws))
    end

    their = istrue(their)

    local items = their and ws.trader_items or ws.broker_items --as:df.item_actual[]
    local sel = their and ws.trader_selected or ws.broker_selected
    local counts = their and ws.trader_count or ws.broker_count
    local creature = df.global.world.raws.creatures.all[ws.entity.race]

    local ret = {}

    for i,item in ipairs(items) do
        local title = itemname(item, 0, true)
        local value = item_or_container_price_for_caravan(item, ws.caravan, ws.entity, creature, nil, ws.caravan.buy_prices, ws.caravan.sell_prices)

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
        error(errmsg_wrongscreen(ws))
    end

    reset_main()

    gui.simulateInput(ws, K'D_DEPOT')

    return df.global.ui.main.mode == df.ui_sidebar_mode.DepotAccess
end

--print(pcall(function() return json:encode(depot_trade_get_items(true)) end))
--print(pcall(function() return json:encode(depot_calculate_profit()) end))
