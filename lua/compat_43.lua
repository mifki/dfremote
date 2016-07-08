function C_ws_cases(ws)
	return ws.cases
end

function C_ws_set_sel_idx_current(ws, idx)
	ws.sel_idx_current = idx
end

function C_pet_set_available(item, val)
	item.pet_flags.available_for_adoption = val
end

function C_pet_available(item)
	return item.pet_flags.available_for_adoption
end

function C_pet_ownerid(item)
	return item.owner_id
end

function C_crime_report_found_body(r)
	return istrue(r.unk1)
end

function C_body_part_geldable(bp)
	return bp.flags.GELDABLE
end

function C_unit_available_for_adoption(unit)
	return unit.flags3.available_for_adoption
end

function C_unit_set_available_for_adoption(unit, val)
	unit.flags3.available_for_adoption = val
end

function C_unit_geld(unit)
	return unit.flags3[29]
end

function C_unit_set_geld(unit, val)
	unit.flags3[29] = val
end

function C_manager_order_is_validated(o)
	return o.status.validated
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