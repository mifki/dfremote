function count_enabled(list, subset)
    local ret = 0

    if subset then --as:subset=number[]
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
    'Standard',
    'Well-Crafted',
    'Finely-Crafted',
    'Superior Quality',
    'Exceptional',
    'Masterwork',
    'Artifact'
}

local function quality_titles()
    return item_quality
end

local furniture_other_materials = {
    'Wood',
    'Plant Cloth',
    'Bone',
    'Tooth',
    'Horn',
    'Pearl',
    'Shell',
    'Leather',
    'Silk',
    'Amber',
    'Coral',
    'Green Glass',
    'Clear Glass',
    'Crystal Glass',
    'Yarn'
}

local function furniture_other_material_titles()
    return furniture_other_materials
end

local ammo_other_materials = {
    'Wood',
    'Bone',
}

local function ammo_other_material_titles()
    return ammo_other_materials
end

local goods_other_materials = {
    'Wood',
    'Plant Cloth',
    'Bone',
    'Tooth',
    'Horn',
    'Pearl',
    'Shell',
    'Leather',
    'Silk',
    'Amber',
    'Coral',
    'Green Glass',
    'Clear Glass',
    'Crystal Glass',
    'Yarn',
    'Wax'
}

local function goods_other_material_titles()
    return goods_other_materials
end

local weapons_other_materials = {
    'Wood',
    'Plant Cloth',
    'Bone',
    'Shell',
    'Leather',
    'Silk',
    'Green Glass',
    'Clear Glass',
    'Crystal Glass',
    'Yarn',
}

local function weapons_other_material_titles()
    return weapons_other_materials
end

local glasses = {
    'Green Glass',
    'Clear Glass',
    'Crystal Glass'
}

local function glass_titles()
    return glasses
end

local bars_other_materials = { 'Coal', 'Potash', 'Ash', 'Pearlash', 'Soap' }
local blocks_other_materials = { 'Green Glass', 'Clear Glass', 'Crystal Glass', 'Wood' }

local function bars_other_material_titles()
    return bars_other_materials
end
local function blocks_other_material_titles()
    return blocks_other_materials
end


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

local function furniture_type_titles()
    return {
        'Floodgates',
        'Hatch Covers',
        'Grates',
        'Doors',
        'Catapult Parts',
        'Ballista Parts',
        'Mechanisms',
        'Beds',
        'Traction Benches',
        'Windows',
        'Thrones',
        'Tables',
        'Coffins',
        'Statues',
        'Slabs',
        'Querns',
        'Millstones',
        'Armor Stands',
        'Weapon Racks',
        'Cabinets',
        'Anvils',
        'Buckets',
        'Bins',
        'Boxes and Bags',
        'Siege Ammo',
        'Barrels',
        'Ballista Arrow Heads',
        'Pipe Sections',

        --tool types
        --todo: are these hardcoded ???
        'Large Pots / Food Storage',
        'Minecarts',
        'Wheelbarrows',
        'Other Large Tools',

        'Sand Bags',
    }
end

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

--todo: game uses plural when in Gems group and singular when in Finished Goods group
function gem_titles()
    local ret = {}
    for i,v in ipairs(df.global.world.raws.inorganics) do
        if v.material.flags.IS_GEM then
            local t = capitalize(v.material.state_name[0])
            table.insert(ret, t)
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

function stoneclay_titles()
    local ret = {}
    for i,v in ipairs(df.global.world.raws.inorganics) do
        if v.material.flags.IS_STONE then
            local t = capitalize(v.material.state_name[0])
            table.insert(ret, t)
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

function metal_titles()
    local ret = {}
    for i,v in ipairs(df.global.world.raws.inorganics) do
        if v.material.flags.IS_METAL then
            local t = capitalize(v.material.state_name[0])
            table.insert(ret, t)
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

function metalore_titles()
    local ret = {}
    for i,v in ipairs(df.global.world.raws.inorganics) do
        if v.flags.METAL_ORE then
            local t = capitalize(v.material.state_name[0])
            table.insert(ret, t)
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

function economic_titles()
    local ret = {}
    for i,v in ipairs(df.global.world.raws.inorganics) do
        if v.material.flags.IS_STONE and not v.flags.METAL_ORE and #v.economic_uses>0 then
            local t = capitalize(v.material.state_name[0])
            table.insert(ret, t)
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

function otherstone_titles()
    local ret = {}
    for i,v in ipairs(df.global.world.raws.inorganics) do
        if v.material.flags.IS_STONE and not v.material.flags.NO_STONE_STOCKPILE and not v.flags.METAL_ORE and #v.economic_uses==0 then
            local t = capitalize(v.material.state_name[0])
            table.insert(ret, t)
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

