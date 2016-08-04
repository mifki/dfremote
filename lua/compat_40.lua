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