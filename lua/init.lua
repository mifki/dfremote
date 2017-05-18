remote_version = require 'remote.version'

json = require 'remote.JSON'
mp = math.frexp and require 'remote.MessagePack' or require 'remote.MessagePack53'
_ = require 'remote.underscore'

gui = require 'gui'
utils = require 'utils'

df_ver = tonumber(dfhack.DF_VERSION:sub(3,4)..dfhack.DF_VERSION:sub(6,7)) -- 4024, 4303, etc.

require 'remote.compat'

require 'remote.utf8.utf8data'
require 'remote.utf8.utf8'

require 'remote.utils'
require 'remote.screens'
require 'remote.build'
require 'remote.nobles'
require 'remote.military'
require 'remote.status'
require 'remote.kitchen'
require 'remote.depot'
require 'remote.buildings'
require 'remote.stockpile'
require 'remote.units'
require 'remote.jobs'
require 'remote.items'
require 'remote.manager'
require 'remote.orders'
require 'remote.labors'
require 'remote.stone'
require 'remote.animals'
require 'remote.reports'
require 'remote.meeting'
require 'remote.setup'
require 'remote.savegame'
require 'remote.zones'
require 'remote.stocks'
require 'remote.worldgen'
require 'remote.embark'
require 'remote.burrows'
require 'remote.waypoints'
require 'remote.civilizations'
require 'remote.justice'
require 'remote.raws'
require 'remote.hauling'

if df_ver >= 4200 then --dfver:4200-
    require 'remote.locations'
    require 'remote.petitions'
    require 'remote.jobdetails'
end

native = {}
--dfhack.open_plugin(native, 'remote')

local lastblderrstr = ''
local lastblderrsync = 0

lastann = 0
lastannrep = 0
local lastextdata = nil
local extdata = nil

building_btns = {} --as:df.interface_button_construction_building_selectorst[]
designate_cmds = {}

function close_all()
    local ws = dfhack.gui.getCurViewscreen()

    --todo: this has to be in sync with get_status somehow
    if ws._type == df.viewscreen_topicmeeting_takerequestsst then
        return
    end

    if ws._type == df.viewscreen_topicmeetingst then
        return
    end

    if ws.parent._type == df.viewscreen_meetingst or ws.parent._type == df.viewscreen_topicmeetingst then
        return
    end

    if ws._type == df.viewscreen_textviewerst then
        local ws = ws --as:df.viewscreen_textviewerst
        --todo: need to properly handle these screens
        if ws.page_filename == 'data/announcement/fortressintro' or ws.page_filename == 'data/announcement/unretire' then
            gui.simulateInput(ws, K'LEAVESCREEN')
            return
        end

        if ws.page_filename == 'data/help/' then
            gui.simulateInput(ws, K'LEAVESCREEN')
            return
        end

        return
    end

    while ws._type ~= df.viewscreen_dwarfmodest do
        local parent = ws.parent
        parent.child = nil
        ws:delete()
        ws = parent
    end
end

function cancel_to_1st_corner()
    df.global.selection_rect.start_x = -30000
end

function reset_main()
    if dfhack.gui.getCurViewscreen()._type == df.viewscreen_dwarfmodest then
        -- if cancelling flow mode zone creation, need to remove the not-yet-created zone !
        if df.global.ui.main.mode == 42 and df.global.ui_sidebar_menus.zone.selected and df.global.ui_building_in_resize and df.global.ui_sidebar_menus.zone.mode ~= 0 then
            dfhack.buildings.deconstruct(df.global.ui_sidebar_menus.zone.selected)            
        end

        df.global.selection_rect.start_x = -30000
        df.global.ui_build_selector.stage = -1
        df.global.ui_building_in_resize = false
        df.global.ui_building_in_assign = false
        df.global.world.selected_building = nil
        df.global.ui_selected_unit = -1
        df.global.ui_workshop_in_add = false
        C_lever_target_type_set(-1)
        df.global.ui_sidebar_menus.zone.selected = nil
        df.global.ui.main.mode = df.ui_sidebar_mode.Default
        df.global.ui.waypoints.in_edit_waypts_mode = false
        df.global.ui.waypoints.in_edit_name_mode = false
        squads_reset()
    end    
end

local spatter_prefixes = {
    { '', 'a dusting of', 'a small pile of', 'a pile of' },
    { '', 'a spattering of', 'a smear of', 'a pool of' },
    { '', '', '', '' },
    { '', 'a dusting of', 'a small pile of', 'a pile of' },
    { '', 'a dusting of', 'a small pile of', 'a pile of' },
    { '', 'a dusting of', 'a small pile of', 'a pile of' },
}

local flow_type_names = {
    'Miasma',
    'Steam', --for mat_type==1 or Mist otherwise
    'Mist',
    'Material Dust', --customised
    'Lava Mist',
    'Smoke',
    'Dragonfire',
    'Fire',
    'A Web',
    'Material Gas', --customised
    'Material Vapor', --customised
    'Ocean Wave',
    'Sea Foam',
    'Item Cloud'
}

local grass_density_prefix = { 'Sparse ', '', 'Dense ' }

local biome_region_offsets = { {-1,-1}, {0,-1}, {1,-1}, {-1,0}, {0,0}, {1,0}, {-1,1}, {0,1}, {1,1} }

local friendly_shape_names = {
    [df.tiletype_shape.PEBBLES] = 'pebbles',
    [df.tiletype_shape.BOULDER] = 'boulder',
    [df.tiletype_shape.WALL] = 'wall',
    [df.tiletype_shape.FLOOR] = 'floor',
    [df.tiletype_shape.FORTIFICATION] = 'fortification',
    [df.tiletype_shape.STAIR_DOWN] = 'downward stairway',
    [df.tiletype_shape.STAIR_UPDOWN] = 'up/down stairway',
    [df.tiletype_shape.STAIR_UP] = 'upward stairway',
    [df.tiletype_shape.RAMP] = 'upward slope',
    [df.tiletype_shape.RAMP_TOP] = 'downward slope',
}

function ttcaption(tt)
    --todo: handle pillars
    return friendly_shape_names[df.tiletype.attrs[tt].shape] or df.tiletype.attrs[tt].caption    
end

local function coordInTree(tree, x, y, z)
        local x1 = tree.pos.x - math.floor(tree.tree_info.dim_x / 2)
        local x2 = tree.pos.x + math.floor(tree.tree_info.dim_x / 2)
        local y1 = tree.pos.y - math.floor(tree.tree_info.dim_y / 2)
        local y2 = tree.pos.y + math.floor(tree.tree_info.dim_y / 2)
        local z1 = tree.pos.z
        local z2 = tree.pos.z + tree.tree_info.body_height
        local z3 = tree.pos.z - tree.tree_info.roots_depth
        
        if ((x >= x1 and x <= x2) and (y >= y1 and y <= y2) and (z >= z1 and z <= z2)) then
            local t = tree.tree_info.body[z - z1]:_displace((y - y1) * tree.tree_info.dim_x + (x - x1)) --as:df.plant_tree_tile
            return (t.trunk or t.branches or t.thick_branches_1 or t.thick_branches_2 or t.thick_branches_3 or t.thick_branches_4 or t.twigs) and t or nil
        end
        
        if ((x >= x1 and x <= x2) and (y >= y1 and y <= y2) and (z < z1 and z >= z3)) then
            local r = tree.tree_info.roots[z1-z-1]:_displace((y - y1) * tree.tree_info.dim_x + (x - x1)) --as:df.plant_tree_tile
            return r.trunk and r or nil
        end
end

local function find_engraving(x, y, z)
    for i,v in ipairs(df.global.world.engravings) do
        local pos = v.pos
        if pos.x == x and pos.y == y and pos.z == z then
            return v
        end
    end

    return nil
end

local quality_chars = { '', '-', '+', '*', dfhack.df2utf(string.char(240)), dfhack.df2utf(string.char(15)) }

local last_look_x = -1
local last_look_y = -1
local last_look_z = -1
local last_look_list = nil

local last_point_x = -1
local last_point_y = -1
local last_point_z = -1
local last_point_cnt = 0
local last_nearest_point = nil

