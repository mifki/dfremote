function C_job_details_setting_detail_type(det)
	return det.setting_detail_type
end

function C_unit_pet_owner_id(unit)
	return unit.relationship_ids[df.unit_relationship_type.Pet]
end

function C_unit_set_pet_owner_id(unit, value)
	unit.relationship_ids[df.unit_relationship_type.Pet] = value
end

function C_unit_spouse_id(unit)
	return unit.relationship_ids[df.unit_relationship_type.Spouse]
end

function C_unit_soul_performance_skills(soul)
	return soul.performance_skills
end

function C_entity_organic_resources_parchment(organic)
	return organic.parchment
end

--todo: what is ws.in_embark_only_warning ???
function C_check_embark_warning_flags(ws)
	return ws.in_embark_aquifer or ws.in_embark_salt or ws.in_embark_large or ws.in_embark_narrow or ws.in_embark_civ_dying
end

function C_location_finder_search_x(finder)
	if dfhack.VERSION == '0.43.05-r1' then
		return finder.anon_1
	end

	return finder.search_x
end

function C_location_finder_set_search_x(finder, val)
	if dfhack.VERSION == '0.43.05-r1' then
		finder.anon_1 = val
	end

	finder.search_x = val
end

function C_location_finder_search_y(finder)
	if dfhack.VERSION == '0.43.05-r1' then
		return finder.search_x
	end

	return finder.search_y
end

function C_embark_get_profile_name(ws, idx)
	--xxx: ws.choices is holding a list of profiles, but the structure is unknown. the first field is string and is the name
	--xxx: so we reinterpret pointers as some other class that has string name as first field, just to access it from Lua easily
	--xxx: in 0.43.05-r1 this list is int32 instead of int64
	local ptr = (ws.choices[idx*2+1] << 32) + ws.choices[idx*2]
	local name = df.reinterpret_cast(df.interaction,ptr).name

	return name
end

