function petition_applicant_name(agreement)
    if #agreement.parties[0].histfig_ids > 0 then
        local hf_id = agreement.parties[0].histfig_ids[0]
        local hf = df.historical_figure.find(hf_id)
        local unit_id = hf and hf.unit_id or -1
        local unit = df.unit.find(unit_id)
        
        return unit and unit_fulltitle(unit) or '#unknown unit#'

    elseif #agreement.parties[0].entity_ids > 0 then
        local entity_id = agreement.parties[0].entity_ids[0]
        local entity = df.historical_entity.find(entity_id)

        return translatename(entity.name, true) or '#unknown entity#'
    end

    return '#unknown applicant#'
end

function petition_reason(agreement)
    local atype = agreement.details[0].type

    if atype == df.agreement_details_type.Residency then
        return 'Residency'

    elseif atype == df.agreement_details_type.Citizenship then
        return 'Citizenship'

    elseif atype == df.agreement_details_type.Location then
        local data = agreement.details[0].data.Location
        local ltype = data.type

        if ltype == df.abstract_building_type.TEMPLE then
            --return (data.tier == 2 and 'Temple complex' or 'Temple')
            return (data.tier == 2 and 'High priest' or 'Priest')
        elseif ltype == df.abstract_building_type.GUILDHALL then
            return (data.tier == 2 and 'Grand guildhall' or 'Guildhall')
        else
            return 'Location'
        end
    end

    return df.agreement_details_type[atype]
end

--luacheck: in=
function petitions_get_list()
    -- execute_with_petitions_screen() could be used here but it'd error when 
    -- there's no petitions because screen doesn't show in that case

    local ret = {}

    for i,v in ipairs(df.global.ui.petitions) do
        local agreement = df.agreement.find(v)
        if agreement and #agreement.parties == 2 and #agreement.details == 1 then
            table.insert(ret, { petition_applicant_name(agreement), agreement.id, petition_reason(agreement) })
        end
    end

    return ret
end

function read_petition_text()
    local text = ''

    local startx = 37
    local endx = df.global.gps.dimx-2
    local starty = 2
    local endy = df.global.gps.dimy-3

    for j=starty,endy do
        local empty = true

        local line = ''
        for i=startx,endx do
            local char = df.global.gps.screen[(i*df.global.gps.dimy+j)*4]

            if char ~= 0 then
                if char ~= 32 then
                    if empty and #line > 0 and line:byte(#line) ~= 32 then
                        line = line .. ' '
                    end
                    empty = false
                end

                if not empty and not (char == 32 and line:byte(#line) == 32) then
                    line = line .. string.char(char)
                end
            end
        end

        if line:match('^Do you approve') then
            break
        end

        if #line > 0 then
            if #text > 0 then
                text = text .. ' '
            end
 
            local colorf = df.global.gps.screen[(startx*df.global.gps.dimy+j)*4+1]
            local colorb = df.global.gps.screen[(startx*df.global.gps.dimy+j)*4+2]
            local colorbright = df.global.gps.screen[(startx*df.global.gps.dimy+j)*4+3]

            text = text .. '[C:' .. colorf .. ':' .. colorb .. ':' .. colorbright .. ']' .. line
        end
    end    

    return dfhack.df2utf(text)
end

--luacheck: in=number
function petition_get_text(id)
    return execute_with_petitions_screen(function(ws)
        for i,v in ipairs(ws.list) do
            if v.id == id then
                ws.cursor = i
                ws:render()
                local text = read_petition_text()

                return { text }
            end
        end

        error('no petition '..tostring(id))     
    end)
end

--luacheck: in=number,bool
function petition_respond(id, approve)
    return execute_with_petitions_screen(function(ws)
        for i,v in ipairs(ws.list) do
            if v.id == id then
                ws.cursor = i
                gui.simulateInput(ws, istrue(approve) and K'OPTION1' or K'OPTION2')

                return true
            end
        end

        error('no petition '..tostring(id))     
    end)
end

--print(pcall(function() return json:encode(petition_respond(1,false)) end))
--print(pcall(function() return json:encode(petition_get_info2(405)) end))