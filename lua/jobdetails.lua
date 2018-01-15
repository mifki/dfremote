local detail_type_names = { 'Material', 'Image', 'Size', 'Decoration Type' }
local decoration_type_titles = { 'Image', 'Covered', 'Hanging rings', 'Bands', 'Spikes' }

local function select_artist_to_choose_image(imgws)
    for j,w in ipairs(imgws.anon_1) do
        if w == 5 then
            imgws.category_idx = j
            gui.simulateInput(imgws, K'SELECT')
            break
        end
    end

    imgws.breakdown_level = df.interface_breakdown_types.STOPSCREEN
end

local function ensure_images_loaded(bldid, idx)
    if #df.global.world.art_image_chunks > 0 then
        return
    end

    local function process(ws)
        local det = df.global.ui_sidebar_menus.job_details

        -- select a detail type if it hasn't been selected as the only available
        if det.setting_detail_type == -1 then
            for i,v in ipairs(det.detail_type) do
                if v == 1 then
                    det.detail_cursor = i
                    gui.simulateInput(ws, K'SELECT')
                    break
                end
            end
        end

        local imgws = dfhack.gui.getCurViewscreen()
        if imgws._type == df.viewscreen_image_creatorst then --as:imgws=df.viewscreen_image_creatorst
            select_artist_to_choose_image(imgws)
        end
    end

    if bldid == -2 then
        execute_with_order_details(idx, function(ws)
            process(ws)
        end)
    else
        execute_with_job_details(bldid, idx, function(ws)
            process(ws)
        end)    
    end
end

local function get_chosen_image_title(art_spec, bldid, idx)
    local imgtype = art_spec.type
    if imgtype == -1 then -- n one
        return 'Allow artist to choose'

    elseif imgtype == 0 then -- histfig
        local hf = df.historical_figure.find(art_spec.id)
        return hf and ('Related to ' .. quotedname(hf.name)) or '#invalid histfig #'

    elseif imgtype == 1 then -- site 
        local site = df.world_site.find(art_spec.id)
        return site and ('Related to ' .. quotedname(site.name)) or '#invalid site#'

    elseif imgtype == 2 then -- entity
        local ent = df.historical_entity.find(art_spec.id)
        return ent and ('Related to ' .. quotedname(ent.name)) or '#invalid entity#'

    elseif imgtype == 3 then -- image
        ensure_images_loaded(bldid, idx)
        
        local _,chunk = utils.linear_index(df.global.world.art_image_chunks, art_spec.id, 'id')
        if chunk then
            local _,img = utils.linear_index(chunk.images, art_spec.subid, 'subid')
            if img then
                return quotedname(img.name)
            end
        end

        return '#invalid image#'
    end

    return '#unknown type#'
end

