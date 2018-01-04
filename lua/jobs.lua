function jobs_get_list()
    return execute_with_jobs_screen(function(ws)
        local ret = {}

        for i,job in ipairs(ws.jobs) do
            if job then
                local title = jobname(job)
                if job.flags['repeat'] then
                    title = title .. '/R'
                end

                local worker = dfhack.job.getWorker(job)
                if not worker then
                    if job.flags.suspend then
                        worker = 'Suspended'
                    else
                        worker = 'Inactive'
                    end
                else
                    worker = unit_fulltitle(worker)
                end

                print(title, worker)
            end
        end

        return ret
    end)    
end

--luacheck: in=number
function job_get_description(unitid)
    local unit = df.unit.find(unitid)
    if not unit then
        error('no unit '..tostring(unitid))
    end

    if unit.job.current_job then
        local job = unit.job.current_job

        local title = jobname(job)
        local worker = dfhack.job.getWorker(job)
        local profcolor = dfhack.units.getProfessionColor(unit)

        local text = '[C:7:0:1]Worker: '
        if worker then
            text = text .. '[C:' .. tostring(profcolor) .. ':0:0]' .. unit_fulltitle(worker)
        else
            text = text .. '[C:0:0:1]Inactive' --todo: check color
        end

        local jobbldref = unit.job.current_job and dfhack.job.getGeneralRef(unit.job.current_job, df.general_ref_type.BUILDING_HOLDER) --as:df.general_ref_building
        local jobbld = jobbldref and df.building.find(jobbldref.building_id) or nil
        if jobbld then
            text = text .. '[B][C:7:0:1]Location: [C:3:0:1]' .. bldname(jobbld)
        end        

        if job.flags['repeat'] or job.flags.suspend then
            text = text .. '[B][C:7:0:1]'
            if job.flags['repeat'] then
                text = text .. '[C:1:0:0]Repeating    ' --todo: color
            end
            if job.flags.suspend then
                text = text .. '[C:4:0:0]Suspended    ' --todo: color
            end
        end

        if #job.items > 0 then
            text = text .. '[B][C:7:0:1]Items:'
            for i,v in ipairs(job.items) do
                text = text .. '[P][C:6:0:1]' .. itemname(v.item, 3, true)
            end
        end

        return { title, text }
    end

    local oldws = dfhack.gui.getCurViewscreen()
    local unitlistws = df.viewscreen_unitlistst:new()
    unitlistws.page = df.viewscreen_unitlist_page.Citizens
    unitlistws.cursor_pos[0] = 0
    unitlistws.units[0]:insert(0, unit)
    unitlistws.jobs[0]:insert(0, nil)
    gui.simulateInput(unitlistws, K'UNITJOB_VIEW_JOB')
    df.delete(unitlistws)

    local ws = dfhack.gui.getCurViewscreen() --as:df.viewscreen_textviewerst
    if ws ~= oldws then
        ws.breakdown_level = df.interface_breakdown_types.STOPSCREEN
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

        local title = dfhack.df2utf(ws.title)
        title = title:gsub("^%s+", ""):gsub("%s+$", "")

        return { title, text }
    end

	return nil
end

-- if screen_main()._type == df.viewscreen_dwarfmodest then
--     print(pcall(function() return json:encode(jobs_get_list()) end))
-- end