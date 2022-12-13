item_type_plural_names = {
    [0] =   'bars',
    [1] =   'cut gems',
    [2] =   'blocks',
    [3] =   'rough gems',
    [4] =   'stones',
    [5] =   'logs',
    [6] =   'doors',
    [7] =   'floodgates',
    [8] =   'beds',
    [9] =   'thrones',
    [10]    =   'chains',
    [11]    =   'flasks',
    [12]    =   'goblets',
    [13]    =   'musical instruments',
    [14]    =   'toys',
    [15]    =   'windows',
    [16]    =   'cages',
    [17]    =   'barrels',
    [18]    =   'buckets',
    [19]    =   'animal traps',
    [20]    =   'tables',
    [21]    =   'coffins',
    [22]    =   'statues',
    [23]    =   'corpses',
    [24]    =   'weapons',
    [25]    =   'armor',
    [26]    =   'footwear',
    [27]    =   'shields/bucklers',
    [28]    =   'headwear',
    [29]    =   'handwear',
    [30]    =   'boxes and bags',
    [31]    =   'bins',
    [32]    =   'armor stands',
    [33]    =   'weapon racks',
    [34]    =   'cabinets',
    [35]    =   'figurines',
    [36]    =   'amulets',
    [37]    =   'scepters',
    [38]    =   'ammunition',
    [39]    =   'crowns',
    [40]    =   'rings',
    [41]    =   'earrings',
    [42]    =   'bracelets',
    [43]    =   'large gem',
    [44]    =   'anvils',
    [45]    =   'body parts',
    [46]    =   'remains',
    [47]    =   'meat',
    [48]    =   'fish',
    [49]    =   'raw fish',
    [50]    =   'small live animal',
    [51]    =   'small tame animal',
    [52]    =   'seeds',
    [53]    =   'plants',
    [54]    =   'tanned hides',
    [55]    =   'leaves',
    [56]    =   'thread',
    [57]    =   'cloth',
    [58]    =   'totems',
    [59]    =   'legwear',
    [60]    =   'backpacks',
    [61]    =   'quivers',
    [62]    =   'catapult parts',
    [63]    =   'ballista parts',
    [64]    =   'siege ammo',
    [65]    =   'ballista arrow heads',
    [66]    =   'mechanisms',
    [67]    =   'trap components',
    [68]    =   'drinks',
    [69]    =   'powder',
    [70]    =   'cheese',
    [71]    =   'prepared meals',
    [72]    =   'liquid',
    [73]    =   'coins',
    [74]    =   'glob',
    [75]    =   'small rock',
    [76]    =   'pipe sections',
    [77]    =   'hatch covers',
    [78]    =   'grates',
    [79]    =   'querns',
    [80]    =   'millstones',
    [81]    =   'splints',
    [82]    =   'crutches',
    [83]    =   'traction benches',
    [84]    =   'limb/body casts',
    [85]    =   'tools',
    [86]    =   'slabs',
    [87]    =   'egg',
    [88]    =   'codices',
    [89]    =   'sheet',
    [90]    =   'branches',
}

local stocks_category_types = {
    47,
    48,
    49,
    87,
    53,
    71,
    70,
    69,
    68,
    55,
    72,
    74,
    52,
    24,
    38,
    25,
    59,
    28,
    29,
    26,
    27,
    60,
    61,
    44,
    32,
    33,
    34,
    6,
    7,
    8,
    9,
    20,
    21,
    22,
    86,
    54,
    57,
    56,
    89,
    5,
    4,
    3,
    0,
    1,
    43,
    73,
    2,
    51,
    50,
    76,
    77,
    78,
    79,
    80,
    15,
    19,
    10,
    16,
    30,
    31,
    17,
    18,
    66,
    67,
    11,
    12,
    14,
    85,
    13,
    35,
    36,
    37,
    39,
    40,
    41,
    42,
    62,
    63,
    64,
    65,
    58,
    23,
    45,
    46,
    75,
    81,
    82,
    83,
    84,
    88,    
}

