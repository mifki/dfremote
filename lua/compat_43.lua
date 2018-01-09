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

function C_viewscreen_workquota_conditionst_item_type(q, i)
	local _,addr = q.anon_2:sizeof()
	return df.reinterpret_cast('int16_t', df.reinterpret_cast('intptr_t', addr).value + 2*i).value
end

function C_viewscreen_workquota_conditionst_item_subtype(q, i)
	local _,addr = q.anon_3:sizeof()
	return df.reinterpret_cast('int16_t', df.reinterpret_cast('intptr_t', addr).value + 2*i).value
end

function C_viewscreen_workquota_conditionst_item_smth1(q, i)
	local _,addr = q.anon_4:sizeof()
	return df.reinterpret_cast('int16_t', df.reinterpret_cast('intptr_t', addr).value + 2*i).value
end

function C_viewscreen_workquota_conditionst_item_smth2(q, i)
	local _,addr = q.anon_5:sizeof()
	return df.reinterpret_cast('int16_t', df.reinterpret_cast('intptr_t', addr).value + 2*i).value
end
