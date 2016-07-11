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
	return item['item_petst.anon_1']
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
	local flags = training_assignment.flags
	return { any_trainer=flags.any_trainer, any_unassigned_trainer=flags.any_unassigned_trainer, train_war=flags.train_war, train_hunt=flags.train_hunt }
end

function C_training_assignment_set_flags(training_assignment, flags)
	training_assignment.flags.any_trainer 			 = istrue(flags.any_trainer)
	training_assignment.flags.any_unassigned_trainer = istrue(flags.any_unassigned_trainer)
	training_assignment.flags.train_war 			 = istrue(flags.train_war)
	training_assignment.flags.train_hunt 			 = istrue(flags.train_hunt)
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