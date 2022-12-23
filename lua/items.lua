function item_is_metal(item)
    local matinfo = dfhack.matinfo.decode(item:getActualMaterial(), item:getActualMaterialIndex())

    return matinfo and (matinfo:getCraftClass() == df.craft_material_class.Metal)
end

-- from plugins/uicommon.h
function item_can_melt(item)
    local f = item.flags
    if f.in_job or f.hostile or f.on_fire or f.rotten or f.trader or f.construction or f.artifact or f.in_building or f.garbage_collect then
        return false
    end

    local t = item:getType()
    if t == df.item_type.BOX or t == df.item_type.BAR then
        return false
    end

    if not item_is_metal(item) then
        return false
    end

    --todo: more checks here ?

    return true
end

function item_is_fort_owned(item)
    if item.flags.spider_web then
        return false
    end

    if item.flags.trader then
        return false
    end

    if item.flags.in_inventory then
        local holder = dfhack.items.getHolderUnit(item)
        if holder and not unit_iscitizen(holder) then
            return false
        end
    end

    return true
end

function item_is_in_stockpile(item, sp)
    local cont = dfhack.items.getContainer(item)
    if cont then
        return item_is_in_stockpile(cont, sp)
    end

    if item.pos.z ~= sp.z or item.pos.x < sp.x1 or item.pos.x >= sp.x2 or item.pos.y < sp.y1 or item.pos.y >= sp.y2 then
        return false
    end

    local e = (item.pos.x - sp.x1) + (item.pos.y - sp.y1) * sp.room.width
    
    return (sp.room.extents[e] == 1)
end

--todo: output for stockpiles should be improved before used in app (currently containers and items inside are mixed)
--todo: make this use bldid too
--luacheck: in=number
function building_get_contained_items(bldid)
    local ws = screen_main()
    if ws._type ~= df.viewscreen_dwarfmodest then
        error(errmsg_wrongscreen(ws))
    end

    if df.global.ui.main.mode ~= 17 or df.global.world.selected_building == nil then
        error('no selected building')
    end

    local ret = {}
    local bld = df.global.world.selected_building

    if bld._type == df.building_stockpilest then
        for i,item in ipairs(df.global.world.items.other.IN_PLAY) do
            --todo: check that the item is owned by the civ
            if item_is_in_stockpile(item,bld) then
                local title = itemname(item, 0, true)

                table.insert(ret, { title, item.id, item.flags.whole, item_can_melt(item) })
            end
        end

    else
        for i,citem in ipairs(bld.contained_items) do --hint:df.building_actual
            local item = citem.item
            local title = itemname(item, 0, true)

            table.insert(ret, { title, item.id, item.flags.whole, item_can_melt(item) })
        end
    end

    return ret
end

--luacheck: in=number,number,bool
function item_action(itemid, action, value)
    local item = df.item:is_instance(itemid) and itemid or df.item.find(itemid) --as:df.item

    if not item then
        error('no item '..tostring(itemid))
    end

    value = istrue(value)

    if action == df.item_flags.forbid or action == df.item_flags.dump or action == df.item_flags.melt or action == df.item_flags.hidden then
        if action == df.item_flags.melt then
            if not item_can_melt(item) then
                return false
            end

            if value and not item.flags.melt then
                utils.insert_sorted(df.global.world.items.other.ANY_MELT_DESIGNATED, item, 'id')
            elseif not value and item.flags.melt then
                utils.erase_sorted(df.global.world.items.other.ANY_MELT_DESIGNATED, item, 'id')
            end

            --todo: any other additional action to update world state?
        end

        item.flags[action] = value

        -- Melt and dump are mutually exclusive
        if value then
            if action == df.item_flags.dump and item.flags.melt then
                item_action(item, item.flags.melt, false)
            elseif action == df.item_flags.melt and item.flags.dump then
                item_action(item, item.flags.dump, false)
            end
        end
    end

    return true
end

item_spatter_sizes = {
    { 0, 'spatter' },
    { 25, 'smear' },
    { 50, 'covering' },
}

--luacheck: in=number
function item_query(itemid)
    local item = df.item.find(itemid) --as:df.item_actual
    if not item then
        error('no item '..tostring(itemid))
    end

    local dispname,realname = itemname(item, 0, true)
    local value = dfhack.items.getValue(item)

    if not item.flags.weight_computed then
        item:calculateWeight()
    end

    local itemscnt = 0
    local unitscnt = 0
    for i,v in ipairs(item.general_refs) do
        if v._type == df.general_ref_contains_itemst then
            itemscnt = itemscnt + 1
        elseif v._type == df.general_ref_contains_unitst then
            unitscnt = unitscnt + 1
        end
    end

    --todo: game shows "water covering" BUT "coating of <name>'s elf blood" for the same spatter size
    local contaminants = {}
    if item.contaminants then
        for i,v in ipairs(item.contaminants) do
            local mi = dfhack.matinfo.decode(v.mat_type, v.mat_index)
            if mi then
                local spattersize = ''
                for k,w in ripairs(item_spatter_sizes) do
                    if v.size >= w[1] then
                        spattersize = ' ' .. w[2]
                        break
                    end
                end

                local creatureprefix = mi.figure and (hfname(mi.figure) .. ' ') or ''

                local matprefix = #mi.material.prefix > 0 and (mi.material.prefix .. ' ') or ''
                local title = creatureprefix .. matprefix .. mi.material.state_name[v.mat_state] .. spattersize

                --todo: any other colors?
                --local c = df.global.world.raws.language.colors[mi.material.state_color[v.mat_state]]
                local color = 2 + 8 --c.color + c.bold*8

                table.insert(contaminants, { title, color })
            end
        end
    end

    return { realname or dispname, item.id, item.flags.whole, item_can_melt(item), realname and dispname or mp.NIL, value, item.weight, itemscnt, unitscnt, contaminants }
