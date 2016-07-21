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

		--todo: don't allow to get image choices
		--local job = df.global.ui_sidebar_menus.job_details.detail_type.job

		--todo: check detidx range

		df.global.ui_sidebar_menus.job_details.detail_cursor = detidx
		gui.simulateInput(ws, K'SELECT')

		for i,v in ipairs(df.global.ui_sidebar_menus.job_details.mat_amount_visible) do
			print(v)
			--table.insert(ret, { detail_type_names[v+1], i, v, '' })
		end

		return ret
	end)
end

print(json:encode(job_details_get_types(-1,0)))
print(json:encode(job_details_get_choices(-1,0,0)))