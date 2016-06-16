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
        { 'Miners', c.MINER },
        { 'Woodworkers', c.WOODWORKER },
        { 'Stoneworkers', c.STONEWORKER },
        { 'Rangers', c.HUNTER },
        { 'Metalsmiths', c.METALSMITH },
        { 'Jewelers', c.JEWELER },
        { 'Craftsdwarves', c.CRAFTSMAN },
        { 'Nobles & Admins', count_nobles },
        { 'Peasants', c.STANDARD },
        { 'Dwarven Children', c.CHILD },
        { 'Fishery Workers', c.FISHERY_WORKER },
        { 'Farmers', c.FARMER },
        { 'Engeneers', c.ENGINEER },
    }
     
    local ret_animal = {    
        { 'Trained Animals', df.global.ui.tasks.trained_animals },
        { 'Other Animals', df.global.ui.tasks.other_animals },
    }
     
    local ret_mil = {    
        { 'Axedwarves', c.AXEMAN },
        { 'Axe Lords', c.MASTER_AXEMAN },
        { 'Swordsdwarves', c.SWORDSMAN },
        { 'Swordmasters', c.MASTER_SWORDSMAN },
        { 'Macedwarves', c.MACEMAN },
        { 'Mace Lords', c.MASTER_MACEMAN },
        { 'Hammerdwarves', c.HAMMERMAN },
        { 'Hammer Lords', c.MASTER_HAMMERMAN },
        { 'Speardwarves', c.SPEARMAN },
        { 'Spearmasters', c.MASTER_SPEARMAN },
        { 'Marksdwarves', c.CROSSBOWMAN },
        { 'Elite Marksdwarves', c.MASTER_CROSSBOWMAN },
        { 'Wrestlers', c.WRESTLER },
        { 'Elite Wrestlers', c.MASTER_WRESTLER },
        { 'Recruit & Others', c.RECRUIT },
    }

    return ret_civil, ret_mil, ret_animal
end

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

function status_get_health(include_healthy)
    if not have_noble('CHIEF_MEDICAL_DWARF') then
        return { false }
    end

    return execute_with_status_page(status_pages.Health, function(ws)
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

--print(pcall(function() return json:encode(status_get_health()) end))