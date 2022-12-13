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
	return { sqpos.activities[0], sqpos.activities[1], sqpos.activities[2] }, { sqpos.events[0], sqpos.events[1], sqpos.events[2] }
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
	return ws.satisfied_items
end

function C_viewscreen_workquota_conditionst_satisfied_orders(ws)
	return ws.satisfied_orders
end

function C_unit_dead(unit)
	return unit.flags1.inactive
end

function C_announcements()
	return df.global.d_init.announcements
end

function C_ui_menu_width()
	return df.global.ui_menu_width[0]
end

function C_ui_area_map_width()
	return df.global.ui_menu_width[1]
end

function C_world_site_nemesis(site)
	return site.unk_1.nemesis
end

function C_world_site_inhabitants(site)
	return site.unk_1.inhabitants
end

function C_world_raws_colors()
	return df.global.world.raws.descriptors.colors
end

function C_unit_corpse_name(unit)
	return unit.enemy.undead.undead_name
end

function C_squads_list()
	return df.global.ui.squads.list
end

function C_plant_tree_tile_any_branches(t)
	return t.branches or t.connection_east or t.connection_south or t.connection_west or t.connection_north
end

function C_viewscreen_image_creatorst_modes(imgws)
	return imgws.modes
end

function C_viewscreen_image_creatorst_set_mode_cursor(imgws, idx)
	imgws.mode_cursor = idx
end

function C_viewscreen_new_regionst_loading_raws(ws)
	return ws.load_world_params
end
