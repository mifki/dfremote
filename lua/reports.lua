-- get new announcements to show at the bottom (oldest first!)
--luacheck: in=
function announcements_get_new()
    local anns = {}
    local popups = {}

    local annzoomed = false
    local cont = ''
    for i,ann in ripairs(df.global.world.status.announcements) do
        if ann.id <= lastann and not (ann.id == lastann and ann.repeat_count > lastannrep) then
            break
        end

        if ann.type < #df.global.d_init.announcements.flags then
            local flags = df.global.d_init.announcements.flags[ann.type]
            if flags.D_DISPLAY then
                if ann.flags.continuation then
                    cont = ' ' .. dfhack.df2utf(ann.text)
                else
                    table.insert(anns, { dfhack.df2utf(ann.text) .. cont, ann.color+(ann.bright and 8 or 0) })
                    cont = ''
                end

                if false and flags.RECENTER and ann.pos.x ~= -30000 and not annzoomed then
                    recenter_view(ann.pos.x, ann.pos.y, ann.pos.z)
                    annzoomed = true
                end
            end
        end
    end
    lastann = df.global.world.status.announcements[#df.global.world.status.announcements-1].id
    lastannrep = df.global.world.status.announcements[#df.global.world.status.announcements-1].repeat_count

    for i,popup in ripairs(df.global.world.status.popups) do
        if popup == last_popup then
            break
        end

        table.insert(popups, { dfhack.df2utf(popup.text), popup.color+(popup.bright and 8 or 0) })
        --break
        --table.insert(sent_popups, 1, popup)
    end
    last_popup = (#df.global.world.status.popups > 0 and df.global.world.status.popups[#df.global.world.status.popups-1] or nil)

    return { anns, popups }
end

-- get all announcements for the announcements screen
--luacheck: in=
function announcements_get_log()
    local ret = {}
    local j = 0
    local cont = ''
    local rep = 0

    for i=#df.global.world.status.announcements-1,0,-1 do
        local ann = df.global.world.status.announcements[i]
        local text = dfhack.df2utf(ann.text)

        if rep == 0 and ann.repeat_count ~= 0 then
            rep = ann.repeat_count
        end

        if ann.flags.continuation then
            cont = ' ' .. text .. cont
        else
            table.insert(ret, { text .. cont, ann.type, ann.color+(ann.bright and 8 or 0), ann.year, ann.time, pos2table(ann.pos), rep })
            cont = ''
            rep = 0

            j = j + 1
            if j > 200 then
                break
            end
        end
    end

    return { ret, df.global.cur_year, df.global.cur_year_tick }
end

--luacheck: in=
function combat_reports_get_groups()
	local ret = {}

    for i,unit in ipairs(df.global.world.units.active) do
        local j = 0
        for t=0,2 do
        	if #unit.reports.log[t] > 0 then
                --local name = unitname(unit)
	        	--local title = 'the ' .. unitprof(unit) .. (#name > 0 and ' ' .. name or '')
                local title = unit_fulltitle(unit)
	        	table.insert(ret, { title, unit.id, t, unit.reports.last_year[t], unit.reports.last_year_tick[t] })

                j = j + 1
                if j > 200 then
                    break
                end                
        	end
        end
    end

    --todo: would it be faster to insert items to right positions instead of sorting?
    table.sort(ret, function(a,b) return (a[4] > b[4]) or (a[4] == b[4] and a[5] > b[5]) end)

    -- reset new report flags
    df.global.world.status.flags[0] = false
    df.global.world.status.flags[1] = false
    df.global.world.status.flags[2] = false

    return { ret, df.global.cur_year, df.global.cur_year_tick }
end

--luacheck: in=number,number
function combat_reports_get(unitid, rtype)
    local unit = df.unit.find(unitid)
    if not unit then
        error('no unit '..tostring(unitid))
    end

    local ret = {}
    local j = 0
    local cont = ''
    local rep = 0

    for i,v in ripairs(unit.reports.log[rtype]) do
        --todo: faster to iterate over reports ourselves as log is sorted already
        local r = df.report.find(v)
        if r then
            local text = dfhack.df2utf(r.text)

            if rep == 0 and r.repeat_count ~= 0 then
                rep = r.repeat_count
            end

            if r.flags.continuation then
                cont = ' ' .. text .. cont
            else
                local pos = (r.pos.x ~= -30000) and { r.pos.x, r.pos.y, r.pos.z } or mp.NIL
                table.insert(ret, { text .. cont, r.type, r.color+(r.bright and 8 or 0), r.year, r.time, pos, rep })
                cont = ''
                rep = 0

                j = j + 1
                if j > 200 then
                   break
                end                
            end
        end
    end

    return { ret, df.global.cur_year, df.global.cur_year_tick }
end

--luacheck: in=
function other_reports_get_list()
    local ret = {}

    for i,v in ripairs(df.global.world.status.mission_reports) do
        local unread = not hasbit(v.unk_7, 0)
        table.insert(ret, { dfhack.df2utf(v.title), {0, i}, unread, v.year, v.year_tick })
    end

    for i,v in ripairs(df.global.world.status.spoils_reports) do --also includes tribute reports
        local unread = not hasbit(v.unk_1, 0)
        table.insert(ret, { dfhack.df2utf(v.title), {1, i}, unread, v.year, v.year_tick })
    end

    for i,v in ripairs(df.global.world.status.interrogation_reports) do
        local unread = not hasbit(v.unk_3, 0)
        table.insert(ret, { dfhack.df2utf(v.title), {2, i}, unread, v.year, v.tick })
    end

    --todo: would it be faster to insert items to right positions instead of sorting?
    table.sort(ret, function(a,b) return (a[4] > b[4]) or (a[4] == b[4] and a[5] > b[5]) end)

    -- reset new report flags
    df.global.world.status.flags[3] = false
    df.global.world.status.flags[4] = false
    df.global.world.status.flags[5] = false
    df.global.world.status.flags[6] = false

    return { ret, df.global.cur_year, df.global.cur_year_tick }
end

--luacheck: in={number,number}
function other_reports_get_text(typeidx)
    local type = typeidx[1]
    local idx = typeidx[2]

    if type == 0 then -- mission
        local ws = df.viewscreen_reportlistst:new()

        ws.units:insert(0, nil)
        ws.types:insert(0, -1)
        ws.last_id:insert(0, -1)
        ws.mission_reports:insert(0, idx)
        ws.spoils_reports:insert(0, -1)

        -- This will also mark the report as read
        gui.simulateInput(ws, K'SELECT')
        gui.simulateInput(ws, K'LEAVESCREEN')

        local text = ''

        for i,v in ipairs(ws.mission_report_text) do
            local line = dfhack.df2utf(ws.mission_report_text[i].value)
            local color = ws.mission_report_colors[i]

            line = fixspaces(line)

            -- Incomplete lines end with a space, a period means end of paragraph
            if #text == 0 or text:sub(#text) == '.' then
                -- ideally the colour value needs to be split into colour and brightness, but the app will accept whatever
                text = text .. '[B][C:' .. tostring(color) .. ':0:0]'
            else
                
            end

            text = text .. line
        end

        df.delete(ws)

        if #text == 0 then
            text = 'Nothing to see here.'
        end

        return { text }
    end

    if type == 1 then -- spoils, tribute
        local report = df.global.world.status.spoils_reports[idx]
        report.unk_1 = bit32.bor(report.unk_1, 1) -- mark as read

        local text = ''

        if #report.item_counts > 0 then
            text = text .. '[B][C:14:0:0]'
        end
        for i,count in ipairs(report.item_counts) do
            local title = generic_item_name(report.item_types[i], report.item_subtypes[i], -1, report.mat_types[i], report.mat_indices[i], count == 1)
            local line = tostring(count) .. ' ' .. title:utf8lower()

            text = text .. '[P]' .. dfhack.df2utf(line)
        end

        if #report.item_counts > 0 then
            text = text .. '[B][C:10:0:0]'
        end
        for i,count in ipairs(report.creature_counts) do
            local raw = df.creature_raw.find(report.creature_races[i])
            local line = tostring(count) .. ' ' .. (count > 1 and raw.name[1] or raw.name[0])

            text = text .. '[P]' .. dfhack.df2utf(line)
        end

        if #text == 0 then
            text = 'Nothing to see here.'
        end        

        return { text }
    end

    if type == 2 then -- interrogation
        local text = ''

        local report = df.global.world.status.interrogation_reports[idx]
        report.unk_3 = bit32.bor(report.unk_3, 1) -- mark as read

        local officer_name = dfhack.df2utf(report.officer_name)
        text = text .. '[B][C:1:0:1]Officer: ' .. officer_name

        for i,line in ipairs(report.details) do
            text = text .. '[B][C:15:0:0]' .. dfhack.df2utf(fixspaces(line.value))
        end

        return { text }
    end
end

--luacheck: in=
function popup_dismiss_all()
    df.global.world.status.popups:resize(0)
end

--luacheck: in=
function popup_dismiss()
    if #df.global.world.status.popups == 0 then
        return {}
    end

    df.global.world.status.popups[0]:delete()
    df.global.world.status.popups:erase(0)
    sent_popups[#sent_popups] = nil

    local ret = {}
    for i,popup in ripairs(df.global.world.status.popups) do
        table.insert(ret, { dfhack.df2utf(popup.text), popup.color+(popup.bright and 8 or 0) })
    end    

    return ret
end

--print(pcall(function() return json:encode(other_reports_get_report({0,2})) end))
--print(pcall(function() return json:encode(other_reports_get_report({1,0})) end))
