--todo: move date formatting to utils
TU_PER_DAY = 1200
TU_PER_MONTH = TU_PER_DAY * 28
TU_PER_YEAR = TU_PER_MONTH * 12

MONTHS = {
    'Granite',
    'Slate',
    'Felsite',
    'Hematite',
    'Malachite',
    'Galena',
    'Limestone',
    'Sandstone',
    'Timber',
    'Moonstone',
    'Opal',
    'Obsidian',
}

function format_date(year, ticks)
    local month = math.floor(ticks / TU_PER_MONTH)
    local day = math.floor((ticks-month*TU_PER_MONTH) / TU_PER_DAY) + 1

    local b = day % 10
    local suf = math.floor((day % 100) / 10) == 1 and 'th' or b == 1 and 'st' or b == 2 and 'nd' or b == 3 and 'rd' or 'th'

    local datestr = day .. suf .. ' ' .. MONTHS[month+1] .. ', ' .. year

    return datestr
end

local seasons = { 'Spring', 'Summer', 'Autumn', 'Winter' }
local seasonparts = { 'Early ', 'Mid-', 'Late ' }

local site_ranks = { 'Outpost', 'Hamlet', 'Village', 'Town', 'City', 'Metropolis' }

--xxx: this is done manually because the in-game display doesn't quite match ui.tasks.unit_counts and df.profession structures
function get_unit_counts()

    local c = df.global.ui.tasks.unit_counts

    local count_nobles = c.CLERK + c.ADMINISTRATOR + c.TRADER +
        c.ARCHITECT + c.ALCHEMIST +
        c.DOCTOR + c.DIAGNOSER + c.BONE_SETTER + c.SUTURER + c.SURGEON

    local ret_civil = {
        { 'Miners', c.MINER, 7 },
        { 'Woodworkers', c.WOODWORKER, 6+8 },
        { 'Stoneworkers', c.STONEWORKER, 15 },
        { 'Rangers', c.HUNTER, 2 },
        { 'Metalsmiths', c.METALSMITH, 0+8},
        { 'Jewelers', c.JEWELER, 2+8 },
        { 'Craftsdwarves', c.CRAFTSMAN },
        { 'Nobles & Admins', count_nobles, 5 },
        { 'Peasants', c.STANDARD, 3 },
        { 'Dwarven Children', c.CHILD, 4 },
        { 'Fishery Workers', c.FISHERY_WORKER, 1 },
        { 'Farmers', c.FARMER, 6 },
        { 'Engineers', c.ENGINEER, 4+8 },
    }
     
    local ret_animal = {    
        { 'Trained Animals', df.global.ui.tasks.trained_animals, 15 },
        { 'Other Animals', df.global.ui.tasks.other_animals, 7 },
    }
     
    local ret_mil = {    
        { 'Axedwarves', c.AXEMAN, 1 },
        { 'Axe Lords', c.MASTER_AXEMAN, 1+8 },
        { 'Swordsdwarves', c.SWORDSMAN, 3 },
        { 'Swordmasters', c.MASTER_SWORDSMAN, 3+8 },
        { 'Macedwarves', c.MACEMAN, 4 },
        { 'Mace Lords', c.MASTER_MACEMAN, 4+8 },
        { 'Hammerdwarves', c.HAMMERMAN, 5 },
        { 'Hammer Lords', c.MASTER_HAMMERMAN, 5+8 },
        { 'Speardwarves', c.SPEARMAN, 6 },
        { 'Spearmasters', c.MASTER_SPEARMAN, 6+8 },
        { 'Marksdwarves', c.CROSSBOWMAN, 2 },
        { 'Elite Marksdwarves', c.MASTER_CROSSBOWMAN, 2+8 },
        { 'Wrestlers', c.WRESTLER, 7 },
        { 'Elite Wrestlers', c.MASTER_WRESTLER, 15 },
        { 'Recruit & Others', c.RECRUIT, 0+8 },
    }

    return ret_civil, ret_mil, ret_animal
end

