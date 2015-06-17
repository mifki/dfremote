require 'remote.alerts'
require 'remote.squads'
require 'remote.equipment'
require 'remote.ammunition'
require 'remote.uniforms'
require 'remote.schedule'



function get_mil_ws()
    local ws = dfhack.gui.getCurViewscreen()
    
    if ws._type == df.viewscreen_layer_militaryst then
        return ws
    end

    if ws._type == df.viewscreen_dwarfmodest then
        df.global.ui.main.mode = 0
        gui.simulateInput(ws, 'D_MILITARY')
        return dfhack.gui.getCurViewscreen()
    end
end

function get_uniform_additem(t)
    local ret = {}

    local ws = dfhack.gui.getCurViewscreen()
    gui.simulateInput(ws, 'D_MILITARY_UNIFORMS')
    gui.simulateInput(ws, 'D_MILITARY_ADD_'..t)
    --[[
    D_MILITARY_ADD_ARMOR,
        D_MILITARY_ADD_PANTS,
        D_MILITARY_ADD_HELM,
        D_MILITARY_ADD_GLOVES,
        D_MILITARY_ADD_BOOTS,
        D_MILITARY_ADD_SHIELD,
        D_MILITARY_ADD_WEAPON,
    ]]

    local num = #ws.equip.add_item.type

    for i = 0,num-1 do

        if ws.equip.add_item.subtype[i] ~= -1 then
            local it = dfhack.items.getSubtypeDef(ws.equip.add_item.type[i], ws.equip.add_item.subtype[i])

            --todo: shields/bucklers
            local pts = {}
            if it.adjective ~= '' then table.insert(pts, it.adjective) end
            pcall(function() if it.material_placeholder ~= '' then table.insert(pts, it.material_placeholder) end end)
            table.insert(pts, it.name_plural)
            local title = table.concat(pts, ' ')

            if ws.equip.add_item.foreign[i] then
                title = title .. ' (foreign)'
            end

            table.insert(ret, title)
        else
            --todo: unk_214
            table.insert(ret, (df.item_type.attrs[ws.equip.add_item.type[i]].caption))
        end
    end

    return ret
end

function get_uniform_additem_all()
    local ret = {}

    ret.armor = get_uniform_additem('ARMOR')
    ret.pants = get_uniform_additem('PANTS')
    ret.helm = get_uniform_additem('HELM')
    ret.gloves = get_uniform_additem('GLOVES')
    ret.boots = get_uniform_additem('BOOTS')
    ret.shield = get_uniform_additem('SHIELD')
    ret.weapon = get_uniform_additem('WEAPON')

    return ret
end

local uniform_material_classes = {}
for i,v in ipairs(df.entity_material_category) do
    uniform_material_classes[i] = v:lower()
end
uniform_material_classes[16] = 'metal'

function uniform_item_name(type, subtype, info)
    
    --printall(info)
    local pts = {}

    if info.item_color ~= -1 then
        --todo: '(Dye)'
        table.insert(pts, df.global.world.raws.language.colors[info.item_color].name)
    end

    if info.material_class ~= -1 then
        table.insert(pts, uniform_material_classes[info.material_class])
    elseif info.mattype ~= -1 then
        table.insert(pts, dfhack.matinfo.decode(info.mattype, info.matindex).material.state_adj[0])
    end

    if subtype ~= -1 then
            local it = dfhack.items.getSubtypeDef(type, subtype)

            --todo: shields/bucklers
            if it.adjective ~= '' then table.insert(pts, it.adjective) end
            pcall(function() if it.material_placeholder ~= '' then table.insert(pts, it.material_placeholder) end end)
            table.insert(pts, it.name_plural)
        else

            -- These are incorrect in DFHack !!            
            if info.indiv_choice.any then
                table.insert(pts, 'indiv choice, any')
            elseif info.indiv_choice.melee then
                table.insert(pts, 'indiv choice, ranged')
            elseif info.indiv_choice.ranged then
                table.insert(pts, 'indiv choice, melee')
            else
                table.insert(pts, df.item_type.attrs[type].caption)
            end
        end

        local title = table.concat(pts, ' ')

        return title

end

function get_uniform_details(idx)

    local ret = {}

    local uni = df.global.ui.main.fortress_entity.uniforms[idx]

    ret.name = uni.name
    ret.flags = { uni.flags.replace_clothing, uni.flags.exact_matches }

    local num = #uni.uniform_item_types[0]

    ret.items = {}
    for part = 0, #uni.uniform_item_types-1 do
        ret.items[part] = {}

        local num = #uni.uniform_item_types[part]
        for i = 0, num-1 do
            local type = uni.uniform_item_types[part][i]
            local subtype = uni.uniform_item_subtypes[part][i]
            local info = uni.uniform_item_info[part][i]

            table.insert(ret.items[part], uniform_item_name(type, subtype, info))
        end
    end

    return ret
end

function get_uniform_addcolor()
    local ret = {}

    for i,c in ipairs(df.global.world.raws.language.colors) do
        table.insert(ret, c.name)
    end

    return ret
end

function get_uniform_ws_addcolor()
    local ret = {}

    local ws = get_mil_ws()
    gui.simulateInput(ws, 'D_MILITARY_UNIFORMS')
    gui.simulateInput(ws, 'D_MILITARY_ADD_COLOR')

    for i,c in ipairs(ws.equip.color.id) do
        if c ~= -1 then
            local title = df.global.world.raws.language.colors[c].name
            if ws.equip.color.dye[i] then
                title = title .. ' (dye)'
            end
            table.insert(ret, title)
        end
    end    

    return ret
end

function get_uniform_addmaterial()
end