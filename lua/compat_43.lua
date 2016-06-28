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