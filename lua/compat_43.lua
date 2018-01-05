function C_crime_report_found_body(r)
	return istrue(r.unk1)
end

function C_unit_geld(unit)
	return unit.flags3[29]
end

function C_unit_set_geld(unit, val)
	unit.flags3[29] = val
end

function C_squad_position_activities_events(sqpos)
	return { sqpos.activities[1], sqpos.activities[2], sqpos.events[0] }, { sqpos.events[1], sqpos.events[2], sqpos.unk_118 }
end