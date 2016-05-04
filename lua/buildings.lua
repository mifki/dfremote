function jeweler_get_choices()
    local ws = dfhack.gui.getCurViewscreen()
    local ret = {}

    for mat_idx,count in ipairs(ws.jeweler_cutgem) do
        local cut = count > 0
        local encrust = ws.jeweler_encrust[mat_idx] > 0

        if cut or encrust then
            local mat = dfhack.matinfo.decode(0,mat_idx).material
            local title = mat.state_name[0]

            table.insert(ret, { title, cut, encrust })
        end
    end

    return ret
end

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
local mood_items = {
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

    local unitid = dfhack.job.getGeneralRef(job, df.general_ref_type.UNIT_WORKER).unit_id
    local unit = df.unit.find(unitid)

    if not unit then
        return nil
    end

    local uname = unitname(unit)
    local prof = dfhack.units.getProfessionName(unit)

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

--xxx: most of the functions below can operate on the currently selected building only
--xxx: this function will try to transition to [q]uery mode and select the passed building
--xxx: currently this is used only to transition from loo[k] mode
function building_query_selected(bldid)
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        error('wrong screen '..tostring(ws._type))
    end

    local bld
    if bldid and bldid ~= -1 and bldid ~= 0 then
        bld = df.building.find(bldid)
    else
        bld = df.global.world.selected_building
    end

    if not bld then
        error('no building '..tostring(bldid))
    end

    if df.global.ui.main.mode ~= 17 or df.global.world.selected_building ~= bld then
        df.global.ui.main.mode = 17
        df.global.cursor.x = bld.x1
        df.global.cursor.y = bld.y1
        df.global.cursor.z = bld.z-1
        gui.simulateInput(ws, 'CURSOR_UP_Z')        
    end

    local btype = bld:getType()
    local bsub = bld:getSubtype()
    local bname = bldname(bld)
    local ret = nil

    local removing = (#bld.jobs == 1 and bld.jobs[0].job_type == df.job_type.DestroyBuilding)
    local actual = df.building_actual:is_instance(bld)
    local forbidden = actual and #bld.contained_items > 0 and bld.contained_items[0].item.flags.forbid

    local curstage = bld:getBuildStage()
    local maxstage = bld:getMaxBuildStage()
    local constructed = (curstage == maxstage)
    local workshop = (btype == df.building_type.Workshop or btype == df.building_type.Furnace
        or btype == df.building_type.Trap and (bsub == df.trap_type.Lever or bsub == df.trap_type.PressurePlate))

    local genflags = packbits(removing, forbidden, actual, constructed, workshop)

    if not constructed then
        local needsarchitect = (bld:needsDesign() and not bld.design.flags.designed)

        local cjob = bld.jobs[0]
        local active = cjob.flags.fetching or cjob.flags.bringing or cjob.flags.working
        local suspended = cjob.flags.suspend

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
        --todo: return broker name, current job, accessibility

        local caravan_state = #df.global.ui.caravans > 0 and df.global.ui.caravans[0].trade_state or 0

        local can_trade = depot_can_trade(bld)
        local can_movegoods = depot_can_movegoods(bld)

        local avail_flags = packbits(can_movegoods, can_trade)

        ret = { btype, genflags, bname, bld.trade_flags.whole, avail_flags }

    elseif btype == df.building_type.Door or btype == df.building_type.Hatch then
        ret = { btype, genflags, bname, bld.door_flags.whole }

    elseif btype == df.building_type.Windmill or btype == df.building_type.WaterWheel or btype == df.building_type.AxleVertical
        or btype == df.building_type.AxleHorizontal or btype == df.building_type.GearAssembly or btype == df.building_type.Rollers
        or btype == df.building_type.ScrewPump then
        local machine = df.machine.find(bld.machine.machine_id)

        local ttype = dfhack.maps.getTileType(bld.centerx, bld.centery, bld.z)
        local stable_foundation = (ttype ~= df.tiletype.OpenSpace)
        ret = { btype, genflags, bname, machine.cur_power, machine.min_power, machine.flags.whole, stable_foundation }

        if btype == df.building_type.Rollers or btype == df.building_type.ScrewPump then
            table.insert(ret, bld.direction)
        end

        if btype == df.building_type.ScrewPump then
            table.insert(ret, bld.pump_manually)
        end
    
    elseif workshop then
        local jobs = {}
        for i,job in ipairs(bld.jobs) do
            local title = dfhack.job.getName(job)
            table.insert(jobs, { title, job.flags.whole })
        end

        local moodinfo = building_workshop_get_mood(bld)
        local workshop_type = (btype ~= df.building_type.Trap and bld.type or bld.trap_type)

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

        ret = { btype, genflags, bname, workshop_type, jobs, moodinfo or mp.NIL, profile_info }

    elseif btype == df.building_type.Chair or btype == df.building_type.Table or btype == df.building_type.Statue
        or btype == df.building_type.Bed or btype == df.building_type.Box or btype == df.building_type.Cabinet
        or btype == df.building_type.Armorstand or btype == df.building_type.Weaponrack or btype == df.building_type.ArcheryTarget
        or btype == df.building_type.Coffin or btype == df.building_type.Slab or btype == df.building_type.Cage
        or btype == df.building_type.Chain or btype == df.building_type.Well then

        local owner = bld.owner
        local ownername = owner and unit_fulltitle(owner) or ''
        local ownerprof = owner and unitprof(owner) or '' --todo: unused because fulltitle already includes profession
        ret = { btype, genflags, bname, bld.is_room, ownername, ownerprof }

        if btype == df.building_type.Table then
            table.insert(ret, bld.table_flags.meeting_hall)

        elseif btype == df.building_type.Bed then
            table.insert(ret, bld.bed_flags.whole)
            table.insert(ret, get_squads_use(bld))

        elseif btype == df.building_type.ArcheryTarget then
            table.insert(ret, bld.archery_direction)
            table.insert(ret, get_squads_use(bld))

        elseif btype == df.building_type.Box or btype == df.building_type.Cabinet
            or btype == df.building_type.Armorstand or btype == df.building_type.Weaponrack then
            table.insert(ret, get_squads_use(bld))
        
        elseif btype == df.building_type.Coffin then
            local buried = owner and owner.flags1.dead or false
            local mode = bld.burial_mode
            local flags = packbits(mode.allow_burial, not mode.no_citizens, not mode.no_pets, buried)
            table.insert(ret, flags)

        elseif btype == df.building_type.Slab then
            local slabitem = bld.contained_items[0].item
            local inmemory = slabitem.engraving_type == df.slab_engraving_type.Memorial and slabitem.topic and hfname(df.historical_figure.find(slabitem.topic)) or mp.NIL
            --todo: show full description and not just the name
            table.insert(ret, inmemory)

        elseif btype == df.building_type.Cage then
            local occupants = {}

            for i,v in ipairs(bld.contained_items[0].item.general_refs) do
                if v._type == df.general_ref_contains_unitst then
                    local unit = df.unit.find(v.unit_id)
                    if unit then
                        local title = unit_fulltitle(unit)
                        table.insert(occupants, { title, unit.id, 0 })
                    end
                elseif v._type == df.general_ref_contains_itemst then
                    local item = df.item.find(v.item_id)
                    if item then
                        local title = itemname(item, 0, true)
                        table.insert(occupants, { title, item.id, 1 })
                    end
                end
            end

            table.insert(ret, occupants)

        elseif btype == df.building_type.Chain then
            local assigned = bld.assigned and unit_fulltitle(bld.assigned) or mp.NIL
            local chained = bld.chained and unit_fulltitle(bld.chained) or mp.NIL
            table.insert(ret, bld.flags.justice)
            table.insert(ret, assigned)
            table.insert(ret, bld.assigned and bld.assigned.id or -1)
            table.insert(ret, chained)
            table.insert(ret, bld.chained and bld.chained.id or -1)

        elseif btype == df.building_type.Well then
            local is_active = building_well_is_active()

            -- find bucket and check if liquid amount is 10
            local liquid = 0
            for j,w in ipairs(bld.contained_items) do
                if w.item._type == df.item_bucketst then
                    for i,v in ipairs(w.item.general_refs) do
                        if v._type == df.general_ref_contains_itemst then
                            local item = df.item.find(v.item_id)
                            if item and item._type == df.item_liquid_miscst then
                                liquid = liquid + item.stack_size
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
        local keys = { 'BUILDJOB_FARM_SPRING', 'BUILDJOB_FARM_SUMMER', 'BUILDJOB_FARM_AUTUMN', 'BUILDJOB_FARM_WINTER' }

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
        local area = (bld.x2-bld.x1+1)*(bld.y2-bld.y1+1)

        ret = { btype, genflags, bname, area, bld.max_barrels, bld.max_bins, bld.max_wheelbarrows }

    elseif btype == df.building_type.SiegeEngine then
        ret = { btype, genflags, bname, bld.type, bld.action, bld.facing }

    elseif btype == df.building_type.NestBox then
        local unit = bld.claimed_by ~= -1 and df.unit.find(bld.claimed_by)
        local unitname = unit and unit_fulltitle(unit) or mp.NIL
        ret = { btype, genflags, bname, unitname }

    elseif btype == df.building_type.Hive then
        local hiveflags = bld.hive_flags.whole
        ret = { btype, genflags, bname, hiveflags }

    elseif btype == df.building_type.AnimalTrap then
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
        gui.simulateInput(ws, 'BUILDJOB_SUSPEND')
    end

    return true    
end

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
    gui.simulateInput(ws, 'BUILDJOB_CANCEL')

    return true    
end

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

function get_job_choices(ws, level)
    local ret = {}
    for i,btn in ipairs(df.global.ui_sidebar_menus.workshop_job.choices_visible) do
        local unavailable = false
        local memorialized = false
        local slab = false

        if btn._type == df.interface_button_building_new_jobst then
            --[[if btn.is_custom then --XXX: this field also means that job is unavailable (red)
                goto continue
            end]]
            unavailable = btn.is_custom
            table.insert(jobchoices, clone_job_button(btn))
        end

        local title = utils.call_with_string(btn, 'getLabel')
        if btn._type == df.interface_button_building_new_jobst and btn.job_type == df.job_type.EngraveSlab then
            slab = true
            title = title:gsub(' %(Engrave Memorial%)', '')
            local hfid = btn.hist_figure_id

            for j,w in ipairs(df.global.world.buildings.other.SLAB) do
                if #w.contained_items > 0 and w.contained_items[0].item.topic == hfid then
                    memorialized = true
                    break
                end
            end
        end

        local key = dfhack.screen.getKeyDisplay(btn.hotkey_id)
        if key == '?' then
            key = ''
        end

        local subchoices = false
        if btn._type == df.interface_button_building_material_selectorst or btn._type == df.interface_button_building_category_selectorst then
            if level == 0 then
                df.global.ui_workshop_in_add = true
                ws:logic() --to initialize / switch to add job menu
            end
            btn:click()
            --gui.simulateInput(ws, btn.hotkey_id)
            ws:logic()
            subchoices = get_job_choices(ws, level+1)

            if level > 0 then
                gui.simulateInput(ws, 'LEAVESCREEN')
            else
                gui.simulateInput(ws, 'CURSOR_DOWN_Z')
                gui.simulateInput(ws, 'CURSOR_UP_Z')
            end
        end

        local flags = packbits(unavailable, slab, memorialized)

        table.insert(ret, { dfhack.df2utf(title), key, subchoices, #jobchoices, flags })

        ::continue::
    end    

    return ret
end

--todo: don't hardcode this; should find all glasses in df.global.world.raws.mat_table.builtin
local glasses = { 'green glass', 'clear glass', 'crystal glass' }

function building_workshop_get_jobchoices(bldid)
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        error('wrong screen '..tostring(ws._type))
    end

    if df.global.ui.main.mode ~= 17 or df.global.world.selected_building == nil then
        error('no selected building')
    end

    local ret = {}
    local bld = df.global.world.selected_building

    if bld._type == df.building_trapst and (bld.trap_type == df.trap_type.Lever or bld.trap_type == df.trap_type.PressurePlate) then
        if bld.trap_type == df.trap_type.Lever then
            table.insert(ret, { 'Pull the Lever', 'P', 0, 0, false })
        end
        table.insert(ret, { 'Link up a Bridge', 'b', 0, 1, false })
        table.insert(ret, { 'Link up a Cage', 'j', 0, 2, false })
        table.insert(ret, { 'Link up a Chain', 'c', 0, 3, false })
        table.insert(ret, { 'Link up a Door', 'd', 0, 4, false })
        table.insert(ret, { 'Link up a Floodgate', 'f', 0, 5, false })
        table.insert(ret, { 'Link up a Hatch', 'h', 0, 6, false })
        table.insert(ret, { 'Link up a Wall Grate', 'w', 0, 7, false })
        table.insert(ret, { 'Link up a Floor Grate', 'g', 0, 8, false })
        table.insert(ret, { 'Link up Vertical Bars', 'B', 0, 9, false })
        table.insert(ret, { 'Link up a Floor Bars', 'Alt+b', 0, 10, false })
        table.insert(ret, { 'Link up a Support', 's', 0, 11, false })
        table.insert(ret, { 'Link up Spears / Spikes', 'S', 0, 12, false })
        table.insert(ret, { 'Link up a Gear Assembly', 'a', 0, 13, false })
        table.insert(ret, { 'Link up a Track Stop', 'T', 0, 14, false })

    elseif bld.type == df.workshop_type.Mechanics then
        table.insert(ret, { 'Make Rock Mechanisms', 't', 0, 0, false })
        table.insert(ret, { 'Make Traction Bench', 'R', 0, 1, false })

    elseif bld.type == df.workshop_type.Butchers then
        table.insert(ret, { 'Butcher a dead animal', 'b', 0, 0, false })
        table.insert(ret, { 'Extract from a dead animal', 'e', 0, 1, false })
        table.insert(ret, { 'Capture a live land animal', 'a', 0, 2, false })

    elseif bld.type == df.workshop_type.Fishery then
        table.insert(ret, { 'Process a Raw Fish', 'p', 0, 0, false })
        table.insert(ret, { 'Extract from a Raw Fish', 'e', 0, 1, false })
        table.insert(ret, { 'Capture a Live Fish', 'f', 0, 2, false })

    elseif bld.type == df.workshop_type.Loom then
        table.insert(ret, { 'Collect Webs', 'c', 0, 0, false })
        table.insert(ret, { 'Weave Cloth (Plant Thread)', 'w', 0, 1, false })
        table.insert(ret, { 'Weave Silk Cloth', 's', 0, 2, false })
        table.insert(ret, { 'Weave Cloth (Wool/Hair Yarn)', 'y', 0, 3, false })
        table.insert(ret, { 'Weave Metal Cloth', 'a', 0, 4, false })

    elseif bld.type == df.workshop_type.Kennels then
        table.insert(ret, { 'Capture a Live Land Animal', 'a', 0, 0, false })
        table.insert(ret, { 'Tame a Small Animal', 't', 0, 1, false })

    elseif bld.type == df.workshop_type.Dyers then
        table.insert(ret, { 'Dye Thread', 't', 0, 0, false })
        table.insert(ret, { 'Dye Cloth', 'c', 0, 1, false })

    elseif bld.type == df.workshop_type.Jewelers then
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
                table.insert(opts, { 'Cut '..matname, '', 0, #ret*4+0, false })
            end
            if enc then
                table.insert(opts, { 'Encrust Finished Goods with '..matname, '', 0, #ret*4+1, false })
                table.insert(opts, { 'Encrust Furniture with '..matname, '', 0, #ret*4+2, false })
                table.insert(opts, { 'Encrust Ammo with '..matname, '', 0, #ret*4+3, false })
            end
            if #opts > 0 then
                table.insert(ret, { matname, '', opts, (cut and 1 or 0) + (enc and 2 or 0), false })
            end
        end
    else
        jobchoices = {}
        ret = get_job_choices(ws, 0)
    end

    return ret
end

local jobs_mechanics = { 'HOTKEY_MECHANIC_PARTS', 'HOTKEY_MECHANIC_TRACTION_BENCH' }
local jobs_butchers = { 'HOTKEY_BUTCHER_BUTCHER', 'HOTKEY_BUTCHER_EXTRACT', 'HOTKEY_BUTCHER_CATCH' }
local jobs_fishery = { 'HOTKEY_FISHERY_PROCESS', 'HOTKEY_FISHERY_EXTRACT', 'HOTKEY_FISHERY_CATCH' }
local jobs_loom = { 'HOTKEY_LOOM_COLLECT_SILK', 'HOTKEY_LOOM_WEAVE_CLOTH', 'HOTKEY_LOOM_WEAVE_SILK', 'HOTKEY_LOOM_WEAVE_YARN', 'HOTKEY_LOOM_WEAVE_METAL' }
local jobs_kennels = { 'HOTKEY_KENNEL_CATCH_VERMIN', 'HOTKEY_KENNEL_TAME_VERMIN' }
local jobs_dyers = { 'HOTKEY_DYER_THREAD', 'HOTKEY_DYER_CLOTH' }
local jobs_trap = { 'HOTKEY_TRAP_PULL_LEVER', 'HOTKEY_TRAP_BRIDGE', 'HOTKEY_TRAP_CAGE', 'HOTKEY_TRAP_CHAIN', 'HOTKEY_TRAP_DOOR', 'HOTKEY_TRAP_FLOODGATE', 'HOTKEY_TRAP_HATCH', 'HOTKEY_TRAP_GRATE_WALL', 'HOTKEY_TRAP_GRATE_FLOOR', 'HOTKEY_TRAP_BARS_VERTICAL', 'HOTKEY_TRAP_BARS_FLOOR', 'HOTKEY_TRAP_SUPPORT', 'HOTKEY_TRAP_SPIKE', 'HOTKEY_TRAP_GEAR_ASSEMBLY', 'HOTKEY_TRAP_TRACK_STOP' }

function building_workshop_addjob(bldid, idx)
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        error('wrong screen '..tostring(ws._type))
    end

    if df.global.ui.main.mode ~= 17 or df.global.world.selected_building == nil then
        error('no selected building')
    end

    local bld = df.global.world.selected_building

    if #bld.jobs >= 10 then
        return --error('too many jobs')
    end

    if bld._type == df.building_trapst and (bld.trap_type == df.trap_type.Lever or bld.trap_type == df.trap_type.PressurePlate) then
        if idx < #jobs_trap then
            gui.simulateInput(ws, 'BUILDJOB_ADD')
            ws:logic() --to initialize / switch to add job menu
            gui.simulateInput(ws, jobs_trap[idx+1])

            if df.global.ui_workshop_in_add and bit32.band(df.global.art_image_chunk_next_id, 0xff) ~= 0xff then
                recenter_view(df.global.cursor.x, df.global.cursor.y, df.global.cursor.z)
            end
        end

    elseif bld.type == df.workshop_type.Mechanics then
        if idx < #jobs_mechanics then
            gui.simulateInput(ws, 'BUILDJOB_ADD')
            ws:logic() --to initialize / switch to add job menu
            gui.simulateInput(ws, jobs_mechanics[idx+1])
        end

    elseif bld.type == df.workshop_type.Butchers then
        if idx < #jobs_butchers then
            gui.simulateInput(ws, 'BUILDJOB_ADD')
            ws:logic() --to initialize / switch to add job menu
            gui.simulateInput(ws, jobs_butchers[idx+1])
        end

    elseif bld.type == df.workshop_type.Fishery then
        if idx < #jobs_fishery then
            gui.simulateInput(ws, 'BUILDJOB_ADD')
            ws:logic() --to initialize / switch to add job menu
            gui.simulateInput(ws, jobs_fishery[idx+1])
        end

    elseif bld.type == df.workshop_type.Loom then
        if idx < #jobs_loom then
            gui.simulateInput(ws, 'BUILDJOB_ADD')
            ws:logic() --to initialize / switch to add job menu
            gui.simulateInput(ws, jobs_loom[idx+1])
        end

    elseif bld.type == df.workshop_type.Kennels then
        if idx < #jobs_kennels then
            gui.simulateInput(ws, 'BUILDJOB_ADD')
            ws:logic() --to initialize / switch to add job menu
            gui.simulateInput(ws, jobs_kennels[idx+1])
        end

    elseif bld.type == df.workshop_type.Dyers then
        if idx < #jobs_dyers then
            gui.simulateInput(ws, 'BUILDJOB_ADD')
            ws:logic() --to initialize / switch to add job menu
            gui.simulateInput(ws, jobs_dyers[idx+1])
        end

    elseif bld.type == df.workshop_type.Jewelers then
        gui.simulateInput(ws, 'BUILDJOB_ADD')
        ws:logic() --to initialize / switch to add job menu
        local m = math.floor(idx / 4)
        local t = idx % 4
        df.global.ui_building_item_cursor = m
        if t == 0 then
            gui.simulateInput(ws, 'HOTKEY_JEWELER_CUT')
        else
            local w = { 'HOTKEY_JEWELER_FINISHED', 'HOTKEY_JEWELER_FURNITURE', 'HOTKEY_JEWELER_AMMO' }
            ws:logic() --to initialize / switch to menu
            gui.simulateInput(ws, 'HOTKEY_JEWELER_ENCRUST')
            gui.simulateInput(ws, w[t])
        end
    
    else    
        local btn = jobchoices[idx]
        btn.building = bld

        btn:click()
    end

    return true
end

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

    local bld = df.global.world.selected_building

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

    local bld = df.global.world.selected_building
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

    local bld = df.global.world.selected_building
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
        [df.building_type.Chair] = 'BUILDJOB_CHAIR_FREE',
        [df.building_type.Table] = 'BUILDJOB_TABLE_FREE',
        [df.building_type.Bed] = 'BUILDJOB_BED_FREE',
        [df.building_type.Box] = 'BUILDJOB_RACKSTAND_FREE',
        [df.building_type.Cabinet] = 'BUILDJOB_RACKSTAND_FREE',
        [df.building_type.Armorstand] = 'BUILDJOB_RACKSTAND_FREE',
        [df.building_type.Weaponrack] = 'BUILDJOB_RACKSTAND_FREE',
        [df.building_type.ArcheryTarget] = 'BUILDJOB_TARGET_FREE',
        [df.building_type.Coffin] = 'BUILDJOB_COFFIN_FREE',
        [df.building_type.Slab] = 'BUILDJOB_STATUE_FREE',
        [df.building_type.Cage] = 'BUILDJOB_CAGE_FREE',
        [df.building_type.Chain] = 'BUILDJOB_CHAIN_FREE',
        [df.building_type.Well] = 'BUILDJOB_WELL_FREE',
    }

    gui.simulateInput(ws, keys[df.global.world.selected_building:getType()])

    return true
end

local room_candidate_ids = {}
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
        [df.building_type.Chair] = 'BUILDJOB_CHAIR_ASSIGN',
        [df.building_type.Table] = 'BUILDJOB_TABLE_ASSIGN',
        [df.building_type.Bed] = 'BUILDJOB_BED_ASSIGN',
        [df.building_type.Box] = 'BUILDJOB_RACKSTAND_ASSIGN',
        [df.building_type.Cabinet] = 'BUILDJOB_RACKSTAND_ASSIGN',
        [df.building_type.Armorstand] = 'BUILDJOB_RACKSTAND_ASSIGN',
        [df.building_type.Weaponrack] = 'BUILDJOB_RACKSTAND_ASSIGN',
        [df.building_type.Coffin] = 'BUILDJOB_COFFIN_ASSIGN',
        [df.building_type.Slab] = 'BUILDJOB_STATUE_ASSIGN',  
        [df.building_type.Cage] = 'BUILDJOB_CAGE_ASSIGN',
        [df.building_type.Chain] = 'BUILDJOB_CHAIN_ASSIGN',
    }

    gui.simulateInput(ws, keys[df.global.world.selected_building:getType()])
    --todo: don't know which of the following is required
    ws:logic()
    ws:render()

    local ret = {}
    room_candidate_ids = {}

    for i,unit in ipairs(df.global.ui_building_assign_units) do
        if not unit then
            table.insert(ret, { 'Nobody', '', false })
            table.insert(room_candidate_ids, -1)
        else
            --todo: use unit_fullname ? how do we want to display them in the list ?
            local cname = unitname(unit)
            local cprof = dfhack.units.getProfessionName(unit)
            table.insert(ret, { cname, cprof, unit.flags1.dead })        
            table.insert(room_candidate_ids, unit.id)
        end
    end

    df.global.ui_building_in_assign = false

    return ret
end

function building_room_owner_set(bldid, idx)
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        return
    end

    if df.global.ui.main.mode ~= 17 or df.global.world.selected_building == nil then
        return
    end

    if not df.global.world.selected_building.is_room then
        return
    end    

    local bld = df.global.world.selected_building
    local btype = bld:getType()
    local unitid = room_candidate_ids[idx+1]
    local unit = (unitid ~= -1) and df.unit.find(unitid) or nil

    if unit ~= nil then
        -- reset squad use
        --TODO: obviously this is required for some building types only
        local eid = df.global.ui.main.fortress_entity.id

        -- update squads
        for i,squad in ipairs(df.global.world.squads.all) do
            if squad.entity_id == eid then
                utils.erase_sorted_key(squad.rooms, bld.id, 'building_id')

                -- for weapon racks we need to remove from these fields as well
                if btype == df.building_type.Weaponrack then
                    utils.erase_sorted(squad.rack_training, bld.id)
                    utils.erase_sorted(squad.rack_combat, bld.id)
                end
            end
        end
        
        -- update room
        -- game actually doesn't use this values, it uses from squad only
        --bld.squads.resize(0)

        --TODO: is this enough?
        df.global.ui.equipment.update.buildings = true

        -- reset additional flags for beds
        if btype == df.building_type.Bed then
            bld.bed_flags.barracks = false
            bld.bed_flags.dormitory = false
        end
    end

    dfhack.buildings.setOwner(bld, unit)

    return true
end

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
        if not df.global.world.selected_building.is_room then
            return
        end

        if flag == 1 then
            bld.table_flags.meeting_hall = istrue(value)
        end
    
    elseif btype == df.building_type.Bed then
        if not df.global.world.selected_building.is_room then
            return
        end

        if flag == 1 then
            if bld.bed_flags.barracks ~= istrue(value) then
                gui.simulateInput(ws, 'BUILDJOB_BED_BARRACKS')
            end

        elseif flag == 2 then
            if bld.bed_flags.dormitory ~= istrue(value) then
                gui.simulateInput(ws, 'BUILDJOB_BED_DORMITORY')
            end
        end

    elseif btype == df.building_type.FarmPlot then
        if flag == 1 then
            local fert = (#bld.jobs > 0 and bld.jobs[0].job_type == df.job_type.FertilizeField)
            if fert ~= istrue(value) then
                gui.simulateInput(ws, 'BUILDJOB_FARM_FERTILIZE')
            end

        elseif flag == 2 then
            bld.seasonal_fertilize = istrue(value) and 1 or 0
        end

    elseif btype == df.building_type.Door then
        if flag == 1 then
            bld.door_flags.forbidden = istrue(value)
        elseif flag == 2 then
            bld.door_flags.pet_passable = istrue(value)
        elseif flag == 3 then
            bld.door_flags.internal = istrue(value)
        end

    elseif btype == df.building_type.ArcheryTarget then
        if flag == 1 then
            bld.archery_direction = value
        end

    elseif btype == df.building_type.SiegeEngine then
        if flag == 1 then
            bld.action = value
        elseif flag == 2 then
            bld.facing = value
        end

    elseif btype == df.building_type.Coffin then
        if flag == 1 then
            bld.burial_mode.allow_burial = istrue(value)
        elseif flag == 2 then
            bld.burial_mode.no_citizens = not istrue(value)
        elseif flag == 3 then
            bld.burial_mode.no_pets = not istrue(value)
        end

    elseif btype == df.building_type.Hive then
        --todo: does this require any other changes, like creating jobs?
        if flag == 1 then
            bld.hive_flags.do_install = istrue(value)
        elseif flag == 2 then
            bld.hive_flags.do_gather = istrue(value)
        end
    
    elseif btype == df.building_type.AnimalTrap then
        if flag == 1 then
            bld.bait_type = (value > 0 and value <= #bait_types) and bait_types[value] or -1
        end

    elseif btype == df.building_type.TradeDepot then
        if flag == 1 then
            if bld.trade_flags.trader_requested ~= istrue(value) then
                gui.simulateInput(ws, 'BUILDJOB_DEPOT_REQUEST_TRADER')
            end
        elseif flag == 2 then
            if bld.trade_flags.anyone_can_trade ~= istrue(value) then
                gui.simulateInput(ws, 'BUILDJOB_DEPOT_BROKER_ONLY')
            end
        end

    elseif btype == df.building_type.Chain then
        if flag == 1 then
            if bld.flags.justice ~= istrue(value) then
                gui.simulateInput(ws, 'BUILDJOB_CHAIN_JUSTICE')
            end
        end

    elseif btype == df.building_type.ScrewPump then
        if flag == 1 then
            bld.pump_manually = istrue(value)
        end
    end

    return true
end

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
        found = false
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


function building_remove(bldid)
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        return
    end

    if df.global.ui.main.mode ~= 17 or df.global.world.selected_building == nil then
        return
    end

    dfhack.buildings.deconstruct(df.global.world.selected_building)
    --gui.simulateInput(ws, 'DESTROYBUILDING')

    return true
end

function building_stopremoval(bldid)
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        return
    end

    if df.global.ui.main.mode ~= 17 or df.global.world.selected_building == nil then
        return
    end

    gui.simulateInput(ws, 'SUSPENDBUILDING')
    return true    
end

function building_suspend(bldid)
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        return
    end

    if df.global.ui.main.mode ~= 17 or df.global.world.selected_building == nil then
        return
    end

    gui.simulateInput(ws, 'SUSPENDBUILDING')
    return true    
end

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

function building_start_resize(bldid)
    --todo: some checks here
    
    df.global.ui_building_in_resize = true
    gui.simulateInput(dfhack.gui.getCurViewscreen(), { 'SECONDSCROLL_DOWN', 'SECONDSCROLL_UP' })
    
    return true
end

function link_targets_get()
    if df.global.ui.main.mode ~= df.ui_sidebar_mode.QueryBuilding or not df.global.ui_workshop_in_add then
        return
    end

    local bld = df.global.world.selected_building
    if not bld or bld._type ~= df.building_trapst then
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

    local linkmode = bit32.band(df.global.art_image_chunk_next_id, 0xff)
    local id = modes_to_ids[linkmode]
    if not id then
        return
    end

    local ret = {}

    --todo: pass coords so that client can zoom straight away ?
    for i,bld in ipairs(df.global.world.buildings.other[id]) do
        if not (linkmode == string.byte'T' and bld.trap_type ~= df.trap_type.TrackStop) then
            local title = bldname(bld)
            table.insert(ret, { title, bld.z - df.global.window_z })
        end
    end

    return ret
end

function link_targets_zoom(idx)
    if df.global.ui.main.mode ~= df.ui_sidebar_mode.QueryBuilding or not df.global.ui_workshop_in_add then
        return
    end

    if idx > 0 then
        df.global.ui_building_item_cursor = idx - 1
        gui.simulateInput(screen_main(), 'SECONDSCROLL_DOWN')
    else
        df.global.ui_building_item_cursor = idx + 1
        gui.simulateInput(screen_main(), 'SECONDSCROLL_UP')
    end

    recenter_view(df.global.cursor.x, df.global.cursor.y, df.global.cursor.z)
end

function link_mechanisms_get()
    if df.global.ui.main.mode ~= df.ui_sidebar_mode.QueryBuilding or not df.global.ui_workshop_in_add then
        return
    end

    local bld = df.global.world.selected_building
    if not bld or bld._type ~= df.building_trapst then
        return
    end

    local linkmode = bit32.band(df.global.art_image_chunk_next_id, 0xff)
    if linkmode ~= string.byte('t') and linkmode ~= string.byte('l') then
        return
    end

    local enough = #df.global.ui_building_assign_items >= 2
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

function link_mechanisms_choose(idx)
    local ws = screen_main()

    df.global.ui_building_item_cursor = idx
    gui.simulateInput(ws, 'SELECT')

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

function link_mechanisms_cancel()
    local ws = screen_main()
    gui.simulateInput(ws, 'LEAVESCREEN')
end

local assign_animal_keys = {
    [df.building_type.Cage] = 'BUILDJOB_CAGE_ASSIGN_OCC',
    [df.building_type.Chain] = 'BUILDJOB_CHAIN_ASSIGN_OCC',
}

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

    local single = (btype == df.building_type.Chain)

    for i,v in ipairs(df.global.ui_building_assign_type) do
        --xxx: this shouldn't happen, but was reported. bug in game? 
        if i >= #df.global.ui_building_assign_is_marked or i >= #df.global.ui_building_assign_units or i >= #df.global.ui_building_assign_items then
            break
        end

        local title = '?something?'
        local obj = nil
        local is_assigned = not single and istrue(df.global.ui_building_assign_is_marked[i]) or false
        local status = 0

        --todo: should include unit sex for units, don't forger about gelded
        if v == 0 then
            obj = df.global.ui_building_assign_units[i]
            title = unit_fulltitle(obj)
            status = unit_assigned_status(obj, zone)
        elseif v == 1 then
            obj = df.global.ui_building_assign_items[i]
            title = itemname(obj, 0, true)
            status = 0
        end

        if obj then
            table.insert(ret, { title, obj and obj.id or -1, is_assigned, v, status })
        end
    end
    --[[for i,unit in ipairs(df.global.ui_building_assign_units) do
        if not unit then
            table.insert(ret, { 'Nobody', -1, -1, false, 0 })
        else
            local is_assigned = not single and istrue(df.global.ui_building_assign_is_marked[i]) or false

            table.insert(ret, { unit_fulltitle(unit), unit.id, unit.sex, is_assigned, unit_assigned_status(unit,bld) })
        end
    end]]

    df.global.ui_building_in_assign = false

    return ret
end


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
                gui.simulateInput(ws, 'SELECT')
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
                    gui.simulateInput(ws, 'SELECT')
                end

                break            
            end
        end
    end

    df.global.ui_building_in_assign = false   
end

--todo: make this work not only for the currently selected building
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

--print(pcall(function() return json:encode(building_assign_get_candidates()) end))
--print(pcall(function() return json:encode(building_workshop_profile_get(4899)) end))