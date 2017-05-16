function get_squads_use(bld)
    local squads = {}
    local eid = df.global.ui.main.fortress_entity.id

    for i,squad in ipairs(df.global.world.squads.all) do
        if squad.entity_id == eid then
            local name = squadname(squad)

            -- find if squad uses this room
            local roomuse = utils.binsearch(squad.rooms, bld.id, 'building_id')
            local mode = roomuse and roomuse.mode.whole or 0

            table.insert(squads, { name, squad.id, mode })
        end
    end

    return squads
end

--todo:  They may also say "Leave me. I need... things... certain things", in which case they want special items such as skulls or vermin remains.
local mood_items = { --as:string[][]
    [df.item_type.WOOD] = { 'logs', 'a forest', 'tree... life' }, --'wood logs'?
    [df.item_type.CLOTH] = { 'cloth', 'stacked cloth', 'cloth... thread' },
    [df.item_type.SMALLGEM] = { 'cut gems', 'cut gems', 'gems... shining' },
    [df.item_type.BAR] = { 'metal bars', 'shining bars of metal', 'bars... metal' },
    [df.item_type.SKIN_TANNED] = { 'tanned hides', 'stacked leather', 'leather... skin' },
    [df.item_type.BLOCKS] = { 'rock blocks', 'square blocks', 'blocks... bricks' },
    [df.item_type.BOULDER] = { 'rock', 'a quarry', 'stone... rock' },
    [df.item_type.ROUGH] = { 'rough gems', 'rough gems', 'rough... color' },

    ['bone'] = { 'bones', 'skeletons', 'bones... yes' },
    ['shell'] = { 'shells', 'shells', 'a shell...' },
    ['skull'] = { 'body parts', 'death', 'a corpse', '__things' },
}

