local orders = {
	{
		'Job Cancellations', {
			{
				'standing_orders_job_cancel_announce', {
					'Announce no job cancellations',
					'Announce some job cancellations',
					'Announce most job cancellations',
					'Announce all job cancellations'
				}, K'ORDERS_EXCEPTIONS'
			},
		}, df.ui_sidebar_mode.Orders
	},

	{
		'Gathering', {
			{ 'standing_orders_gather_animals', 'Dwarves gather animals', K'ORDERS_GATHER_ANIMALS' },
			{ 'standing_orders_gather_food', 'Dwarves gather food', K'ORDERS_GATHER_FOOD' },
			{ 'standing_orders_gather_furniture', 'Dwarves gather furniture', K'ORDERS_GATHER_FURNITURE' },
			{ 'standing_orders_gather_bodies', 'Dwarves gather bodies', K'ORDERS_GATHER_BODIES' },
			{ 'standing_orders_gather_minerals', 'Dwarves gather minerals', K'ORDERS_GATHER_STONE' },
			{ 'standing_orders_gather_wood', 'Dwarves gather wood', K'ORDERS_GATHER_WOOD' },
		}, df.ui_sidebar_mode.Orders
	},

	{
		'Refuse', {
			{ 'standing_orders_gather_refuse', 'Dwarves gather refuse', K'ORDERS_REFUSE_GATHER' },
			{ 'standing_orders_gather_refuse_outside', '\tDwarves gather refuse from outside', K'ORDERS_REFUSE_OUTSIDE' },
			{ 'standing_orders_gather_vermin_remains', '\t\tDwarves gather vermin remains', K'ORDERS_REFUSE_OUTSIDE_VERMIN' },
		--[[}, df.ui_sidebar_mode.OrdersRefuse
	},

	{
		'', {]]
			{ 'standing_orders_dump_corpses', '\tDwarves dump corpses', K'ORDERS_REFUSE_DUMP_CORPSE' },
			{ 'standing_orders_dump_skulls', '\tDwarves dump skulls', K'ORDERS_REFUSE_DUMP_SKULL' },
			{ 'standing_orders_dump_bones', '\tDwarves dump bones', K'ORDERS_REFUSE_DUMP_BONE' }, 
			{ 'standing_orders_dump_shells', '\tDwarves dump shells', K'ORDERS_REFUSE_DUMP_SHELL' },
			{ 'standing_orders_dump_skins', '\tDwarves dump skins', K'ORDERS_REFUSE_DUMP_SKIN' },
			{ 'standing_orders_dump_hair', '\tDwarves dump hair & wool', K'ORDERS_REFUSE_DUMP_STRAND_TISSUE' },
			{ 'standing_orders_dump_other', '\tDwarves dump other', K'ORDERS_REFUSE_DUMP_OTHER' },
		}, df.ui_sidebar_mode.OrdersRefuse
	},

	{
		'Forbidding', {
			{ 'standing_orders_forbid_used_ammo', 'Forbid used ammunition', K'ORDERS_FORBID_PROJECTILE' },
			{ 'standing_orders_forbid_own_dead', 'Forbid your dead', K'ORDERS_FORBID_YOUR_CORPSE' },
			{ 'standing_orders_forbid_own_dead_items', 'Forbid your death items', K'ORDERS_FORBID_YOUR_ITEMS' },
			{ 'standing_orders_forbid_other_nohunt', 'Forbid other dead', K'ORDERS_FORBID_OTHER_CORPSE' },
			{ 'standing_orders_forbid_other_dead_items', 'Forbid other death items', K'ORDERS_FORBID_OTHER_ITEMS' },
		}, df.ui_sidebar_mode.OrdersForbid
	},

	{
		'', {
			{ 'standing_orders_farmer_harvest', 'Only farmers harvest', K'ORDERS_ALL_HARVEST' },
			{ 'standing_orders_mix_food', 'Mix food', K'ORDERS_MIXFOODS' },
		}, df.ui_sidebar_mode.Orders
	},

	{
		'Workshop Orders', {
			{ 'standing_orders_auto_collect_webs', 'Auto collect webs', K'ORDERS_COLLECT_WEB' },
			{ 'standing_orders_auto_slaughter', 'Auto slaughter', K'ORDERS_SLAUGHTER' },
			{ 'standing_orders_auto_butcher', 'Auto butcher', K'ORDERS_BUTCHER' },
			{ 'standing_orders_auto_fishery', 'Auto fishery', K'ORDERS_AUTO_FISHERY' },
			{ 'standing_orders_auto_kitchen', 'Auto kitchen', K'ORDERS_AUTO_KITCHEN' },
			{ 'standing_orders_auto_tan', 'Auto tan', K'ORDERS_TAN' },
		}, df.ui_sidebar_mode.OrdersWorkshop
	},

	{
		'', {
			{
				'standing_orders_auto_loom', {
					'No auto loom',
					'Auto loom dyed thread',
					'Auto loom all thread',
				}, 'ORDERS_LOOM'
			},
		}, df.ui_sidebar_mode.OrdersWorkshop
	},

	{
		'', {
			{ 'standing_orders_use_dyed_cloth', 'Use dyed cloth only', K'ORDERS_DYED_CLOTH' },
		}, df.ui_sidebar_mode.OrdersWorkshop
	},

	{
		'Activity Zone Orders', {
			{ 'standing_orders_zoneonly_drink', 'Zone-only drinking', K'ORDERS_ZONE_DRINKING' },
			{ 'standing_orders_zoneonly_fish', 'Zone-only fishing', K'ORDERS_ZONE_FISHING' },
		}, df.ui_sidebar_mode.OrdersZone
	}
}

