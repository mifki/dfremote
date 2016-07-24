local detail_type_names = { 'Material', 'Image', 'Size', 'Decoration Type' }
local decoration_type_titles = { 'Image', 'Covered', 'Hanging rings', 'Bands', 'Spikes' }

--luacheck: in=number,number
function job_details_get_types(bldid, idx)
	return execute_with_job_details(bldid, idx, function(ws)
		local list = {}

		local job = df.global.ui_sidebar_menus.job_details.job

		if not job then
			return {}, mp.NIL
		end

		local jobtitle = dfhack.job.getName(job)

		--0-material, 1-image, 2-size, 3-type
		for i,v in ipairs(df.global.ui_sidebar_menus.job_details.detail_type) do
			if v ~= 1 then -- image not supported
				local cur = ''

				if v == 0 then
					local mat_type = job.mat_type
					local mat_index = job.mat_index
					
					local mi = dfhack.matinfo.decode(mat_type, mat_index)
					local mat = mi.material
		            cur = dfhack.df2utf((#mat.prefix>0 and (mat.prefix .. ' ') or '') .. mat.state_name[0]):utf8capitalize()

		        elseif v == 2 then
					local creature = df.global.world.raws.creatures.all[job.hist_figure_id]
					cur = dfhack.df2utf(creature.name[1]):utf8capitalize()

		        elseif v == 3 then
					cur = decoration_type_titles[job.hist_figure_id]

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
	return execute_with_job_details(bldid, jobidx, function(ws)
		local ret = {}
		
		local det = df.global.ui_sidebar_menus.job_details

		local dtype = det.detail_type[detidx]
		if dtype ~= 0 and dtype ~= 2 and dtype ~= 3 then -- Material, size, type
			error('unsupported detail type '..tostring(dtype))
		end

		if det.setting_deatil_type == -1 then
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
	return execute_with_job_details(bldid, jobidx, function(ws)
		local det = df.global.ui_sidebar_menus.job_details

		local dtype = det.detail_type[detidx]
		if dtype ~= 0 and dtype ~= 2 and dtype ~= 3 then -- Material, size, type
			error('unsupported detail type '..tostring(dtype))
		end

		--todo: modify job.hist_figure_id which holds the detail setting directly ?

		if det.setting_deatil_type == -1 then
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
		local ordertitle = 'asda'

		--0-material, 1-image, 2-size, 3-type
		for i,v in ipairs(df.global.ui_sidebar_menus.job_details.detail_type) do
			if v ~= 1 then -- image not supported
				local cur = ''

				if v == 0 then
					local mat_type = order.mat_type
					local mat_index = order.mat_index
					
					local mi = dfhack.matinfo.decode(mat_type, mat_index)
					local mat = mi.material
		            cur = dfhack.df2utf((#mat.prefix>0 and (mat.prefix .. ' ') or '') .. mat.state_name[0]):utf8capitalize()

		        elseif v == 2 then
					local creature = df.global.world.raws.creatures.all[order.hist_figure_id]
					cur = dfhack.df2utf(creature.name[1]):utf8capitalize()

		        elseif v == 3 then
					cur = decoration_type_titles[order.hist_figure_id]

				end

				table.insert(list, { detail_type_names[v+1], i, v, cur })
			end
		end

		--todo: pass not just order title, include e.g. 'for <race>' for armor, etc.

		return { list, ordertitle }
	end)
end

-- print(json:encode(job_details_get_types(-1,0)))
-- print(json:encode(job_details_get_choices(-1,0,0)))
-- print(json:encode(order_details_get_types(1)))