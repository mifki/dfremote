function C_job_details_setting_detail_type(det)
	return det.setting_deatil_type
end

function C_unit_pet_owner_id(unit)
	return unit.relations.pet_owner_id
end

function C_unit_set_pet_owner_id(unit, value)
	unit.relations.pet_owner_id = value
end

function C_unit_spouse_id(unit)
	return unit.relations.spouse_id
end

function C_unit_soul_performance_skills(soul)
	return soul.perfomance_skills
end

function C_entity_organic_resources_parchment(organic)
	return organic.anon_1
end

function C_check_embark_warning_flags(ws)
	return ws.in_embark_aquifer or ws.in_embark_salt or ws.in_embark_large or ws.in_embark_normal
end

function C_reset_embark_warning_flags(ws)
	ws.in_embark_aquifer = false
	ws.in_embark_salt = false
	ws.in_embark_large = false
	ws.in_embark_normal = false
end

function C_location_finder_search_x(finder)
	return finder.search_x
end

function C_location_finder_set_search_x(finder, val)
	finder.search_x = val
end

function C_location_finder_search_y(finder)
	return finder.search_y
end

function C_embark_get_profile_name(ws, idx)
	--xxx: ws.choices is holding a list of profiles, but the structure is unknown. the first field is string and is the name
	--xxx: so we reinterpret pointers as some other class that has string name as first field, just to access it from Lua easily
	local ptr = ws.choices[idx]
	local name = df.reinterpret_cast(df.interaction,ptr).name

	return name
end

--xxx: one extra field in ui_build_item_req in 0.43 which hasn't been added to dfhack
function C_build_req_get_required(req)
	local _,addr = req:sizeof()
	req = df.reinterpret_cast(df.ui_build_item_req, addr+4)

	return req.count_required
end

function C_build_req_get_max(req)
	local _,addr = req:sizeof()
	req = df.reinterpret_cast(df.ui_build_item_req, addr+4)

	return req.count_max
end

function C_build_req_get_provided(req)
	local _,addr = req:sizeof()
	req = df.reinterpret_cast(df.ui_build_item_req, addr+4)

	return req.count_provided
end