--luacheck: in=
function stocks_init()
    native.itemcache_init()
end

--luacheck: in=
function stocks_free()
    native.itemcache_free()
end

--luacheck: in=
function stocks_get_categories()
    local data = native.itemcache_get()
    local list = {}

    for i,v in ipairs(stocks_category_types) do
        local name = item_type_plural_names[v]
        local cat = data.cats[v]
        table.insert(list, { name, v, cat.count, cat.busy })
    end

    local precision = df.global.ui.nobles.bookkeeper_precision

    return { list, precision }
end

--luacheck: in=number,bool
function stocks_get_items(type, grouped)
    local data = native.itemcache_get_category(type)

    local ret = {}
    if istrue(grouped) then
        for i,v in ipairs(data.groups_index) do
            table.insert(ret, { dfhack.df2utf(v.title), { v.type, v.subtype, v.mat_type, v.mat_index }, v.flags_all.whole, group_can_melt(v), v.flags_some.whole, v.count })
        end

    else
        for i,v in ipairs(data.groups_index) do
            for j,item in ipairs(v.items) do --as:df.item
                local title = itemname(item, 4, true)

                --todo: check that using flags.in_building is ok and shouldn't rather check the actual ref to the containing building
                --todo: the same for inventory ?
                table.insert(ret, { title, item.id, item.flags.whole, item_can_melt(item), item_is_fort_owned(item) })
            end
        end        
    end

    return ret
end

-- from plugins/uicommon.h
function group_can_melt(group)
    local f = group.flags_all
    if f.in_job or f.hostile or f.on_fire or f.rotten or f.trader or f.construction or f.artifact or f.in_building or f.garbage_collect then
        return false
    end

    local t = group.type
    if t == df.item_type.BOX or t == df.item_type.BAR then
        return false
    end

    local matinfo = dfhack.matinfo.decode(group.mat_type, group.mat_index)
    local metal = matinfo and (matinfo:getCraftClass() == df.craft_material_class.Metal)

    if not metal then
        return false
    end

    --todo: more checks here ?

    return true
end

--luacheck: in=number[],number,bool
function stocks_group_action(groupid, action, value)
    local type = groupid[1]
    local subtype = groupid[2]
    local mat_type = groupid[3]
    local mat_index = groupid[4]

    local data = native.itemcache_get().cats[type]

    value = istrue(value)

    for i,v in ipairs(data.groups_index) do
        if v.subtype == subtype and v.mat_type == mat_type and v.mat_index == mat_index then
            for j,item in ipairs(v.items) do
                item_action(item, action, value)
            end

            --todo: ideally we can check return values of item_action and set or not set these flags accordingly
            --todo: (primarily for melt), but group flags will be updated next time anyway so why bother
            v.flags_all[action] = value
            v.flags_some[action] = value

            -- Melt and dump are mutually exclusive
            if value then
                if action == df.item_flags.dump and v.flags_some.melt then
                    v.flags_all.melt = false
                    v.flags_some.melt = false
                elseif action == df.item_flags.melt and v.flags_some.dump then
                    v.flags_all.dump = false
                    v.flags_some.dump = false
                end
            end

            break
        end
    end
end

--luacheck: in=
function stocks_search(q, grouped)
    local ret = {}

    local data = native.itemcache_search(q)
    if istrue(grouped) then
        for i,v in ipairs(data) do
            table.insert(ret, { dfhack.df2utf(v.title), { v.type, v.subtype, v.mat_type, v.mat_index }, v.flags_all.whole, group_can_melt(v), v.flags_some.whole, v.count })
        end

    else
        for i,v in ipairs(data) do
            for j,item in ipairs(v.items) do --as:df.item
                local title = itemname(item, 4, true)

                table.insert(ret, { title, item.id, item.flags.whole, item_can_melt(item), item_is_fort_owned(item) })
            end
        end        
    end

    data:delete()

    return ret
end