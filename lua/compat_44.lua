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

function C_embark_get_profile_name(ws, idx)
	if dfhack.VERSION == '0.43.05-r1' then
		--xxx: ws.choices is holding a list of profiles, but the structure is unknown. the first field is string and is the name
		--xxx: so we reinterpret pointers as some other class that has string name as first field, just to access it from Lua easily
		--xxx: in 0.43.05-r1 this list is int32 instead of int64
		local ptr = (ws.choices[idx*2+1] << 32) + ws.choices[idx*2]
		local name = df.reinterpret_cast(df.interaction,ptr).name

		return name
	end

	return ws.choices[idx].name
end

function C_location_finder(finder)
	if dfhack.VERSION == '0.43.05-r1' then
		local size,addr = finder:sizeof()
		local _finder = df.reinterpret_cast(df.viewscreen_choose_start_sitest.T_finder, addr-4) --as:df.viewscreen_choose_start_sitest.T_finder
		return _finder
	end

	return finder
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
	return unit.enemy.undead.unk_7
end

function C_squads_list()
	if dfhack.VERSION == '0.44.12-r1' then
		-- squad list is in a wrong location and has a wrong type
		return df.reinterpret_cast(df.global.ui.squads.list, df.global.ui.squads.unk_44_12i)
	end

	return df.global.ui.squads.list
end