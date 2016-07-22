local detail_type_names = { 'Material', 'Image', 'Size', 'Type' }

--luacheck: in=number,number
function job_details_get_types(bldid, idx)
	return execute_with_job_details(bldid, idx, function(ws)
		local ret = {}

		--local job = df.global.ui_sidebar_menus.job_details.detail_type.job

		--0-material, 1-image, 2-size, 3-type
		for i,v in ipairs(df.global.ui_sidebar_menus.job_details.detail_type) do
			table.insert(ret, { detail_type_names[v+1], i, v, '' })
		end

		return ret
	end)
end

--luacheck: in=number,number,number
function job_details_get_choices(bldid, jobidx, detidx)
	return execute_with_job_details(bldid, jobidx, function(ws)
		local ret = {}
		
		local det = df.global.ui_sidebar_menus.job_details

		--local job = det.detail_type.job

		--todo: check detidx range
		--todo: don't allow to get image choices
		local dtype = det.detail_type[detidx]
		if dtype ~= 0 then -- Material
			error('unsupported detail type '..tostring(dtype))
		end

		df.global.ui_sidebar_menus.job_details.detail_cursor = detidx
		gui.simulateInput(ws, K'SELECT')
		
		-- using _visible instead of _all because they're already sorted - available mats on top
		if dtype == 0 then -- material
			for i,v in ipairs(det.mat_type_visible) do
				local mat_type = v
				local mat_index = det.mat_index_visible[i]
				local mat_amount = det.mat_amount_visible[i]
				
				local mi = dfhack.matinfo.decode(mat_type, mat_index)
				local mat = mi.material
	            local title = dfhack.df2utf((#mat.prefix>0 and (mat.prefix .. ' ') or '') .. mat.state_name[0]):utf8capitalize()
				
				table.insert(ret, { title, { mat_type, mat_index }, mat_amount })
			end
		end

		return ret
	end)
end

-- print(json:encode(job_details_get_types(-1,0)))
-- print(json:encode(job_details_get_choices(-1,0,0)))