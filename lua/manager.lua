--todo: convert to use order id instead of idx

function order_find_by_id(id)
    for i,v in ipairs(df.global.world.manager_orders) do
        if v.id == id then
            return v, i
        end
    end

    return nil
end

function ordertitle(o, with_amount)
	local btn = df.interface_button_building_new_jobst:new()
	
	btn.reaction_name = o.reaction_name
	btn.hist_figure_id = o.hist_figure_id
	btn.job_type = o.job_type
	btn.item_type = o.item_type
	btn.item_subtype = o.item_subtype
	btn.mat_type = o.mat_type
	btn.mat_index = o.mat_index
	btn.item_category.whole = o.item_category.whole
	btn.material_category.whole = o.material_category.whole
	
	local title = dfhack.df2utf(utils.call_with_string(btn, 'getLabel'))
	df.delete(btn)

	if with_amount then
		title = title .. ' (' .. tostring(o.amount_total) .. ')'
	end

	return title
end

--luacheck: in=
function manager_get_orders()
    local have_manager = have_noble('MANAGER')

	local orders = {}

	for i,o in ipairs(df.global.world.manager_orders) do
		local title = ordertitle(o)
		table.insert(orders, { title, o.amount_left, o.amount_total, o.status.whole, o.max_workshops, #o.item_conditions+#o.order_conditions })
	end

	return { orders, have_manager }
end

--luacheck: in=
function manager_get_orders2()
    local have_manager = have_noble('MANAGER')

	local orders = {}

	for i,o in ipairs(df.global.world.manager_orders) do
		local title = ordertitle(o)
		table.insert(orders, { title, o.id, o.amount_left, o.amount_total, o.status.whole, o.max_workshops, #o.item_conditions+#o.order_conditions })
	end

	return { orders, have_manager }
end

local order_templates = nil
local order_template_names = nil

local function populate_order_templates()
	execute_with_manager_orders_screen(function(ws)
		order_templates = {}
		order_template_names = {}

		for i,o in ipairs(ws.orders) do
			local btn = df.interface_button_building_new_jobst:new()
			btn.reaction_name = o.reaction_name
			btn.hist_figure_id = o.hist_figure_id
			btn.job_type = o.job_type
			btn.item_type = o.item_type
			btn.item_subtype = o.item_subtype
			btn.mat_type = o.mat_type
			btn.mat_index = o.mat_index
			btn.item_category.whole = o.item_category.whole
			btn.material_category.whole = o.material_category.whole
			table.insert(order_template_names, dfhack.df2utf(utils.call_with_string(btn, 'getLabel')))

			local ot = {} --as:{reaction_name:string,hist_figure_id:number,job_type:'df.job_type',item_type:'df.item_type',item_subtype:number,mat_type:number,mat_index:number,item_category_whole:number,material_category_whole:number}
			ot.reaction_name = o.reaction_name
			ot.hist_figure_id = o.hist_figure_id
			ot.job_type = o.job_type
			ot.item_type = o.item_type
			ot.item_subtype = o.item_subtype
			ot.mat_type = o.mat_type
			ot.mat_index = o.mat_index
			ot.item_category_whole = o.item_category.whole
			ot.material_category_whole = o.material_category.whole
			table.insert(order_templates, ot)
		end
	end)
end

--luacheck: in=number
function manager_get_ordertemplates(fromidx) 
	if not order_templates or #order_templates == nil or fromidx == 0 then
		populate_order_templates()
	end

	local ret = {}
	for i=fromidx+1,fromidx+300 do
		table.insert(ret, order_template_names[i])
	end
	return { ret, fromidx+300 < #order_template_names }
end

--luacheck: in=number,number
function manager_new_order(idx, amount)
	--xxx: this temporary fixes the bug in the app where templates are not reloaded when connected to another server
	if not order_templates or #order_templates == nil then
		populate_order_templates()
	end

	local ot = order_templates[idx + 1] --as:{reaction_name:string,hist_figure_id:number,job_type:'df.job_type',item_type:'df.item_type',item_subtype:number,mat_type:number,mat_index:number,item_category_whole:number,material_category_whole:number}
	local o = df.manager_order:new()

	o.id = df.global.world.manager_order_next_id
	df.global.world.manager_order_next_id = df.global.world.manager_order_next_id + 1

	o.reaction_name = ot.reaction_name
	o.hist_figure_id = ot.hist_figure_id
	o.job_type = ot.job_type
	o.item_type = ot.item_type
	o.item_subtype = ot.item_subtype
	o.mat_type = ot.mat_type
	o.mat_index = ot.mat_index
	o.item_category.whole = ot.item_category_whole
	o.material_category.whole = ot.material_category_whole
	o.amount_left = amount
	o.amount_total = amount

	df.global.world.manager_orders:insert(#df.global.world.manager_orders, o)
	df.global.ui.manager_cooldown = 0
end

--luacheck: in=number
function manager_delete_order(idx)
	df.global.world.manager_orders:erase(idx)
end

--luacheck: in=numeber,number
function manager_reorder(fromidx, toidx)
    local o = df.global.world.manager_orders[fromidx]
    df.global.world.manager_orders:erase(fromidx)
    df.global.world.manager_orders:insert(toidx, o)
end

--luacheck: in=number,number
function manager_order_set_max_workshops(idx, maxw)
	maxw = math.max(0, maxw)

    local o = df.global.world.manager_orders[idx]
    o.max_workshops = maxw
end


--luacheck: in=number
function manager_order_conditions_get(id)
    local order,idx = order_find_by_id(id)
    if not order then
        error('no order '..tostring(id))
    end

	return execute_with_order_conditions(idx, function(ws)
	    local conditions = {}

	    for i,v in ipairs(order.item_conditions) do
		    local q = df.reaction_product_itemst:new()

		    q.item_type = v.item_type
		    q.item_subtype = v.item_subtype
		    	    
		    local itemname = utils.call_with_string(q, 'getDescription')
		    q:delete()

		    itemname = itemname:sub(1, itemname:find(' %(')-1)
	    	itemname = itemname:lower()
		    itemname = dfhack.df2utf(itemname)

		    local matname = mp.NIL
	    	local mi = dfhack.matinfo.decode(v.mat_type, v.mat_index)
	        if mi then
	            local mat = mi.material
	            matname = dfhack.df2utf((#mat.prefix>0 and (mat.prefix .. ' ') or '') .. mat.state_name[0])
	        end

	    	table.insert(conditions, { 0, ws.satisfied[i], itemname, matname, v.compare_type, v.compare_val })
	    end

	    for i,v in ipairs(order.order_conditions) do
	    	local target = order_find_by_id(v.order_id)
	    	local s = target and ordertitle(target, true) or '#invalid order#'
	    	table.insert(conditions, { 1, ws.anon_1[i], s, v.condition })
	    end

	    return { ordertitle(order, true), order.id, conditions, order.frequency }
	end)
end

--luacheck: in=
function manager_order_condition_get_item_choices()
	local q = df.viewscreen_workquota_conditionst:new()
	local o = df.manager_order:new()

	q.order = o

	local ret = {}

	gui.simulateInput(q, K'WORK_ORDER_CONDITION_ADD_ITEM')
	gui.simulateInput(q, K'WORK_ORDER_CONDITION_ITEM_TYPE')

	for i,v in ipairs(q.list_entries) do
		-- local item_type = C_viewscreen_workquota_conditionst_item_type(q,i)
		-- local item_subtype = C_viewscreen_workquota_conditionst_item_subtype(q,i)

		table.insert(ret, { dfhack.df2utf(v.value), i })
	end

	--todo: ideally catch errors and always delete
	q:delete()
	o:delete()

	return ret
end

--luacheck: in=
function manager_order_condition_get_material_choices()
	local q = df.viewscreen_workquota_conditionst:new()
	local o = df.manager_order:new()

	q.order = o

	local ret = {}

	gui.simulateInput(q, K'WORK_ORDER_CONDITION_ADD_ITEM')
	gui.simulateInput(q, K'WORK_ORDER_CONDITION_ITEM_MATERIAL')

	for i,v in ipairs(q.list_entries) do
		-- local mat_type = q.list_unk1[i]
		-- local mat_index = q.list_unk2[i]

		table.insert(ret, { dfhack.df2utf(v.value), i })
	end

	--todo: ideally catch errors and always delete
	q:delete()
	o:delete()

	return ret
end

--luacheck: in=
function manager_order_condition_get_trait_choices()
	local q = df.viewscreen_workquota_conditionst:new()
	local o = df.manager_order:new()

	q.order = o

	local ret = {}

	gui.simulateInput(q, K'WORK_ORDER_CONDITION_ADD_ITEM')
	gui.simulateInput(q, K'WORK_ORDER_CONDITION_ITEM_TRAITS')

	for i,v in ipairs(q.traits) do
		table.insert(ret, { dfhack.df2utf(v.name), i })
	end

	--todo: ideally catch errors and always delete
	q:delete()
	o:delete()

	return ret
end

--luacheck: in=number,number,number
function manager_order_condition_set_item(id, condidx, choiceidx)
    local order = order_find_by_id(id)
    if not order then
        error('no order '..tostring(id))
    end

	local q = df.viewscreen_workquota_conditionst:new()
	q.order = order

	q.cond_idx = condidx
	gui.simulateInput(q, K'WORK_ORDER_CONDITION_ITEM_TYPE')
	
	q.list_idx = choiceidx
	gui.simulateInput(q, K'SELECT')

	--todo: ideally catch errors and always delete
	q:delete()

	return true
end

--luacheck: in=number,number,number
function manager_order_condition_set_material(id, condidx, choiceidx)
    local order = order_find_by_id(id)
    if not order then
        error('no order '..tostring(id))
    end

	local q = df.viewscreen_workquota_conditionst:new()
	q.order = order

	q.cond_idx = condidx
	gui.simulateInput(q, K'WORK_ORDER_CONDITION_ITEM_MATERIAL')

	q.list_idx = choiceidx
	gui.simulateInput(q, K'SELECT')

	--todo: ideally catch errors and always delete
	q:delete()

	return true
end

--luacheck: in=number,number,number[]
function manager_order_condition_set_traits(id, condidx, choiceidxs)
    local order = order_find_by_id(id)
    if not order then
        error('no order '..tostring(id))
    end

	local q = df.viewscreen_workquota_conditionst:new()
	q.order = order

	q.cond_idx = condidx
	gui.simulateInput(q, K'WORK_ORDER_CONDITION_ITEM_TRAITS')

	-- reset all traits first because we can only toggle
	order.item_conditions[condidx].flags1.whole = 0
	order.item_conditions[condidx].flags2.whole = 0
	order.item_conditions[condidx].flags3.whole = 0
	order.item_conditions[condidx].flags4 = 0
	order.item_conditions[condidx].flags5 = 0
	order.item_conditions[condidx].reaction_class = ''
	order.item_conditions[condidx].has_material_reaction_product = ''
	order.item_conditions[condidx].inorganic_bearing = -1
	order.item_conditions[condidx].has_tool_use = df.tool_uses.NONE

	--todo: .anon_1, .anon_2, .anon_3 ?

	for i,v in ipairs(choiceidxs) do
		q.list_idx = v
		gui.simulateInput(q, K'SELECT')
	end

	--todo: ideally catch errors and always delete
	q:delete()

	return true
end

--luacheck: in=number,number,number
function manager_order_conditions_set_frequency(id, freq)
    local order,idx = order_find_by_id(id)
    if not order then
        error('no order '..tostring(id))
    end

	order.frequency = freq
end

--luacheck: in=number,number,number,number
function manager_order_condition_set_compare(id, condidx, compare_type, compare_val)
    local order = order_find_by_id(id)
    if not order then
        error('no order '..tostring(id))
    end

    local cond = order.item_conditions[condidx]
    
    cond.compare_type = compare_type
    cond.compare_val = compare_val

	return true
end

--luacheck: in=number
function manager_order_condition_get_order_choices(id)
    local order = order_find_by_id(id)
    if not order then
        error('no order '..tostring(id))
    end

	local ret = {}

	for i,o in ipairs(df.global.world.manager_orders) do
		local found = false
		for j,v in ipairs(order.order_conditions) do
			if v.order_id == o.id then
				found = true
				break
			end
		end

		if o ~= order and not found then
			local title = ordertitle(o, true)
			table.insert(ret, { title, o.id })
		end
	end

	return ret
end

--luacheck: in=number,number
function manager_order_conditions_add_order(id, anotherid)
    local order = order_find_by_id(id)
    if not order then
        error('no order '..tostring(id))
    end

    local cond = df.manager_order_condition_order:new()
    cond.order_id = anotherid
    cond.condition = df.manager_order_condition_order.T_condition.Completed

    order.order_conditions:insert('#', cond)

    return true
end

--luacheck: in=number,number
function manager_order_conditions_add_item(id, itemidx)
    local order = order_find_by_id(id)
    if not order then
        error('no order '..tostring(id))
    end

	local q = df.viewscreen_workquota_conditionst:new()
	q.order = order

	gui.simulateInput(q, K'WORK_ORDER_CONDITION_ADD_ITEM')
	q.cond_idx = #order.item_conditions - 1

	gui.simulateInput(q, K'WORK_ORDER_CONDITION_ITEM_TYPE')
	q.list_idx = itemidx
	gui.simulateInput(q, K'SELECT')

	--todo: ideally catch errors and always delete
	q:delete()

    return true
end

--luacheck: in=number
function manager_order_conditions_add_reagents(id)
    local order = order_find_by_id(id)
    if not order then
        error('no order '..tostring(id))
    end

	local q = df.viewscreen_workquota_conditionst:new()
	q.order = order

	gui.simulateInput(q, K'WORK_ORDER_CONDITION_REAGENTS')

	--todo: ideally catch errors and always delete
	q:delete()

    return true
end

--luacheck: in=number
function manager_order_conditions_add_products(id)
    local order = order_find_by_id(id)
    if not order then
        error('no order '..tostring(id))
    end

	local q = df.viewscreen_workquota_conditionst:new()
	q.order = order

	gui.simulateInput(q, K'WORK_ORDER_CONDITION_PRODUCTS')

	--todo: ideally catch errors and always delete
	q:delete()

    return true
end

--luacheck: in=number,number
function manager_order_conditions_delete(id, condidx)
    local order = order_find_by_id(id)
    if not order then
        error('no order '..tostring(id))
    end

	local q = df.viewscreen_workquota_conditionst:new()
	q.order = order
	q.cond_idx = condidx

	gui.simulateInput(q, K'WORK_ORDER_CONDITION_DELETE')

	--todo: ideally catch errors and always delete
	q:delete()

	return true
end

-- print(pcall(function() return json:encode(manager_order_conditions_get(0)) end))
-- print(pcall(function() return json:encode(manager_order_condition_get_item_choices()) end))
-- print(pcall(function() return json:encode(manager_order_condition_get_material_choices()) end))
-- print(pcall(function() return json:encode(manager_order_condition_get_trait_choices()) end))
-- print(pcall(function() return json:encode(manager_order_condition_set_item(0,1,10)) end))
-- print(pcall(function() return json:encode(manager_order_condition_set_material(0,1,10)) end))
-- print(pcall(function() return json:encode(manager_order_condition_set_traits(0,0,{2,4,6})) end))
-- print(pcall(function() return json:encode(manager_order_conditions_set_frequency(0,2)) end))
-- print(pcall(function() return json:encode(manager_order_condition_set_compare(0,1,1,13)) end))
-- print(pcall(function() return json:encode(manager_order_condition_get_order_choices(0)) end))
