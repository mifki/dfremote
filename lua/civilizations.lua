--luacheck: in=
function civilizations_get_list()
    local ret = {}

    execute_with_world_screen(function(ws)
        gui.simulateInput(ws, K'CIV_CIVS')

        for i,v in ipairs(ws.entities) do
            local name = translatename(v.name, false)
            local name_eng = translatename(v.name, true)

            local race = df.global.world.raws.creatures.all[v.race]
            local site_gov = v.type == df.historical_entity_type.SiteGovernment

            table.insert(ret, { name, v.id, name_eng, race.name[2], site_gov })
        end
    end)

    return ret
end

--luacheck: in=number
function civilization_get_info(civid)
    local civ = df.historical_entity.find(civid)
    if not civ then
        error('no civ '..tostring(civid))
    end

    local civsws = df.viewscreen_civlistst:new()
    civsws.page = 0
    civsws.entities:insert(0, civ)
    gui.simulateInput(civsws, K'SELECT')
    df.delete(civsws)

    local ws = dfhack.gui.getCurViewscreen() --as:df.viewscreen_entityst
    if ws._type ~= df.viewscreen_entityst then
        error('failed to switch to civ info screen')
    end
    ws.breakdown_level = df.interface_breakdown_types.STOPSCREEN

    local leaders = {}
    for i,v in ipairs(ws.important_leader_nemesis) do
        local fig = v.figure
        local name = hfname(fig)

        local race = df.global.world.raws.creatures.all[fig.race]
        local prof = dfhack.units.getCasteProfessionName(fig.race, fig.caste, fig.profession, false)

        local pos = ''
        -- that's where game gets the position to display from
        for j,w in ipairs(fig.entity_links) do
            if w._type == df.histfig_entity_link_positionst then
                local w = w --as:df.histfig_entity_link_positionst
                for m,ass in ipairs(ws.entity.positions.assignments) do
                    if ass.id == w.assignment_id then
                        for k,p in ipairs(ws.entity.positions.own) do
                            if p.id == ass.position_id then
                                pos = fig.sex == 0 and p.name_female[0] or p.name_male[0]
                                if #pos == 0 then
                                    pos = p.name[0]
                                end

                                break
                            end
                        end

                        break
                    end
                end

                break
            end
        end

        table.insert(leaders, { name, fig.id, race.name[0], prof, pos })
    end

    local agreements = {}
    for i,v in ipairs(ws.agreements) do
        local type = v.type
        local title = ''

        local site = df.world_site.find(df.global.ui.site_id)
        local site_title = translatename(site.name, false)

        if type == df.meeting_event_type.ExportAgreement or type == df.meeting_event_type.ImportAgreement then
            if type == df.meeting_event_type.ExportAgreement then
                title = 'Exports to ' .. site_title
            elseif type == df.meeting_event_type.ImportAgreement then
                title = 'Imports from ' .. site_title
            end

            local year = v.year
            local month = math.floor(v.ticks / TU_PER_MONTH)
            local day = math.floor((v.ticks-month*TU_PER_MONTH) / TU_PER_DAY) + 1

            local b = day % 10
            local suf = math.floor((day % 100) / 10) == 1 and 'th' or b == 1 and 'st' or b == 2 and 'nd' or b == 3 and 'rd' or 'th'

            local datestr = day .. suf .. ' ' .. MONTHS[month+1] .. ', ' .. year
    
            table.insert(agreements, { title, i, type, datestr })
        end
    end

    return { leaders, agreements }
end

--luacheck: in=number,number
function civilization_get_agreement(civid, idx)
    local civ = df.historical_entity.find(civid)
    if not civ then
        error('no civ '..tostring(civid))
    end

    local civsws = df.viewscreen_civlistst:new()
    civsws.page = 0
    civsws.entities:insert(0, civ)
    gui.simulateInput(civsws, K'SELECT')
    df.delete(civsws)

    local ws = dfhack.gui.getCurViewscreen() --as:df.viewscreen_entityst
    ws.breakdown_level = df.interface_breakdown_types.STOPSCREEN

    local agreement = ws.agreements[idx]
    local ret = nil

    if agreement.type == df.meeting_event_type.ImportAgreement then
        ret = process_buy_agreement(agreement.buy_prices)
    elseif agreement.type == df.meeting_event_type.ExportAgreement then
        ret = process_sell_agreement(ws.entity.id, agreement.sell_prices)
    end

    return { ret, agreement.type }
end

-- print(pcall(function() return json:encode(civilizations_get_list()) end))
-- print(pcall(function() return json:encode(civilization_get_info(75)) end))
-- print(pcall(function() return json:encode(civilization_get_agreement(75,1)) end))
-- print(pcall(function() return json:encode(civilization_get_agreement(75,0)) end))