--todo: maybe check game tick just to be sure?
--todo: tiletypes
--todo: capitalize
function get_look_list(detailed)
    if not detailed and last_look_x == df.global.cursor.x and last_look_y == df.global.cursor.y and last_look_z == df.global.cursor.z and last_look_list then
        return last_look_list
    end

    local ret = {}

    for i,v in ipairs(df.global.ui_look_list.items) do
        local t = v.type

        local title = ''
        local color = 15
        local data = {}

        if t == df.ui_look_list.T_items.T_type.Item then
            local item = v.item

            local ref = dfhack.items.getGeneralRef(item, df.general_ref_type.IS_ARTIFACT) --as:df.general_ref_artifact
            if ref then
                title = translatename(df.artifact_record.find(ref.artifact_id).name)
            else
                title = itemname(item, 0, true)
            end

            color = 6+8
            if detailed then
                data = { item.id, item.flags.whole, item_can_melt(item) }
            end

        elseif t == df.ui_look_list.T_items.T_type.Building then
            title = bldname(v.building)
            color = 1+8
            if detailed then
                local bld = v.building
                data = { bld.id }
            end

        elseif t == df.ui_look_list.T_items.T_type.Unit and v.unit then
            title = unit_fulltitle(v.unit)
            --xxx: game shows all units in white in loo[k] mode
            color = 15 --dfhack.units.getProfessionColor(v.unit)
            if detailed then
                local unit = v.unit
                local job, jobcolor = unit_jobtitle(unit, false)
                data = { unit.id, job, jobcolor }
            end

        elseif t == df.ui_look_list.T_items.T_type.Water then
            if v.spatter_size >= 24 then
                title = 'stagnant salt water ['.. (v.spatter_size%8) ..'/7]'
            elseif v.spatter_size >= 16 then
                title = 'stagnant water ['.. (v.spatter_size%8) ..'/7]'
            elseif v.spatter_size >= 8 then
                title = 'salt water ['.. (v.spatter_size%8) ..'/7]'
            else
                title = 'water ['.. v.spatter_size ..'/7]'
            end
            color = 1

        elseif t == df.ui_look_list.T_items.T_type.Magma then
            title = 'magma ['.. v.spatter_size ..'/7]'
            color = 4

        elseif t == df.ui_look_list.T_items.T_type.Floor then
            local x = df.global.cursor.x
            local y = df.global.cursor.y
            local z = df.global.cursor.z
            local bx = bit32.rshift(x, 4)
            local by = bit32.rshift(y, 4)
            local block = df.global.world.map.block_index[bx][by][z]
            local tt = block.tiletype[x%16][y%16]
            local ttmat = df.tiletype.attrs[tt].material

            --todo: sand soil floor -> sand
            
            --todo: material
            --todo: damp !
            --print(tt,ttmat)

            if ttmat == df.tiletype_material.GRASS_LIGHT or ttmat == df.tiletype_material.GRASS_DARK or
                ttmat == df.tiletype_material.GRASS_DRY or ttmat == df.tiletype_material.GRASS_DEAD then
                
                local amount = 0
                local plant_index = -1

                for i,ev in ipairs(block.block_events) do
                    if ev:getType() == df.block_square_event_type.grass then
                        local ev = ev --as:df.block_square_event_grassst
                        if ev.amount[x%16][y%16] > amount then
                            amount = ev.amount[x%16][y%16]
                            plant_index = ev.plant_index
                        end
                    end
                end

                local plant = plant_index ~= -1 and df.plant_raw.find(plant_index) or nil

                --todo: check the formula, the resulting density is reported to be nil sometimes
                local density = grass_density_prefix[math.floor(amount/33.4)+1] or ''

                title = density .. (plant and plant.name or 'grass')

                if df.tiletype.attrs[tt].shape ~= df.tiletype_shape.FLOOR then
                    title = title .. ' ' .. ttcaption(tt)
                end
            
            elseif ttmat == df.tiletype_material.MUSHROOM or ttmat == df.tiletype_material.ROOT or
                ttmat == df.tiletype_material.TREE or ttmat == df.tiletype_material.PLANT then

                --todo: shrubs, leaves, ...
                --todo: fungiwood dead sapling -> dead young fungiwood

                --xxx: this is from MapCache::prepare() but why???
                local mapcol = df.global.world.map.column_index[math.floor(x/48)*3][math.floor(y/48)*3]
                
                --print(bx,by)
                for i,p in ipairs(mapcol.plants) do
                    if not p.tree_info then
                        local pos = p.pos
                        if pos.x == x and pos.y == y and pos.z == z then
                            local plant = df.plant_raw.find(p.material)
                            local plantname = plant and plant.name_plural or 'plant'

                            --todo: don't show tiletype caption for shrub and dead shrub (?)

                            if tt == df.tiletype.Shrub then
                                title = plantname
                                if plant then
                                    for k,m in ipairs(plant.growths) do
                                        --todo: check timing_1, 2
                                        title = title .. ', ' .. m.name_plural
                                    end
                                end
                            elseif tt == df.tiletype.ShrubDead then
                                title = 'Dead ' .. plantname
                            else
                                title = (plant and plant.name or 'plant') .. ' ' .. ttcaption(tt)
                            end
                            break --todo: break ?
                        end

                    else
                        local t = coordInTree(p, x, y, z)
                        if t then
                            local plant = df.plant_raw.find(p.material)

                            title = (plant and plant.name or 'plant')

                            if ttmat == df.tiletype_material.ROOT then
                                title = title .. ' roots'
                            elseif t.trunk then
                                title = title .. ' trunk'
                            elseif t.branches or t.thick_branches_1 or t.thick_branches_2 or t.thick_branches_3 or t.thick_branches_4 then
                                title = title .. ' branches'
                            elseif t.twigs then
                                title = title .. ' twigs'                                    
                            end

                            break --todo: break ?
                        end
                    end
                end

                --todo: temporary
                if #title == 0 then
                    title = ttcaption(tt)
                end

            elseif ttmat == df.tiletype_material.MINERAL then
                for i,ev in ripairs(block.block_events) do
                    if ev:getType() == df.block_square_event_type.mineral then
                        local ev = ev --as:df.block_square_event_mineralst
                        if bit32.band(ev.tile_bitmask.bits[y%16], shft(x%16)) ~= 0 then
                            local matinfo = dfhack.matinfo.decode(0, ev.inorganic_mat)
                            local matname = matinfo and matinfo.material.state_adj.Solid or 'mineral'
                            title = matname .. ' ' .. ((ev.flags.cluster_small or ev.flags.cluster_one) and 'cluster' or ttcaption(tt))
        
                            if df.tiletype.attrs[tt].shape == df.tiletype_shape.FLOOR then
                                for i,ev in ipairs(block.block_events) do
                                    if ev:getType() == df.block_square_event_type.material_spatter then --as:ev=df.block_square_event_material_spatterst
                                        if ev.amount[x%16][y%16] > 0 then
                                            local mi = dfhack.matinfo.decode(ev.mat_type, ev.mat_index)
                                            if mi and mi.material.id == 'MUD' then
                                                title = 'muddy ' .. title
                                            end
                                        end
                                    end
                                end
                            end

                            --todo: only for wall/floor
                            local engraving = find_engraving(x, y, z)
                            if engraving then
                                local q = quality_chars[engraving.quality+1]
                                title = q..'detailed'..q .. ' ' .. title

                            elseif df.tiletype.attrs[tt].special == df.tiletype_special.SMOOTH then
                                title = 'smooth ' .. title
                            end
                            --todo: detailed
        
                            break
                        end
                    end
                end                

            elseif ttmat == df.tiletype_material.STONE or ttmat == df.tiletype_material.SOIL or
                ttmat == df.tiletype_material.DRIFTWOOD then

                local biome_offset_idx = block.region_offset[block.designation[x%16][y%16].biome]
                local geolayer_idx = block.designation[x%16][y%16].geolayer_index

                local offset = biome_region_offsets[biome_offset_idx+1]
                local rpos = { bit32.rshift(df.global.world.map.region_x,4) + offset[1], bit32.rshift(df.global.world.map.region_y,4) + offset[2] }
                local rbio = dfhack.maps.getRegionBiome(table.unpack(rpos))
                local geobiome = df.world_geo_biome.find(rbio.geo_index)
                local layer = geobiome.layers[geolayer_idx]
                local matinfo = dfhack.matinfo.decode(0, layer.mat_index)

                --print(biome_idx, geolayer_idx, rbio.geo_index, mat)
                if df.tiletype.attrs[tt].special == df.tiletype_special.FURROWED then
                    title = 'furrowed ' .. matinfo.material.state_name[0]
                else
                    title = matinfo.material.state_adj[0] .. ' ' .. ttcaption(tt)

                    if df.tiletype.attrs[tt].shape == df.tiletype_shape.FLOOR then
                        for i,ev in ipairs(block.block_events) do
                            if ev:getType() == df.block_square_event_type.material_spatter then --as:ev=df.block_square_event_material_spatterst
                                if ev.amount[x%16][y%16] > 0 then
                                    local mi = dfhack.matinfo.decode(ev.mat_type, ev.mat_index)
                                    if mi and mi.material.id == 'MUD' then
                                        title = 'muddy ' .. title
                                    end
                                end
                            end
                        end
                    end

                    --todo: only for wall/floor
                    local engraving = find_engraving(x, y, z)
                    if engraving then
                        local q = quality_chars[engraving.quality+1]
                        title = q..'detailed'..q .. ' ' .. title

                    elseif df.tiletype.attrs[tt].special == df.tiletype_special.SMOOTH then
                        title = 'smooth ' .. title
                    end
                end

            elseif ttmat == df.tiletype_material.CONSTRUCTION then
                local pos = df.coord:new()
                pos.x = x
                pos.y = y
                pos.z = z
                local const = df.construction.find(pos)
                local mi = const and dfhack.matinfo.decode(const.mat_type, const.mat_index)
                pos:delete()

                local matname
                if mi then
                    matname = mi.material.state_adj[0]
                    if const.item_type == df.item_type.BLOCKS then
                        matname = matname .. ' block'
                    elseif const.item_type == df.item_type.BOULDER then
                        matname = 'rough ' .. matname .. ' block'
                    elseif const.item_type == df.item_type.WOOD then
                        matname = matname .. ' log'
                    end
                else
                    matname = '#unknown material#'
                end

                title = matname .. ' ' .. ttcaption(tt)
            else
                title = ttcaption(tt)
            end

            color = 1

        elseif t == df.ui_look_list.T_items.T_type.Flow then
            local flow = v.flow
            local ftype = flow.type

            if ftype == df.flow_type.Steam then
                title = (flow.mat_type == 1 and 'steam' or 'mist')
            elseif ftype == df.flow_type.MaterialDust then
                title = dfhack.matinfo.decode(flow.mat_type, flow.mat_index).material.state_name.Powder
            elseif ftype == df.flow_type.MaterialGas then
                title = dfhack.matinfo.decode(flow.mat_type, flow.mat_index).material.state_name.Gas
            elseif ftype == df.flow_type.MaterialVapor then
                title = dfhack.matinfo.decode(flow.mat_type, flow.mat_index).material.state_name.Liquid .. ' vapor'
            else
                title = flow_type_names[ftype+1]
            end

            --todo: colors for other flows
            if ftype == df.flow_type.Miasma then
                color = 5
            end

        elseif t == df.ui_look_list.T_items.T_type.Campfire then
            title = 'a campfire'
        elseif t == df.ui_look_list.T_items.T_type.Fire then
            title = 'a fire'
        elseif t == df.ui_look_list.T_items.T_type.Spoor then
            title = 'Track/Spoor'

        elseif t == df.ui_look_list.T_items.T_type.Vermin then
            local vermin = v.vermin
            local race = df.global.world.raws.creatures.all[vermin.race]
            title = (vermin.flags.is_colony and 'a colony or ' or '') .. race.name[vermin.amount > 1 and 1 or 0]
            color = 2+8

        elseif t == df.ui_look_list.T_items.T_type.Spatter then
            local mi = dfhack.matinfo.decode(v.spatter_mat_type, v.spatter_mat_index)

            --todo: hazel tree seeds -> hazel nuts
            --todo: oak seed -> acorns

            --todo: what are the situations mi == nil ?
            if mi then
                if v.spatter_item_type == df.item_type.PLANT_GROWTH then
                    title = mi.plant.growths[v.spatter_item_subtype].name_plural
                    color = 2

                elseif v.spatter_item_type == -1 then
                    --<a spattering of> <Urist McMiner> <dwarf> <blood>

                    local spatterprefix = spatter_prefixes[v.spatter_mat_state+1][v.spatter_size+1] or ''
                    if #spatterprefix > 0 then
                        spatterprefix = spatterprefix .. ' '
                    end

                    local creatureprefix = mi.figure and (hfname(mi.figure) .. ' ') or ''

                    local matprefix = #mi.material.prefix > 0 and (mi.material.prefix .. ' ') or ''
                    title = spatterprefix .. creatureprefix .. matprefix .. mi.material.state_name[v.spatter_mat_state]

                    local c = df.global.world.raws.language.colors[mi.material.state_color[v.spatter_mat_state]]
                    color = c.color + c.bold*8

                else
                    if mi.material.id == 'SEED' then
                        title = mi.plant.seed_plural
                        color = 2
                    else
                        title = mi.material.prefix .. ' ' .. mi.material.state_name.Solid
                        color = mi.material.basic_color[0] + mi.material.basic_color[1]*8
                    end
                end
            end
        end

        --title = dfhack.df2utf(title)

        if #title > 0 then
            if detailed then
                table.insert(ret, { title, color, t, table.unpack(data) })
            else
                table.insert(ret, { title, color })
            end
        end
    end

    last_look_x = df.global.cursor.x
    last_look_y = df.global.cursor.y
    last_look_z = df.global.cursor.z
    last_look_list = ret

    return ret
