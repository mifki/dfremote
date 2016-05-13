-- get new announcements to show at the bottom (oldest first!)
function announcements_get_new()
    local anns = {}
    local popups = {}

    local annzoomed = false
    local cont = ''
    for i,ann in ripairs(df.global.world.status.announcements) do
        if ann.id <= lastann and not (ann.id == lastann and ann.repeat_count > lastannrep) then
            break
        end

        if ann.type < #df.global.announcements.flags then
            local flags = df.global.announcements.flags[ann.type]
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

function reports_get_groups()
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

    df.global.world.status.flags.whole = bit32.band(df.global.world.status.flags.whole, bit32.bnot(7))

    return { ret, df.global.cur_year, df.global.cur_year_tick }
end

function reports_get(unitid, rtype)
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

function popup_dismiss_all()
    df.global.world.status.popups:resize(0)
end

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