--luacheck: in=
function status_get_overview()
    local wealth = df.global.ui.tasks.wealth
    local food = df.global.ui.tasks.food

    local have_appraisal = have_broker_appraisal()

    local created_wealth = { wealth.total, wealth.weapons, wealth.armor, wealth.furniture, wealth.other, wealth.architecture, wealth.displayed, wealth.held }

    local ret_food = { food.total, food.meat, food.fish, food.plant, food.seeds, food.drink, food.other }

    local site = df.world_site.find(df.global.ui.site_id)
    local is_mountainhome = have_noble('MONARCH') --todo: what if monarch dies? there should be more correct way
    local site_title = (is_mountainhome and 'Mountainhome' or site_ranks[df.global.ui.fortress_rank+1]) .. ' ' .. translatename(site.name) .. ', "' .. dfhack.TranslateName(site.name, true) .. '"'

    local month = math.floor(df.global.cur_year_tick / TU_PER_MONTH)
    local datestr = format_date(df.global.cur_year, df.global.cur_year_tick) .. ', ' .. seasonparts[month%3+1] .. seasons[math.floor(month/3)+1]

    local population = df.global.ui.tasks.population    
    local c1,c2,c3 = get_unit_counts()

    local precision = df.global.ui.bookkeeper_precision

    return { site_title, datestr, created_wealth, wealth.imported, wealth.exported, ret_food, population, c1,c2,c3, have_appraisal, precision }
end

--luacheck: in=bool
function status_get_health(include_healthy)
    if not have_noble('CHIEF_MEDICAL_DWARF') then
        return { false }
    end

    return execute_with_status_page(status_pages.Health, function(ws)
        local ws = ws --as:df.viewscreen_layer_overall_healthst
        local ret = {}

        for i,unit in ipairs(ws.unit) do
            local b1 = ws.bits1[i].whole
            local b2 = ws.bits2[i].whole
            local b3 = ws.bits3[i].whole
            
            if include_healthy or b1 ~= 0 or b2 ~= 0 or b3 ~= 0 then
                table.insert(ret, { unit_fulltitle(unit), unit.id, b1, b2, b3 })
            end
        end

        return { true, ret }
    end)
end

--luacheck: in=number[]
function performance_skill_get_description(_id)
    local type = _id[1]
    local id = _id[2]

    -- instrument
    if type == 0 then
        local inst = df.global.world.raws.itemdefs.instruments[id]
        local text = inst.description:gsub('  ', ' ')

        return { text }
    end

    local unit = df.unit:new()

    local scr = df.viewscreen_unitlistst:new()

    local act = df.activity_entry:new()
    act.id = 9999999
    act.type = 8

    df.global.world.activities.all:insert(#df.global.world.activities.all, act)

    unit.social_activities:insert(0,9999999)

    local event = df.activity_event_performancest:new()
    event.type = type
    event.event = id

    act.events:insert(0,event)

    scr.units[0]:insert(0, unit)
    scr.jobs[0]:insert(0, nil)

    scr.page = df.viewscreen_unitlist_page.Citizens
    scr.cursor_pos[0] = 0

    gui.simulateInput(scr, 'UNITJOB_VIEW_JOB')

    df.global.world.activities.all:erase(#df.global.world.activities.all-1)
    scr.units[0]:erase(0)
    unit:delete()
    event:delete()
    act:delete()
    scr:delete()

    local ws = dfhack.gui.getCurViewscreen() --as:df.viewscreen_textviewerst

    if ws._type ~= df.viewscreen_textviewerst then
        error('can not switch to form description screen')
    end

    ws.breakdown_level = df.interface_breakdown_types.STOPSCREEN

    local text = ''
    
    for i,v in ipairs(ws.src_text) do
        if #v.value > 0 then
            text = text .. dfhack.df2utf(v.value:gsub('%[B]', '[P]', 1)) .. ' '
        end
    end

    text = text:gsub('  ', ' ')

    return { text }
end

--print(pcall(function() return json:encode(status_get_health()) end))
--print(pcall(function() return json:encode(performance_skill_get_description({1,2})) end))