--todo: order globals are now available on all platforms, use them

local function parse_orders_main(t, ret)
    ret['standing_orders_job_cancel_announce'] = t(0, 12, 's') and 1 or t(0, 12, 'm') and 2 or t(0, 12, 'a') and 3 or 0

	ret['standing_orders_gather_animals'] = t(1, 11, 'G')
	ret['standing_orders_gather_food'] = t(2, 11, 'G')
	ret['standing_orders_gather_furniture'] = t(3, 11, 'G')
	ret['standing_orders_gather_bodies'] = t(4, 11, 'G')
	
	ret['standing_orders_gather_minerals'] = t(6, 11, 'G')
	ret['standing_orders_gather_wood'] = t(7, 11, 'G')
	ret['standing_orders_farmer_harvest'] = t(8, 3, 'O')
    ret['standing_orders_mix_food'] = t(9, 3, 'M')
end

local function parse_orders_forbid(t, ret)
    ret['standing_orders_forbid_used_ammo'] = t(0, 3, 'F')
	ret['standing_orders_forbid_own_dead'] = t(1, 3, 'F')
	ret['standing_orders_forbid_own_dead_items'] = t(2, 3, 'F')
	ret['standing_orders_forbid_other_nohunt'] = t(3, 3, 'F')
	ret['standing_orders_forbid_other_dead_items'] = t(4, 3, 'F')
end

local function parse_orders_refuse(t, ret, ws)
	local s1 = false
	local s2 = false

	ret['standing_orders_gather_refuse'] = t(0, 11, 'G')
	if ws and not ret['standing_orders_gather_refuse'] then --as:ws=df.viewscreen
		gui.simulateInput(ws, K'ORDERS_REFUSE_GATHER')
		ws:render()
		s1 = true
	end

	ret['standing_orders_gather_refuse_outside'] = t(1, 11, 'G')
	if ws and not ret['standing_orders_gather_refuse_outside'] then --as:ws=df.viewscreen
		gui.simulateInput(ws, K'ORDERS_REFUSE_OUTSIDE')
		ws:render()
		s2 = true
	end

	local dy = 1 --ret['standing_orders_gather_refuse_outside'] and 1 or 0

	ret['standing_orders_gather_vermin_remains'] = t(3, 5, 'G')
	ret['standing_orders_dump_corpses'] = t(3+dy, 11, 'D')
	ret['standing_orders_dump_skulls'] = t(4+dy, 11, 'D')
	ret['standing_orders_dump_bones'] = t(5+dy, 11, 'D')
	ret['standing_orders_dump_shells'] = t(6+dy, 11, 'D')
	ret['standing_orders_dump_skins'] = t(7+dy, 11, 'D')
	ret['standing_orders_dump_hair'] = t(8+dy, 11, 'D')
	ret['standing_orders_dump_other'] = t(9+dy, 11, 'D')

	if s2 then
		gui.simulateInput(ws, K'ORDERS_REFUSE_OUTSIDE')
	end
	if s1 then
		gui.simulateInput(ws, K'ORDERS_REFUSE_GATHER')
	end
end

local function parse_orders_workshop(t, ret)
	ret['standing_orders_auto_loom'] = t(0, 13, 'A') and 2 or (t(0, 13, 'D') and 1 or 0)
	ret['standing_orders_use_dyed_cloth'] = t(1, 7, 'D')
	ret['standing_orders_auto_collect_webs'] = t(2, 3, 'A')
	ret['standing_orders_auto_slaughter'] = t(3, 3, 'A')
	ret['standing_orders_auto_butcher'] = t(4, 3, 'A')
	ret['standing_orders_auto_fishery'] = t(5, 3, 'A')
	ret['standing_orders_auto_kitchen'] = t(6, 3, 'A')
	ret['standing_orders_auto_tan'] = t(7, 3, 'A')	
end

local function parse_orders_zone(t, ret)
	ret['standing_orders_zoneonly_drink'] = t(0, 3, 'Z')
	ret['standing_orders_zoneonly_fish'] = t(1, 3, 'Z')
