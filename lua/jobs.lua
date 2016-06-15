function jobs_get_list()
end

function job_get_description(unitid)
    local unit = df.unit.find(unitid)
    if not unit then
        error('no unit '..tostring(unitid))
    end

    local oldws = dfhack.gui.getCurViewscreen()
    local unitlistws = df.viewscreen_unitlistst:new()
    unitlistws.page = df.viewscreen_unitlist_page.Citizens
    unitlistws.cursor_pos[0] = 0
    unitlistws.units[0]:insert(0, unit)
    unitlistws.jobs[0]:insert(0, nil)
    gui.simulateInput(unitlistws, 'UNITJOB_VIEW_JOB')
    df.delete(unitlistws)

    local ws = dfhack.gui.getCurViewscreen()
    if ws ~= oldws then
        ws.breakdown_level = 2
    end

    if ws._type == df.viewscreen_textviewerst then
        local text = ''
        for i,v in ipairs(ws.formatted_text) do
            if not v.text then
                text = text .. '[P]'
            else
                text = text .. dfhack.df2utf(charptr_to_string(v.text)) .. ' '
            end
        end

        text = text:gsub('%s+', ' ')

        local title = ws.title
        title = title:gsub("^%s+", ""):gsub("%s+$", "")

        return { title, text }
    end

	return nil
end

if screen_main()._type == df.viewscreen_dwarfmodest then
    print(pcall(function() return json:encode(activity_get_description(1244)) end))
end