end
--print(pcall(function() print(json:encode(get_look_list(true))) end))

--luacheck: in=
function look_get_details()
    local c = df.global.cursor
    local bx = bit32.rshift(c.x, 4)
    local by = bit32.rshift(c.y, 4)
    local block = df.global.world.map.block_index[bx][by][c.z]
    local flags = 0
    if block then
        local d = block.designation[c.x%16][c.y%16]
        flags = packbits(d.outside, d.light, d.subterranean)
    else
        print('no block !')
    end

    return { get_look_list(true), flags }
end

--todo: do this in C for speed?
function count_idlers()
    local cnt = 0

    for i,unit in ipairs(df.global.world.units.active) do
        if not unit.flags1.dead and not unit.job.current_job then
            local prf = unit.profession
            if dfhack.units.isCitizen(unit) then
                --todo: need to check activity_entry.events for individual drills ?
                if prf ~= df.profession.BABY and prf ~= df.profession.CHILD and prf ~= df.profession.DRUNK and
                   not df.profession.attrs[prf].military and #unit.military.individual_drills == 0 then
                    local on_break = false
                    for j,t in ipairs(unit.status.misc_traits) do
                        if t.id == df.misc_trait_type.OnBreak or t.id == df.misc_trait_type.Migrant then
                            on_break = true
                            break
                        end
                    end

                    if not on_break and #unit.specific_refs == 0 then
                        cnt = cnt + 1
                    end
                end
            end
        end
    end

    return cnt
end

last_popup = nil
sent_popups = {}

local last_idlers = nil
local last_siege = nil
local last_day = nil
local last_petitions = nil
local last_report_alert = nil
local idlers_wait = 0

local last_follow_unit = nil
local last_follow_unitid = -1
local last_follow_unit_x = nil
local last_follow_unit_y = nil
local last_follow_unit_z = nil

