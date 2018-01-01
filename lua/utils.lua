SYMBOL_MALE_UTF = '♂'
SYMBOL_FEMALE_UTF = '♀'
SYMBOL_MALE_DF = dfhack.utf2df(SYMBOL_MALE_UTF)
SYMBOL_FEMALE_DF = dfhack.utf2df(SYMBOL_FEMALE_UTF)

function istrue(v)
    return v ~= nil and v ~= false and v ~= 0
end

function shft(b)
    return bit32.lshift(1, b)
end

function hasbit(v, b)
    return bit32.band(v, bit32.lshift(1, b)) ~= 0
end

function bit(f, v)
    return v and bit32.lshift(1, f) or 0
end

function packbits(...)
    local args = table.pack(...) --as:number[]
    local v = 0
    
    for i=0,7 do
        if istrue(args[i+1]) then
            v = v + shft(i)
        end
    end

    return v
end

function ripairs(t)
  local function ripairs_it(t,i)
    i=i-1
    if i < 0 then return nil end
    local v=t[i]
    return i,v
  end
  return ripairs_it, t, #t
end

function ripairs_tbl(t)
  local function ripairs_it(t,i)
    i=i-1
    if i < 1 then return nil end
    local v=t[i]
    return i,v
  end
  return ripairs_it, t, #t+1
end

function capitalize(str)
    local ret = string.gsub(str, "(%a)([%w_']*)", function(a,b) return string.upper(a)..b end)    
    return ret
end

--todo: need to capitalize all words
function unitname(unit, eng)
    --xxx: temporary - logs say this was called with nil unit from somewhere several times
    if not unit then
        return '#no unit#'
    end

    --xxx: temporary fix for unitname() still may be called for non-units (like histfigs) somewhere
    local nameobj = unit._type == df.unit and dfhack.units.getVisibleName(unit) or unit.name
    
    local name = dfhack.df2utf(dfhack.TranslateName(nameobj, eng):gsub('`', '\''))
    return string.utf8capitalize(name)
end

function hfname(hf, eng)
    local name = dfhack.df2utf(dfhack.TranslateName(hf.name, eng):gsub('`', '\'')) --todo: need gsub here?
    return string.utf8capitalize(name)
end

function translatename(name, eng)
    local name = dfhack.df2utf(dfhack.TranslateName(name, eng))
    return string.utf8capitalize(name)
end

function unitprof(unit)
    local prof = dfhack.df2utf(dfhack.units.getProfessionName(unit))
    return string.utf8capitalize(prof)
end

function bldname(bld)
    local name = dfhack.df2utf(utils.call_with_string(bld, 'getName'))
    name = name:gsub('\\f', SYMBOL_FEMALE_UTF):gsub('\\m', SYMBOL_MALE_UTF)
    return string.utf8capitalize(name)
end

function locname(loc)
    local name = dfhack.df2utf(dfhack.TranslateName(loc:getName(), true))
    return string.utf8capitalize(name)
end

--todo: this should add {} for forbidden items
--todo: add info what different type values do
function itemname(item, type, decorate)
    local name = dfhack.items.getDescription(item, type, decorate):gsub('`', '\'')

    if decorate then
        name = name:gsub('<',string.char(174)):gsub('>',string.char(175)):gsub('=',string.char(240)):gsub('@',string.char(15))

        local wear = item:getWear()
        if wear > 0 then
            local x
            if wear == 1 then
                x = 'x'
            elseif wear == 2 then
                x = 'X'
            elseif wear == 3 then
                x = 'xX'
            else
                x = 'XX'
            end

            name = x .. name .. x
        end
    end

    local artname = nil
    local ref = dfhack.items.getGeneralRef(item, df.general_ref_type.IS_ARTIFACT) --as:df.general_ref_artifact
    if ref then
        local art = df.artifact_record.find(ref.artifact_id)
        artname = translatename(art.name) .. ' "' .. translatename(art.name, true) .. '"'
    end    

    --xxx: capitalization removed temporary because it doesn't capitalize decorated names
    --string.utf8capitalize(dfhack.df2utf(name))
    if artname then
        return artname, dfhack.df2utf(name)
    else
        return dfhack.df2utf(name), nil
    end
end

function burrowname(burrow)
    return (#burrow.name > 0) and burrow.name or ('Burrow ' .. tostring(burrow.id+1))
end

function pointname(point)
    return (#point.name > 0) and point.name or ('Point ' .. tostring(point.id+1))
end

function routename(route)
    return (#route.name > 0) and route.name or ('Route ' .. tostring(route.id))
end

function stopname(stop)
    return (#stop.name > 0) and stop.name or ('Stop ' .. tostring(stop.id))
end

function alertname(alert)
    return (#alert.name > 0) and alert.name or ('Alert State ' .. tostring(alert.id))
end

function squadname(squad)
    return (#squad.alias > 0) and squad.alias or dfhack.df2utf(dfhack.TranslateName(squad.name, true))    
end

function uniformname(uniform)
    return (#uniform.name > 0) and uniform.name or ('Uniform ' .. tostring(uniform.id+1))
end

function zonename(zone)
    return 'Activity Zone #' .. tostring(zone.zone_num)
end

function jobname(job)
    return dfhack.df2utf(dfhack.job.getName(job)):utf8capitalize()
end

function quotedname(name)
    return translatename(name) .. ', "' .. translatename(name, true) .. '"'
end

function pos2table(pos)
    return (pos.x ~= -30000) and { pos.x, pos.y, pos.z } or mp.NIL
end

local clock = os.clock
function sleep(n)  -- seconds
  local t0 = clock()
  while clock() - t0 <= n do end
end

function K(k)
    return df.interface_key[k]
end

function list_select_item_by_id(ws, listidx, array, id)
    local idx = -1
    for i,v in ipairs(array) do
        if v and v.id == id then
            idx = i
            break
        end
    end

    if idx == -1 then
        error('list_select_item_by_id did not find ' .. id .. ' in ' .. listidx)
    end

    if idx > 0 then
        ws.layer_objects[listidx].cursor = idx - 1 --hint:df.layer_object_listst
        gui.simulateInput(ws, K'STANDARDSCROLL_DOWN')            
    end 

    return idx
end

--[[function assert_screen(ws, t)
    if ws._type ~= t then
        error(errmsg_wrongscreen(ws))
    end    
end]]

function errmsg_wrongscreen(ws)
    return 'wrong screen ' .. tostring(ws._type) .. ' ' .. dfhack.gui.getCurFocus()
end

function errmsg_wrongmode()
    return 'wrong mode ' .. tostring(df.global.ui.main.mode) .. ' ' .. dfhack.gui.getCurFocus()
end