function building_workshop_get_mood(bld)
    local job = (#bld.jobs > 0) and bld.jobs[0]

    if not job or df.job_type[job.job_type]:sub(1,#'StrangeMood') ~= 'StrangeMood' then
        return nil
    end

    local unitid = dfhack.job.getGeneralRef(job, df.general_ref_type.UNIT_WORKER).unit_id --hint:df.general_ref_unit_workerst
    local unit = df.unit.find(unitid)

    if not unit then
        return nil
    end

    local uname = unitname(unit)
    local prof = unitprof(unit)

    local demands = {}
    if unit.mood ~= df.mood_type.Fell then
        for i,ji in ipairs(job.job_items) do
            local mi = nil

            if ji.item_type == -1 then
                if ji.flags2.bone then
                    mi = mood_items['bone']
                elseif ji.flags2.shell then
                    mi = mood_items['shell']
                elseif ji.flags2.body_part then
                    mi = mood_items['skull']
                end
            else
                mi = mood_items[ji.item_type]
            end

            if not mi then
                table.insert(demands, '???') --todo: !!
                goto next
            end

            local demand = mi[unit.mood+1] or mi[1]
            if #demands > 0 and demands[#demands] == demand then --todo: really want this?
                goto next
            end

            table.insert(demands, demand)

            ::next::
        end
    end

    local artname = dfhack.TranslateName(unit.status.artifact_name) or ''

    return { uname, prof, unit.mood, demands, dfhack.df2utf(artname), job.flags.working }
end

local bait_types = { df.item_type.MEAT, df.item_type.FISH, df.item_type.GEM }
local function bait_idx(t)
    for i,v in ipairs(bait_types) do
        if v == t then
            return i
        end
    end

    return 0
end

--[[local function building_location_name(bld)
    local loc
    if df_ver >= 4200 then --dfver:4200-
        if bld.is_room and bld.location_id ~= -1 then
            loc = location_find_by_id(bld.location_id)
        end
    end

    return loc and locname(loc) or mp.NIL    
end]]

--xxx: most of the functions below can operate on the currently selected building only
--xxx: this function will try to transition to [q]uery mode and select the passed building
--xxx: currently this is used only to transition from loo[k] mode
--luacheck: in=number
function building_query_selected(bldid)
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        error('wrong screen '..tostring(ws._type))
    end

    local bld
    if bldid and bldid ~= -1 then
        bld = df.building.find(bldid)
    else
        bld = df.global.world.selected_building
    end

    if not bld then
        error('no building '..tostring(bldid))
    end

    if df.global.ui.main.mode ~= df.ui_sidebar_mode.QueryBuilding or df.global.world.selected_building ~= bld then
        df.global.ui.main.mode = df.ui_sidebar_mode.QueryBuilding
        df.global.cursor.x = bld.x1
        df.global.cursor.y = bld.y1
        df.global.cursor.z = bld.z-1
        gui.simulateInput(ws, K'CURSOR_UP_Z')        
    end

    local btype = bld:getType()
    local bsub = bld:getSubtype()
    local bname = bldname(bld)
    local ret = nil

    local removing = (#bld.jobs > 0 and bld.jobs[0].job_type == df.job_type.DestroyBuilding)
    local actual = df.building_actual:is_instance(bld)
    local forbidden = actual and #bld.contained_items > 0 and bld.contained_items[0].item.flags.forbid --hint:df.building_actual

    local curstage = bld:getBuildStage()
    local maxstage = bld:getMaxBuildStage()
    local constructed = (curstage == maxstage)
    local workshop_like = (btype == df.building_type.Workshop or btype == df.building_type.Furnace
        or (btype == df.building_type.Trap and (bsub == df.trap_type.Lever or bsub == df.trap_type.PressurePlate)))

    local genflags = packbits(removing, forbidden, actual, constructed, workshop_like)

    if not constructed then
        local needsarchitect = (bld:needsDesign() and not bld.design.flags.designed) --hint:df.building_actual

        --todo: how can there be no construction job (found in logs)?
        local cjob = #bld.jobs > 0 and bld.jobs[0]
        local active = cjob and (cjob.flags.fetching or cjob.flags.bringing or cjob.flags.working)
        local suspended = cjob and cjob.flags.suspend

        --todo: 'Construction initiated.' - when?
        local stagename
        if needsarchitect then
            stagename = 'Waiting for architect...'
        elseif curstage == 0 then
            stagename = 'Waiting for construction...'
        elseif curstage == 1 then
            stagename = 'Partially constructed.'
        elseif curstage == 2 then
            stagename = 'Construction nearly done.'
        else
            stagename = 'Constructing...' --xxx: just not to leave it empty in case there are other values
        end

        ret = { btype, genflags, bname, stagename, active, suspended }

    elseif btype == df.building_type.TradeDepot then
        local bld = bld --as:df.building_tradedepotst
        --todo: return broker name, current job, accessibility

        local caravan_state = #df.global.ui.caravans > 0 and df.global.ui.caravans[0].trade_state or 0

        local can_trade = depot_can_trade(bld)
        local can_movegoods = depot_can_movegoods(bld)

        local avail_flags = packbits(can_movegoods, can_trade)

        ret = { btype, genflags, bname, bld.trade_flags.whole, avail_flags }

    elseif btype == df.building_type.Door or btype == df.building_type.Hatch then
        local bld = bld --as:df.building_doorst
        ret = { btype, genflags, bname, bld.door_flags.whole }

    elseif btype == df.building_type.Windmill or btype == df.building_type.WaterWheel or btype == df.building_type.AxleVertical
        or btype == df.building_type.AxleHorizontal or btype == df.building_type.GearAssembly or btype == df.building_type.Rollers
        or btype == df.building_type.ScrewPump then
        local machine = df.machine.find(bld.machine.machine_id)

        local ttype = dfhack.maps.getTileType(bld.centerx, bld.centery, bld.z)
        local stable_foundation = (ttype ~= df.tiletype.OpenSpace)
        ret = { btype, genflags, bname, machine.cur_power, machine.min_power, machine.flags.whole, stable_foundation }

        if btype == df.building_type.Rollers or btype == df.building_type.ScrewPump then
            local bld = bld --as:df.building_rollersst
            table.insert(ret, bld.direction)
        end

        if btype == df.building_type.ScrewPump then
            local bld = bld --as:df.building_screw_pumpst
            table.insert(ret, bld.pump_manually)
        end
    
    elseif workshop_like then
        local jobs = {}
        for i,job in ipairs(bld.jobs) do
            local title = jobname(job)

            --todo: first check that job type supports setting details
            local can_set_details = (#job.items == 0)

            --todo: game actually shows 'A' not based on flags but rather on presence of general_ref_unit_workerst ref

            local moreflags = packbits(can_set_details)

            table.insert(jobs, { title, job.flags.whole, moreflags })
        end

        local moodinfo = building_workshop_get_mood(bld)
        local workshop_type = -1
        --todo: --fixme: should pass type for furnaces as well, but app currently doesn't check building type
        --               when comparing subtype, thus treating magma smelters and jeweler's workshops
        if btype == df.building_type.Trap then --as:bld=df.building_trapst
            workshop_type = bld.trap_type
        elseif btype == df.building_type.Workshop then --as:bld=df.building_workshopst
            workshop_type = bld.type
        end

        local profile_info = mp.NIL
        if have_noble('MANAGER') then
            local min = bld.profile.min_level
            local max = bld.profile.max_level

            if min == 3000 then
                min = 15
            end
            if max == 3000 then
                max = 15
            end

            profile_info = { #bld.profile.permitted_workers, min, max }
        end

        local clt = (btype == df.building_type.Workshop or btype == df.building_type.Furnace) and bld:getClutterLevel() or 0
        local num_items = (btype == df.building_type.Workshop or btype == df.building_type.Furnace) and #bld.contained_items or 0 --hint:df.building_actual

        --TODO: how to determine this properly?
        local millstone_needs_power = (workshop_type == df.workshop_type.Millstone) and #building_workshop_get_jobchoices(bldid) == 0 or false

        ret = { btype, genflags, bname, workshop_type, jobs, moodinfo or mp.NIL, profile_info, clt, num_items, millstone_needs_power }

    elseif btype == df.building_type.Chair or btype == df.building_type.Table or btype == df.building_type.Statue
        or btype == df.building_type.Bed or btype == df.building_type.Box or btype == df.building_type.Cabinet
        or btype == df.building_type.Armorstand or btype == df.building_type.Weaponrack or btype == df.building_type.ArcheryTarget
        or btype == df.building_type.Coffin or btype == df.building_type.Slab or btype == df.building_type.Cage
        or btype == df.building_type.Chain or btype == df.building_type.Well then

        local owner = bld.owner
        local ownername = owner and unit_fulltitle(owner) or ''
        if owner and C_unit_spouse_id(owner) ~= -1 then
            local owner2 = df.unit.find(C_unit_spouse_id(owner))
            if owner2 then
                ownername = ownername .. ' & ' .. unit_fulltitle(owner2)
            end
        end
        local ownerprof = mp.NIL --xxx: unused because fulltitle already includes profession (and becase of spouses)
        ret = { btype, genflags, bname, bld.is_room, ownername, ownerprof }

        if btype == df.building_type.Table then
            local bld = bld --as:df.building_tablest
            table.insert(ret, bld.table_flags.meeting_hall)
            
            local lname = mp.NIL
            if df_ver >= 4200 then --dfver:4200-
                if bld.is_room and bld.location_id ~= -1 then
                    local loc = location_find_by_id(bld.location_id)
                    if loc then
                        lname = locname(loc)
                    end
                end
            end
            table.insert(ret, lname)

        elseif btype == df.building_type.Bed then
            local bld = bld --as:df.building_bedst
            table.insert(ret, bld.bed_flags.whole)
            table.insert(ret, get_squads_use(bld))

            -- some operations on bedrooms are unavailable if the bed is in a tavern
            local lname, is_tavern = mp.NIL, false
            if df_ver >= 4200 then --dfver:4200-
                if bld.is_room and bld.location_id ~= -1 then
                    local loc = location_find_by_id(bld.location_id)
                    if loc then
                        lname = locname(loc) 
                        is_tavern = loc._type == df.abstract_building_inn_tavernst
                    end
                end
            end
            table.insert(ret, lname)
            table.insert(ret, is_tavern)

        elseif btype == df.building_type.ArcheryTarget then
            local bld = bld --as:df.building_archerytargetst
            table.insert(ret, bld.archery_direction)
            table.insert(ret, get_squads_use(bld))

        elseif btype == df.building_type.Box or btype == df.building_type.Cabinet
            or btype == df.building_type.Armorstand or btype == df.building_type.Weaponrack then
            table.insert(ret, get_squads_use(bld))
        
        elseif btype == df.building_type.Coffin then
            local bld = bld --as:df.building_coffinst
            local buried = owner and owner.flags1.dead or false
            local mode = bld.burial_mode
            local flags = packbits(mode.allow_burial, not mode.no_citizens, not mode.no_pets, buried)
            table.insert(ret, flags)

        elseif btype == df.building_type.Slab then
            local bld = bld --as:df.building_slabst
            local slabitem = bld.contained_items[0].item --as:df.item_slabst
            local inmemory = slabitem.engraving_type == df.slab_engraving_type.Memorial and slabitem.topic and hfname(df.historical_figure.find(slabitem.topic)) or mp.NIL
            --todo: show full description and not just the name
            table.insert(ret, inmemory)

        elseif btype == df.building_type.Cage then
            local bld = bld --as:df.building_cagest
            local occupants = {}

            for i,v in ipairs(bld.contained_items[0].item.general_refs) do
                if v._type == df.general_ref_contains_unitst then
                    local unit = df.unit.find(v.unit_id) --hint:df.general_ref_contains_unitst
                    if unit then
                        local title = unit_fulltitle(unit)
                        table.insert(occupants, { title, unit.id, 0 })
                    end
                elseif v._type == df.general_ref_contains_itemst then
                    local item = df.item.find(v.item_id) --hint:df.general_ref_contains_itemst
                    if item then
                        local title = itemname(item, 0, true)
                        table.insert(occupants, { title, item.id, 1 })
                    end
                end
            end

            table.insert(ret, occupants)

        elseif btype == df.building_type.Chain then
            local bld = bld --as:df.building_chainst
            local assigned = bld.assigned and unit_fulltitle(bld.assigned) or mp.NIL
            local chained = bld.chained and unit_fulltitle(bld.chained) or mp.NIL
            table.insert(ret, bld.flags.justice)
            table.insert(ret, assigned)
            table.insert(ret, bld.assigned and bld.assigned.id or -1)
            table.insert(ret, chained)
            table.insert(ret, bld.chained and bld.chained.id or -1)

        elseif btype == df.building_type.Well then
            local bld = bld --as:df.building_wellst
            local is_active = building_well_is_active()

            -- find bucket and check if liquid amount is 10
            local liquid = 0
            for j,w in ipairs(bld.contained_items) do
                if w.item._type == df.item_bucketst then
                    for i,v in ipairs(w.item.general_refs) do
                        if v._type == df.general_ref_contains_itemst then
                            local item = df.item.find(v.item_id) --hint:df.general_ref_item
                            if item and item._type == df.item_liquid_miscst then
                                liquid = liquid + item.stack_size --hint:df.item_liquid_miscst
                            end
                        end
                    end

                    break
                end
            end
            local is_full = liquid == 10

            local flags = packbits(is_active, is_full)
            table.insert(ret, flags)
        end

    elseif btype == df.building_type.FarmPlot then
        local bld = bld --as:df.building_farmplotst
        local keys = { K'BUILDJOB_FARM_SPRING', K'BUILDJOB_FARM_SUMMER', K'BUILDJOB_FARM_AUTUMN', K'BUILDJOB_FARM_WINTER' }

        local crops = {}
        for i,sk in ipairs(keys) do
            gui.simulateInput(ws, sk)

            local seascrops = { { 'Fallow', 9999, true } }
            for i,plantid in ipairs(df.global.ui.selected_farm_crops) do
                local name = df.global.world.raws.plants.all[plantid].name_plural:gsub("^%l", string.upper)
                local has_seeds = df.global.ui.available_seeds[i]
                table.insert(seascrops, { name, plantid, has_seeds })
            end
            table.insert(crops, seascrops)
        end

        local seasons = {}
        for i,plantid in ipairs(bld.plant_id) do
            local name = (plantid ~= -1) and df.global.world.raws.plants.all[plantid].name_plural:gsub("^%l", string.upper) or 'Fallow'
            table.insert(seasons, name)
        end

        local fert = (#bld.jobs > 0 and bld.jobs[0].job_type == df.job_type.FertilizeField)
        local fertinfo = { fert, bld.current_fertilization, bld.max_fertilization, bld.material_amount }

        ret = { btype, genflags, bname, seasons, crops, fertinfo, bld.seasonal_fertilize }

    elseif btype == df.building_type.Stockpile then
        local bld = bld --as:df.building_stockpilest
        local area = (bld.x2-bld.x1+1)*(bld.y2-bld.y1+1)

        ret = { btype, genflags, bname, area, bld.max_barrels, bld.max_bins, bld.max_wheelbarrows }

    elseif btype == df.building_type.SiegeEngine then
        local bld = bld --as:df.building_siegeenginest
        ret = { btype, genflags, bname, bld.type, bld.action, bld.facing }

    elseif btype == df.building_type.NestBox then
        local bld = bld --as:df.building_nest_boxst
        local unit = bld.claimed_by ~= -1 and df.unit.find(bld.claimed_by)
        local unitname = unit and unit_fulltitle(unit) or mp.NIL
        ret = { btype, genflags, bname, unitname }

    elseif btype == df.building_type.Hive then
        local bld = bld --as:df.building_hivest
        local hiveflags = bld.hive_flags.whole
        ret = { btype, genflags, bname, hiveflags }

    elseif btype == df.building_type.AnimalTrap then
        local bld = bld --as:df.building_animaltrapst
        local baitidx = bait_idx(bld.bait_type)
        local bait = #bld.contained_items > 1 and bld.contained_items[1].item --todo: is this correct?
        local itemname = bait and itemname(bait, 0, true) or mp.NIL
        local caught = bait and bait._type == df.item_verminst
        ret = { btype, genflags, bname, baitidx, itemname, caught }

    else
        ret = { btype, genflags, bname }
    end

    return ret
end

--luacheck: in=number,number,bool
function building_workshop_set_repeat(bldid, idx, value)
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        return
    end

    if df.global.ui.main.mode ~= 17 or df.global.world.selected_building == nil then
        return
    end

    local bld = df.global.world.selected_building

    bld.jobs[idx].flags['repeat'] = istrue(value)

    return true
end

--luacheck: in=number,number,bool
function building_workshop_set_suspend(bldid, idx, value)
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        return
    end

    if df.global.ui.main.mode ~= 17 or df.global.world.selected_building == nil then
        return
    end

    local bld = df.global.world.selected_building

    if bld.jobs[idx].flags['suspend'] ~= istrue(value) then
        df.global.ui_workshop_job_cursor = idx
        gui.simulateInput(ws, K'BUILDJOB_SUSPEND')
    end

    return true    
end

--luacheck: in=number,number,bool
function building_workshop_set_do_now(bldid, idx, value)
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        return
    end

    if df.global.ui.main.mode ~= 17 or df.global.world.selected_building == nil then
        return
    end

    local bld = df.global.world.selected_building

    if bld.jobs[idx].flags['do_now'] ~= istrue(value) then
        df.global.ui_workshop_job_cursor = idx
        gui.simulateInput(ws, K'BUILDJOB_NOW')
    end

    return true    
end

--luacheck: in=number,number
function building_workshop_cancel(bldid, idx)
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        return
    end

    if df.global.ui.main.mode ~= 17 or df.global.world.selected_building == nil then
        return
    end

    local bld = df.global.world.selected_building

    df.global.ui_workshop_job_cursor = idx
    gui.simulateInput(ws, K'BUILDJOB_CANCEL')

    return true    
end

--luacheck: in=number,number,number
function building_workshop_reorder(bldid, fromidx, toidx)
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        return
    end

    if df.global.ui.main.mode ~= 17 or df.global.world.selected_building == nil then
        return
    end

    local bld = df.global.world.selected_building

    local j = bld.jobs[fromidx]
    bld.jobs:erase(fromidx)
    bld.jobs:insert(toidx, j)

    return true    
end

function clone_job_button(orig)
    local btn = df.interface_button_building_new_jobst:new()

    --btn.building=bld
    btn.job_type = orig.job_type
    btn.reaction_name=orig.reaction_name
    btn.item_type = orig.item_type
    btn.item_subtype=orig.item_subtype
    btn.mat_type=orig.mat_type
    btn.mat_index=orig.mat_index
    btn.item_category.whole=orig.item_category.whole
    btn.material_category.whole=orig.material_category.whole
    btn.hist_figure_id=orig.hist_figure_id

    return btn
end    

local jobchoices = {}

--todo: refactor this to have two separate paths for interface_button_building_new_jobst and subcategories
function get_job_choices(ws, level)
    local ret = {}
    for i,btn in ipairs(df.global.ui_sidebar_menus.workshop_job.choices_visible) do
        local btn = btn --as:df.interface_button_building_new_jobst
        local unavailable = false
        local memorialized = false
        local slab = false

        if btn._type == df.interface_button_building_new_jobst then
            unavailable = btn.is_custom
            table.insert(jobchoices, clone_job_button(btn))
        end

        local title = utils.call_with_string(btn, 'getLabel')
        if btn._type == df.interface_button_building_new_jobst and btn.job_type == df.job_type.EngraveSlab then
            slab = true
            title = title:gsub(' %(Engrave Memorial%)', '')
            local hfid = btn.hist_figure_id

            for j,w in ipairs(df.global.world.buildings.other.SLAB) do --as:df.building_slabst
                if #w.contained_items > 0 and w.contained_items[0].item.topic == hfid then --hint:df.item_slabst
                    memorialized = true
                    break
                end
            end
        end

        local key = dfhack.screen.getKeyDisplay(btn.hotkey_id)
        if key == '?' then
            key = ''
        end

        local descr = mp.NIL
        local subchoices = mp.NIL
        if btn._type == df.interface_button_buildingst or btn._type == df.interface_button_building_material_selectorst or btn._type == df.interface_button_building_category_selectorst then
            if level == 0 then
                df.global.ui_workshop_in_add = true
                ws:logic() --to initialize / switch to add job menu
            end
            btn:click()
            --gui.simulateInput(ws, btn.hotkey_id)
            ws:logic()
            subchoices = get_job_choices(ws, level+1)

            if level > 0 then
                gui.simulateInput(ws, K'LEAVESCREEN')
            else
                gui.simulateInput(ws, K'CURSOR_DOWN_Z')
                gui.simulateInput(ws, K'CURSOR_UP_Z')
            end
            
        else
            if df_ver >= 4200 then --dfver:4200-
                if btn.job_type == df.job_type.CustomReaction and btn.reaction_name:sub(1,5) == 'MAKE_' then
                    local rid = btn.reaction_name:sub(6)
                    local found = false
                    for i,v in ipairs(df.global.world.raws.itemdefs.instruments) do
                        if v.id == rid then
                            descr = dfhack.df2utf(v.description:gsub('%s+', ' '))
                            found = true
                            break
                        end
                    end
                    if not found then
                        for i,v in ipairs(df.global.world.raws.itemdefs.tools) do
                            if v.id == rid then
                                descr = dfhack.df2utf(v.description:gsub('%s+', ' '))
                                found = true
                                break
                            end
                        end
                    end
                end
            end
        end

        local flags = packbits(unavailable, slab, memorialized)
        table.insert(ret, { dfhack.df2utf(title), key, subchoices, #jobchoices, flags, descr })

        ::continue::
    end    

    return ret
end

--todo: don't hardcode this; should find all glasses in df.global.world.raws.mat_table.builtin
local glasses = { 'green glass', 'clear glass', 'crystal glass' }

function building_workshop_get_jobchoices(bldid)
    local ws = dfhack.gui.getCurViewscreen() --as:df.viewscreen_dwarfmodest
    if ws._type ~= df.viewscreen_dwarfmodest then
        error('wrong screen '..tostring(ws._type))
    end

    if df.global.ui.main.mode ~= 17 or df.global.world.selected_building == nil then
        error('no selected building')
    end

    local ret = {}
    local bld = df.global.world.selected_building

    if bld._type == df.building_trapst and (bld.trap_type == df.trap_type.Lever or bld.trap_type == df.trap_type.PressurePlate) then --hint:df.building_trapst
        local bld = bld --as:df.building_trapst

        if bld.trap_type == df.trap_type.Lever then
            table.insert(ret, { 'Pull the Lever', 'P', mp.NIL, 0, 0 })
        end

        table.insert(ret, { 'Link up a Bridge', 'b', mp.NIL, 1, 0 })
        table.insert(ret, { 'Link up a Cage', 'j', mp.NIL, 2, 0 })
        table.insert(ret, { 'Link up a Chain', 'c', mp.NIL, 3, 0 })
        table.insert(ret, { 'Link up a Door', 'd', mp.NIL, 4, 0 })
        table.insert(ret, { 'Link up a Floodgate', 'f', mp.NIL, 5, 0 })
        table.insert(ret, { 'Link up a Hatch', 'h', mp.NIL, 6, 0 })
        table.insert(ret, { 'Link up a Wall Grate', 'w', mp.NIL, 7, 0 })
        table.insert(ret, { 'Link up a Floor Grate', 'g', mp.NIL, 8, 0 })
        table.insert(ret, { 'Link up Vertical Bars', 'B', mp.NIL, 9, 0 })
        table.insert(ret, { 'Link up a Floor Bars', 'Alt+b', mp.NIL, 10, 0 })
        table.insert(ret, { 'Link up a Support', 's', mp.NIL, 11, 0 })
        table.insert(ret, { 'Link up Spears / Spikes', 'S', mp.NIL, 12, 0 })
        table.insert(ret, { 'Link up a Gear Assembly', 'a', mp.NIL, 13, 0 })
        table.insert(ret, { 'Link up a Track Stop', 'T', mp.NIL, 14, 0 })

    elseif bld._type == df.building_workshopst then
        local bld = bld --as:df.building_workshopst
        local wtype = bld.type
        
        if wtype == df.workshop_type.Mechanics then
            table.insert(ret, { 'Make Rock Mechanisms', 't', mp.NIL, 0, 0 })
            table.insert(ret, { 'Make Traction Bench', 'R', mp.NIL, 1, 0 })
    
        elseif wtype == df.workshop_type.Butchers then
            table.insert(ret, { 'Butcher a dead animal', 'b', mp.NIL, 0, 0 })
            table.insert(ret, { 'Extract from a dead animal', 'e', mp.NIL, 1, 0 })
            table.insert(ret, { 'Capture a live land animal', 'a', mp.NIL, 2, 0 })
    
        elseif wtype == df.workshop_type.Fishery then
            table.insert(ret, { 'Process a Raw Fish', 'p', mp.NIL, 0, 0 })
            table.insert(ret, { 'Extract from a Raw Fish', 'e', mp.NIL, 1, 0 })
            table.insert(ret, { 'Capture a Live Fish', 'f', mp.NIL, 2, 0 })
    
        elseif wtype == df.workshop_type.Loom then
            table.insert(ret, { 'Collect Webs', 'c', mp.NIL, 0, 0 })
            table.insert(ret, { 'Weave Cloth (Plant Thread)', 'w', mp.NIL, 1, 0 })
            table.insert(ret, { 'Weave Silk Cloth', 's', mp.NIL, 2, 0 })
            table.insert(ret, { 'Weave Cloth (Wool/Hair Yarn)', 'y', mp.NIL, 3, 0 })
            table.insert(ret, { 'Weave Metal Cloth', 'a', mp.NIL, 4, 0 })
    
        elseif wtype == df.workshop_type.Kennels then
            table.insert(ret, { 'Capture a Live Land Animal', 'a', mp.NIL, 0, 0 })
            table.insert(ret, { 'Tame a Small Animal', 't', mp.NIL, 1, 0 })
    
        elseif wtype == df.workshop_type.Dyers then
            table.insert(ret, { 'Dye Thread', 't', mp.NIL, 0, 0 })
            table.insert(ret, { 'Dye Cloth', 'c', mp.NIL, 1, 0 })
    
        elseif wtype == df.workshop_type.Jewelers then
            for i=0,#ws.jeweler_cutgem-1 do
                local matname
                local cut = ws.jeweler_cutgem[i] > 0
                local enc = ws.jeweler_encrust[i] > 0
                if cut or enc then
                    if i < #df.global.world.raws.inorganics then
                        local matinfo = dfhack.matinfo.decode(0,i)
                        matname = matinfo and matinfo.material.state_name[0] or '#unknown material#'
                    elseif i - #df.global.world.raws.inorganics < 3 then
                        matname = glasses[i - #df.global.world.raws.inorganics + 1]
                    else
                        matname = '#unknown material#'
                    end
                end
    
                local opts = {}
                if cut then
                    table.insert(opts, { 'Cut '..matname, '', mp.NIL, #ret*4+0, 0 })
                end
                if enc then
                    table.insert(opts, { 'Encrust Finished Goods with '..matname, '', mp.NIL, #ret*4+1, 0 })
                    table.insert(opts, { 'Encrust Furniture with '..matname, '', mp.NIL, #ret*4+2, 0 })
                    table.insert(opts, { 'Encrust Ammo with '..matname, '', mp.NIL, #ret*4+3, 0 })
                end
                if #opts > 0 then
                    table.insert(ret, { matname, '', opts, (cut and 1 or 0) + (enc and 2 or 0), 0 })
                end
            end
        
        else
            jobchoices = {}
            ret = get_job_choices(ws, 0)
        end

    else
        jobchoices = {}
        ret = get_job_choices(ws, 0)
    end

    return ret
end

local jobs_mechanics = { K'HOTKEY_MECHANIC_PARTS', K'HOTKEY_MECHANIC_TRACTION_BENCH' }
local jobs_butchers = { K'HOTKEY_BUTCHER_BUTCHER', K'HOTKEY_BUTCHER_EXTRACT', K'HOTKEY_BUTCHER_CATCH' }
local jobs_fishery = { K'HOTKEY_FISHERY_PROCESS', K'HOTKEY_FISHERY_EXTRACT', K'HOTKEY_FISHERY_CATCH' }
local jobs_loom = { K'HOTKEY_LOOM_COLLECT_SILK', K'HOTKEY_LOOM_WEAVE_CLOTH', K'HOTKEY_LOOM_WEAVE_SILK', K'HOTKEY_LOOM_WEAVE_YARN', K'HOTKEY_LOOM_WEAVE_METAL' }
local jobs_kennels = { K'HOTKEY_KENNEL_CATCH_VERMIN', K'HOTKEY_KENNEL_TAME_VERMIN' }
local jobs_dyers = { K'HOTKEY_DYER_THREAD', K'HOTKEY_DYER_CLOTH' }
local jobs_trap = { K'HOTKEY_TRAP_PULL_LEVER', K'HOTKEY_TRAP_BRIDGE', K'HOTKEY_TRAP_CAGE', K'HOTKEY_TRAP_CHAIN', K'HOTKEY_TRAP_DOOR', K'HOTKEY_TRAP_FLOODGATE', K'HOTKEY_TRAP_HATCH', K'HOTKEY_TRAP_GRATE_WALL', K'HOTKEY_TRAP_GRATE_FLOOR', K'HOTKEY_TRAP_BARS_VERTICAL', K'HOTKEY_TRAP_BARS_FLOOR', K'HOTKEY_TRAP_SUPPORT', K'HOTKEY_TRAP_SPIKE', K'HOTKEY_TRAP_GEAR_ASSEMBLY', K'HOTKEY_TRAP_TRACK_STOP' }

--luacheck: in=number,number,bool
function building_workshop_addjob(bldid, idx, rep)
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        error('wrong screen '..tostring(ws._type))
    end

    if df.global.ui.main.mode ~= 17 or df.global.world.selected_building == nil then
        error('no selected building')
    end

    local bld = df.global.world.selected_building
    if bld._type ~= df.building_workshopst and bld._type ~= df.building_furnacest and bld._type ~= df.building_trapst then
        error('not workshop or furnace or trap '..tostring(bld._type))
    end

    if #bld.jobs >= 10 then
        return --error('too many jobs')
    end
    
    df.global.ui_workshop_in_add = false

    if bld._type == df.building_trapst and (bld.trap_type == df.trap_type.Lever or bld.trap_type == df.trap_type.PressurePlate) then --hint:df.building_trapst
        local bld = bld --as:df.building_trapst

        if idx < #jobs_trap then
            gui.simulateInput(ws, K'BUILDJOB_ADD')
            ws:logic() --to initialize / switch to add job menu
            gui.simulateInput(ws, jobs_trap[idx+1])

            if df.global.ui_workshop_in_add and C_lever_target_type_get() ~= -1 then
                recenter_view(df.global.cursor.x, df.global.cursor.y, df.global.cursor.z)
            end
        end

    else
        local bld = bld --as:df.building_workshopst
        local wtype = bld.type

        if wtype == df.workshop_type.Mechanics then
            if idx < #jobs_mechanics then
                gui.simulateInput(ws, K'BUILDJOB_ADD')
                ws:logic() --to initialize / switch to add job menu
                gui.simulateInput(ws, jobs_mechanics[idx+1])
            end
    
        elseif wtype == df.workshop_type.Butchers then
            if idx < #jobs_butchers then
                gui.simulateInput(ws, K'BUILDJOB_ADD')
                ws:logic() --to initialize / switch to add job menu
                gui.simulateInput(ws, jobs_butchers[idx+1])
            end
    
        elseif wtype == df.workshop_type.Fishery then
            if idx < #jobs_fishery then
                gui.simulateInput(ws, K'BUILDJOB_ADD')
                ws:logic() --to initialize / switch to add job menu
                gui.simulateInput(ws, jobs_fishery[idx+1])
            end
    
        elseif wtype == df.workshop_type.Loom then
            if idx < #jobs_loom then
                gui.simulateInput(ws, 'BUILDJOB_ADD')
                ws:logic() --to initialize / switch to add job menu
                gui.simulateInput(ws, jobs_loom[idx+1])
            end
    
        elseif wtype == df.workshop_type.Kennels then
            if idx < #jobs_kennels then
                gui.simulateInput(ws, K'BUILDJOB_ADD')
                ws:logic() --to initialize / switch to add job menu
                gui.simulateInput(ws, jobs_kennels[idx+1])
            end
    
        elseif wtype == df.workshop_type.Dyers then
            if idx < #jobs_dyers then
                gui.simulateInput(ws, K'BUILDJOB_ADD')
                ws:logic() --to initialize / switch to add job menu
                gui.simulateInput(ws, jobs_dyers[idx+1])
            end
    
        elseif wtype == df.workshop_type.Jewelers then
            gui.simulateInput(ws, K'BUILDJOB_ADD')
            ws:logic() --to initialize / switch to add job menu
            local m = math.floor(idx / 4)
            local t = idx % 4
            df.global.ui_building_item_cursor = m
            if t == 0 then
                gui.simulateInput(ws, K'HOTKEY_JEWELER_CUT')
            else
                local w = { K'HOTKEY_JEWELER_FINISHED', K'HOTKEY_JEWELER_FURNITURE', K'HOTKEY_JEWELER_AMMO' }
                ws:logic() --to initialize / switch to menu
                gui.simulateInput(ws, K'HOTKEY_JEWELER_ENCRUST')
                gui.simulateInput(ws, w[t])
            end
        
        else    
            local btn = jobchoices[idx] --as:df.interface_button_building_new_jobst
            btn.building = bld
    
            btn:click()
        end
    end

    --todo: check here again for traps and other unsopported job types
    if istrue(rep) then
        --todo: check that there's indeed a new job added
        if #bld.jobs > 0 then
            bld.jobs[#bld.jobs-1].flags['repeat'] = true
        end
    end

    return true
end

--luacheck: in=number
function building_workshop_profile_get(bldid)
    --[[local bld = df.building.find(bldid)
    if not bld or (bld._type ~= df.building_furnacest and bld._type ~= df.building_workshopst) then
        return nil
    end]]

    local ws = screen_main()
    if ws._type ~= df.viewscreen_dwarfmodest then
        return
    end

    if df.global.ui.main.mode ~= 17 or df.global.world.selected_building == nil then
        return
    end

    local bld = df.global.world.selected_building --as:df.building_workshopst
    --[[if bld._type ~= df.building_workshopst and bld._type ~= df.building_furnacest then
        error('not a workshop or furnace '..tostring(bld._type))
    end]]

    local profile = bld.profile
    local workers = {}
    local permitted_workers = {}

    for i,v in ipairs(profile.permitted_workers) do
        table.insert(permitted_workers, v)
    end

    for i,unit in ipairs(unitlist_get_units(df.viewscreen_unitlist_page.Citizens)) do
        table.insert(workers, { unit_fulltitle(unit), unit.id })
    end

    local min = profile.min_level
    local max = profile.max_level

    if min == 3000 then
        min = 15
    end
    if max == 3000 then
        max = 15
    end

    return { workers, permitted_workers, min, max }
end

--luacheck: in=number,number,number
function building_workshop_profile_set_minmax(bldid, min, max)
    --[[local bld = df.building.find(bldid)
    if not bld or (bld._type ~= df.building_furnacest and bld._type ~= df.building_workshopst) then
        return nil
    end]]

    local ws = screen_main()
    if ws._type ~= df.viewscreen_dwarfmodest then
        return
    end

    if df.global.ui.main.mode ~= 17 or df.global.world.selected_building == nil then
        return
    end

    local bld = df.global.world.selected_building --as:df.building_workshopst
    --[[if bld._type ~= df.building_workshopst and bld._type ~= df.building_furnacest then
        error('not a workshop or furnace '..tostring(bld._type))
    end]]

    local profile = bld.profile

    if min == 15 then
        min = 3000
    end
    if max == 15 then
        max = 3000
    end

    profile.min_level = min    
    profile.max_level = max    

    return true
end

--luacheck: in=number,number,bool
function building_workshop_profile_set_unit(bldid, unitid, on)
    --[[local bld = df.building.find(bldid)
    if not bld or (bld._type ~= df.building_furnacest and bld._type ~= df.building_workshopst) then
        return nil
    end]]

    local ws = screen_main()
    if ws._type ~= df.viewscreen_dwarfmodest then
        return
    end

    if df.global.ui.main.mode ~= 17 or df.global.world.selected_building == nil then
        return
    end

    local bld = df.global.world.selected_building --as:df.building_workshopst
    --[[if bld._type ~= df.building_workshopst and bld._type ~= df.building_furnacest then
        error('not a workshop or furnace '..tostring(bld._type))
    end]]

    local profile = bld.profile
    on = istrue(on)

    if unitid == -1 then
        if on then
            profile.permitted_workers:resize(0)
        end

    else
        if on then
            utils.insert_sorted(profile.permitted_workers, unitid)
        else
            -- it's not sorted in game, can't use erase_sorted()
            for i,v in ipairs(profile.permitted_workers) do
                if v == unitid then
                    profile.permitted_workers:erase(i)
                    break
                end
            end
        end
    end

    return true
end

--luacheck: in=number
function building_room_free(bldid)
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        print('a')
        return
    end

    if df.global.ui.main.mode ~= 17 or df.global.world.selected_building == nil then
        print('b')
        return
    end

    if not df.global.world.selected_building.is_room then
        print('c')
        return
    end

    local keys = {
        [df.building_type.Chair] = K'BUILDJOB_CHAIR_FREE',
        [df.building_type.Table] = K'BUILDJOB_TABLE_FREE',
        [df.building_type.Bed] = K'BUILDJOB_BED_FREE',
        [df.building_type.Box] = K'BUILDJOB_RACKSTAND_FREE',
        [df.building_type.Cabinet] = K'BUILDJOB_RACKSTAND_FREE',
        [df.building_type.Armorstand] = K'BUILDJOB_RACKSTAND_FREE',
        [df.building_type.Weaponrack] = K'BUILDJOB_RACKSTAND_FREE',
        [df.building_type.ArcheryTarget] = K'BUILDJOB_TARGET_FREE',
        [df.building_type.Coffin] = K'BUILDJOB_COFFIN_FREE',
        [df.building_type.Slab] = K'BUILDJOB_STATUE_FREE',
        [df.building_type.Cage] = K'BUILDJOB_CAGE_FREE',
        [df.building_type.Chain] = K'BUILDJOB_CHAIN_FREE',
        [df.building_type.Well] = K'BUILDJOB_WELL_FREE',
    }

    gui.simulateInput(ws, keys[df.global.world.selected_building:getType()])

    return true
end

--luacheck: in=number
function building_room_owner_get_candidates(bldid)
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        error('wrong screen '..tostring(ws._type))
    end

    if df.global.ui.main.mode ~= 17 or df.global.world.selected_building == nil then
        error('no selected building')
    end

    if not df.global.world.selected_building.is_room then
        error('not a room')
    end

    local keys = {
        [df.building_type.Chair] = K'BUILDJOB_CHAIR_ASSIGN',
        [df.building_type.Table] = K'BUILDJOB_TABLE_ASSIGN',
        [df.building_type.Bed] = K'BUILDJOB_BED_ASSIGN',
        [df.building_type.Box] = K'BUILDJOB_RACKSTAND_ASSIGN',
        [df.building_type.Cabinet] = K'BUILDJOB_RACKSTAND_ASSIGN',
        [df.building_type.Armorstand] = K'BUILDJOB_RACKSTAND_ASSIGN',
        [df.building_type.Weaponrack] = K'BUILDJOB_RACKSTAND_ASSIGN',
        [df.building_type.Coffin] = K'BUILDJOB_COFFIN_ASSIGN',
        [df.building_type.Slab] = K'BUILDJOB_STATUE_ASSIGN',  
        [df.building_type.Cage] = K'BUILDJOB_CAGE_ASSIGN',
        [df.building_type.Chain] = K'BUILDJOB_CHAIN_ASSIGN',
    }

    gui.simulateInput(ws, keys[df.global.world.selected_building:getType()])
    --todo: don't know which of the following is required
    ws:logic()
    ws:render()

    --todo: check that we have switched to the assignment mode

    local ret = {}

    for i,unit in ipairs(df.global.ui_building_assign_units) do
        if not unit then
            table.insert(ret, { 'Nobody', '', false })
        else
            local cname = unitname(unit)
            local cprof = unitprof(unit)
            table.insert(ret, { cname, cprof, unit.flags1.dead })        
        end
    end

    df.global.ui_building_in_assign = false

    return ret
end

--luacheck: in=number
function building_room_owner_get_candidates2(bldid)
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        error('wrong screen '..tostring(ws._type))
    end

    if df.global.ui.main.mode ~= 17 or df.global.world.selected_building == nil then
        error('no selected building')
    end

    if not df.global.world.selected_building.is_room then
        error('not a room')
    end

    local keys = {
        [df.building_type.Chair] = K'BUILDJOB_CHAIR_ASSIGN',
        [df.building_type.Table] = K'BUILDJOB_TABLE_ASSIGN',
        [df.building_type.Bed] = K'BUILDJOB_BED_ASSIGN',
        [df.building_type.Box] = K'BUILDJOB_RACKSTAND_ASSIGN',
        [df.building_type.Cabinet] = K'BUILDJOB_RACKSTAND_ASSIGN',
        [df.building_type.Armorstand] = K'BUILDJOB_RACKSTAND_ASSIGN',
        [df.building_type.Weaponrack] = K'BUILDJOB_RACKSTAND_ASSIGN',
        [df.building_type.Coffin] = K'BUILDJOB_COFFIN_ASSIGN',
        [df.building_type.Slab] = K'BUILDJOB_STATUE_ASSIGN',  
        [df.building_type.Cage] = K'BUILDJOB_CAGE_ASSIGN',
        [df.building_type.Chain] = K'BUILDJOB_CHAIN_ASSIGN',
    }

    gui.simulateInput(ws, keys[df.global.world.selected_building:getType()])
    --todo: don't know which of the following is required
    ws:logic()
    ws:render()

    --todo: check that we have switched to the assignment mode

    local ret = {}

    for i,unit in ipairs(df.global.ui_building_assign_units) do
        if not unit then
            table.insert(ret, { 'Nobody', -1, 15, false })
        else
            local cname = unit_fulltitle(unit)
            local cprofcolor = dfhack.units.getProfessionColor(unit)
            table.insert(ret, { cname, unit.id, cprofcolor, unit.flags1.dead })        
        end
    end

    df.global.ui_building_in_assign = false

    return ret
end

--luacheck: in=number,number
function building_room_owner_set(bldid, idx)
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        error('wrong screen '..tostring(ws._type))
    end

    if df.global.ui.main.mode ~= 17 or df.global.world.selected_building == nil then
        error('no selected building')
    end

    if not df.global.world.selected_building.is_room then
        error('not a room')
    end

    local keys = {
        [df.building_type.Chair] = K'BUILDJOB_CHAIR_ASSIGN',
        [df.building_type.Table] = K'BUILDJOB_TABLE_ASSIGN',
        [df.building_type.Bed] = K'BUILDJOB_BED_ASSIGN',
        [df.building_type.Box] = K'BUILDJOB_RACKSTAND_ASSIGN',
        [df.building_type.Cabinet] = K'BUILDJOB_RACKSTAND_ASSIGN',
        [df.building_type.Armorstand] = K'BUILDJOB_RACKSTAND_ASSIGN',
        [df.building_type.Weaponrack] = K'BUILDJOB_RACKSTAND_ASSIGN',
        [df.building_type.Coffin] = K'BUILDJOB_COFFIN_ASSIGN',
        [df.building_type.Slab] = K'BUILDJOB_STATUE_ASSIGN',  
        [df.building_type.Cage] = K'BUILDJOB_CAGE_ASSIGN',
        [df.building_type.Chain] = K'BUILDJOB_CHAIN_ASSIGN',
    }

    gui.simulateInput(ws, keys[df.global.world.selected_building:getType()])
    --todo: don't know which of the following is required
    ws:logic()
    ws:render()

    --todo: check that we have switched to the assignment mode    

    df.global.ui_building_item_cursor = idx    
    gui.simulateInput(ws, 'SELECT')

    df.global.ui_building_in_assign = false    

    return true
end

--luacheck: in=number,number
function building_room_owner_set2(bldid, id)
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        error('wrong screen '..tostring(ws._type))
    end

    if df.global.ui.main.mode ~= 17 or df.global.world.selected_building == nil then
        error('no selected building')
    end

    if not df.global.world.selected_building.is_room then
        error('not a room')
    end

    local keys = {
        [df.building_type.Chair] = K'BUILDJOB_CHAIR_ASSIGN',
        [df.building_type.Table] = K'BUILDJOB_TABLE_ASSIGN',
        [df.building_type.Bed] = K'BUILDJOB_BED_ASSIGN',
        [df.building_type.Box] = K'BUILDJOB_RACKSTAND_ASSIGN',
        [df.building_type.Cabinet] = K'BUILDJOB_RACKSTAND_ASSIGN',
        [df.building_type.Armorstand] = K'BUILDJOB_RACKSTAND_ASSIGN',
        [df.building_type.Weaponrack] = K'BUILDJOB_RACKSTAND_ASSIGN',
        [df.building_type.Coffin] = K'BUILDJOB_COFFIN_ASSIGN',
        [df.building_type.Slab] = K'BUILDJOB_STATUE_ASSIGN',  
        [df.building_type.Cage] = K'BUILDJOB_CAGE_ASSIGN',
        [df.building_type.Chain] = K'BUILDJOB_CHAIN_ASSIGN',
    }

    gui.simulateInput(ws, keys[df.global.world.selected_building:getType()])
    --todo: don't know which of the following is required
    ws:logic()
    ws:render()

    --todo: check that we have switched to the assignment mode    

    for i,unit in ipairs(df.global.ui_building_assign_units) do
        if (not unit and id == -1) or (unit and unit.id == id) then
            df.global.ui_building_item_cursor = i
            gui.simulateInput(ws, 'SELECT')
            df.global.ui_building_in_assign = false -- just in case
            return true
        end
    end

    df.global.ui_building_in_assign = false
    error('no candidate with id '..tostring(id))
end

--luacheck: in=number,number,number
function building_set_flag(bldid, flag, value)
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        return
    end

    if df.global.ui.main.mode ~= 17 or df.global.world.selected_building == nil then
        return
    end

    local bld = df.global.world.selected_building
    local btype = bld:getType()

    if btype == df.building_type.Table then
        local bld = bld --as:df.building_tablest
        if not df.global.world.selected_building.is_room then
            return
        end

        if flag == 1 then
            bld.table_flags.meeting_hall = istrue(value)
        end
    
    elseif btype == df.building_type.Bed then
        local bld = bld --as:df.building_bedst
        if not df.global.world.selected_building.is_room then
            return
        end

        if flag == 1 then
            if bld.bed_flags.barracks ~= istrue(value) then
                gui.simulateInput(ws, K'BUILDJOB_BED_BARRACKS')
            end

        elseif flag == 2 then
            if bld.bed_flags.dormitory ~= istrue(value) then
                gui.simulateInput(ws, K'BUILDJOB_BED_DORMITORY')
            end
        end

    elseif btype == df.building_type.FarmPlot then
        local bld = bld --as:df.building_farmplotst
        if flag == 1 then
            local fert = (#bld.jobs > 0 and bld.jobs[0].job_type == df.job_type.FertilizeField)
            if fert ~= istrue(value) then
                gui.simulateInput(ws, K'BUILDJOB_FARM_FERTILIZE')
            end

        elseif flag == 2 then
            bld.seasonal_fertilize = istrue(value) and 1 or 0
        end

    elseif btype == df.building_type.Door or btype == df.building_type.Hatch then
        local bld = bld --as:df.building_doorst
        if flag == 1 then
            -- For some reason, just setting forbidden flag doesn't prevent dwarves from using the door
            if bld.door_flags.forbidden ~= istrue(value) then
               gui.simulateInput(ws, K'BUILDJOB_DOOR_LOCK')
               --todo: return whether the lock was successfull to the app ?
            end
        elseif flag == 2 then
            bld.door_flags.pet_passable = istrue(value)
        elseif flag == 3 then
            bld.door_flags.internal = istrue(value)
        end

    elseif btype == df.building_type.ArcheryTarget then
        local bld = bld --as:df.building_archerytargetst
        if flag == 1 then
            bld.archery_direction = value
        end

    elseif btype == df.building_type.SiegeEngine then
        local bld = bld --as:df.building_siegeenginest
        if flag == 1 then
            bld.action = value
        elseif flag == 2 then
            bld.facing = value
        end

    elseif btype == df.building_type.Coffin then
        local bld = bld --as:df.building_coffinst
        if flag == 1 then
            bld.burial_mode.allow_burial = istrue(value)
        elseif flag == 2 then
            bld.burial_mode.no_citizens = not istrue(value)
        elseif flag == 3 then
            bld.burial_mode.no_pets = not istrue(value)
        end

    elseif btype == df.building_type.Hive then
        local bld = bld --as:df.building_hivest
        --todo: does this require any other changes, like creating jobs?
        if flag == 1 then
            bld.hive_flags.do_install = istrue(value)
        elseif flag == 2 then
            bld.hive_flags.do_gather = istrue(value)
        end
    
    elseif btype == df.building_type.AnimalTrap then
        local bld = bld --as:df.building_animaltrapst
        if flag == 1 then
            bld.bait_type = (value > 0 and value <= #bait_types) and bait_types[value] or -1
        end

    elseif btype == df.building_type.TradeDepot then
        local bld = bld --as:df.building_tradedepotst
        if flag == 1 then
            if bld.trade_flags.trader_requested ~= istrue(value) then
                gui.simulateInput(ws, K'BUILDJOB_DEPOT_REQUEST_TRADER')
            end
        elseif flag == 2 then
            if bld.trade_flags.anyone_can_trade ~= istrue(value) then
                gui.simulateInput(ws, K'BUILDJOB_DEPOT_BROKER_ONLY')
            end
        end

    elseif btype == df.building_type.Chain then
        local bld = bld --as:df.building_chainst
        if flag == 1 then
            if bld.flags.justice ~= istrue(value) then
                gui.simulateInput(ws, K'BUILDJOB_CHAIN_JUSTICE')
            end
        end

    elseif btype == df.building_type.ScrewPump then
        local bld = bld --as:df.building_screw_pumpst
        if flag == 1 then
            bld.pump_manually = istrue(value)
        end
    end

    return true
end

--luacheck: in=number,number,number
function building_room_set_squaduse(bldid, squadid, mode)
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        error('wrong screen '..tostring(ws._type))
    end

    if df.global.ui.main.mode ~= 17 or df.global.world.selected_building == nil then
        error('no selected building')
    end

    if not df.global.world.selected_building.is_room then
        error('not a room')
    end

    local bld = df.global.world.selected_building
    local btype = bld:getType()

    local squad = df.squad.find(squadid)
    if not squad then
        error('no squad '..tostring(squadid))
    end

    if btype == df.building_type.Bed or btype == df.building_type.Box or btype == df.building_type.Cabinet
        or btype == df.building_type.Armorstand or btype == df.building_type.Weaponrack or btype == df.building_type.ArcheryTarget then
        -- update room
        -- game actually doesn't use these values, it uses from squad only
        if btype ~= df.building_type.ArcheryTarget then
            local found = false
            for j,squse in ipairs(bld.squads) do
                if squse.squad_id == squadid then
                    squse.mode.whole = mode
                    found = true
                end
            end

            if not found then
                local squse = df.building_squad_use:new()
                squse.squad_id = squadid
                squse.mode.whole = mode

                utils.insert_sorted(bld.squads, squse, 'squad_id')
            end
        end

        -- update squad
        local found = false
        for j,roomuse in ipairs(squad.rooms) do
            if roomuse.building_id == bld.id then
                roomuse.mode.whole = mode
                found = true
            end
        end

        if not found then
            local roomuse = df.squad.T_rooms:new()
            roomuse.building_id = bld.id
            roomuse.mode.whole = mode

            utils.insert_sorted(squad.rooms, roomuse, 'building_id')
        end

        -- for weapon racks we need to update these fields as well
        if btype == df.building_type.Weaponrack then
            if bit32.band(mode, bit32.lshift(1,df.squad_use_flags.indiv_eq)) ~= 0 then
                --print ('seting combat')
                utils.insert_sorted(squad.rack_combat, bld.id)
            else
                --print ('removing combat')
                utils.erase_sorted(squad.rack_combat, bld.id)
            end

            if bit32.band(mode, bit32.lshift(1,df.squad_use_flags.train)) ~= 0 then
                --print ('seting train')
                utils.insert_sorted(squad.rack_training, bld.id)
            else
                --print ('removing train')
                utils.erase_sorted(squad.rack_training, bld.id)
            end
        end

        --TODO: is this enough?
        df.global.ui.equipment.update.buildings = true
    end

    return true
end


--luacheck: in=number
function building_remove(bldid)
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        return
    end

    if df.global.ui.main.mode ~= 17 or df.global.world.selected_building == nil then
        return
    end

    dfhack.buildings.deconstruct(df.global.world.selected_building)
    --gui.simulateInput(ws, K'DESTROYBUILDING')

    return true
end

--luacheck: in=number
function building_stopremoval(bldid)
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        return
    end

    if df.global.ui.main.mode ~= 17 or df.global.world.selected_building == nil then
        return
    end

    gui.simulateInput(ws, K'SUSPENDBUILDING')
    return true    
end

--luacheck: in=number
function building_suspend(bldid)
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        return
    end

    if df.global.ui.main.mode ~= 17 or df.global.world.selected_building == nil then
        return
    end

    gui.simulateInput(ws, K'SUSPENDBUILDING')
    return true    
end

--luacheck: in=number,number,number
function building_farm_set_crop(bldid, season, plantid)
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        return
    end

    if df.global.ui.main.mode ~= 17 or df.global.world.selected_building == nil then
        return
    end

    local bld = df.global.world.selected_building
    if bld:getType() ~= df.building_type.FarmPlot then
        return
    end

    bld.plant_id[season] = (plantid == 9999) and -1 or plantid

    return true
end

--luacheck: in=number
function building_start_resize(bldid)
    --todo: some checks here
    
    df.global.ui_building_in_resize = true
    gui.simulateInput(dfhack.gui.getCurViewscreen(), { K'SECONDSCROLL_DOWN', K'SECONDSCROLL_UP' })
    
    return true
end

--luacheck: in=
function link_targets_get()
    if df.global.ui.main.mode ~= df.ui_sidebar_mode.QueryBuilding or not df.global.ui_workshop_in_add then
        return
    end

    local trigger = df.global.world.selected_building --as:df.building_trapst
    if not trigger or trigger._type ~= df.building_trapst then
        return
    end

    local modes_to_ids = {
        [string.byte'b'] = 'BRIDGE',
        [string.byte'j'] = 'CAGE',
        [string.byte'c'] = 'CHAIN',
        [string.byte'd'] = 'DOOR',
        [string.byte'f'] = 'FLOODGATE',
        [string.byte'h'] = 'HATCH',
        [string.byte'w'] = 'GRATE_WALL',
        [string.byte'g'] = 'GRATE_FLOOR',
        [string.byte'B'] = 'BARS_VERTICAL',
        [string.byte'F'] = 'BARS_FLOOR',
        [string.byte's'] = 'SUPPORT',
        [string.byte'S'] = 'WEAPON_UPRIGHT',
        [string.byte'a'] = 'GEAR_ASSEMBLY',
        [string.byte'T'] = 'TRAP',
    }

    local linkmode = C_lever_target_type_get()
    local id = modes_to_ids[linkmode]
    if not id then
        return
    end

    local linked_ids = {}
    for i,v in ipairs(trigger.linked_mechanisms) do
        for j,w in ipairs(v.general_refs) do
            if w._type == df.general_ref_building_holderst then --as:w=df.general_ref_building_holderst
                utils.insert_sorted(linked_ids, w.building_id)
                break
            end
        end
    end

    local ret = {}

    --todo: pass bld id to zoom without using ui_building_item_cursor !
    for i,bld in ipairs(df.global.world.buildings.other[id]) do
        if not (linkmode == string.byte'T' and bld.trap_type ~= df.trap_type.TrackStop) then --hint:df.building_trapst
            if not utils.binsearch(linked_ids, bld.id) then
                local title = bldname(bld)
                table.insert(ret, { title, bld.z - df.global.window_z })
            end
        end
    end

    return ret
end

--luacheck: in=bool
function link_target_confirm(fast)
    if df.global.ui.main.mode ~= df.ui_sidebar_mode.QueryBuilding or not df.global.ui_workshop_in_add then
        return
    end

    local bld = df.global.world.selected_building
    if not bld or bld._type ~= df.building_trapst then
        return
    end
    
    local ws = screen_main()
    gui.simulateInput(ws, K'SELECT')    
    
    -- Automatically select first two mechanisms
    if istrue(fast) then
        local linkmode = C_lever_target_type_get()

        -- If the mode is right, the same building is still selected, linkmode is right, and we have enough mechanisms to select
        if df.global.ui.main.mode == df.ui_sidebar_mode.QueryBuilding and df.global.ui_workshop_in_add
           and bld == df.global.world.selected_building
           and linkmode == string.byte('t') and #df.global.ui_building_assign_items >= 2 then

            gui.simulateInput(ws, K'SELECT')
            gui.simulateInput(ws, K'SELECT')
            
            df.global.cursor.x = bld.centerx
            df.global.cursor.y = bld.centery
            df.global.cursor.z = bld.z
            recenter_view (bld.centerx, bld.centery, bld.z)            
            
            return false
        end
    end

    --todo: return link_targets_get() as when placing buildings
    return true
end

--luacheck: in=number
function link_targets_zoom(idx)
    if df.global.ui.main.mode ~= df.ui_sidebar_mode.QueryBuilding or not df.global.ui_workshop_in_add then
        return
    end

    if idx > 0 then
        df.global.ui_building_item_cursor = idx - 1
        gui.simulateInput(screen_main(), K'SECONDSCROLL_DOWN')
    else
        df.global.ui_building_item_cursor = idx + 1
        gui.simulateInput(screen_main(), K'SECONDSCROLL_UP')
    end

    recenter_view(df.global.cursor.x, df.global.cursor.y, df.global.cursor.z)
end

--luacheck: in=
function link_mechanisms_get()
    if df.global.ui.main.mode ~= df.ui_sidebar_mode.QueryBuilding or not df.global.ui_workshop_in_add then
        return
    end

    local bld = df.global.world.selected_building
    if not bld or bld._type ~= df.building_trapst then
        return
    end

    local linkmode = C_lever_target_type_get()
    if linkmode ~= string.byte('t') and linkmode ~= string.byte('l') then
        return
    end
    
    local enough = (linkmode == string.byte('t') and #df.global.ui_building_assign_items >= 2) or
                   (linkmode == string.byte('l') and #df.global.ui_building_assign_items >= 1) or false

    if not enough then
        return { linkmode, false, {} }
    end

    local list = {}
    for i,item in ipairs(df.global.ui_building_assign_items) do
        local title = itemname(item, 0, true)
        table.insert(list, { title })
    end

    return { linkmode, true, list }
end

--luacheck: in=number
function link_mechanisms_choose(idx)
    local ws = screen_main()

    df.global.ui_building_item_cursor = idx
    gui.simulateInput(ws, K'SELECT')

    -- Finished choosing mechanisms, zoom back to the lever
    if not df.global.ui_workshop_in_add then
        local bld = df.global.world.selected_building
        if bld then
            df.global.cursor.x = bld.centerx
            df.global.cursor.y = bld.centery
            df.global.cursor.z = bld.z
            recenter_view (bld.centerx, bld.centery, bld.z)
        end
    end
end

--luacheck: in=
function link_mechanisms_cancel()
    local ws = screen_main()
    gui.simulateInput(ws, K'LEAVESCREEN')
end

local assign_animal_keys = {
    [df.building_type.Cage] = K'BUILDJOB_CAGE_ASSIGN_OCC',
    [df.building_type.Chain] = K'BUILDJOB_CHAIN_ASSIGN_OCC',
}

--luacheck: in=number
function building_assign_get_candidates(bldid)
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        error('wrong screen '..tostring(ws._type))
    end

    if df.global.ui.main.mode ~= 17 or df.global.world.selected_building == nil then
        error('no selected building')
    end

    local bld = df.global.world.selected_building
    local btype = bld:getType()

    gui.simulateInput(ws, assign_animal_keys[btype])
    --todo: don't know which of the following is required
    ws:logic()
    ws:render()

    local ret = {}

    if btype == df.building_type.Chain then
        for i,unit in ipairs(df.global.ui_building_assign_units) do
            if not unit then
                table.insert(ret, { 'Nobody', -1, false, 0, 0 })
            else
                table.insert(ret, { unit_fulltitle(unit), unit.id, false, 0, unit_assigned_status(unit,bld) })
            end
        end        

    else
        for i,v in ipairs(df.global.ui_building_assign_type) do
            --xxx: this shouldn't happen, but was reported. bug in game? 
            if i >= #df.global.ui_building_assign_is_marked or i >= #df.global.ui_building_assign_units or i >= #df.global.ui_building_assign_items then
                break
            end

            local title = '?something?'
            local id = -1
            local is_assigned = istrue(df.global.ui_building_assign_is_marked[i])
            local status = 0

            --todo: should include unit sex for units, don't forger about gelded
            if v == 0 then
                local unit = df.global.ui_building_assign_units[i]
                id = unit.id
                title = unit_fulltitle(unit)
                status = unit_assigned_status(unit, bld)
            elseif v == 1 then
                local item = df.global.ui_building_assign_items[i]
                id = item.id
                title = itemname(item, 0, true)
                status = 0
            end

            table.insert(ret, { title, id, is_assigned, v, status })
        end
    end

    df.global.ui_building_in_assign = false

    return ret
end


--luacheck: in=number,number,number,bool
function building_assign(bldid, objid, objtype, on)
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        return
    end

    if df.global.ui.main.mode ~= 17 or df.global.world.selected_building == nil then
        return
    end

    local bld = df.global.world.selected_building
    local btype = bld:getType()

    on = istrue(on)

    gui.simulateInput(ws, assign_animal_keys[btype])
    --todo: don't know which of the following is required
    ws:logic()
    ws:render()

    --[[local single = (btype == df.building_type.Chain)
    for i,v in ipairs(df.global.ui_building_assign_units) do
        if (not v and unitid == -1) or (v and v.id == unitid) then
            if single or istrue(df.global.ui_building_assign_is_marked[i]) ~= on then
                df.global.ui_building_item_cursor = i
                gui.simulateInput(ws, K'SELECT')
            end

            if single then
                break
            end
        end
    end]]

    local vect = nil
    if objtype == 0 then
        vect = df.global.ui_building_assign_units
    elseif objtype == 1 then
        vect = df.global.ui_building_assign_items
    end

    if vect then
        for i,v in ipairs(vect) do
            if v and v.id == objid then
                if istrue(df.global.ui_building_assign_is_marked[i]) ~= on then
                    df.global.ui_building_item_cursor = i
                    local ws = dfhack.gui.getCurViewscreen()
                    gui.simulateInput(ws, K'SELECT')
                end

                break            
            end
        end
    end

    df.global.ui_building_in_assign = false   
end

--todo: make this work not only for the currently selected building
--luacheck: in=
function building_well_is_active()
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        return
    end

    if df.global.ui.main.mode ~= 17 or df.global.world.selected_building == nil then
        return
    end

    local x = df.global.gps.dimx - 2 - 30 + 1
    if df.global.ui_menu_width == 1 or df.global.ui_area_map_width == 2 then
        x = x - (23 + 1)
    end

    x = x + 1

    local ch = df.global.gps.screen[(x*df.global.gps.dimy+2)*4]
    return string.char(ch) == 'A'
end

--luacheck: in=number
function building_quick_action(idx)
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        return
    end
    
    local bld = df.global.world.selected_building

    if df.global.ui.main.mode ~= 17 or bld == nil then
        return
    end

    -- For doors - lock/unlock
    if bld._type == df.building_doorst then --as:bld=df.building_doorst
        if idx == 1 then
            bld.door_flags.forbidden = not bld.door_flags.forbidden
        end
    
    -- For levers - pull
    elseif bld._type == df.building_trapst and bld:getSubtype() == df.trap_type.Lever then --as:bld=df.building_trapst
        if idx == 1 then
            df.global.ui_workshop_in_add = false
            gui.simulateInput(ws, K'BUILDJOB_ADD')
            ws:logic() --to initialize / switch to add job menu
            gui.simulateInput(ws, K'HOTKEY_TRAP_PULL_LEVER')
        end
    end
end

--luacheck: in=
function buildings_get_list()
    local ret = {}
    
    for i,bld in ipairs(df.global.world.buildings.other.IN_PLAY) do
        local title, descr
        
        if bld.is_room then
            local info = room_type_table[bld._type]
            if info then
                local quality = bld:getRoomValue(unit)
            
                for i,v in ripairs_tbl(room_quality_table) do
                    if quality >= v[1] then
                        title = bldname(bld) .. ', ' .. v[info.qidx]
                        break
                    end
                end
            else
                title = bldname(bld)
            end

        else
            title = bldname(bld)
        end
        
        local owner = bld.owner
        local flags = packbits(bld.is_room)
        
        table.insert(ret, { title, bld.id, bld:getType(), bld:getSubtype(), descr or mp.NIL, owner and unit_fulltitle(owner) or mp.NIL, owner and owner.id or -1, flags })
    end
    
    table.sort(ret, function(a,b)
        return a[3] == b[3] and a[4] < b[4] or a[3] < b[3]
    end)
    
    return ret
end

--luacheck: in=
function buildings_get_list2()
    return execute_with_rooms_screen(function(ws)
        local ret = {}
        for i,bld in ipairs(ws.buildings) do
            local title, descr

            if bld._type == df.building_civzonest then --as:bld=df.building_civzonest
                title = 'Activity Zone'
                descr = zone_mode_string_for_flags(bld.zone_flags.whole)

                if not bld.zone_flags.active then
                    title = title .. ' (Inactive)'
                end
            
            elseif bld.is_room then
                local info = room_type_table[bld._type]
                if info then
                    local quality = bld:getRoomValue(unit)
                
                    for i,v in ripairs_tbl(room_quality_table) do
                        if quality >= v[1] then
                            title = v[info.qidx]
                            descr = bldname(bld)
                            break
                        end
                    end
                else
                    title = bldname(bld)
                end

            else
                title = bldname(bld)
            end
            
            local owner = bld.owner
            local is_room = bld.is_room and bld._type ~= df.building_civzonest
            local flags = packbits(is_room)
            
            table.insert(ret, { title, bld.id, bld:getType(), bld:getSubtype(), descr or mp.NIL, owner and unit_fulltitle(owner) or mp.NIL, owner and owner.id or -1, flags })
        end
                
        return ret
    end)
end

--luacheck: in=number
function building_goto(bldid)
    local bld = df.building.find(bldid)

    if not bld then
        return
    end

    --todo: reset main
    df.global.ui.main.mode = df.ui_sidebar_mode.QueryBuilding

    df.global.cursor.x = bld.centerx
    df.global.cursor.y = bld.centery
    df.global.cursor.z = bld.z-1

    local ws = dfhack.gui.getCurViewscreen()
    --gui.simulateInput(ws, K'CURSOR_DOWN_Z')
    gui.simulateInput(ws, K'CURSOR_UP_Z')

    recenter_view(bld.centerx, bld.centery, bld.z)
    --return {jobbld.centerx,jobbld.centery,jobbld.z}
end

--print(pcall(function() return json:encode(building_assign_get_candidates()) end))
--print(pcall(function() return json:encode(building_workshop_profile_get(4899)) end))
--print(pcall(function() return json:encode(building_workshop_get_jobchoices(0)) end))
--print(pcall(function() return json:encode(buildings_get_list()) end))