end

local function simulate_orders_globals()
	return execute_with_main_mode(df.ui_sidebar_mode.Orders, function(ws)
        ws:render()

        local x = df.global.gps.dimx - 2 - 30 + 1
        if C_ui_menu_width() == 1 or C_ui_area_map_width() == 2 then
            x = x - (23 + 1)
        end
        x = x + 1

        local y = 5
        local x2 = x + 3

        local function t(row, dx, ch)
        	local offset = ((x+dx)*df.global.gps.dimy+(y+row))*4
        	if offset < 0 then
        		error('screen offset < 0 ('..
                    ' dims ' .. tostring(df.global.gps.dimx) .. ' ' .. tostring(df.global.gps.dimy) ..
                    ' dims ' .. tostring(df.global.init.display.grid_x) .. ' ' .. tostring(df.global.init.display.grid_y) .. ')')
    		end
        	return string.char(df.global.gps.screen[offset]) == ch
        end

        local ret = {}
        parse_orders_main(t, ret)

        df.global.ui.main.mode = df.ui_sidebar_mode.OrdersForbid
        ws:render()
        parse_orders_forbid(t, ret)

        df.global.ui.main.mode = df.ui_sidebar_mode.OrdersRefuse
        ws:render()
        parse_orders_refuse(t, ret, ws)

		df.global.ui.main.mode = df.ui_sidebar_mode.OrdersWorkshop
		ws:render()
		parse_orders_workshop(t, ret)

		df.global.ui.main.mode = df.ui_sidebar_mode.OrdersZone
		ws:render()
		parse_orders_zone(t, ret)

        return ret
	end)	
end

--luacheck: in=
function orders_get()
	--local check = df.global.standing_orders_gather_animals
	local globals = simulate_orders_globals()

	local ret = {}

	for i,g in ipairs(orders) do
		local grp = {}
		for j,v in ipairs(g[2]) do
			local title = v[2]
			local field = v[1]
			local val = globals[field] or false --todo: -1 and disable in-app (?)

			table.insert(grp, { title, val })
		end

		table.insert(ret, { g[1], grp })
	end

	return ret
end

--luacheck: in=number,number,bool
function orders_set(section, idx, val)
	section = section + 1
	idx = idx + 1

	local order = orders[section][2][idx]
	local gname = order[1]
	local mode = orders[section][3]

	if type (order[2]) == 'string' then
		val = istrue(val)
	end

	return execute_with_main_mode(mode, function(ws)
        local x = df.global.gps.dimx - 2 - 30 + 1
        if C_ui_menu_width() == 1 or C_ui_area_map_width() == 2 then
            x = x - (23 + 1)
        end
        x = x + 1

        local y = 5
        local x2 = x + 3

        local function t(row, dx, ch)
        	return string.char(df.global.gps.screen[((x+dx)*df.global.gps.dimy+(y+row))*4]) == ch
        end

		local s1 = false
		local s2 = false
        if mode == df.ui_sidebar_mode.OrdersRefuse then
        	ws:render()
	        local globals = {}        	
    		parse_orders_refuse(t, globals, ws)
			if idx ~= 1 and not globals['standing_orders_gather_refuse'] then
				gui.simulateInput(ws, K'ORDERS_REFUSE_GATHER')
				s1 = true
			end

			if idx ~= 2 and not globals['standing_orders_gather_refuse_outside'] then
				gui.simulateInput(ws, K'ORDERS_REFUSE_OUTSIDE')
				s2 = true
			end    		
    	end

        local prev = nil
        while true do
	        ws:render()
	        local globals = {}
	        if mode == df.ui_sidebar_mode.Orders then
	        	parse_orders_main(t, globals)
	    	elseif mode == df.ui_sidebar_mode.OrdersRefuse then
	    		parse_orders_refuse(t, globals)
	    	elseif mode == df.ui_sidebar_mode.OrdersForbid then
	    		parse_orders_forbid(t, globals)
	    	elseif mode == df.ui_sidebar_mode.OrdersWorkshop then
	    		parse_orders_workshop(t, globals)
	    	elseif mode == df.ui_sidebar_mode.OrdersZone then
	    		parse_orders_zone(t, globals)
	    	end

        	if globals[gname] == val or prev == globals[gname] then
        		break
        	end
	    	
	    	prev = globals[gname]
	    	gui.simulateInput(ws, order[3])
	    end

		if s2 then
			gui.simulateInput(ws, K'ORDERS_REFUSE_OUTSIDE')
		end
		if s1 then
			gui.simulateInput(ws, K'ORDERS_REFUSE_GATHER')
		end

	    return true
    end)	
end

--print(pcall(function() return json:encode(orders_get()) end))
--print(pcall(function() return json:encode(orders_set(7,0,1)) end))