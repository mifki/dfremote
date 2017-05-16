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