--luacheck: in=number,number
function job_details_get_types(bldid, idx)
    if bldid == -2 then
        return order_details_get_types(idx)
    end

    return execute_with_job_details(bldid, idx, function(ws, job)
        local jobtitle = jobname(job)
        local list = {}

        if df.global.ui_sidebar_menus.job_details.job == job then
            --0-material, 1-image, 2-size, 3-type
            for i,v in ipairs(df.global.ui_sidebar_menus.job_details.detail_type) do
                local cur = ''

                if v == 0 then -- material
                    local mat_type = job.mat_type
                    local mat_index = job.mat_index
                    
                    local mi = dfhack.matinfo.decode(mat_type, mat_index)
                    if mi then --todo: use material_category instead
                        local mat = mi.material
                        cur = dfhack.df2utf((#mat.prefix>0 and (mat.prefix .. ' ') or '') .. mat.state_name[0]):utf8capitalize()
                    end

                elseif v == 1 then -- image
                    cur = get_chosen_image_title(job.art_spec, bldid, idx)

                elseif v == 2 then -- size
                    local race = job.hist_figure_id ~= -1 and job.hist_figure_id or df.global.ui.race_id
                    local creature = df.global.world.raws.creatures.all[race]
                    cur = dfhack.df2utf(creature.name[1]):utf8capitalize()

                elseif v == 3 then -- type
                    if job.hist_figure_id == -1 then
                        cur = 'Not set'
                    else
                        cur = decoration_type_titles[job.hist_figure_id+1] or '#unknown#'
                    end
                end

                table.insert(list, { detail_type_names[v+1], i, v, cur })
            end
        end

        --todo: pass not just job title, include e.g. 'for <race>' for armor, etc.

        return { list, jobtitle }
    end)
end

--luacheck: in=number,number,number
function job_details_get_choices(bldid, jobidx, detidx)
    if bldid == -2 then
        return order_details_get_choices(jobidx, detidx)
    end

    return execute_with_job_details(bldid, jobidx, function(ws)
        local ret = {}
        
        local det = df.global.ui_sidebar_menus.job_details

        local dtype = det.detail_type[detidx]
        if dtype ~= 0 and dtype ~= 2 and dtype ~= 3 then -- Material, size, type
            error('unsupported detail type '..tostring(dtype))
        end

        -- select a detail type if it hasn't been selected as the only available
        if det.setting_detail_type == -1 then
            df.global.ui_sidebar_menus.job_details.detail_cursor = detidx
            gui.simulateInput(ws, K'SELECT')
        end
        
        -- using _visible instead of _all because they're already sorted - available mats on top
        if dtype == 0 then -- material
            for i,v in ipairs(det.mat_type_visible) do
                local mat_type = v
                local mat_index = det.mat_index_visible[i]
                local mat_amount = det.mat_amount_visible[i]
                
                local mi = dfhack.matinfo.decode(mat_type, mat_index)
                local mat = mi.material
                local title = dfhack.df2utf((#mat.prefix>0 and (mat.prefix .. ' ') or '') .. mat.state_name[0]):utf8capitalize()
                
                table.insert(ret, { title, i--[[{ mat_type, mat_index }]], mat_amount })
            end
        
        elseif dtype == 2 then -- size
            for i,v in ipairs(det.sizes_visible) do
                local creature = df.global.world.raws.creatures.all[v]
                local title = dfhack.df2utf(creature.name[1]):utf8capitalize()

                table.insert(ret, { title, i --[[, mp.NIL]] })
            end         

        elseif dtype == 3 then -- type
            for i,v in ipairs(det.decoration_types) do
                local title = decoration_type_titles[v+1]
                if v == 0 then
                    title = title .. ' (image customization is not supported)'
                end

                table.insert(ret, { title, i --[[, mp.NIL]] })
            end
        end

        return ret
    end)
end

--luacheck: in=number,number,number,number
function job_details_set(bldid, jobidx, detidx, choiceidx)
    if bldid == -2 then
        return order_details_set(jobidx, detidx, choiceidx)
    end

    return execute_with_job_details(bldid, jobidx, function(ws)
        local det = df.global.ui_sidebar_menus.job_details

        local dtype = det.detail_type[detidx]
        if dtype ~= 0 and dtype ~= 2 and dtype ~= 3 then -- Material, size, type
            error('unsupported detail type '..tostring(dtype))
        end

        --todo: modify job.hist_figure_id which holds the detail setting directly ?

        -- select a detail type if it hasn't been selected as the only available
        if det.setting_detail_type == -1 then
            df.global.ui_sidebar_menus.job_details.detail_cursor = detidx
            gui.simulateInput(ws, K'SELECT')
        end
        
        if dtype == 0 then -- material
            det.mat_cursor = choiceidx
        elseif dtype == 2 then -- size
            det.size_cursor = choiceidx
        elseif dtype == 3 then -- decoration type
            det.decoration_cursor = choiceidx
        end
        gui.simulateInput(ws, K'SELECT')
        
        -- local imgws = dfhack.gui.getCurViewscreen()
        -- if imgws._type == df.viewscreen_image_creatorst then --as:imgws=df.viewscreen_image_creatorst
        --     select_artist_to_choose_image(imgws)
        -- end

        return true
    end)
end

function order_details_get_types(idx)
    return execute_with_order_details(idx, function(ws)
        local list = {}

        local order = df.global.world.manager_orders[idx]
        local ordertitle = ordertitle(order)

        --0-material, 1-image, 2-size, 3-type
        for i,v in ipairs(df.global.ui_sidebar_menus.job_details.detail_type) do
            local cur = ''

            if v == 0 then -- material
                local mat_type = order.mat_type
                local mat_index = order.mat_index
                
                local mi = dfhack.matinfo.decode(mat_type, mat_index)
                if mi then --todo: use material_category instead
                    local mat = mi.material
                    cur = dfhack.df2utf((#mat.prefix>0 and (mat.prefix .. ' ') or '') .. mat.state_name[0]):utf8capitalize()
                end

            elseif v == 1 then -- image
                cur = get_chosen_image_title(order.art_spec, -2, idx)

            elseif v == 2 then -- size
                local race = order.hist_figure_id ~= -1 and order.hist_figure_id or df.global.ui.race_id
                local creature = df.global.world.raws.creatures.all[race]
                cur = dfhack.df2utf(creature.name[1]):utf8capitalize()

            elseif v == 3 then -- type
                if order.hist_figure_id == -1 then
                    cur = 'Not set'
                else
                    cur = decoration_type_titles[order.hist_figure_id+1] or '#unknown#'
                end
            end

            table.insert(list, { detail_type_names[v+1], i, v, cur })
        end

        --todo: pass not just order title, include e.g. 'for <race>' for armor, etc.

        return { list, ordertitle }
    end)
end

function order_details_get_choices(idx, detidx)
    return execute_with_order_details(idx, function(ws)
        local ret = {}
        
        local det = df.global.ui_sidebar_menus.job_details

        local dtype = det.detail_type[detidx]
        if dtype ~= 0 and dtype ~= 2 and dtype ~= 3 then -- Material, size, type
            error('unsupported detail type '..tostring(dtype))
        end

        -- select a detail type if it hasn't been selected as the only available
        if det.setting_detail_type == -1 then
            df.global.ui_sidebar_menus.job_details.detail_cursor = detidx
            gui.simulateInput(ws, K'SELECT')
        end
        
        -- using _visible instead of _all because they're already sorted - available mats on top
        if dtype == 0 then -- material
            for i,v in ipairs(det.mat_type_visible) do
                local mat_type = v
                local mat_index = det.mat_index_visible[i]
                local mat_amount = det.mat_amount_visible[i]
                
                local mi = dfhack.matinfo.decode(mat_type, mat_index)
                local mat = mi.material
                local title = dfhack.df2utf((#mat.prefix>0 and (mat.prefix .. ' ') or '') .. mat.state_name[0]):utf8capitalize()
                
                table.insert(ret, { title, i--[[{ mat_type, mat_index }]], mat_amount })
            end
        
        elseif dtype == 2 then -- size
            for i,v in ipairs(det.sizes_visible) do
                local creature = df.global.world.raws.creatures.all[v]
                local title = dfhack.df2utf(creature.name[1]):utf8capitalize()

                table.insert(ret, { title, i --[[, mp.NIL]] })
            end         

        elseif dtype == 3 then -- type
            for i,v in ipairs(det.decoration_types) do
                local title = decoration_type_titles[v+1]
                if v == 0 then
                    title = title .. ' (image customization is not supported)'
                end

                table.insert(ret, { title, i --[[, mp.NIL]] })
            end
        end

        return ret
    end)
end

function order_details_set(idx, detidx, choiceidx)
    return execute_with_order_details(idx, function(ws)
        local det = df.global.ui_sidebar_menus.job_details

        local dtype = det.detail_type[detidx]
        if dtype ~= 0 and dtype ~= 2 and dtype ~= 3 then -- Material, size, type
            error('unsupported detail type '..tostring(dtype))
        end

        --todo: modify job.hist_figure_id which holds the detail setting directly ?

        -- select a detail type if it hasn't been selected as the only available
        if det.setting_detail_type == -1 then
            df.global.ui_sidebar_menus.job_details.detail_cursor = detidx
            gui.simulateInput(ws, K'SELECT')
        end
        
        if dtype == 0 then -- material
            det.mat_cursor = choiceidx
        elseif dtype == 2 then -- size
            det.size_cursor = choiceidx
        elseif dtype == 3 then -- decoration type
            det.decoration_cursor = choiceidx
        end
        gui.simulateInput(ws, K'SELECT')
        
        -- local imgws = dfhack.gui.getCurViewscreen()
        -- if imgws._type == df.viewscreen_image_creatorst then --as:imgws=df.viewscreen_image_creatorst
        --     select_artist_to_choose_image(imgws)
        -- end
        
        return true
    end)
end

--luacheck: in=number,number,number
function job_details_image_get_choices(bldid, idx, imgtype)
    if imgtype == 0 then -- histfig
        local ret = {}

        for i,v in ipairs(df.global.world.history.figures) do
            if v.race ~= -1 and v.name.has_name then
                local name = translatename(v.name)
                local name_eng = translatename(v.name, true)
                
                table.insert(ret, { name, v.id, name_eng })
            end
        end

        table.sort(ret, function(a,b) return a[1] < b[1] end)
        return ret        
    end

    if imgtype == 1 then -- site
        local ret = {}

        for i,v in ipairs(df.global.world.world_data.sites) do
            if not v.flags.Undiscovered then
                local name = translatename(v.name)
                local name_eng = translatename(v.name, true)
                
                table.insert(ret, { name, v.id, name_eng })
            end
        end

        table.sort(ret, function(a,b) return a[1] < b[1] end)
        return ret
    end

    if imgtype == 2 then -- entity
        local ret = {}

        for i,v in ipairs(df.global.world.entities.all) do
            local name = translatename(v.name)
            if #name > 0 then
                local name_eng = translatename(v.name, true)
                
                table.insert(ret, { name, v.id, name_eng })
            end
        end

        table.sort(ret, function(a,b) return a[1] < b[1] end)
        return ret
    end

    if imgtype == 3 then -- existing image
        ensure_images_loaded(bldid, idx)

        local ret = {}

        local group = df.historical_entity.find(df.global.ui.group_id)
        local civ = df.historical_entity.find(df.global.ui.civ_id)

        local function process(ent, kind)
            for i,v in ipairs(ent.resources.art_image_types) do
                local id = ent.resources.art_image_ids[i]
                local subid = ent.resources.art_image_subids[i]
                local _,chunk = utils.linear_index(df.global.world.art_image_chunks, id, 'id')
                
                if chunk then
                    local _,img = utils.linear_index(chunk.images, subid, 'subid')
    
                    if img then
                        local name = translatename(img.name)
                        local name_eng = translatename(img.name, true)
    
                        local origin = kind
                        if v == 0 then
                            origin = kind .. ' symbol'
                        elseif v == 1 then
                            origin = kind .. ' comission'
                        end
    
                        table.insert(ret, { name, { id, subid }, name_eng, origin })

                    else
                        print ('no img '..tostring(subid)..' in chunk '..tostring(id))
                    end

                else
                    print ('no chunk '..tostring(id))
                end
            end
        end

        process(group, 'Group')
        process(civ, 'Civ.')
    
        return ret
    end
end

--luacheck: in=number,number,number,number
function job_details_set_image(bldid, idx, imgtype, id)
    if bldid == -2 then
        local order = df.global.world.manager_orders[idx]

        order.art_spec.type = imgtype
        if type(id) == 'table' then
            local spec = id --as:number[]
            order.art_spec.id = spec[1]
            order.art_spec.subid = spec[2]
        else
            order.art_spec.id = id
            order.art_spec.subid = -1
        end

        return true
    end

    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        error(errmsg_wrongscreen(ws))
    end

    if df.global.ui.main.mode ~= df.ui_sidebar_mode.QueryBuilding or df.global.world.selected_building == nil then
        error('no selected_building')
    end

    local bld = df.global.world.selected_building
    --todo: check bld.id == bldid

    if idx < 0 or idx > #bld.jobs then
        error('invalid job idx '..tostring(idx))
    end

    local job = bld.jobs[idx]

    job.art_spec.type = imgtype
    if type(id) == 'table' then
        local spec = id --as:number[]
        job.art_spec.id = spec[1]
        job.art_spec.subid = spec[2]
    else --as:id=number
        job.art_spec.id = id
        job.art_spec.subid = -1
    end

    return true
end

-- print(pcall(function() return json:encode(job_details_image_get_choices(-2,0,0)) end))