end

--luacheck: in=number
function item_get_description(itemid)
    local item = df.item.find(itemid)
    if not item then
        error('no item '..tostring(itemid))
    end

    local itemws = df.viewscreen_itemst:new()
    itemws.item = item
    gui.simulateInput(itemws, K'ITEM_DESCRIPTION')

    df.delete(itemws)

    local ws = dfhack.gui.getCurViewscreen() --as:df.viewscreen_textviewerst

    local text = ''
    
    for i,v in ipairs(ws.src_text) do
        if #v.value > 0 then
            text = text .. dfhack.df2utf(v.value:gsub('%[R]', '[P]')) .. ' '
        end
    end

    --xxx: item description-specific
    text = text:gsub('%s*%[B]%s*$', '')
    text = text:gsub('%s*%[P]%s*$', '')

    text = text:gsub('  ', ' ')

    ws.breakdown_level = df.interface_breakdown_types.STOPSCREEN

    return { text }
end

--luacheck: in=number
function item_get_contained_items(itemid)
    local item = df.item.find(itemid)
    if not item then
        error('no item '..tostring(itemid))
    end

    local ret = {}

    for i,v in ipairs(item.general_refs) do
        if v._type == df.general_ref_contains_itemst then
            local v = v --as:df.general_ref_contains_itemst
            local item = df.item.find(v.item_id)
            if item then
                local title = itemname(item, 0, true)
                table.insert(ret, { title, item.id, item.flags.whole, item_can_melt(item) })
            end
        end
    end

    return ret
end

--luacheck: in=number
function item_get_contained_units(itemid)
    local item = df.item.find(itemid)
    if not item then
        error('no item '..tostring(itemid))
    end

    local ret = {}

    for i,v in ipairs(item.general_refs) do
        if v._type == df.general_ref_contains_unitst then
            local v = v --as:df.general_ref_contains_unitst
            local unit = df.unit.find(v.unit_id)
            if unit then
                local title = unit_fulltitle(unit)
                table.insert(ret, { title, unit.id })
            end
        end
    end

    return ret
end

--luacheck: in=
function artifacts_list()
    local ret = {}

    --todo: what is the correct way to get artifacts?
    for i,item in ipairs(df.global.world.items.other.IN_PLAY) do
        if item.flags.artifact then
            local artname,realname = itemname(item, 0, true)
            if realname then
                table.insert(ret, { realname, item.id, item.flags.whole, false, artname })
            end
        end
    end

    return ret
end

mat_category_names = { --as:string[]
    [df.entity_material_category.None] = 'any material',
    [df.entity_material_category.Leather] = 'leather',
    [df.entity_material_category.Cloth] = 'cloth',
    [df.entity_material_category.Wood] = 'wood',
    [df.entity_material_category.Stone] = 'stone',
    [df.entity_material_category.Ammo2] = 'metal',
    [df.entity_material_category.Armor] = 'metal',
    [df.entity_material_category.Gem] = 'gem',
    [df.entity_material_category.Bone] = 'bone',
    [df.entity_material_category.Shell] = 'shell',
    [df.entity_material_category.Pearl] = 'pearl',
    [df.entity_material_category.Ivory] = 'tooth',
    [df.entity_material_category.Horn] = 'horn',
    [df.entity_material_category.PlantFiber] = 'plant fiber',
    [df.entity_material_category.Silk] = 'silk',
    [df.entity_material_category.Wool] = 'yarn',
}

--todo: implement this without reaction_product_itemst
function generic_item_name(type, subtype, mat_class, mat_type, mat_index, single)
    --local q = df.item:new()
    local q = df.reaction_product_itemst:new()

    q.item_type = type
    q.item_subtype = subtype
    
    --todo: use this in appropriate places
    if single then
        q.count = 1
    end

    if mat_class == -1 then
        q.mat_type = mat_type
        q.mat_index = mat_index
    end
    
    local title = utils.call_with_string(q, 'getDescription')
    q:delete()

    title = title:sub(1, title:find(' %(')-1)
    title = dfhack.df2utf(title)

    if mat_class ~= -1 then
        local n = mat_category_names[mat_class]
        if n then
            title = capitalize(n) .. ' ' .. title:utf8lower()
        end
    end

    return title
end

--luacheck: in=number
function item_zoom(itemid)
    local item = df.item.find(itemid)
    if not item then
        return false
    end

    local x,y,z = dfhack.items.getPosition(item)
    if x ~= -30000 then
        recenter_view(x, y, z)

        local ws = dfhack.gui.getCurViewscreen()
        gui.simulateInput(ws, K'D_LOOK')

        df.global.cursor.x = x
        df.global.cursor.y = y

        if z > 0 then
            df.global.cursor.z = z - 1
            gui.simulateInput(ws, K'CURSOR_UP_Z')        
        else
            df.global.cursor.z = z + 1
            gui.simulateInput(ws, K'CURSOR_DOWN_Z')
        end

        return true
    end

    return false
end

--print(pcall(function() return json:encode(building_get_contained_items()) end))