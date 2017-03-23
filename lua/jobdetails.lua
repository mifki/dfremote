local detail_type_names = { 'Material', 'Image', 'Size', 'Decoration Type' }
local decoration_type_titles = { 'Image', 'Covered', 'Hanging rings', 'Bands', 'Spikes' }

--luacheck: in=number,number
function job_details_get_types(bldid, idx)
	if bldid == -2 then
		return order_details_get_types(idx)
	end

	return execute_with_job_details(bldid, idx, function(ws)
		local list = {}

		local job = df.global.ui_sidebar_menus.job_details.job

		if not job then
			return { {}, mp.NIL }
		end

		local jobtitle = jobname(job)

		--0-material, 1-image, 2-size, 3-type
		for i,v in ipairs(df.global.ui_sidebar_menus.job_details.detail_type) do
			local cur = ''

			if v == 0 then
				local mat_type = job.mat_type
				local mat_index = job.mat_index
				
				local mi = dfhack.matinfo.decode(mat_type, mat_index)
				if mi then --todo: use material_category instead
					local mat = mi.material
		            cur = dfhack.df2utf((#mat.prefix>0 and (mat.prefix .. ' ') or '') .. mat.state_name[0]):utf8capitalize()
		        end

	        elseif v == 2 then
	        	local race = job.hist_figure_id ~= -1 and job.hist_figure_id or df.global.ui.race_id
				local creature = df.global.world.raws.creatures.all[race]
				cur = dfhack.df2utf(creature.name[1]):utf8capitalize()

	        elseif v == 3 then
				cur = decoration_type_titles[job.hist_figure_id] or '#unknown#'

			end

			table.insert(list, { detail_type_names[v+1], i, v, cur })
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

		if C_job_details_setting_detail_type(det) == -1 then
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
				if v ~= 0 then -- image not supported
					local title = decoration_type_titles[v+1]

					table.insert(ret, { title, i --[[, mp.NIL]] })
				end
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

		if C_job_details_setting_detail_type(det) == -1 then
			df.global.ui_sidebar_menus.job_details.detail_cursor = detidx
			gui.simulateInput(ws, K'SELECT')
		end
		
		if dtype == 0 then -- material
			det.mat_cursor = choiceidx
		elseif dtype == 2 then -- size
			det.size_cursor = choiceidx
		elseif dtype == 3 then -- size
			det.decoration_cursor = choiceidx
		end
		gui.simulateInput(ws, K'SELECT')

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

			if v == 0 then
				local mat_type = order.mat_type
				local mat_index = order.mat_index
				
				local mi = dfhack.matinfo.decode(mat_type, mat_index)
				if mi then --todo: use material_category instead
					local mat = mi.material
		            cur = dfhack.df2utf((#mat.prefix>0 and (mat.prefix .. ' ') or '') .. mat.state_name[0]):utf8capitalize()
		        end

	        elseif v == 2 then
	        	local race = order.hist_figure_id ~= -1 and order.hist_figure_id or df.global.ui.race_id
				local creature = df.global.world.raws.creatures.all[race]
				cur = dfhack.df2utf(creature.name[1]):utf8capitalize()

	        elseif v == 3 then
				cur = decoration_type_titles[order.hist_figure_id]

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

		if C_job_details_setting_detail_type(det) == -1 then
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
				if v ~= 0 then -- image not supported
					local title = decoration_type_titles[v+1]

					table.insert(ret, { title, i --[[, mp.NIL]] })
				end
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

		if C_job_details_setting_detail_type(det) == -1 then
			df.global.ui_sidebar_menus.job_details.detail_cursor = detidx
			gui.simulateInput(ws, K'SELECT')
		end
		
		if dtype == 0 then -- material
			det.mat_cursor = choiceidx
		elseif dtype == 2 then -- size
			det.size_cursor = choiceidx
		elseif dtype == 3 then -- size
			det.decoration_cursor = choiceidx
		end
		gui.simulateInput(ws, K'SELECT')

		return true
	end)
end

local function ensure_images_loaded(bldid, idx)
	if #df.global.world.art_image_chunks > 0 then
		return
	end

	local function process(ws)
		for i,v in ipairs(df.global.ui_sidebar_menus.job_details.detail_type) do
			if v == 1 then
				df.global.ui_sidebar_menus.job_details.detail_cursor = i
				gui.simulateInput(ws, K'SELECT')

				local imgws = dfhack.gui.getCurViewscreen()
				if imgws._type == df.viewscreen_image_creatorst then --as:imgws=df.viewscreen_image_creatorst
					for j,w in ipairs(imgws.anon_1) do
						if w == 5 then
							imgws.category_idx = j
							gui.simulateInput(imgws, K'SELECT')
							break
						end
					end

					imgws.breakdown_level = df.interface_breakdown_types.STOPSCREEN
				end

				return
			end
		end		
	end

	if bldid == -2 then
		execute_with_order_details(idx, function(ws)
			process(ws)
		end)

		return
	end

	execute_with_job_details(bldid, idx, function(ws)
		process(ws)
	end)	
end

--luacheck: in=number,number,number
function job_details_image_get_choices(bldid, idx, imgtype)
	if imgtype == 1 then -- Site
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

	if imgtype == 2 then -- Entity
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

	if imgtype == 3 then
		ensure_images_loaded(bldid, idx)

		local ret = {}

		local group = df.historical_entity.find(df.global.ui.group_id)
		local civ = df.historical_entity.find(df.global.ui.civ_id)

		local function process(ent, kind)
			for i,v in ipairs(ent.resources.art_image_types) do
				local id = ent.resources.art_image_ids[i]
				local subid = ent.resources.art_image_subids[i]
				local _,chunk = utils.linear_index(df.global.world.art_image_chunks, id, 'id')
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
        error('wrong screen '..tostring(ws._type))
    end

    if df.global.ui.main.mode ~= 17 or df.global.world.selected_building == nil then
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