--todo: is this the right way?
function clay_titles()
    local ret = {}
    for i,v in ipairs(df.global.world.raws.inorganics) do
        if v.flags.SOIL and #v.material.reaction_product.id>0 and v.material.reaction_product.id[0].value=='FIRED_MAT' then
            local t = capitalize(v.material.state_name[0])
            table.insert(ret, t)
        end
    end

    return ret
end

function animal_to_creature_idx(pos)
    local ret = {}
    for i,v in ipairs(df.global.world.raws.creatures.all) do
        --todo: is this correct?
        if not v.flags.CASTE_FEATURE_BEAST and not v.flags.CASTE_NIGHT_CREATURE_ANY and not v.flags.CASTE_DEMON and not v.flags.CASTE_TITAN and not v.flags.EQUIPMENT_WAGON then
            table.insert(ret, i)
            if pos and #ret == pos then
                return i
            end
        end
    end

    return ret
end

--todo: game uses plural when in Animals group and singular when in Refuse group
function animal_titles()
    local ret = {}
    for i,v in ipairs(df.global.world.raws.creatures.all) do
        --todo: is this correct?
        if not v.flags.CASTE_FEATURE_BEAST and not v.flags.CASTE_NIGHT_CREATURE_ANY and not v.flags.CASTE_DEMON and not v.flags.CASTE_TITAN and not v.flags.EQUIPMENT_WAGON then
            local t = capitalize(v.name[0])
            table.insert(ret, t)
        end
    end

    return ret
end

--todo: use mat_table.organic_types.Plants
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

function foodplant_titles()
    local ret = {}
    for i,v in ipairs(df.global.world.raws.plants.all) do
        local flags = v.flags
        if flags.SPRING or flags.SUMMER or flags.AUTUMN or flags.WINTER then
            local t = capitalize(v.name)
            table.insert(ret, t)
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

function tree_titles()
    local ret = {}
    for i,v in ipairs(df.global.world.raws.plants.all) do
        if v.flags.TREE then
            local t = capitalize(v.name_plural)
            table.insert(ret, t)
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

function refusetype_to_itemtype_idx(pos)
    if pos then
        return refuse_types[pos]
    end
    return refuse_types
end

local function refuse_type_titles()
    return {
        'Remains',
        'Meat',
        'Fish',
        'Raw Fish',
        'Seeds',
        'Plants',
        'Leaves',
        'Cheese',
        'Prepared Meals',
        'Eggs',
        'Logs',
        'Doors',
        'Floodgates',
        'Beds',
        'Thrones',
        'Chains',
        'Flasks',
        'Goblets',
        'Musical Instruments',
        'Toys',
        'Windows',
        'Cages',
        'Barrels',
        'Buckets',
        'Animal Traps',
        'Tables',
        'Coffins',
        'Statues',
        'Weapons',
        'Armor',
        'Footwear',
        'Shields / Bucklers',
        'Headwear',
        'Handwear',
        'Boxes and Bags',
        'Bins',
        'Armor Stands',
        'Weapon Racks',
        'Cabinets',
        'Figurines',
        'Amulets',
        'Scepters',
        'Ammunition',
        'Crowns',
        'Rings',
        'Earrings',
        'Bracelets',
        'Large Gems',
        'Anvils',
        'Small Live Animals',
        'Small Tame Animals',
        'Tanned Hides',
        'Thread',
        'Cloth',
        'Totems',
        'Legwear',
        'Backpacks',
        'Quivers',
        'Catapult Parts',
        'Ballista Parts',
        'Siege Ammo',
        'Ballista Arrow Heads',
        'Mechanisms',
        'Trap Components',
        'Drinks',
        'Powder',
        'Liquid',
        'Coins',
        'Glob',
        'Pipe Sections',
        'Hatch Covers',
        'Grates',
        'Querns',
        'Millstones',
        'Splints',
        'Crutches',
        'Traction Benches',
        'Tools',
        'Slabs',
        'Books',
    }  
end

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

function goods_to_itemtype_idx(pos)
    if pos then
        return goods_types[pos]
    end
    return goods_types
end

function goods_titles()
    return {
    'Chains',
    'Flasks',
    'Goblets',
    'Musical Instruments',
    'Toys',
    'Armor',
    'Footwear',
    'Headwear',
    'Handwear',
    'Figurines',
    'Amulets',
    'Scepters',
    'Crowns',
    'Rings',
    'Earrings',
    'Bracelets',
    'Large Gems',
    'Totems',
    'Legwear',
    'Backpacks',
    'Quivers',
    'Splints',
    'Crutches',
    'Tools',
    'Books'
}
end

