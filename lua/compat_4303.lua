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