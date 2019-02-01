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

function C_viewscreen_workquota_conditionst_satisfied_items(ws)
	return ws.satisfied
end

function C_viewscreen_workquota_conditionst_satisfied_orders(ws)
	return ws.anon_1
end

function C_unit_dead(unit)
	return unit.flags1.dead
end

function C_announcements()
	return df.global.announcements
end

function C_ui_menu_width()
	return df.global.ui_menu_width
end

function C_ui_area_map_width()
	return df.global.ui_area_map_width
end

function C_world_site_nemesis(site)
	return site.nemesis
end

function C_world_site_inhabitants(site)
	return site.inhabitants
end

function C_world_raws_colors()
	return df.global.world.raws.language.colors
end

function C_unit_corpse_name(unit)
	return unit.enemy.undead.anon_7
end

function C_squads_list()
	return df.global.ui.squads.list
end

function C_plant_tree_tile_any_branches(t)
	return t.branches or t.thick_branches_1 or t.thick_branches_2 or t.thick_branches_3 or t.thick_branches_4
end