--luacheck: in=
function get_status()
    if screen_main()._type ~= df.viewscreen_dwarfmodest then
        return 97, 0
    end

    local ws = dfhack.gui.getCurViewscreen()

    if ws._type == df.viewscreen_export_regionst or ws._type == df.viewscreen_game_cleanerst then
        return 97, 0
    end

    --todo: if not in dwarfmode, send a special status
    --todo: handle data/announcement/* screens here ?

    if ws._type == df.viewscreen_topicmeeting_takerequestsst then
        return 60, 3
    end

    if ws._type == df.viewscreen_topicmeetingst then
        --todo: this is a temporary hack to force send status update if the next
        --todo: meeting view is displayed the same remote tick when the previous one is dismissed
        local zz = tostring(ws.popup) --hint:df.viewscreen_topicmeetingst
        return 60, 2, { zz }
    end

    if ws._type == df.viewscreen_textviewerst and ws.parent._type == df.viewscreen_meetingst then
        return 60, 1
    end

    if ws._type == df.viewscreen_tradeagreementst and ws.parent._type == df.viewscreen_topicmeetingst then
        return 60, 4
    end  

    if ws._type == df.viewscreen_requestagreementst and ws.parent._type == df.viewscreen_topicmeetingst then
        return 60, 5
    end  

    if ws._type == df.viewscreen_topicmeeting_fill_land_holder_positionsst and ws.parent._type == df.viewscreen_topicmeetingst then
        return 60, 6
    end  

    if ws._type == df.viewscreen_textviewerst then
        local ws = ws --as:df.viewscreen_textviewerst
        if ws.page_filename:find('data/announcement/') then
            local text = ''
            for i,v in ipairs(ws.formatted_text) do
                text = text .. dfhack.df2utf(charptr_to_string(v.text)) .. ' '
            end
            text = text:gsub('%s+', ' ')
    
            local title = ws.title
            title = title:gsub("^%s+", ""):gsub("%s+$", "")
    
            return 98, 0, { title, text }
        end
    end
    
    --if ws._type == df.viewscreen_dwarfmodest then
    local mainmode = df.global.ui.main.mode
    local modestr = df.ui_sidebar_mode[mainmode] or ''

    if mainmode ~= df.ui_sidebar_mode.LookAround then
        last_look_list = nil
    end

    if mainmode ~= df.ui_sidebar_mode.NotesPoints then
        last_nearest_point = nil
    end

    if mainmode ~= 0 then
        df.global.ui.follow_unit = -1
    end

    --[d]esignate
    if modestr:sub(1,#'Designate') == 'Designate' then
        if df.global.selection_rect.start_x == -30000 then
            if mainmode == df.ui_sidebar_mode.DesignateMine and df.global.ui_sidebar_menus.designation.mine_mode > 0 then
                return 31, mainmode, df.global.ui_sidebar_menus.designation.mine_mode
            else
                return 31, mainmode
            end
        else
            local dx = math.abs(df.global.cursor.x - df.global.selection_rect.start_x) + 1
            local dy = math.abs(df.global.cursor.y - df.global.selection_rect.start_y) + 1
            local dz = math.abs(df.global.cursor.z - df.global.selection_rect.start_z) + 1
            if mainmode == df.ui_sidebar_mode.DesignateMine and df.global.ui_sidebar_menus.designation.mine_mode > 0 then
                return 32, mainmode, { dx, dy, dz, df.global.ui_sidebar_menus.designation.mine_mode }
            else
                return 32, mainmode, { dx, dy, dz }
            end
        end
    end

    -- zones [i]
    if mainmode == df.ui_sidebar_mode.Zones then
        if df.global.ui_sidebar_menus.zone.selected and not df.global.ui_building_in_resize then
            local zone = df.global.ui_sidebar_menus.zone.selected
            local info = { zonename(zone), zone.zone_flags.whole }
            return 64, 1, info
        else
            local zonemode = df.global.ui_sidebar_menus.zone.mode
            if zonemode == df.ui_sidebar_menus.T_zone.T_mode.Rectangle then
                if df.global.selection_rect.start_x == -30000 then
                    return 61, 0
                else
                    local dx = math.abs(df.global.cursor.x - df.global.selection_rect.start_x) + 1
                    local dy = math.abs(df.global.cursor.y - df.global.selection_rect.start_y) + 1
                    local dz = math.abs(df.global.cursor.z - df.global.selection_rect.start_z) + 1
                    return 61, 1, { dx, dy, dz }
                end
            elseif zonemode == df.ui_sidebar_menus.T_zone.T_mode.Flow then
                return 62, (df.global.ui_building_in_resize and 1 or 0)
            elseif zonemode == df.ui_sidebar_menus.T_zone.T_mode.FloorFlow then
                return 63, (df.global.ui_building_in_resize and 1 or 0)
            end
        end
    end

    -- notes/points (N)
    if mainmode == df.ui_sidebar_mode.NotesPoints then
        if last_point_x == df.global.cursor.x and last_point_y == df.global.cursor.y and last_point_z == df.global.cursor.z and last_nearest_point and last_point_cnt == #df.global.ui.waypoints.points then
        else
            last_point_x = df.global.cursor.x
            last_point_y = df.global.cursor.y
            last_point_z = df.global.cursor.z
            last_point_cnt = #df.global.ui.waypoints.points

            last_nearest_point = waypoints_nearest_point()
        end        

        local can_place = not last_nearest_point or last_nearest_point[4][1] ~= 0 or last_nearest_point[4][2] ~= 0 or last_nearest_point[4][3] ~= 0
        return 26, can_place and 1 or 0, last_nearest_point and { last_nearest_point[1], last_nearest_point[4] } or nil
    end

    --stock[p]ile
    if mainmode == df.ui_sidebar_mode.Stockpiles then
        if df.global.selection_rect.start_x == -30000 then
            return 41, 0
        else
            local dx = math.abs(df.global.cursor.x - df.global.selection_rect.start_x) + 1
            local dy = math.abs(df.global.cursor.y - df.global.selection_rect.start_y) + 1
            local dz = math.abs(df.global.cursor.z - df.global.selection_rect.start_z) + 1

            return 42, 0, { dx, dy, dz }
        end
    end

    --[b]uild
    if mainmode == df.ui_sidebar_mode.Build then
        local bldstage = df.global.ui_build_selector.stage

        if bldstage == 1 or bldstage == 0 then
            local btype = df.global.ui_build_selector.building_type
            local sizemode = 0
            if btype == df.building_type.FarmPlot or btype == df.building_type.Construction or
                btype == df.building_type.RoadPaved or btype == df.building_type.RoadDirt
                or btype == df.building_type.Bridge then
                sizemode = 3 -- any direction
            elseif btype == df.building_type.AxleHorizontal then
                sizemode = (df.global.world.selected_direction == 0) and 1 or 2
            elseif btype == df.building_type.Rollers then
                sizemode = (df.global.world.selected_direction == 1 or df.global.world.selected_direction == 3) and 1 or 2
            end

            local s2 = bit32.lshift(build_has_options() and 1 or 0, 4) + bit32.lshift(sizemode, 2) + 1

            if #df.global.ui_build_selector.errors > 0 then
                local errs = build_get_errors()
                return 16, s2, errs
            else
                return 16, s2 --todo: maybe send {} in this case?
            end
        elseif bldstage == 2 then
            return 16, 2
        end
    end

    --[q]uery building
    if mainmode == df.ui_sidebar_mode.QueryBuilding then
        if df.global.ui_building_in_resize then
            return 101, 0
        end

        local bld = df.global.world.selected_building
        if bld then
            local name = bldname(bld)
    
            if bld._type == df.building_trapst and df.global.ui_workshop_in_add then
                local linkmode = C_lever_target_type_get()
                if linkmode ~= -1 then

                    if linkmode == string.byte('t') or linkmode == string.byte('l') then
                        local enough = (linkmode == string.byte('t') and #df.global.ui_building_assign_items >= 2) or
                                       (linkmode == string.byte('l') and #df.global.ui_building_assign_items >= 1) or false
                        return 103, enough and 1 or 0
                    else
                        return 102, 0, name --todo: return whether there's a building under cursor and its name
                    end
                end
            end

            if bld._type == df.building_coffinst and bld.owner and bld.owner.flags1.dead then
                name = name .. ' (✝\xEF\xB8\x8E)' --todo: this modifier shouldn't be on server side
            elseif bld._type == df.building_doorst and bld.door_flags.forbidden then --hint:df.building_doorst
                name = name .. ' (locked)' --todo: this modifier shouldn't be on server side
            elseif bld._type == df.building_workshopst or bld._type == df.building_furnacest then
                local jc = #bld.jobs
                if jc == 0 then
                    name = name .. ' (no jobs)'
                else
                    name = name .. ' (' .. jc .. ' ' .. (jc == 1 and 'job' or 'jobs') .. ')'
                end
            end

            return 23, (bld and 1 or 0), name
        else 
            return 23, 0, nil
        end
    end

    --[v]iew unit
    if mainmode == df.ui_sidebar_mode.ViewUnits then
        --todo: pass unit name to the app
        local unit = (df.global.ui_selected_unit ~= -1) and df.global.world.units.active[df.global.ui_selected_unit]
        local txt = nil
        if unit then
            txt = unit_fulltitle(unit)
            --local name = unit and unitname(unit)
            --fullname = (#name > 0 and (name .. ', ') or '') .. unitprof(unit)
            local jobtitle = unit_jobtitle(unit)
            if #jobtitle > 0 then
                txt = txt .. '\n' .. jobtitle
            end
        end
        return 24, (unit and 1 or 0), txt
    end

    --loo[k]
    if mainmode == df.ui_sidebar_mode.LookAround then
        local look_list = get_look_list()
        return 25, 1, look_list
    end    

    --[s]quads
    if mainmode == df.ui_sidebar_mode.Squads then
        if df.global.ui.squads.in_move_order then
            return 51, 0
        end

        if df.global.ui.squads.in_kill_order --[[and not df.global.ui.squads.in_kill_rect]] and not df.global.ui.squads.in_kill_list then

            if df.global.ui.squads.in_kill_rect and df.global.ui.squads.rect_start.x == -30000 then
                return 54, 0
            end

            --todo: if map_moved !
            local targets = {}
            for i,t in ipairs(df.global.ui.squads.kill_rect_targets) do
                local name = unit_creature_name(t)
                table.insert(targets, name)
            end

            return (df.global.ui.squads.in_kill_rect and 55 or 52), #df.global.ui.squads.kill_rect_targets, targets
        end

        if df.global.ui.squads.in_kill_order and df.global.ui.squads.in_kill_list then
            return 53, 0
        end

        return 50, 0
    end

    --[D]epot access
    if mainmode == df.ui_sidebar_mode.DepotAccess then
        local x = df.global.gps.dimx - 2 - 30 + 1
        if df.global.ui_menu_width == 1 or df.global.ui_area_map_width == 2 then
            x = x - (23 + 1)
        end

        x = x + 1 + 6

        local ch = df.global.gps.screen[(x*df.global.gps.dimy+7)*4]
        local access = string.char(ch) == 'a'
        return 48, access and 1 or 0
    end

    if mainmode == df.ui_sidebar_mode.Burrows then
        local sel_idx = df.global.ui.burrows.sel_index
        if sel_idx == -1 then
            df.global.ui.main.mode = df.ui_sidebar_mode.Default
            mainmode = df.ui_sidebar_mode.Default
        else
            local burrow = df.global.ui.burrows.list[sel_idx]
            local bname = burrowname(burrow)

            local in_edit = istrue(df.global.ui.burrows.in_define_mode)

            if in_edit then
                local rect_started = (df.global.ui.burrows.rect_start.x ~= -30000)
                local erasing = df.global.ui.burrows.brush_erasing

                return 71, packbits(erasing, rect_started), bname
            else
                return 70, 0, bname
            end
        end
    end

    --end    

    if df.global.ui.follow_unit ~= -1 then
        last_follow_unit = (df.global.ui.follow_unit == last_follow_unitid) and last_follow_unit or df.unit.find(df.global.ui.follow_unit)

        local pos = last_follow_unit.pos

        if last_follow_unitid ~= df.global.ui.follow_unit
            or last_follow_unit_x ~= pos.x or last_follow_unit_y ~= pos.y or last_follow_unit_z ~= pos.z then
            recenter_view(pos.x, pos.y, pos.z)
        end

        last_follow_unitid = df.global.ui.follow_unit
        last_follow_unit_x = pos.x
        last_follow_unit_y = pos.y
        last_follow_unit_z = pos.z
    else
        last_follow_unit = nil
        last_follow_unitid = -1
    end

    local hasnewann = false
    local annzoomed = false
    for i,ann in ripairs(df.global.world.status.announcements) do
        if ann.id <= lastann and not (ann.id == lastann and ann.repeat_count > lastannrep) then
            break
        end

        local flags = df.global.announcements.flags[ann.type]
        if flags.D_DISPLAY then
            hasnewann = true
        end

        --xxx: the game doesn't update coords for repeating announcements, so no point sending
        --xxx: but the game has already jumped so until we use wz var, we have to send new center
        if --[[lastann < ann.id and]] flags.D_DISPLAY and flags.RECENTER and ann.pos.x ~= -30000 and not annzoomed then
            recenter_view(ann.pos.x, ann.pos.y, ann.pos.z)
            annzoomed = true
        end
    end

    if #df.global.world.status.popups > 0 then
        if last_popup ~= df.global.world.status.popups[#df.global.world.status.popups-1] then
            hasnewann = true
        end
    end

    local ext = nil

    if hasnewann then
        ext = ext or {}
        table.insert(ext, announcements_get_new())
    end
    
    if last_follow_unit then
        ext = ext or {}
        --todo: both unit and job colours
        table.insert(ext, { unit_fulltitle(last_follow_unit), unit_jobtitle(last_follow_unit, false) })
    end

    local hasnewidlers = false
    if idlers_wait == 0 then
        idlers_wait = 4
        local idlers = count_idlers()
        if idlers ~= last_idlers then
            last_idlers = idlers
            hasnewidlers = true
            ext = ext or {}
            table.insert(ext, idlers)
        end
    else
        idlers_wait = idlers_wait - 1
    end

    local hasnewsiege = false
    local siege = false
    --todo: do we need to check all of them - can early ones be active if later not?
    for i,v in ripairs(df.global.ui.invasions.list) do
        if v.flags.active and v.flags.siege then
            siege = true
            break
        end
    end
    if siege ~= last_siege then
        last_siege = siege
        hasnewsiege = true
        ext = ext or {}
        table.insert(ext, siege)
    end

    local hasnewday = false
    local day = math.floor(df.global.cur_year_tick / TU_PER_DAY)
    if day ~= last_day then
        last_day = day
        hasnewday = true
        ext = ext or {}
        table.insert(ext, day)
    end

    local hasnewreportalert = false
    local report_alert = bit32.band(df.global.world.status.flags.whole, 7) --combat/hunting/sparring
    if report_alert ~= last_report_alert then
        last_report_alert = report_alert
        hasnewreportalert = true
        ext = ext or {}
        table.insert(ext, report_alert)
    end
    
    local hasnewpetitions = false
    if df_ver >= 4200 then --dfver:4200-
        local petitions = #df.global.ui.petitions
    
        if petitions ~= last_petitions then
            last_petitions = petitions
            hasnewpetitions = true
            ext = ext or {}
            table.insert(ext, petitions)
        end
    end

    return 0, packbits(df.global.pause_state, hasnewann, last_follow_unit, hasnewidlers, hasnewsiege, hasnewday, hasnewreportalert, hasnewpetitions), ext
end

local send_center = false
local center_sent
local centerx, centery, centerz

function recenter_view(x,y,z)
    --if df.global.window_x ~= x or df.global.window_y ~= y or df.global.window_z ~= z then
        centerx = x
        centery = y
        centerz = z
        center_sent = false
        send_center = true
    --end
end

--luacheck: in=bool
function get_status_ext(needs_sync)
    needs_sync = istrue(needs_sync)

    if needs_sync then
        send_center = send_center or (not center_sent and centerx)
        --print('needs sync')
        --todo: shouldn't it send ext when needs_sync as well !?
        sent_popups = {}
        last_popup = nil
        last_idlers = nil
        last_siege = nil
        last_petitions = nil
        last_day = nil
        last_report_alert = nil
        idlers_wait = 0
    elseif not send_center then
        center_sent = true
    end

    local s1, s2, ext = get_status()

    extdata = mp.pack(ext)

    if extdata ~= lastextdata or needs_sync then
        lastextdata = extdata
    else
        extdata = nil
    end

    if extdata then
        --print 'will send ext'
    end

    local centerdata = nil
    if send_center then
        send_center = false
        centerdata = string.char(centerx, centery, centerz)
    end

    return s1, s2, extdata, centerdata
end

function genrespseqstr(seq)
    local rseq = seq + 1
    return string.char(128, bit32.band(rseq, 0xff), bit32.rshift(rseq, 8))
end

function generrseqstr(seq)
    local rseq = seq + 1
    return string.char(130, bit32.band(rseq, 0xff), bit32.rshift(rseq, 8))
end

--luacheck: in=number,number,number,number
function set_traffic_costs(high, normal, low, restricted)
    df.global.ui.main.traffic_cost_high = high
    df.global.ui.main.traffic_cost_normal = normal
    df.global.ui.main.traffic_cost_low = low
    df.global.ui.main.traffic_cost_restricted = restricted
end

--luacheck: in=bool
function pause_game(pause)
    df.global.pause_state = istrue(pause)
end

-- from quicksave.lua
--luacheck: in=
function save_game()
    local ui_main = df.global.ui.main
    local flags4 = df.global.d_init.flags4

    local function restore_autobackup()
        if ui_main.autosave_request and dfhack.isMapLoaded() then
            dfhack.timeout(10, 'frames', restore_autobackup)
        else
            flags4.AUTOBACKUP = true
        end
    end

    -- Request auto-save
    ui_main.autosave_request = true

    -- And since it will overwrite the backup, disable it temporarily
    if flags4.AUTOBACKUP then
        flags4.AUTOBACKUP = false
        restore_autobackup()
    end
end

--luacheck: in=string
function dfaas_save_game(pwd)
    if not native.verify_pwd(pwd or '') then
        return false
    end

    --todo: need to return to main screen!

    save_game()    
    return true
end

--luacheck: in=string
function dfaas_save_done(pwd)
    if not native.verify_pwd(pwd or '') then
        return false
    end

    --todo: need to return to main screen!

    return (df.global.ui.main.autosave_request ~= true)
end

--luacheck: in=
function save_and_close()
    local ws = screen_main()
    local optsws = df.viewscreen_optionst:new()

    optsws.options:insert(0, 1) -- save
    optsws.parent = ws
    ws.child = optsws

    gui.simulateInput(optsws, K'SELECT')
end

--luacheck: in=
function end_game_retire()
    local ws = screen_main()
    local optsws = df.viewscreen_optionst:new()

    optsws.parent = ws
    ws.child = optsws

    optsws.in_retire_dwf_abandon_adv = 1

    gui.simulateInput(optsws, K'MENU_CONFIRM')
end

--luacheck: in=
function end_game_abandon()
    local ws = screen_main()
    local optsws = df.viewscreen_optionst:new()

    optsws.parent = ws
    ws.child = optsws

    optsws.in_abandon_dwf = 1

    gui.simulateInput(optsws, K'MENU_CONFIRM')
end

--luacheck: in=
function query_building()
    reset_main()

    local x = df.global.cursor.x
    local y = df.global.cursor.y
    local z = df.global.window_z

    local ws = dfhack.gui.getCurViewscreen()
    gui.simulateInput(ws, K'D_BUILDJOB')    

    if x ~= -30000 then
        df.global.cursor.x = x
        df.global.cursor.y = y

        if z > 0 then
            df.global.cursor.z = z - 1
            gui.simulateInput(ws, K'CURSOR_UP_Z')        
        else
            df.global.cursor.z = z + 1
            gui.simulateInput(ws, K'CURSOR_DOWN_Z')
        end
    end
end

--luacheck: in=
function query_unit()
    reset_main()

    local x = df.global.cursor.x
    local y = df.global.cursor.y
    local z = df.global.window_z

    local ws = dfhack.gui.getCurViewscreen()
    gui.simulateInput(ws, K'D_VIEWUNIT') 

    if x ~= -30000 then
        df.global.cursor.x = x
        df.global.cursor.y = y

        if z > 0 then
            df.global.cursor.z = z - 1
            gui.simulateInput(ws, K'CURSOR_UP_Z')        
        else
            df.global.cursor.z = z + 1
            gui.simulateInput(ws, K'CURSOR_DOWN_Z')
        end
    end
end

--luacheck: in=
function query_look()
    reset_main()

    local x = df.global.cursor.x
    local y = df.global.cursor.y
    local z = df.global.window_z

    local ws = dfhack.gui.getCurViewscreen()
    gui.simulateInput(ws, K'D_LOOK')

    if x ~= -30000 then
        df.global.cursor.x = x
        df.global.cursor.y = y

        if z > 0 then
            df.global.cursor.z = z - 1
            gui.simulateInput(ws, K'CURSOR_UP_Z')        
        else
            df.global.cursor.z = z + 1
            gui.simulateInput(ws, K'CURSOR_DOWN_Z')
        end
    end
end


--luacheck: in=
function select_confirm()
    --[[local zoombacktobld = nil
    if df.global.ui.main.mode == df.ui_sidebar_mode.QueryBuilding then

        local bld = df.global.world.selected_building
        if bld and C_lever_target_type_get() ~= -1 then
            zoombacktobld = bld
        end
    end]]

    -- limit zones and stockpiles to 31x31 max
    if ((df.global.ui.main.mode == df.ui_sidebar_mode.Zones and df.global.ui_sidebar_menus.zone.mode == df.ui_sidebar_menus.T_zone.T_mode.Rectangle)
     or (df.global.ui.main.mode == df.ui_sidebar_mode.Stockpiles))
     and df.global.selection_rect.start_x ~= -30000 then
        df.global.cursor.x = math.min(df.global.cursor.x, df.global.selection_rect.start_x + 30)
        df.global.cursor.x = math.max(df.global.cursor.x, df.global.selection_rect.start_x - 30)
        df.global.cursor.y = math.min(df.global.cursor.y, df.global.selection_rect.start_y + 30)
        df.global.cursor.y = math.max(df.global.cursor.y, df.global.selection_rect.start_y - 30)
        df.global.cursor.z = math.min(df.global.cursor.z, df.global.selection_rect.start_z + 30)
        df.global.cursor.z = math.max(df.global.cursor.z, df.global.selection_rect.start_z - 30)
    end

    local maybestockpile = df.global.ui.main.mode == 15 and df.global.selection_rect.start_x ~= -30000
    local oldstockpilecnt = #df.global.world.buildings.other.STOCKPILE

    local ws = dfhack.gui.getCurViewscreen()
    gui.simulateInput(ws, K'SELECT')

    if maybestockpile and df.global.ui.main.mode == 15 and df.global.selection_rect.start_x == -30000 and
       oldstockpilecnt < #df.global.world.buildings.other.STOCKPILE then
        df.global.ui.main.mode = df.ui_sidebar_mode.QueryBuilding
        local ws = screen_main()
        gui.simulateInput(ws, K'CURSOR_DOWN_Z')
        gui.simulateInput(ws, K'CURSOR_UP_Z')        
    end

    --[[if zoombacktobld then
        recenter_view(zoombacktobld.centerx, zoombacktobld.centery, zoombacktobld.z)
    end]]
end

--luacheck: in=
function leavescreen()
    local ws = dfhack.gui.getCurViewscreen()
    gui.simulateInput(ws, K'LEAVESCREEN')    
end


--luacheck: in=
function zlevel_up()
    local ws = screen_main()
    gui.simulateInput(ws, K'CURSOR_UP_Z')    
end

--luacheck: in=
function zlevel_down()
    local ws = screen_main()
    gui.simulateInput(ws, K'CURSOR_DOWN_Z')    
end

--luacheck: in=string
function zlevel_set(data)
    local z = data:byte(1)
    local ws = screen_main()

    if z > 0 then
        df.global.window_z = z - 1
        df.global.cursor.z = z - 1
        gui.simulateInput(ws, K'CURSOR_UP_Z')
    else
        df.global.window_z = z + 1
        df.global.cursor.z = z + 1
        gui.simulateInput(ws, K'CURSOR_DOWN_Z')
    end
end

--luacheck: in=
function dim_bigger()
    local ws = screen_main()
    gui.simulateInput(ws, K'SECONDSCROLL_DOWN')    
end

--luacheck: in=
function dim_smaller()
    local ws = screen_main()
    gui.simulateInput(ws, K'SECONDSCROLL_UP')    
end

--luacheck: in=
function dim_x_more()
    local ws = screen_main()
    gui.simulateInput(ws, K'BUILDING_DIM_X_UP')    
end

--luacheck: in=
function dim_x_less()
    local ws = screen_main()
    gui.simulateInput(ws, K'BUILDING_DIM_X_DOWN')    
end

--luacheck: in=
function dim_y_more()
    local ws = screen_main()
    gui.simulateInput(ws, K'BUILDING_DIM_Y_UP')    
end

--luacheck: in=
function dim_y_less()
    local ws = screen_main()
    gui.simulateInput(ws, K'BUILDING_DIM_Y_DOWN')    
end


--luacheck: in=string
function set_cursor_pos(data)
    local mx = data:byte(1)
    local my = data:byte(2)

    df.global.cursor.x = mx
    df.global.cursor.y = my
    df.global.cursor.z = df.global.window_z

    local ws = screen_main()
    gui.simulateInput(ws, K'CURSOR_DOWN_Z')
    gui.simulateInput(ws, K'CURSOR_UP_Z')

    if data:byte(3) ~= 0 then
        -- limit zones and stockpiles to 31x31 max
        if ((df.global.ui.main.mode == df.ui_sidebar_mode.Zones and df.global.ui_sidebar_menus.zone.mode == df.ui_sidebar_menus.T_zone.T_mode.Rectangle)
         or (df.global.ui.main.mode == df.ui_sidebar_mode.Stockpiles))
         and df.global.selection_rect.start_x ~= -30000 then
            df.global.cursor.x = math.min(df.global.cursor.x, df.global.selection_rect.start_x + 30)
            df.global.cursor.x = math.max(df.global.cursor.x, df.global.selection_rect.start_x - 30)
            df.global.cursor.y = math.min(df.global.cursor.y, df.global.selection_rect.start_y + 30)
            df.global.cursor.y = math.max(df.global.cursor.y, df.global.selection_rect.start_y - 30)
            df.global.cursor.z = math.min(df.global.cursor.z, df.global.selection_rect.start_z + 30)
            df.global.cursor.z = math.max(df.global.cursor.z, df.global.selection_rect.start_z - 30)
        end

        local maybestockpile = df.global.ui.main.mode == 15 and df.global.selection_rect.start_x ~= -30000
        local oldstockpilecnt = #df.global.world.buildings.other.STOCKPILE 

        gui.simulateInput(ws, K'SELECT')

        if maybestockpile and df.global.ui.main.mode == 15 and df.global.selection_rect.start_x == -30000 and
            oldstockpilecnt < #df.global.world.buildings.other.STOCKPILE then
            df.global.ui.main.mode = df.ui_sidebar_mode.QueryBuilding
            local ws = screen_main()
            gui.simulateInput(ws, K'CURSOR_DOWN_Z')
            gui.simulateInput(ws, K'CURSOR_UP_Z')        
        end
    end
end

--luacheck: in=string
function set_cursor_pos_relative(data)
    local dx = data:byte(1) - 127
    local dy = data:byte(2) - 127

    df.global.cursor.x = df.global.cursor.x + dx
    df.global.cursor.y = df.global.cursor.y + dy
    df.global.cursor.z = df.global.window_z

    local ws = screen_main()
    gui.simulateInput(ws, K'CURSOR_DOWN_Z')
    gui.simulateInput(ws, K'CURSOR_UP_Z')
end

--luacheck: in=number
function designate(idx)
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        return
    end

    local x = df.global.cursor.x
    local y = df.global.cursor.y
    local z = df.global.window_z

    reset_main()
    
    --todo: until we support this, otherwise there's no way to change to normal mode
    df.global.ui_sidebar_menus.designation.marker_only = false
    df.global.ui_sidebar_menus.designation.priority = 4000

    gui.simulateInput(ws, K'D_DESIGNATE')

    local cmd = designate_cmds[idx]
    for i,v in ipairs(cmd) do
        gui.simulateInput(ws, v)
    end

    if x ~= -30000 then
        df.global.cursor.x = x
        df.global.cursor.y = y

        if z > 0 then
            df.global.cursor.z = z - 1
            gui.simulateInput(ws, K'CURSOR_UP_Z')        
        else
            df.global.cursor.z = z + 1
            gui.simulateInput(ws, K'CURSOR_DOWN_Z')
        end
    end

    return true
end

local original_designation_mode = nil

--luacheck: in=
function designate_toggle_erase()
    local mainmode = df.global.ui.main.mode
    local modestr = df.ui_sidebar_mode[mainmode] or ''

    if mainmode ~= df.ui_sidebar_mode.DesignateRemoveDesignation and
       modestr:sub(1,#'Designate') == 'Designate' and
       modestr:sub(1,#'DesignateItems') ~= 'DesignateItems' and
       modestr:sub(1,#'DesignateTraffic') ~= 'DesignateTraffic' and
       modestr:sub(1,#'DesignateToggle') ~= 'DesignateToggle' then
        original_designation_mode = mainmode
        df.global.ui.main.mode = df.ui_sidebar_mode.DesignateRemoveDesignation
        return true
    
    elseif mainmode == df.ui_sidebar_mode.DesignateRemoveDesignation and original_designation_mode then
        df.global.ui.main.mode = original_designation_mode
        original_designation_mode = nil
        return true
    end
    
    return false
end

--luacheck: in=
function close_legends()
    if screen_main()._type ~= df.viewscreen_legendsst then
        return
    end

    local ws = dfhack.gui.getCurViewscreen()
    while ws and ws.parent and ws._type ~= df.viewscreen_legendsst do
        local parent = ws.parent
        parent.child = nil
        ws:delete()
        ws = parent
    end

    ws.cur_page = df.viewscreen_legendsst.T_cur_page.Main --hint:df.viewscreen_legendsst
    gui.simulateInput(ws, K'LEAVESCREEN')
end

function ensure_native()
    if #native == 0 then
        dfhack.open_plugin(native, 'remote')
    end
end

local function perform_update(pwd)
    if not native.verify_pwd(pwd or '') then
        return false
    end

    return native.start_update()
end

local handlers_foreign = {
    [238] = {
        [4] = setup_get_server_info,
        [6] = perform_update,
        
        [20] = dfaas_save_game,
        [21] = dfaas_save_done,
    },
}

local handlers = {
    [50] = zlevel_set,
    [51] = zlevel_up,
    [52] = zlevel_down,
    [53] = dim_bigger,
    [54] = dim_smaller,
    [55] = dim_x_more,
    [56] = dim_x_less,
    [57] = dim_y_more,
    [58] = dim_y_less,

    [99] = close_all,
    [100] = reset_main,
    [101] = cancel_to_1st_corner,

    [113] = set_cursor_pos,
    [114] = set_cursor_pos_relative,

    [130] = {
        [1] = animals_get,
        [2] = animals_get2,
        
        [11] = animals_set_slaughter,
        [12] = animals_set_available,
        [13] = animals_train_war,
        [14] = animals_train_hunting,
        [15] = animals_set_geld,
        [20] = animals_trainer_get_choices,
        [21] = animals_trainer_set,
    },

    [131] = {
        [1] = zone_create,
        [2] = zone_settings_get,
        [3] = zone_settings_set,
        [4] = zone_information_get,
        [5] = zone_information_set,
        [6] = zone_assign,
        [7] = zone_remove,
    },

    [132] = {
        [1] = stocks_get_categories,
        [2] = stocks_get_items,
        [3] = stocks_search,
        [4] = stocks_group_action,
        [10] = stocks_init,
        [11] = stocks_free,
    },

    [133] = {
        [1] = burrows_get_list,
        [2] = burrows_add,
        [3] = burrow_delete,
        [4] = burrow_get_units,
        [5] = burrow_set_name,
        [6] = burrow_start_edit,
        [7] = burrow_set_brush_mode,
        [8] = burrow_end_edit,
        [9] = burrow_get_info,
        [10] = burrow_limit_workshops,
        [11] = burrow_set_unit,
        [12] = burrow_zoom,
    },

    [134] = {
        [1] = alerts_get_list,
        [2] = alerts_set_civ,
        [3] = alerts_add,
        [4] = alert_delete,
        [5] = alert_get_info,
        [6] = alert_set_burrow,
        [7] = alert_set_name,

        [10] = squads_get_list,
        [11] = squad_disband,
        [12] = squad_get_info,
        [13] = squad_remove_member,
        [14] = squad_set_name,
        [15] = squad_set_supplies,
        [16] = squad_create_with_leader,
        [17] = squad_get_candidates,
        [18] = squad_add_members,

        [20] = ammunition_get_list_short,
        [21] = ammunition_get_additem,
        [22] = ammunition_item_add,
        [23] = ammunition_item_remove,
        [24] = ammunition_get_assigned,
        [25] = ammunition_get_squad,
        [26] = ammunition_set_amount,
        [27] = ammunition_set_flags,

        [30] = uniforms_get_list,
        [31] = uniforms_add,
        [32] = uniform_get_info,
        [33] = uniform_set_name,
        [34] = uniform_set_flags,
        [35] = uniform_get_additem,
        [36] = uniform_item_add,
        [37] = uniform_item_delete,
        [38] = uniform_delete,
        [39] = uniform_item_get_matchoices,
        [40] = uniform_item_set_material,
        [41] = uniform_item_get_colorchoices,
        [42] = uniform_item_set_color,
        [43] = uniform_apply,

        [50] = equipment_get,
        [51] = equipment_set_flags,
        [52] = equipment_item_delete,
        [53] = equipment_item_get_matchoices,
        [54] = equipment_item_set_material,        
        [55] = equipment_item_get_colorchoices,
        [56] = equipment_item_set_color,
        [57] = equipment_get_additem,
        [58] = equipment_item_add,
        [59] = equipment_get_additem_specific,
        [60] = equipment_item_add_specific,
    },

    [135] = {
        [1] = schedule_get_overview2,
        [2] = schedule_get_months,
        [3] = schedule_get_orders,
        [4] = schedule_month_duplicate_to_all,
        [5] = schedule_set_options,

        [10] = schedule_order_get,
        [11] = schedule_order_set_mincount,
        [12] = schedule_order_cancel,
        [13] = schedule_order_get_choices,
        [14] = schedule_order_add,
    },

    [136] = {
        [1] = waypoints_get_points,
        [2] = waypoints_nearest_point,
        [3] = waypoints_nearest_and_all,
        [4] = waypoints_add_point,
        [5] = waypoints_place_point,
        [6] = waypoints_mode_points,
        [7] = waypoints_delete_point,
        [8] = waypoints_zoom_to_point,
        [9] = waypoints_set_name_comment,

        [10] = routes_get_list,
        [11] = routes_add_route,
        [12] = route_delete,
        [13] = route_set_name,
        [14] = route_get_info,
        [15] = route_add_points,
        [16] = route_reorder_points,
        [17] = route_delete_point,
    },

    [137] = {
        [1] = civilizations_get_list,
        [2] = civilization_get_info,
        [3] = civilization_get_agreement,
    },

    [138] = {
        [1] = justice_get_data,
        [2] = justice_get_convict_info,
        [3] = justice_get_crime_details,
        [4] = justice_get_convict_choices,
        [5] = justice_convict,

        --xxx: temporary due to a typo in the app
        [10] = setup_get_settings,
    },

    [139] = {
        [1] = locations_get_list,
        [2] = location_get_info,
        [3] = location_set_restriction,
        [4] = location_set_parameter,
        [5] = location_retire,
        [6] = locations_add,
        [7] = locations_add_get_deity_choices,
        
        [10] = location_occupation_get_candidates,
        [11] = location_occupation_assign,

        [20] = location_assign_get_list,
        [21] = location_assign,
    },

    [140] = {
        [1] = building_stockpile_setmax,
        [2] = building_stockpile_getsettings,
        [3] = building_stockpile_setenabled,
        [4] = building_stockpile_setflag,
        [5] = building_stockpile_create,
        [6] = building_stockpile_getsettings_level3,
    },

    [141] = {
        [1] = petitions_get_list,
        [2] = petition_respond,
        [3] = petition_get_info,
    },

    [142] = {
        --[1] = jobs_get_list,
        [2] = job_get_description,
    },

    [144] = {
        [1] = status_get_overview,
        [2] = status_get_health,

        [10] = performance_skill_get_description,
    },

    [145] = {
        [1] = manager_get_orders,
        [2] = manager_get_ordertemplates,
        [3] = manager_new_order,
        [4] = manager_delete_order,
        [5] = manager_reorder,
        [6] = manager_order_set_max_workshops,
    },

    [146] = {
        [1] = hauling_get_routes,
        [2] = hauling_route_info,
        [3] = hauling_route_delete,
        [4] = hauling_route_delete_stop,
    },

    [148] = {
        [1] = look_get_details,
    },

    [149] = {
        [1] = query_building,
        [2] = query_unit,
        [3] = query_look,
    },

    [150] = {
        [3] = select_confirm,
        [4] = leavescreen,

        [10] = pause_game,
        [11] = save_game,
        [12] = save_and_close,
        [13] = close_legends,
        [14] = end_game_retire,
        [15] = end_game_abandon,
    },

    [151] = {
        [1] = orders_get,
        [2] = orders_set,
    },

    [152] = {
        [1] = squads_get_info,
        [2] = squads_reset,

        --todo: support multiple squads in the following commands
        [11] = squads_cancel_order,
        [12] = squads_order_move,
        [13] = squads_order_attack_list,
        [14] = squads_attack_list_get,
        [15] = squads_attack_list_confirm,
        [16] = squads_order_attack_map,
        [17] = squads_order_attack_rect,
        [18] = squad_set_alert,
    },

    [162] = {
        [1] = labors_get_labors,
        [2] = labors_get_counts,
        [3] = labors_get_all_dwarves,
        [4] = labors_get_dwarves_with_labor,
        [5] = labors_get_dwarf_labors,
        [6] = labors_set,
    },

    [167] = {
        [1] = stone_get,
        [2] = stone_set,
    },

    [171] = {
        [1] = depot_trade_overview,
        [2] = depot_trade_get_items,
        [3] = depot_trade_set,
        [4] = depot_trade_dotrade,
        [5] = depot_trade_seize,
        [6] = depot_trade_offer,
        [7] = depot_trade_get_items2,

        [20] = depot_movegoods_get,
        [21] = depot_movegoods_set,
        [22] = depot_movegoods_get2,

        [30] = depot_access,
    },

    [174] = {
        [1] = building_remove,
        [2] = building_stopremoval,
        [3] = building_get_contained_items,
        [4] = building_query_selected,
        [5] = building_set_flag,
        [6] = building_start_resize,
        [7] = building_suspend,
        [8] = building_quick_action,

        [10] = building_workshop_get_jobchoices,
        [11] = building_workshop_set_repeat,
        [12] = building_workshop_set_suspend,
        [13] = building_workshop_cancel,
        [14] = building_workshop_reorder,
        [15] = building_workshop_addjob,
        [16] = building_workshop_profile_get,
        [17] = building_workshop_profile_set_minmax,
        [18] = building_workshop_profile_set_unit,
        [19] = building_workshop_set_do_now,

        [30] = building_room_free,
        [31] = building_room_owner_get_candidates,
        [32] = building_room_owner_set,
        [33] = building_room_set_squaduse,
        [34] = building_room_owner_get_candidates2,
        [35] = building_room_owner_set2,

        [40] = building_farm_set_crop,
        [41] = building_assign_get_candidates,
        [42] = building_assign,
        
        [50] = buildings_get_list2,
        [51] = building_goto,
    },

    [176] = {
        [1] = announcements_get_log,
        [2] = reports_get_groups,
        [3] = reports_get,
        [4] = announcements_get_new,
        [5] = popup_dismiss,
        [5] = popup_dismiss_all,
    },

    [192] = {
        [1] = build,
        [2] = build_confirm,
        [3] = build_options_get,
        [4] = build_options_set,
        [5] = build_set_trap_options,
    },

    [193] = {
        [1] = set_traffic_costs,
        [2] = designate,
        [3] = designate_toggle_erase,
    },

    [195] = {
        [1] = unit_query_selected,
        [2] = unit_follow,

        [10] = units_list_dwarves,
        [11] = units_list_livestock,
        [12] = units_list_other,
        [13] = units_list_dead,
        
        [20] = unit_goto,
        [21] = unit_goto_bld,
        [22] = unit_job_removeworker,
        [23] = unit_job_suspend,
        [24] = unit_job_set_repeat,
        [25] = unit_job_cancel,
        
        [30] = unit_get_thoughts,
        [31] = unit_get_relationships,
        [32] = unit_get_inventory,
        [33] = unit_get_skills,
        [34] = unit_get_health,
        [35] = unit_customize,
        [36] = unit_get_inventory_and_spatters,
        [37] = unit_get_skills2,
        [38] = unit_get_skills3,

        [40] = unit_get_assigned_animals,
        [41] = unit_get_assign_animal_choices,
        [42] = unit_assign_animals,
    },

    [197] = {
        [1] = item_action,
        [2] = item_query,
        [3] = item_get_description,
        [4] = item_get_contained_items,
        [5] = item_get_contained_units,
        [6] = item_zoom,
    },

    [198] = {
        [1] = artifacts_list,
    },

    [199] = {
        [1] = job_details_get_types,
        [2] = job_details_get_choices,
        [3] = job_details_set,
        [4] = job_details_set_image,
        [5] = job_details_image_get_choices,
    },

    [203] = {
        [1] = build_req_get,
        [2] = build_req_choose,
        [3] = build_req_cancel,
        [4] = build_req_done,
    },

    [204] = {
        [1] = link_mechanisms_get,
        [2] = link_mechanisms_choose,
        [3] = link_mechanisms_cancel,
        [4] = link_targets_get,
        [5] = link_targets_zoom,
        [6] = link_target_confirm,
    },

    [237] = {
        [1] = savegame_list,
        [2] = savegame_load,
        [3] = savegame_checkloaded,
        [4] = worlds_get_empty,

        [10] = create_new_world,
        [11] = worldgen_status,
        [12] = worldgen_accept,
        [13] = worldgen_cancel,
        [14] = worldgen_get_world_info,
        [15] = worldgen_resolve_rejected,
        [16] = worldgen_continue,

        [20] = embark_get_overview,
        [21] = embark_set_civ,
        [22] = embark_finder_find,
        [23] = embark_finder_status,
        [24] = embark_cancel,
        [25] = embark_finder_stop,
        [26] = embark_finder_clear,
        [27] = embark_finder_next,
        [28] = embark_newgame,
        [29] = embark_get_reclaim_sites,
        [30] = embark_embark,
        [31] = embark_play,
        [32] = embark_back_to_map,
        [33] = embark_reclaim,
    },

    [238] = {
        [1] = setup_get_designations,
        [2] = setup_get_buildings,
        [3] = labors_get_labors,
        [4] = setup_get_server_info,
        [5] = setup_get_mapinfo,
        [6] = perform_update,
        [7] = raws_apply_tileset,
        [8] = raws_apply_creature_gfx,

        [10] = setup_get_settings,
        [11] = setup_set_setting,
    },

    [239] = {
        [1] = nobles_get_positions,
        [2] = nobles_get_candidates,
        [3] = nobles_replace,

        [10] = bookkeeper_set_precision,

        [20] = noble_get_mandates,
        [21] = noble_get_reqs,
    },

    [243] = {
        [10] = kitchen_get_data,
        [11] = kitchen_set,
    },

    [253] = {
        [1] = meeting_get,
        [2] = meeting_action,
        [3] = import_req_get_items,
        [4] = import_req_set,
        [5] = import_agreement_get,
        [6] = export_agreement_get,
        [7] = landholders_get,
        [8] = landholders_set,
    }
}

function handle_command(cmd, subcmd, seq, data, foreign)
    --print(cmd,subcmd,seq)

    ensure_native()

    local hs = foreign and handlers_foreign or handlers

    local grp = hs[cmd]
    local handler = (cmd < 128) and grp or (grp and grp[subcmd] or nil)

    if handler then
        local params = cmd < 128 and {data} or ((#data > 0) and mp.unpack(data) or {})
        local ret
        local ok,err = pcall(function() ret = handler(table.unpack(params)) end)
        if not ok then
            print (err)
        end
        
        if ok then
            return true, genrespseqstr(seq) .. (cmd < 128 and (ret or '') or mp.pack(ret))    
        else
            return true, generrseqstr(seq) .. err
        end
    end

    local err = 'no cmd ' .. tostring(cmd) .. ' ' .. tostring(subcmd)
    print(err)
    return true, generrseqstr(seq) .. err
end

local first_time_setup_done = false
function matching_version(clientver, apply)
    -- In the future we may support different client versions and will return the best possible match
    
    -- Also, we will configure some DF flags we require and unload incompatible plugins here
    if apply and not first_time_setup_done then
        print ('DF Remote will now adjust certain settings and disable several plugins that are incompatible with the server.\nYou may want to restart DF before playing locally again.')
        
        --df.global.init.display.flag.USE_GRAPHICS = false
        df.global.init.font.use_ttf = df.init_font.T_use_ttf.TTF_OFF
        
        df.global.d_init.flags4.PAUSE_ON_LOAD = true
        df.global.d_init.flags4.INITIAL_SAVE = false
        df.global.d_init.flags4.EMBARK_WARNING_ALWAYS = false
        df.global.d_init.post_prepare_embark_confirmation = df.d_init_embark_confirm.NO
        df.global.d_init.idlers = df.d_init_idlers.OFF
        
        --todo: don't use _silent if debug is on
        dfhack.run_command_silent('multilevel 0')
        dfhack.run_command_silent('disable confirm')
        --dfhack.run_command_silent('disable autolabor')
        dfhack.run_command_silent('unload workflow menu-mouse dwarfmonitor')
        
        -- disabled for now because it's not strictly required and the setting persists
        --dfhack.run_command_silent('gui/load-screen disable') 
        
        first_time_setup_done = true
    end
    
    --todo: print this in debug mode
    --print('using version ' .. remote_version .. ' for client version ' .. clientver, apply)
    return remote_version
end

if #df.global.world.status.announcements > 0 then
    lastann = df.global.world.status.announcements[#df.global.world.status.announcements-1].id
    lastannrep = df.global.world.status.announcements[#df.global.world.status.announcements-1].repeat_count
end

local remote = {
    handle_command = handle_command,
    get_status = get_status,
    get_status_ext = get_status_ext,
    matching_version = matching_version,
    
    get_version = function()
        return remote_version
    end,
    
    unload = function()
        --todo: restore modified settings and load unloaded plugins here?
        
        for n,p in pairs(package.loaded) do
            if n:sub(1,#'remote') == 'remote' then
                package.loaded[n] = nil
            end
        end
    end
}

return remote