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

local stocks_category_names = {
    'meat',
    'fish',
    'raw fish',
    'egg',
    'plants',
    'prepared meals',
    'cheese',
    'powder',
    'drinks',
    'leaves',
    'liquid',
    'glob',
    'seeds',
    'weapons',
    'ammunition',
    'armor',
    'legwear',
    'headwear',
    'handwear',
    'footwear',
    'shields/bucklers',
    'backpacks',
    'quivers',
    'anvils',
    'armor stands',
    'weapon racks',
    'cabinets',
    'doors',
    'floodgates',
    'beds',
    'thrones',
    'tables',
    'coffins',
    'statues',
    'slabs',
    'tanned hides',
    'cloth',
    'thread',
    'logs',
    'stones',
    'rough gems',
    'bars',
    'cut gems',
    'large gem',
    'coins',
    'blocks',
    'small tame animal',
    'small live animal',
    'pipe sections',
    'hatch covers',
    'grates',
    'querns',
    'millstones',
    'windows',
    'animal traps',
    'chains',
    'cages',
    'boxes and bags',
    'bins',
    'barrels',
    'buckets',
    'mechanisms',
    'trap components',
    'flasks',
    'goblets',
    'toys',
    'tools',
    'musical instruments',
    'figurines',
    'amulets',
    'scepters',
    'crowns',
    'rings',
    'earrings',
    'bracelets',
    'catapult parts',
    'ballista parts',
    'siege ammo',
    'ballista arrow heads',
    'totems',
    'corpses',
    'body parts',
    'remains',
    'small rock',
    'splints',
    'crutches',
    'traction benches',
    'limb/body casts',
    'books',    
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

    for i,v in ipairs(stocks_category_names) do
        local type = stocks_category_types[i]
        local cat = data.cats[type]
        table.insert(list, { v, type, cat.count, cat.busy })
    end

    local precision = df.global.ui.bookkeeper_precision

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

--luacheck: in=number[],number,number
function stocks_group_action(groupid, action, value)
    local type = groupid[1]
    local subtype = groupid[2]
    local mat_type = groupid[3]
    local mat_index = groupid[4]

    local data = native.itemcache_get().cats[type]

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