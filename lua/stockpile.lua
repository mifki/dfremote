function count_enabled(list, subset)
    local ret = 0

    if subset then
        for i,v in ipairs(subset) do
            if --[[v < #list and]] istrue(list[v]) then
                ret = ret + 1
            end
        end
    else
        for i,v in ipairs(list) do
            if istrue(v) then
                ret = ret + 1
            end
        end
    end

    return ret
end

function populate_enabled(list, cnt)
    if list._type ~= 'bool[]' then
        list:resize(cnt)
        for i=0,cnt-1 do
            list[i] = 1
        end    
    else
        for i=0,cnt-1 do
            list[i] = true
        end    
    end
end

local item_quality = {
    'Ordinary',
    'Well Crafted',
    'Finely Crafted',
    'Superior',
    'Exceptional',
    'Masterful',
    'Artifact'
}

local furniture_type = {
    'FLOODGATE',
    'HATCH_COVER',
    'GRATE',
    'DOOR',
    'CATAPULTPARTS',
    'BALLISTAPARTS',
    'TRAPPARTS',
    'BED',
    'TRACTION_BENCH',
    'WINDOW',
    'CHAIR',
    'TABLE',
    'COFFIN',
    'STATUE',
    'SLAB',
    'QUERN',
    'MILLSTONE',
    'ARMORSTAND',
    'WEAPONRACK',
    'CABINET',
    'ANVIL',
    'BUCKET',
    'BIN',
    'BOX',
    'SIEGEAMMO',
    'BARREL',
    'BALLISTAARROWHEAD',
    'PIPE_SECTION',

    --tool types
    'FOOD_STORAGE',
    'MINECART',
    'WHEELBARROW',
    'OTHER_LARGE_TOOLS',

    'SAND_BAG',
}

function gem_to_mat_idx(pos)
    local ret = {}
    for i,v in ipairs(df.global.world.raws.inorganics) do
        if v.material.flags.IS_GEM then
            table.insert(ret, i)
            if pos and #ret == pos then
                return i
            end
        end
    end    

    return ret
end

function stoneclay_to_mat_idx(pos)
    local ret = {}
    for i,v in ipairs(df.global.world.raws.inorganics) do
        if v.material.flags.IS_STONE then
            table.insert(ret, i)
            if pos and #ret == pos then
                return i
            end
        end
    end    

    return ret
end

function metal_to_mat_idx(pos)
    local ret = {}
    for i,v in ipairs(df.global.world.raws.inorganics) do
        if v.material.flags.IS_METAL then
            table.insert(ret, i)
            if pos and #ret == pos then
                return i
            end
        end
    end

    return ret
end

function metalore_to_mat_idx(pos)
    local ret = {}
    for i,v in ipairs(df.global.world.raws.inorganics) do
        if v.flags.METAL_ORE then
            table.insert(ret, i)
            if pos and #ret == pos then
                return i
            end
        end
    end

    return ret
end

function economic_to_mat_idx(pos)
    local ret = {}
    for i,v in ipairs(df.global.world.raws.inorganics) do
        if v.material.flags.IS_STONE and not v.flags.METAL_ORE and #v.economic_uses>0 then
            table.insert(ret, i)
            if pos and #ret == pos then
                return i
            end
        end
    end

    return ret
end

function otherstone_to_mat_idx(pos)
    local ret = {}
    for i,v in ipairs(df.global.world.raws.inorganics) do
        if v.material.flags.IS_STONE and not v.material.flags.NO_STONE_STOCKPILE and not v.flags.METAL_ORE and #v.economic_uses==0 then
            table.insert(ret, i)
            if pos and #ret == pos then
                return i
            end
        end
    end

    return ret
end

--todo: is this the right way?
function clay_to_mat_idx(pos)
    local ret = {}
    for i,v in ipairs(df.global.world.raws.inorganics) do
        if v.flags.SOIL and #v.material.reaction_product.id>0 and v.material.reaction_product.id[0].value=='FIRED_MAT' then
            table.insert(ret, i)
            if pos and #ret == pos then
                return i
            end
        end
    end

    return ret
end

function animal_to_creature_idx(pos)
    local ret = {}
    for i,v in ipairs(df.global.world.raws.creatures.all) do
        if not v.flags.CASTE_FEATURE_BEAST then
            table.insert(ret, i)
            if pos and #ret == pos then
                return i
            end
        end
    end

    return ret
end

function foodplant_to_plant_idx(pos)
    local ret = {}
    for i,v in ipairs(df.global.world.raws.plants.all) do
        local flags = v.flags
        if flags.SPRING or flags.SUMMER or flags.AUTUMN or flags.WINTER then
            table.insert(ret, i)
            if pos and #ret == pos then
                return i
            end
        end
    end

    return ret
end

function tree_to_plant_idx(pos)
    local ret = {}
    for i,v in ipairs(df.global.world.raws.plants.all) do
        if v.flags.TREE then
            table.insert(ret, i)
            if pos and #ret == pos then
                return i
            end
        end
    end

    return ret
end

function glass_to_builtin_idx(pos)
    local idxs = { 3, 4, 5 }
    if pos then
        return idxs[pos]
    end
    return idxs
end

local refuse_types = {
    df.item_type.REMAINS,
    df.item_type.MEAT,
    df.item_type.FISH,
    df.item_type.FISH_RAW,
    df.item_type.SEEDS,
    df.item_type.PLANT,
    df.item_type.PLANT_GROWTH, --?
    df.item_type.CHEESE,
    df.item_type.FOOD,
    df.item_type.EGG,
    df.item_type.WOOD,
    df.item_type.DOOR,
    df.item_type.FLOODGATE,
    df.item_type.BED,
    df.item_type.CHAIR,
    df.item_type.CHAIN,
    df.item_type.FLASK,
    df.item_type.GOBLET,
    df.item_type.INSTRUMENT,
    df.item_type.TOY,
    df.item_type.WINDOW,
    df.item_type.CAGE,
    df.item_type.BARREL,
    df.item_type.BUCKET,
    df.item_type.ANIMALTRAP,
    df.item_type.TABLE,
    df.item_type.COFFIN,
    df.item_type.STATUE,
    df.item_type.WEAPON,
    df.item_type.ARMOR,
    df.item_type.SHOES,
    df.item_type.SHIELD,
    df.item_type.HELM,
    df.item_type.GLOVES,
    df.item_type.BOX,
    df.item_type.BIN,
    df.item_type.ARMORSTAND,
    df.item_type.WEAPONRACK,
    df.item_type.CABINET,
    df.item_type.FIGURINE,
    df.item_type.AMULET,
    df.item_type.SCEPTER,
    df.item_type.AMMO,
    df.item_type.CROWN,
    df.item_type.RING,
    df.item_type.EARRING,
    df.item_type.BRACELET,
    df.item_type.GEM,
    df.item_type.ANVIL,
    df.item_type.VERMIN,
    df.item_type.PET,
    df.item_type.SKIN_TANNED,
    df.item_type.THREAD,
    df.item_type.CLOTH,
    df.item_type.TOTEM,
    df.item_type.PANTS,
    df.item_type.BACKPACK,
    df.item_type.QUIVER,
    df.item_type.CATAPULTPARTS,
    df.item_type.BALLISTAPARTS,
    df.item_type.SIEGEAMMO,
    df.item_type.BALLISTAARROWHEAD,
    df.item_type.TRAPPARTS,
    df.item_type.TRAPCOMP,
    df.item_type.DRINK,
    df.item_type.POWDER_MISC,
    df.item_type.LIQUID_MISC,
    df.item_type.COIN,
    df.item_type.GLOB,
    df.item_type.PIPE_SECTION,
    df.item_type.HATCH_COVER,
    df.item_type.GRATE,
    df.item_type.QUERN,
    df.item_type.MILLSTONE,
    df.item_type.SPLINT,
    df.item_type.CRUTCH,
    df.item_type.TRACTION_BENCH,
    df.item_type.TOOL,
    df.item_type.SLAB,
    df.item_type.BOOK
}

local goods_types = {
    df.item_type.CHAIN,
    df.item_type.FLASK,
    df.item_type.GOBLET,
    df.item_type.INSTRUMENT,
    df.item_type.TOY,
    df.item_type.ARMOR,
    df.item_type.SHOES,
    df.item_type.HELM,
    df.item_type.GLOVES,
    df.item_type.FIGURINE,
    df.item_type.AMULET,
    df.item_type.SCEPTER,
    df.item_type.CROWN,
    df.item_type.RING,
    df.item_type.EARRING,
    df.item_type.BRACELET,
    df.item_type.GEM,
    df.item_type.TOTEM,
    df.item_type.PANTS,
    df.item_type.BACKPACK,
    df.item_type.QUIVER,
    df.item_type.SPLINT,
    df.item_type.CRUTCH,
    df.item_type.TOOL,
    df.item_type.BOOK
}

function refusetype_to_itemtype_idx(pos)
    if pos then
        return refuse_types[pos]
    end
    return refuse_types
end

function goods_to_itemtype_idx(pos)
    if pos then
        return goods_types[pos]
    end
    return goods_types
end

--todo: should cache this
function stockpile_settings_schema()
    return
{
    {
        'Animals', 'animals',
        {
            { 'Animals', 'enabled', #df.global.world.raws.creatures.all, animal_to_creature_idx } --todo: filtered! 799->655    
        },
        {
            { 'Empty Cages', 'empty_cages' }, { 'Empty Animal Traps', 'empty_traps' }
        }
    },

    {
        'Food', 'food', 
        {
            { 'Meat', 'meat', #df.global.world.raws.mat_table.organic_types[df.organic_mat_category.Meat] },
            { 'Fish', 'fish', #df.global.world.raws.mat_table.organic_types[df.organic_mat_category.Fish] },
            { 'Unprepared Fish', 'unprepared_fish', #df.global.world.raws.mat_table.organic_types[df.organic_mat_category.UnpreparedFish] },
            { 'Egg', 'egg', #df.global.world.raws.mat_table.organic_types[df.organic_mat_category.Eggs] },
            { 'Plants', 'plants', #df.global.world.raws.mat_table.organic_types[df.organic_mat_category.Plants], foodplant_to_plant_idx },
            { 'Drink (Plant)', 'drink_plant', #df.global.world.raws.mat_table.organic_types[df.organic_mat_category.PlantDrink] },
            { 'Drink (Animal)', 'drink_animal', #df.global.world.raws.mat_table.organic_types[df.organic_mat_category.CreatureDrink] },
            { 'Cheese (Plant)', 'cheese_plant', #df.global.world.raws.mat_table.organic_types[df.organic_mat_category.PlantCheese] },
            { 'Cheese (Animal)', 'cheese_animal', #df.global.world.raws.mat_table.organic_types[df.organic_mat_category.CreatureCheese] },
            { 'Seeds', 'seeds', #df.global.world.raws.mat_table.organic_types[df.organic_mat_category.Seed], },
            { 'Fruit/Leaves', 'leaves', #df.global.world.raws.mat_table.organic_types[df.organic_mat_category.Leaf] },
            { 'Milled Plant', 'powder_plant', #df.global.world.raws.mat_table.organic_types[df.organic_mat_category.PlantPowder] },
            { 'Bone Meal', 'powder_creature', #df.global.world.raws.mat_table.organic_types[df.organic_mat_category.CreaturePowder] },
            { 'Fat', 'glob', #df.global.world.raws.mat_table.organic_types[df.organic_mat_category.Glob] },
            { 'Paste', 'glob_paste', #df.global.world.raws.mat_table.organic_types[df.organic_mat_category.Paste] },
            { 'Pressed Material', 'glob_pressed', #df.global.world.raws.mat_table.organic_types[df.organic_mat_category.Pressed] },
            { 'Extract (Plant)', 'liquid_plant', #df.global.world.raws.mat_table.organic_types[df.organic_mat_category.PlantLiquid] },
            { 'Extract (Animal)', 'liquid_animal', #df.global.world.raws.mat_table.organic_types[df.organic_mat_category.CreatureLiquid] },
            { 'Misc. Liquid', 'liquid_misc', #df.global.world.raws.mat_table.organic_types[df.organic_mat_category.MiscLiquid] },
        },
        {
            { 'Prepared Food', 'prepared_meals' }
        }
    },

    {
        'Furniture & Siege Ammo', 'furniture',
        {
            { 'Type', 'type', #furniture_type },

            { 'Stone & Clay', 'mats', #df.global.world.raws.inorganics, stoneclay_to_mat_idx },
            { 'Metal', 'mats', #df.global.world.raws.inorganics, metal_to_mat_idx },
            
            { 'Other Materials', 'other_mats', 15 }, --TODO: not good
            
            { 'Core Quality', 'quality_core', item_quality },
            { 'Total Quality', 'quality_total', item_quality }
        },
        {
            --{ 'Sand Bags', 'sand_bags' } --XXX: not shown in the UI, seems not used
        }
    },     

    {
        'Corpses', 'corpses',
        {}, {}
    },

    {
        'Refuse', 'refuse',
        {
            { 'Type', 'type', df.item_type._last_item+1, refusetype_to_itemtype_idx }, --todo: in game it's 112 somehow

            --todo: all filtered 799->655
            { 'Corpses', 'corpses', #df.global.world.raws.creatures.all, animal_to_creature_idx },
            { 'Body Parts', 'body_parts', #df.global.world.raws.creatures.all, animal_to_creature_idx },
            { 'Skulls', 'skulls', #df.global.world.raws.creatures.all, animal_to_creature_idx },
            { 'Bones', 'bones', #df.global.world.raws.creatures.all, animal_to_creature_idx },
            { 'Shells', 'shells', #df.global.world.raws.creatures.all, animal_to_creature_idx },
            { 'Teeth', 'teeth', #df.global.world.raws.creatures.all, animal_to_creature_idx },
            { 'Horns & Hooves', 'horns', #df.global.world.raws.creatures.all, animal_to_creature_idx },
            { 'Hair & Wool', 'hair', #df.global.world.raws.creatures.all, animal_to_creature_idx },
        },
        {
            --XXX: in game these are shown in Type list, we'll include them as flags for now!
            { 'Fresh Raw Hide', 'fresh_raw_hide' },
            { 'Rotten Raw Hide', 'rotten_raw_hide' },
        }
    },        

    {
        'Stone', 'stone',
        {
            --todo: all filtered
            { 'Metal Ores', 'mats', #df.global.world.raws.inorganics, metalore_to_mat_idx },
            { 'Economic', 'mats', #df.global.world.raws.inorganics, economic_to_mat_idx },
            { 'Other Stone', 'mats', #df.global.world.raws.inorganics, otherstone_to_mat_idx },
            { 'Clay', 'mats', #df.global.world.raws.inorganics, clay_to_mat_idx },
        },
        {
        }
    },    

    {
        'Ammo', 'ammo',
        {
            { 'Type', 'type', #df.global.world.raws.itemdefs.ammo },
            
            { 'Metal', 'mats', #df.global.world.raws.inorganics, metal_to_mat_idx },
            { 'Other Materials', 'other_mats', 2 }, --TODO: not good
            
            { 'Core Quality', 'quality_core', item_quality },
            { 'Total Quality', 'quality_total', item_quality }
        },
        {
        }
    },

    {
        'Coins', 'coins',
        {
            { 'Coins', 'mats', #df.global.world.raws.inorganics, metal_to_mat_idx },
        },
        {
        }
    },

    {
        'Bars & Blocks', 'bars_blocks',
        {
            { 'Bars - Metal', 'bars_mats', #df.global.world.raws.inorganics, metal_to_mat_idx },
            { 'Bars - Other Materials', 'bars_other_mats', { 'Coal', 'Potash', 'Ash', 'Pearlash', 'Soap' } },
            { 'Blocks - Stone & Clay', 'blocks_mats', #df.global.world.raws.inorganics, stoneclay_to_mat_idx },
            { 'Blocks - Metal', 'blocks_mats', #df.global.world.raws.inorganics, metal_to_mat_idx },
            { 'Blocks - Other Materials', 'blocks_other_mats', { 'Green Glass', 'Clear Glass', 'Crystal Glass', 'Wood' } }
        },
        {
        }
    },

    {
        'Gems', 'gems',
        {
            { 'Rough Gem', 'rough_mats', #df.global.world.raws.inorganics, gem_to_mat_idx },
            { 'Rough Glass', 'rough_other_mats', #df.global.world.raws.mat_table.builtin, glass_to_builtin_idx },
            { 'Cut Gem', 'cut_mats', #df.global.world.raws.inorganics, gem_to_mat_idx },
            { 'Cut Glass', 'cut_other_mats', #df.global.world.raws.mat_table.builtin, glass_to_builtin_idx },
            { 'Cut Stone', 'cut_mats', #df.global.world.raws.inorganics, stoneclay_to_mat_idx },
        },
        {
        }
    },

    {
        'Finished Goods', 'finished_goods',
        {
            { 'Type', 'type', df.item_type._last_item+1, goods_to_itemtype_idx },

            { 'Stone & Clay', 'mats', #df.global.world.raws.inorganics, stoneclay_to_mat_idx },
            { 'Metal', 'mats', #df.global.world.raws.inorganics, metal_to_mat_idx },
            { 'Gem', 'mats', #df.global.world.raws.inorganics, gem_to_mat_idx },

            { 'Other Materials', 'other_mats', 16 }, --TODO: not good
            
            { 'Core Quality', 'quality_core', item_quality },
            { 'Total Quality', 'quality_total', item_quality }
        },
        {
        }
    },        

    {
        'Leather', 'leather',
        {
            { 'Leather', 'mats', #df.global.world.raws.mat_table.organic_types[df.organic_mat_category.Leather] }
        },
        {
        }
    },       

    {
        'Cloth', 'cloth',
        {
            { 'Thread - Silk', 'thread_silk', #df.global.world.raws.mat_table.organic_types[df.organic_mat_category.Silk] },
            { 'Thread - Plant', 'thread_plant', #df.global.world.raws.mat_table.organic_types[df.organic_mat_category.PlantFiber] },
            { 'Thread - Yarn', 'thread_yarn', #df.global.world.raws.mat_table.organic_types[df.organic_mat_category.Yarn] },
            { 'Thread - Metal', 'thread_metal', #df.global.world.raws.mat_table.organic_types[df.organic_mat_category.MetalThread] },

            { 'Cloth - Silk', 'cloth_silk', #df.global.world.raws.mat_table.organic_types[df.organic_mat_category.Silk] },
            { 'Cloth - Plant', 'cloth_plant', #df.global.world.raws.mat_table.organic_types[df.organic_mat_category.PlantFiber] },
            { 'Cloth - Yarn', 'cloth_yarn', #df.global.world.raws.mat_table.organic_types[df.organic_mat_category.Yarn] },
            { 'Cloth - Metal', 'cloth_metal', #df.global.world.raws.mat_table.organic_types[df.organic_mat_category.MetalThread] },
        },
        {
        }
    },    

    {
        'Wood', 'wood',
        {
            { 'Wood', 'mats', #df.global.world.raws.plants.all, tree_to_plant_idx }
        },
        {
        }
    },    

    {
        'Weapons & Trap Components', 'weapons',
        {
            { 'Weapons', 'weapon_type', #df.global.world.raws.itemdefs.weapons },
            { 'Trap Components', 'trapcomp_type', #df.global.world.raws.itemdefs.trapcomps },
            
            { 'Metal', 'mats', #df.global.world.raws.inorganics, metal_to_mat_idx },
            { 'Stone', 'mats', #df.global.world.raws.inorganics, stoneclay_to_mat_idx },
            { 'Other Materials', 'other_mats', 10 }, --TODO: not good --todo: or 11? --todo: in fact only 10 is shown in the list in game
            
            { 'Core Quality', 'quality_core', item_quality },
            { 'Total Quality', 'quality_total', item_quality }
        },
        {
            { 'Usable', 'usable' }, { 'Unusable', 'unusable' }
        }
    },    

    {
        'Armor', 'armor',
        {
            { 'Body', 'body', #df.global.world.raws.itemdefs.armor },
            { 'Head', 'head', #df.global.world.raws.itemdefs.helms },
            { 'Feet', 'feet', #df.global.world.raws.itemdefs.shoes },
            { 'Hands', 'hands', #df.global.world.raws.itemdefs.gloves },
            { 'Legs', 'legs', #df.global.world.raws.itemdefs.pants },
            { 'Sheilds', 'shield', #df.global.world.raws.itemdefs.shields },
            
            { 'Metal', 'mats', #df.global.world.raws.inorganics, metal_to_mat_idx },
            { 'Other Materials', 'other_mats', 11 }, --TODO: not good
            
            { 'Core Quality', 'quality_core', item_quality },
            { 'Total Quality', 'quality_total', item_quality }
        },
        {
            { 'Usable', 'usable' }, { 'Unusable', 'unusable' }
        }
    }
}
end

function building_stockpile_getsettings()
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        error('wrong screen')
    end

    if df.global.ui.main.mode ~= 17 or df.global.world.selected_building == nil then
        error('no selected building')
    end

    local bld = df.global.world.selected_building
    if bld:getType() ~= df.building_type.Stockpile then
        error('not a stockpile')
    end

    local ss = bld.settings

    local ret = {}
    for i,toplevel in ipairs(stockpile_settings_schema()) do
        local toplevel_name = toplevel[1]
        local toplevel_field = toplevel[2]
        local toplevel_enabled = ss.flags[toplevel_field]
        local groups = toplevel[3]
        local flags = toplevel[4]

        local grps = {}
        local flgs = {}
        if #groups > 0 or #flags > 0 then
            local toplevel_obj = ss[toplevel_field]
            for j,group in ipairs(groups) do
                local list = toplevel_obj[group[2]]
                local group_name = group[1]
                local num_enabled, num_all

                if type(group[4]) == 'function' then
                    local idx_fn = group[4]
                    local idxs = idx_fn()
                    num_enabled = toplevel_enabled and count_enabled(list, idxs) or 0
                    num_all = #idxs
                else
                    num_enabled = toplevel_enabled and count_enabled(list) or 0
                    num_all = (type(group[3]) == 'table') and #group[3] or group[3]
                end

                --todo: maybe not return empty categories? but then need to remove them form schema or adjust index in building_stockpile_setenabled() 
                --if num_all > 0 then
                    table.insert(grps, { group_name, num_enabled, num_all })
                --end
            end

            for j,flag in ipairs(flags) do
                local flag_name = flag[1]
                table.insert(flgs, { flag_name, toplevel_obj[flag[2]] })
            end        
        end

        table.insert(ret, { toplevel_name, toplevel_enabled, grps, flgs })
    end

    local flags = {
        { 'Allow Plant/Animal', ss.allow_organic },
        { 'Allow Non-Plant/Animal', ss.allow_inorganic },
    }
    table.insert(ret, flags)

    return ret
end

--todo: support passing path as the first param
function building_stockpile_setenabled(...)
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        return
    end

    if df.global.ui.main.mode ~= 17 or df.global.world.selected_building == nil then
        return
    end

    local bld = df.global.world.selected_building
    if bld:getType() ~= df.building_type.Stockpile then
        return
    end

    local path = table.pack(...)
    local enabled = istrue(path[#path])
    path[#path] = nil

    local ss = bld.settings

    if #path == 1 then
        local p1 = path[1]
        local toplevel = stockpile_settings_schema()[p1+1]
        local toplevel_field = toplevel[2]

        ss.flags[toplevel_field] = enabled

        if #toplevel[3] > 0 or #toplevel[4] > 0 then
            local toplevel_obj = ss[toplevel_field]

            for i,group in ipairs(toplevel[3]) do
                local list = toplevel_obj[group[2]]
                local num_all = (type(group[3]) == 'table') and #group[3] or group[3]
                if enabled then
                    populate_enabled(list, num_all)
                end
            end

            if enabled then
                for j,flag in ipairs(toplevel[4]) do
                    local flag_name = flag[1]
                    toplevel_obj[flag[2]] = true
                end                    
            end
        end

    elseif #path == 2 then
        local p1 = path[1] + 1
        local toplevel = stockpile_settings_schema()[p1]
        local toplevel_field = toplevel[2]
        local toplevel_obj = ss[toplevel_field]

        local p2 = path[2] + 1
        local group = toplevel[3][p2]
        local list = toplevel_obj[group[2]]

        local v = enabled and 1 or 0
        if type(group[4]) == 'function' then
            local idx_fn = group[4]
            local idxs = idx_fn()
            for i,idx in ipairs(idxs) do
                list[idx] = v
            end
        else
            for i=0,#list-1 do
                list[i] = v
            end
        end

    elseif #path == 3 then
        local p1 = path[1] + 1
        local toplevel = stockpile_settings_schema()[p1]
        local toplevel_field = toplevel[2]
        local toplevel_obj = ss[toplevel_field]

        local p2 = path[2] + 1
        local group = toplevel[3][p2]
        local list = toplevel_obj[group[2]]

        local p3 = path[3]
        if type(group[4]) == 'function' then
            local idx_fn = group[4]
            local idx = idx_fn(p3 + 1)
            list[idx] = enabled and 1 or 0
        else
            list[p3] = enabled and 1 or 0
        end
    else
        return
    end

    return true
end

function building_stockpile_setflag(group, flag, enabled)
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        return
    end

    if df.global.ui.main.mode ~= 17 or df.global.world.selected_building == nil then
        return
    end

    local bld = df.global.world.selected_building
    if bld:getType() ~= df.building_type.Stockpile then
        return
    end

    enabled = istrue(enabled)

    local ss = bld.settings

    if group == 100 then
        if flag == 0 then
            ss.allow_organic = enabled
        elseif flag == 1 then
            ss.allow_inorganic = enabled
        end

        return
    end

    local toplevel = stockpile_settings_schema()[group + 1]
    local toplevel_field = toplevel[2]
    local toplevel_obj = ss[toplevel_field]

    local flags = toplevel[4]
    local flag_field = flags[flag + 1][2]

    toplevel_obj[flag_field] = enabled

    return true
end

function building_stockpile_setmax(barrels, bins, wheelbarrows)
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        return
    end

    if df.global.ui.main.mode ~= 17 or df.global.world.selected_building == nil then
        return
    end

    local bld = df.global.world.selected_building
    if bld:getType() ~= df.building_type.Stockpile then
        return
    end

    bld.max_barrels = barrels
    bld.max_bins = bins
    bld.max_wheelbarrows = wheelbarrows

    return true
end

function building_stockpile_create()
    df.global.ui.main.mode = 0

    local ws = dfhack.gui.getCurViewscreen()
    gui.simulateInput(ws, 'D_STOCKPILES')    
end