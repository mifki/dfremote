function C_ws_cases(ws)
	return ws.recent_cases
end

function C_ws_set_sel_idx_current(ws, idx)
	ws.anon_1 = idx
end

function C_pet_set_available(item, val)
	item.anon_2 = val and 1 or 0
end

function C_pet_available(item)
	return istrue(item.anon_2)
end

function C_pet_ownerid(item)
	local ownerid = item['item_petst.anon_1'] --as:number
	return ownerid
end

function C_crime_report_found_body(r)
	return istrue(r.unk1)
end

function C_body_part_geldable(bp)
	return bp.flags[38]
end

function C_unit_available_for_adoption(unit)
	return unit.flags3[27]
end

function C_unit_set_available_for_adoption(unit, val)
	unit.flags3[27] = val
end

function C_unit_geld(unit)
	return unit.flags3[29]
end

function C_unit_set_geld(unit, val)
	unit.flags3[29] = val
end

function C_manager_order_is_validated(o)
	return o.is_validated
end

function C_training_assignment_get_flags(training_assignment)	
	local any_trainer 			 = bit32.band(training_assignment.auto_mode, 1) ~= 0
	local any_unassigned_trainer = bit32.band(training_assignment.auto_mode, 2) ~= 0
	local train_war 			 = bit32.band(training_assignment.auto_mode, 4) ~= 0
	local train_hunt 			 = bit32.band(training_assignment.auto_mode, 8) ~= 0	
	
	return { any_trainer=any_trainer, any_unassigned_trainer=any_unassigned_trainer, train_war=train_war, train_hunt=train_hunt }
end

function C_training_assignment_set_flags(training_assignment, flags)
	training_assignment.auto_mode = packbits(flags.any_trainer, flags.any_unassigned_trainer, flags.train_war, flags.train_hunt)
end

function C_build_req_get_required(req)
	return req.count_required
end

function C_build_req_get_max(req)
	return req.count_max
end

function C_build_req_get_provided(req)
	return req.count_provided
end

function C_lever_target_type_get()
	if dfhack.getOSType() == 'windows' then
		return df.reinterpret_cast('int8_t', 0x01165807+dfhack.internal.getRebaseDelta()).value
	else
		return df.reinterpret_cast('int8_t', dfhack.internal.getAddress('ui_workshop_in_add')+1).value
	end	
end

function C_lever_target_type_set(val)
	if dfhack.getOSType() == 'windows' then
		df.reinterpret_cast('int8_t', 0x01165807+dfhack.internal.getRebaseDelta()).value = val
	else
		df.reinterpret_cast('int8_t', dfhack.internal.getAddress('ui_workshop_in_add')+1).value = val
	end	
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