local function itemdef_titles(defs)
    local ret = {}

    for i,v in ipairs(defs) do
        local t = capitalize((#v.adjective>0 and (v.adjective .. ' ') or '') .. v.name_plural)
        table.insert(ret, t)
    end

    return ret
end

function ammo_type_titles()
    return itemdef_titles(df.global.world.raws.itemdefs.ammo)
end

function weapon_titles()
    return itemdef_titles(df.global.world.raws.itemdefs.weapons)
end

function trapcomp_titles()
    return itemdef_titles(df.global.world.raws.itemdefs.trapcomps)
end

function armor_titles()
    return itemdef_titles(df.global.world.raws.itemdefs.armor)
end
function headwear_titles()
    return itemdef_titles(df.global.world.raws.itemdefs.helms)
end
function footwear_titles()
    return itemdef_titles(df.global.world.raws.itemdefs.shoes)
end
function handwear_titles()
    return itemdef_titles(df.global.world.raws.itemdefs.gloves)
end
function legwear_titles()
    return itemdef_titles(df.global.world.raws.itemdefs.pants)
end
function shield_titles()
    return itemdef_titles(df.global.world.raws.itemdefs.shields)
end

--luacheck: in=number,number,string
function organic_titles_prefixstate(group, state, suffix)
    local types = df.global.world.raws.mat_table.organic_types[group]
    local indexes = df.global.world.raws.mat_table.organic_indexes[group]
    
    local ret = {}
    
    for i=0,#types-1 do
        local mi = dfhack.matinfo.decode(types[i], indexes[i])
        if mi and mi.material then
            local mat = mi.material
            local t = capitalize((#mat.prefix>0 and (mat.prefix .. ' ') or '') .. mat.state_name[state] .. suffix)
            table.insert(ret, t)
        else
            table.insert(ret, '#unknown#')
        end
    end

    return ret
end

function organic_leather_titles()
    return organic_titles_prefixstate('Leather', 0, '')
end

function organic_meat_titles()
    local types = df.global.world.raws.mat_table.organic_types.Meat
    local indexes = df.global.world.raws.mat_table.organic_indexes.Meat
    
    --xxx: we skip first two mats in the list because they seem to be placeholders for these two hardcoded options
    local ret = { 'Meat', 'Prepared Eye' }
    
    for i=2,#types-1 do
        local mi = dfhack.matinfo.decode(types[i], indexes[i])
        if mi and mi.material then
            local mat = mi.material
            local t = capitalize((#mat.meat_name[2]>0 and (mat.meat_name[2] .. ' ') or '') .. (#mat.prefix>0 and (mat.prefix .. ' ') or '') .. mat.meat_name[0])
            table.insert(ret, t)
        else
            table.insert(ret, '#unknown#')
        end
    end

    return ret
end

function organic_fish_titles()
    local types = df.global.world.raws.mat_table.organic_types.Fish
    local indexes = df.global.world.raws.mat_table.organic_indexes.Fish
    
    local ret = {}

    for i=0,#types-1 do
        local raw = df.global.world.raws.creatures.all[types[i]]
        if raw then
            local caste = raw.caste[indexes[i]]
            local t = capitalize(caste.caste_name[0])
            if caste.gender == 0 then
                t = t .. ', ' .. SYMBOL_FEMALE
            elseif caste.gender == 1 then
                t = t .. ', ' .. SYMBOL_MALE
            end
            table.insert(ret, t)
        end
    end

    return ret
end

function organic_rawfish_titles()
    local types = df.global.world.raws.mat_table.organic_types.UnpreparedFish
    local indexes = df.global.world.raws.mat_table.organic_indexes.UnpreparedFish
    
    local ret = {}

    for i=0,#types-1 do
        local raw = df.global.world.raws.creatures.all[types[i]]
        if raw then
            local caste = raw.caste[indexes[i]]
            local t = 'Unprepared Raw ' .. capitalize(caste.caste_name[0])
            if caste.gender == 0 then
                t = t .. ', ' .. SYMBOL_FEMALE
            elseif caste.gender == 1 then
                t = t .. ', ' .. SYMBOL_MALE
            end
            table.insert(ret, t)
        end
    end

    return ret
end

function organic_egg_titles()
    local types = df.global.world.raws.mat_table.organic_types.Eggs
    local indexes = df.global.world.raws.mat_table.organic_indexes.Eggs
    
    local ret = {}
    
    for i=0,#types-1 do
        local raw = df.global.world.raws.creatures.all[types[i]]
        if raw then
            local caste = raw.caste[indexes[i]]
            local t = capitalize(caste.caste_name[0] .. ' egg')
            table.insert(ret, t)
        end
    end

    return ret
end

function organic_silk_thread_titles()
    return organic_titles_prefixstate('Silk', 0, ' thread')
end

function organic_silk_cloth_titles()
    return organic_titles_prefixstate('Silk', 0, ' cloth')
end

function organic_plantfiber_thread_titles()
    return organic_titles_prefixstate('PlantFiber', 0, ' thread')
end

function organic_plantfiber_cloth_titles()
    return organic_titles_prefixstate('PlantFiber', 0, ' cloth')
end

function organic_yarn_thread_titles()
    return organic_titles_prefixstate('Yarn', 0, ' thread')
end

function organic_yarn_cloth_titles()
    return organic_titles_prefixstate('Yarn', 0, ' cloth')
end

function organic_metalthread_thread_titles()
    return organic_titles_prefixstate('MetalThread', 0, ' strands')
end

function organic_metalthread_cloth_titles()
    return organic_titles_prefixstate('MetalThread', 0, ' cloth')
end

function organic_plantdrink_titles()
    return organic_titles_prefixstate('PlantDrink', 'Liquid', '')
end

function organic_creaturedrink_titles()
    return organic_titles_prefixstate('CreatureDrink', 'Liquid', '')
end

function organic_plantcheese_titles()
    return organic_titles_prefixstate('PlantCheese', 0, '')
end

function organic_creaturecheese_titles()
    return organic_titles_prefixstate('CreatureCheese', 0, '')
end

function organic_seed_titles()
    local types = df.global.world.raws.mat_table.organic_types.Seed
    local indexes = df.global.world.raws.mat_table.organic_indexes.Seed
    
    local ret = {}
    
    for i=0,#types-1 do
        local mi = dfhack.matinfo.decode(types[i], indexes[i])
        if mi and mi.plant then
            local t = capitalize(mi.plant.seed_plural)
            table.insert(ret, t)
        else
            table.insert(ret, '#unknown#')
        end
    end

    return ret
end

function organic_leaf_titles()
    local types = df.global.world.raws.mat_table.organic_types.Leaf
    local indexes = df.global.world.raws.mat_table.organic_indexes.Leaf
    
    local ret = {}
    
    for i=0,#types-1 do
        local mi = dfhack.matinfo.decode(types[i], indexes[i])
        if mi and mi.plant then
            local t = nil
            for j,growth in ipairs(mi.plant.growths) do
                if growth.str_growth_item[3] == mi.material.id then
                    t = growth.name
                    break
                end
            end
            t = t or ((#mat.prefix>0 and (mat.prefix .. ' ') or '') .. mat.state_name[state] .. suffix)
            t = capitalize(t)
            table.insert(ret, t)
        else
            table.insert(ret, '#unknown#')
        end
    end

    return ret
end

function organic_plantpowder_titles()
    return organic_titles_prefixstate('PlantPowder', 'Powder', '')
end

function organic_creaturepowder_titles()
    return organic_titles_prefixstate('CreaturePowder', 'Powder', '')
end

function organic_glob_titles()
    return organic_titles_prefixstate('Glob', 0, '')
end

function organic_paste_titles()
    return organic_titles_prefixstate('Paste', 'Paste', '')
end

function organic_pressed_titles()
    return organic_titles_prefixstate('Pressed', 'Pressed', '')
end

function organic_plantliquid_titles()
    return organic_titles_prefixstate('PlantLiquid', 'Liquid', '')
end

function organic_animalliquid_titles()
    return organic_titles_prefixstate('CreatureLiquid', 'Liquid', '')
end

function organic_miscliquid_titles()
    return organic_titles_prefixstate('MiscLiquid', 'Liquid', '')
end

function sheet_paper_titles()
    return organic_titles_prefixstate(37, 0, ' sheet')
end

function sheet_parchment_titles()
    return organic_titles_prefixstate(38, 0, ' sheet')
end

function inorganic_titles()
    local ret = {}
    for i,v in ipairs(df.global.world.raws.inorganics) do
        local t = capitalize(v.material.state_name[0])
        table.insert(ret, t)
    end    

    return ret
end

--todo: should cache this
function stockpile_settings_schema()
    local ret =
    {
        {
            'Animals', 'animals',
            {
                { 'Animals', 'enabled', #df.global.world.raws.creatures.all, animal_to_creature_idx, animal_titles }
            },
            {
                { 'Empty Cages', 'empty_cages' }, { 'Empty Animal Traps', 'empty_traps' }
            }
        },
    
        {
            'Food', 'food', 
            {
                { 'Meat', 'meat', #df.global.world.raws.mat_table.organic_types.Meat, nil, organic_meat_titles },
                { 'Fish', 'fish', #df.global.world.raws.mat_table.organic_types.Fish, nil, organic_fish_titles },
                { 'Unprepared Fish', 'unprepared_fish', #df.global.world.raws.mat_table.organic_types.UnpreparedFish, nil, organic_rawfish_titles  },
                { 'Egg', 'egg', #df.global.world.raws.mat_table.organic_types.Eggs, nil, organic_egg_titles },
                { 'Plants', 'plants', #df.global.world.raws.mat_table.organic_types.Plants, foodplant_to_plant_idx, foodplant_titles },
                { 'Drink (Plant)', 'drink_plant', #df.global.world.raws.mat_table.organic_types.PlantDrink, nil, organic_plantdrink_titles },
                { 'Drink (Animal)', 'drink_animal', #df.global.world.raws.mat_table.organic_types.CreatureDrink, nil, organic_creaturedrink_titles },
                { 'Cheese (Plant)', 'cheese_plant', #df.global.world.raws.mat_table.organic_types.PlantCheese, nil, organic_plantcheese_titles },
                { 'Cheese (Animal)', 'cheese_animal', #df.global.world.raws.mat_table.organic_types.CreatureCheese, nil, organic_creaturecheese_titles },
                { 'Seeds', 'seeds', #df.global.world.raws.mat_table.organic_types.Seed, nil, organic_seed_titles },
                { 'Fruit/Leaves', 'leaves', #df.global.world.raws.mat_table.organic_types.Leaf, nil, organic_leaf_titles },
                { 'Milled Plant', 'powder_plant', #df.global.world.raws.mat_table.organic_types.PlantPowder, nil, organic_plantpowder_titles },
                { 'Bone Meal', 'powder_creature', #df.global.world.raws.mat_table.organic_types.CreaturePowder, nil, organic_creaturepowder_titles },
                { 'Fat', 'glob', #df.global.world.raws.mat_table.organic_types.Glob, nil, organic_glob_titles },
                { 'Paste', 'glob_paste', #df.global.world.raws.mat_table.organic_types.Paste, nil, organic_paste_titles },
                { 'Pressed Material', 'glob_pressed', #df.global.world.raws.mat_table.organic_types.Pressed, nil, organic_pressed_titles },
                { 'Extract (Plant)', 'liquid_plant', #df.global.world.raws.mat_table.organic_types.PlantLiquid, nil, organic_plantliquid_titles },
                { 'Extract (Animal)', 'liquid_animal', #df.global.world.raws.mat_table.organic_types.CreatureLiquid, nil, organic_animalliquid_titles },
                { 'Misc. Liquid', 'liquid_misc', #df.global.world.raws.mat_table.organic_types.MiscLiquid, nil, organic_miscliquid_titles },
            },
            {
                { 'Prepared Food', 'prepared_meals' }
            }
        },
    
        {
            'Furniture & Siege Ammo', 'furniture',
            {
                { 'Type', 'type', #furniture_type, nil, furniture_type_titles },
    
                { 'Stone & Clay', 'mats', #df.global.world.raws.inorganics, stoneclay_to_mat_idx, stoneclay_titles },
                { 'Metal', 'mats', #df.global.world.raws.inorganics, metal_to_mat_idx, metal_titles },
                
                { 'Other Materials', 'other_mats', #furniture_other_materials, nil, furniture_other_material_titles },
                
                { 'Core Quality', 'quality_core', item_quality, nil, quality_titles },
                { 'Total Quality', 'quality_total', item_quality, nil, quality_titles }
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
                { 'Type', 'type', df.item_type._last_item+1, refusetype_to_itemtype_idx, refuse_type_titles }, --todo: in game it's 112 somehow
    
                --todo: all filtered 799->655
                { 'Corpses', 'corpses', #df.global.world.raws.creatures.all, animal_to_creature_idx, animal_titles },
                { 'Body Parts', 'body_parts', #df.global.world.raws.creatures.all, animal_to_creature_idx, animal_titles },
                { 'Skulls', 'skulls', #df.global.world.raws.creatures.all, animal_to_creature_idx, animal_titles },
                { 'Bones', 'bones', #df.global.world.raws.creatures.all, animal_to_creature_idx, animal_titles },
                { 'Shells', 'shells', #df.global.world.raws.creatures.all, animal_to_creature_idx, animal_titles },
                { 'Teeth', 'teeth', #df.global.world.raws.creatures.all, animal_to_creature_idx, animal_titles },
                { 'Horns & Hooves', 'horns', #df.global.world.raws.creatures.all, animal_to_creature_idx, animal_titles },
                { 'Hair & Wool', 'hair', #df.global.world.raws.creatures.all, animal_to_creature_idx, animal_titles },
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
                { 'Metal Ores', 'mats', #df.global.world.raws.inorganics, metalore_to_mat_idx, metalore_titles },
                { 'Economic', 'mats', #df.global.world.raws.inorganics, economic_to_mat_idx, economic_titles },
                { 'Other Stone', 'mats', #df.global.world.raws.inorganics, otherstone_to_mat_idx, otherstone_titles },
                { 'Clay', 'mats', #df.global.world.raws.inorganics, clay_to_mat_idx, clay_titles },
            },
            {
            }
        },    
    
        {
            'Ammo', 'ammo',
            {
                { 'Type', 'type', #df.global.world.raws.itemdefs.ammo, nil, ammo_type_titles },
                
                { 'Metal', 'mats', #df.global.world.raws.inorganics, metal_to_mat_idx, metal_titles },
                { 'Other Materials', 'other_mats', #ammo_other_materials, nil, ammo_other_material_titles },
                
                { 'Core Quality', 'quality_core', item_quality, nil, quality_titles },
                { 'Total Quality', 'quality_total', item_quality, nil, quality_titles }
            },
            {
            }
        },
    
        {
            'Coins', 'coins',
            {
                { 'Coins', 'mats', #df.global.world.raws.inorganics, nil, inorganic_titles },
            },
            {
            }
        },
    
        {
            'Bars & Blocks', 'bars_blocks',
            {
                { 'Bars - Metal', 'bars_mats', #df.global.world.raws.inorganics, metal_to_mat_idx, metal_titles },
                { 'Bars - Other Materials', 'bars_other_mats', #bars_other_materials, nil, bars_other_material_titles },
                { 'Blocks - Stone & Clay', 'blocks_mats', #df.global.world.raws.inorganics, stoneclay_to_mat_idx, stoneclay_titles },
                { 'Blocks - Metal', 'blocks_mats', #df.global.world.raws.inorganics, metal_to_mat_idx, metal_titles },
                { 'Blocks - Other Materials', 'blocks_other_mats', #blocks_other_materials, nil, blocks_other_material_titles }
            },
            {
            }
        },
    
        {
            'Gems', 'gems',
            {
                { 'Rough Gem', 'rough_mats', #df.global.world.raws.inorganics, gem_to_mat_idx, gem_titles },
                { 'Rough Glass', 'rough_other_mats', #df.global.world.raws.mat_table.builtin, glass_to_builtin_idx, glass_titles },
                { 'Cut Gem', 'cut_mats', #df.global.world.raws.inorganics, gem_to_mat_idx, gem_titles },
                { 'Cut Glass', 'cut_other_mats', #df.global.world.raws.mat_table.builtin, glass_to_builtin_idx, glass_titles },
                { 'Cut Stone', 'cut_mats', #df.global.world.raws.inorganics, stoneclay_to_mat_idx, stoneclay_titles },
            },
            {
            }
        },
    
        {
            'Finished Goods', 'finished_goods',
            {
                { 'Type', 'type', df.item_type._last_item+1, goods_to_itemtype_idx, goods_titles },
    
                { 'Stone & Clay', 'mats', #df.global.world.raws.inorganics, stoneclay_to_mat_idx, stoneclay_titles },
                { 'Metal', 'mats', #df.global.world.raws.inorganics, metal_to_mat_idx, metal_titles },
                { 'Gem', 'mats', #df.global.world.raws.inorganics, gem_to_mat_idx, gem_titles },
    
                { 'Other Materials', 'other_mats', #goods_other_materials, nil, goods_other_material_titles },
                
                { 'Core Quality', 'quality_core', item_quality, nil, quality_titles },
                { 'Total Quality', 'quality_total', item_quality, nil, quality_titles }
            },
            {
            }
        },        
    
        {
            'Leather', 'leather',
            {
                { 'Leather', 'mats', #df.global.world.raws.mat_table.organic_types.Leather, nil, organic_leather_titles }
            },
            {
            }
        },       
    
        {
            'Cloth', 'cloth',
            {
                { 'Thread - Silk', 'thread_silk', #df.global.world.raws.mat_table.organic_types.Silk, nil, organic_silk_thread_titles },
                { 'Thread - Plant', 'thread_plant', #df.global.world.raws.mat_table.organic_types.PlantFiber, nil, organic_plantfiber_thread_titles },
                { 'Thread - Yarn', 'thread_yarn', #df.global.world.raws.mat_table.organic_types.Yarn, nil, organic_yarn_thread_titles },
                { 'Thread - Metal', 'thread_metal', #df.global.world.raws.mat_table.organic_types.MetalThread, nil, organic_metalthread_thread_titles },
    
                { 'Cloth - Silk', 'cloth_silk', #df.global.world.raws.mat_table.organic_types.Silk, nil, organic_silk_cloth_titles },
                { 'Cloth - Plant', 'cloth_plant', #df.global.world.raws.mat_table.organic_types.PlantFiber, nil, organic_plantfiber_cloth_titles },
                { 'Cloth - Yarn', 'cloth_yarn', #df.global.world.raws.mat_table.organic_types.Yarn, nil, organic_yarn_cloth_titles },
                { 'Cloth - Metal', 'cloth_metal', #df.global.world.raws.mat_table.organic_types.MetalThread, nil, organic_metalthread_cloth_titles },
            },
            {
            }
        },    
    
        {
            'Wood', 'wood',
            {
                { 'Wood', 'mats', #df.global.world.raws.plants.all, tree_to_plant_idx, tree_titles }
            },
            {
            }
        },    
    
        {
            'Weapons & Trap Components', 'weapons',
            {
                { 'Weapons', 'weapon_type', #df.global.world.raws.itemdefs.weapons, nil, weapon_titles },
                { 'Trap Components', 'trapcomp_type', #df.global.world.raws.itemdefs.trapcomps, nil, trapcomp_titles },
                
                { 'Metal', 'mats', #df.global.world.raws.inorganics, metal_to_mat_idx, metal_titles },
                { 'Stone', 'mats', #df.global.world.raws.inorganics, stoneclay_to_mat_idx, stoneclay_titles },
                { 'Other Materials', 'other_mats', #weapons_other_materials, nil, weapons_other_material_titles },
                
                { 'Core Quality', 'quality_core', item_quality, nil, quality_titles },
                { 'Total Quality', 'quality_total', item_quality, nil, quality_titles }
            },
            {
                { 'Usable', 'usable' }, { 'Unusable', 'unusable' }
            }
        },    
    
        {
            'Armor', 'armor',
            {
                { 'Body', 'body', #df.global.world.raws.itemdefs.armor, nil, armor_titles },
                { 'Head', 'head', #df.global.world.raws.itemdefs.helms, nil, headwear_titles },
                { 'Feet', 'feet', #df.global.world.raws.itemdefs.shoes, nil, footwear_titles },
                { 'Hands', 'hands', #df.global.world.raws.itemdefs.gloves, nil, handwear_titles },
                { 'Legs', 'legs', #df.global.world.raws.itemdefs.pants, nil, legwear_titles },
                { 'Sheilds', 'shield', #df.global.world.raws.itemdefs.shields, nil, shield_titles },
                
                { 'Metal', 'mats', #df.global.world.raws.inorganics, metal_to_mat_idx, metal_titles },
                { 'Other Materials', 'other_mats', #weapons_other_materials, nil, weapons_other_material_titles  },
                
                { 'Core Quality', 'quality_core', item_quality, nil, quality_titles },
                { 'Total Quality', 'quality_total', item_quality, nil, quality_titles }
            },
            {
                { 'Usable', 'usable' }, { 'Unusable', 'unusable' }
            }
        },
    }

    if df_ver >= 4200 then --dfver:4200-
        table.insert(ret,
        {
            'Sheet', 'sheet',
            {
                { 'Paper', 'paper', #df.global.world.raws.mat_table.organic_types[37], nil, sheet_paper_titles },
                { 'Parchment', 'parchment', #df.global.world.raws.mat_table.organic_types[38], nil, sheet_parchment_titles },
            },
            {
            }
        })
    end

    return ret
end

--luacheck: in=
function building_stockpile_getsettings()
    local ws = screen_main()
    if ws._type ~= df.viewscreen_dwarfmodest then
        error(errmsg_wrongscreen(ws))
    end

    if df.global.ui.main.mode ~= df.ui_sidebar_mode.QueryBuilding or df.global.world.selected_building == nil then
        error('no selected building')
    end

    local bld = df.global.world.selected_building --as:df.building_stockpilest
    if bld._type ~= df.building_stockpilest then
        error('not a stockpile '..tostring(bld))
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
            local toplevel_obj = ss[toplevel_field] --as:bool[][]
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

                local has_level3 = group[5] ~= nil

                --todo: maybe not return empty categories? but then need to remove them form schema or adjust index in building_stockpile_setenabled() 
                --if num_all > 0 then
                    table.insert(grps, { group_name, num_enabled, num_all, has_level3 })
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

--luacheck: in=number,number
function building_stockpile_getsettings_level3(l1, l2)
    local ws = screen_main()
    if ws._type ~= df.viewscreen_dwarfmodest then
        error(errmsg_wrongscreen(ws))
    end

    if df.global.ui.main.mode ~= df.ui_sidebar_mode.QueryBuilding or df.global.world.selected_building == nil then
        error('no selected building')
    end

    local bld = df.global.world.selected_building --as:df.building_stockpilest
    if bld._type ~= df.building_stockpilest then
        error('not a stockpile '..tostring(bld))
    end

    local ss = bld.settings

    local toplevel = stockpile_settings_schema()[l1+1]
    local toplevel_field = toplevel[2]
    local toplevel_obj = ss[toplevel_field] --as:bool[][]

    local group = toplevel[3][l2+1]
    local list = toplevel_obj[group[2]]

    local titles = group[5]()

    local idx_fn = group[4] or function(i) return i-1 end

    local ret = {}
    for i,v in ipairs(titles) do
        table.insert(ret, { dfhack.df2utf(v), list[idx_fn(i)] })
    end

    return ret
end

--todo: support passing path as the first param
--luacheck: in=
function building_stockpile_setenabled(...)
    local ws = screen_main()
    if ws._type ~= df.viewscreen_dwarfmodest then
        error(errmsg_wrongscreen(ws))
    end

    if df.global.ui.main.mode ~= df.ui_sidebar_mode.QueryBuilding or df.global.world.selected_building == nil then
        error('no selected building')
    end

    local bld = df.global.world.selected_building --as:df.building_stockpilest
    if bld._type ~= df.building_stockpilest then
        error('not a stockpile '..tostring(bld))
    end

    local path = table.pack(...) --as:number[]
    local enabled = istrue(path[#path])
    path[#path] = nil

    local ss = bld.settings

    if #path == 1 then
        local p1 = path[1]
        local toplevel = stockpile_settings_schema()[p1+1]
        local toplevel_field = toplevel[2]

        ss.flags[toplevel_field] = enabled

        if #toplevel[3] > 0 or #toplevel[4] > 0 then
            local toplevel_obj = ss[toplevel_field] --as:bool[][]

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
        local toplevel_obj = ss[toplevel_field] --as:bool[][]

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
        local toplevel_obj = ss[toplevel_field] --as:bool[][]

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

--luacheck: in=number,number,bool
function building_stockpile_setflag(group, flag, enabled)
    local ws = screen_main()
    if ws._type ~= df.viewscreen_dwarfmodest then
        error(errmsg_wrongscreen(ws))
    end

    if df.global.ui.main.mode ~= df.ui_sidebar_mode.QueryBuilding or df.global.world.selected_building == nil then
        error('no selected building')
    end

    local bld = df.global.world.selected_building --as:df.building_stockpilest
    if bld._type ~= df.building_stockpilest then
        error('not a stockpile '..tostring(bld))
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
    local toplevel_obj = ss[toplevel_field] --as:bool[][]

    local flags = toplevel[4]
    local flag_field = flags[flag + 1][2]

    toplevel_obj[flag_field] = enabled

    return true
end

--luacheck: in=number,number,number
function building_stockpile_setmax(barrels, bins, wheelbarrows)
    local ws = screen_main()
    if ws._type ~= df.viewscreen_dwarfmodest then
        error(errmsg_wrongscreen(ws))
    end

    if df.global.ui.main.mode ~= df.ui_sidebar_mode.QueryBuilding or df.global.world.selected_building == nil then
        error('no selected building')
    end

    local bld = df.global.world.selected_building --as:df.building_stockpilest
    if bld._type ~= df.building_stockpilest then
        error('not a stockpile '..tostring(bld))
    end

    bld.max_barrels = barrels
    bld.max_bins = bins
    bld.max_wheelbarrows = wheelbarrows

    return true
end

--luacheck: in=
function building_stockpile_create()
    df.global.ui.main.mode = df.ui_sidebar_mode.Default

    local ws = dfhack.gui.getCurViewscreen()
    gui.simulateInput(ws, K'D_STOCKPILES')    
end