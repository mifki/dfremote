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
			{ 'standing_orders_farmer_harvest', 'Everybody (not only farmers) harvest', K'ORDERS_ALL_HARVEST' },
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

--luacheck: in=
function orders_get()
	local globals = df.global

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

--todo: can we just set global values without ui?
--luacheck: in=number,number,bool
function orders_set(section, idx, val)
	section = section + 1
	idx = idx + 1

	local order = orders[section][2][idx]
	local gname = order[1]
	local mode = orders[section][3]
	local key = order[3]

	-- if type (order[2]) == 'string' then
	-- 	val = istrue(val)
	-- end

	return execute_with_main_mode(mode, function(ws)
		local globals = df.global
		local s1 = false
		local s2 = false
    
    	--xxx: the app allows to set refuse flags even if the main "gather refuse" is unset
    	--xxx: in that case, temporarily enable/show refuse options
        if mode == df.ui_sidebar_mode.OrdersRefuse then
			if idx ~= 1 and not istrue(globals[orders[section][2][1][1]]) then
				gui.simulateInput(ws, orders[section][2][1][3])
				s1 = true
			end

			if idx ~= 2 and not istrue(globals[orders[section][2][2][1]]) then
				gui.simulateInput(ws, orders[section][2][2][3])
				s2 = true
			end    		
    	end

        local prev = nil
        while true do
        	if globals[gname] == val or prev == globals[gname] then
        		break
        	end
	    	
	    	prev = globals[gname]
	    	gui.simulateInput(ws, key)
	    	print (val,globals[gname])
	    end

	    --xxx: now disable/hide the refuse options temporarily shown above
		if s2 then
			gui.simulateInput(ws, orders[section][2][2][3])
		end
		if s1 then
			gui.simulateInput(ws, orders[section][2][1][3])
		end

	    return true
    end)	
end

--print(pcall(function() return json:encode(orders_get()) end))
--print(pcall(function() return json:encode(orders_set(7,0,1)) end))