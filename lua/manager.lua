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

local job_item_flag_titles1 = {
	[df.job_item_flags1.improvable] = 'improvable',
	[df.job_item_flags1.butcherable] = 'butcherable',
	[df.job_item_flags1.millable] = 'millable',
	[df.job_item_flags1.allow_buryable] = 'possible buriable',
	[df.job_item_flags1.unrotten] = 'unrotten',
	[df.job_item_flags1.undisturbed] = 'undisturbed',
	[df.job_item_flags1.collected] = 'collected',
	[df.job_item_flags1.sharpenable] = 'sharpenable',
	[df.job_item_flags1.murdered] = 'murdered',
	[df.job_item_flags1.distillable] = 'distillable',
	[df.job_item_flags1.empty] = 'empty',
	[df.job_item_flags1.processable] = 'processable',
	[df.job_item_flags1.bag] = 'bag',
	[df.job_item_flags1.cookable] = 'cookable',
	[df.job_item_flags1.extract_bearing_plant] = 'extract-bearing plant',
	[df.job_item_flags1.extract_bearing_fish] = 'extract-bearing fish',
	[df.job_item_flags1.extract_bearing_vermin] = 'extract-bearing small creature',
	[df.job_item_flags1.processable_to_vial] = 'processable (to vial)',
	[df.job_item_flags1.processable_to_bag] = 'processable (to bag)',
	[df.job_item_flags1.processable_to_barrel] = 'processable (to barrel)',
	[df.job_item_flags1.solid] = 'solid',
	[df.job_item_flags1.tameable_vermin] = 'tameable small creature',
	[df.job_item_flags1.nearby] = 'nearby',
	[df.job_item_flags1.sand_bearing] = 'sand-bearing',
	[df.job_item_flags1.glass] = 'glass',
	[df.job_item_flags1.milk] = 'milk',
	[df.job_item_flags1.milkable] = 'milkable',
	[df.job_item_flags1.finished_goods] = 'finished good',
	[df.job_item_flags1.ammo] = 'ammo',
	[df.job_item_flags1.furniture] = 'furniture',
	--[df.job_item_flags1.not_bin] = ''
	[df.job_item_flags1.lye_bearing] = 'lye-bearing',
}

local job_item_flag_titles2 = {
	[df.job_item_flags2.dye] = 'dye',
	[df.job_item_flags2.dyeable] = 'dyeable',
	[df.job_item_flags2.dyed] = 'dyed',
	[df.job_item_flags2.sewn_imageless] = 'sewn-imageless',
	[df.job_item_flags2.glass_making] = 'glass-making',
	[df.job_item_flags2.screw] = 'screw',
	[df.job_item_flags2.building_material] = 'building material',
	[df.job_item_flags2.fire_safe] = 'fire-safe',
	[df.job_item_flags2.magma_safe] = 'magma_safe',
	[df.job_item_flags2.deep_material] = 'deep material',
	[df.job_item_flags2.melt_designated] = 'melt-designated',
	[df.job_item_flags2.non_economic] = 'non-economic',
	--[df.job_item_flags2.allow_melt_dump] = 
	--[df.job_item_flags2.allow_artifact] = 
	[df.job_item_flags2.plant] = 'plant',
	[df.job_item_flags2.silk] = 'silk',
	[df.job_item_flags2.leather] = 'leather',
	[df.job_item_flags2.bone] = 'bone',
	[df.job_item_flags2.shell] = 'shell',
	[df.job_item_flags2.totemable] = 'totemable',
	[df.job_item_flags2.horn] = 'horn',
	[df.job_item_flags2.pearl] = 'pearl',
	[df.job_item_flags2.plaster_containing] = 'plaster-containing',
	--[df.job_item_flags2.anon_1] = 
	[df.job_item_flags2.soap] = 'soap',
	--[df.job_item_flags2.body_part] = 
	[df.job_item_flags2.ivory_tooth] = 'ivory/tooth',
	[df.job_item_flags2.lye_milk_free] = 'lye/milk-free',
	[df.job_item_flags2.blunt] = 'blunt',
	[df.job_item_flags2.unengraved] = 'unengraved',
	[df.job_item_flags2.hair_wool] = 'hair/wool',
	[df.job_item_flags2.yarn] = 'yarn',
} 

local job_item_flag_titles3 = {
	[df.job_item_flags3.unimproved] = 'unimproved',
	--[df.job_item_flags3.any_raw_material] = 
	[df.job_item_flags3.non_absorbent] = 'non-absorbent',
	[df.job_item_flags3.non_pressed] = 'non-pressed',
	--[df.job_item_flags3.allow_liquid_powder] = 
	--[df.job_item_flags3.any_craft] = 
	[df.job_item_flags3.hard] = 'hard',
	[df.job_item_flags3.food_storage] = 'food storage',
	[df.job_item_flags3.metal] = 'metal',
	[df.job_item_flags3.sand] = 'sand',
	--[df.job_item_flags3.anon_1] = 
	[df.job_item_flags3.written_on] = 'written-on',
	[df.job_item_flags3.edged] = 'edged',
}

local tool_use_titles = {
	[df.tool_uses.LIQUID_COOKING] = 'liquid cooking',
	[df.tool_uses.LIQUID_SCOOP] = 'liquid scoop',
	[df.tool_uses.GRIND_POWDER_RECEPTACLE] = 'poweder grinding receptacle',
	[df.tool_uses.GRIND_POWDER_GRINDER] = 'powder grinding',
	[df.tool_uses.MEAT_CARVING] = 'meat carving',
	[df.tool_uses.MEAT_BONING] = 'meat boning',
	[df.tool_uses.MEAT_SLICING] = 'meat slicing',
	[df.tool_uses.MEAT_CLEAVING] = 'meat cleaving',
	[df.tool_uses.HOLD_MEAT_FOR_CARVING] = 'meat-carving holder',
	[df.tool_uses.MEAL_CONTAINER] = 'meal container',
	[df.tool_uses.LIQUID_CONTAINER] = 'liquid container',
	[df.tool_uses.FOOD_STORAGE] = 'food storage',
	[df.tool_uses.HIVE] = 'hive',
	[df.tool_uses.NEST_BOX] = 'nest box',
	[df.tool_uses.SMALL_OBJECT_STORAGE] = 'small object container',
	[df.tool_uses.TRACK_CART] = 'track cart',
	[df.tool_uses.HEAVY_OBJECT_HAULING] = 'heavy object hauler',
	[df.tool_uses.STAND_AND_WORK_ABOVE] = 'stand-and-work',
	[df.tool_uses.ROLL_UP_SHEET] = 'sheet roller',
	[df.tool_uses.PROTECT_FOLDED_SHEETS] = 'folded sheet protector',
	[df.tool_uses.CONTAIN_WRITING] = 'writing container',
	[df.tool_uses.BOOKCASE] = 'bookcase',
}

local function get_condition_traits(cond)
	--todo: if a material is specified for the condition, conflicting traits will not be shown in game

	local ret = {}

	if cond.has_tool_use ~= df.tool_uses.NONE then
		table.insert(ret, tool_use_titles[cond.has_tool_use])

		-- if tool use is set, game shows only it and not other traits
		return ret
	end

	for i,v in pairs(job_item_flag_titles1) do
		if cond.flags1[i] then
			table.insert(ret, v)
		end
	end

	for i,v in pairs(job_item_flag_titles2) do
		if cond.flags2[i] then
			table.insert(ret, v)
		end
	end

	for i,v in pairs(job_item_flag_titles3) do
		if cond.flags3[i] then
			table.insert(ret, v)
		end
	end

	if cond.inorganic_bearing ~= -1 then
		local mi = dfhack.matinfo.decode(0, cond.inorganic_bearing)
		local t = (mi and mi.material.state_name.Solid or '#unknown mat#') .. '-bearing'

		table.insert(ret, t)
	end

	if #cond.reaction_class > 0 then
		table.insert(ret, cond.reaction_class)
	end

	if #cond.has_material_reaction_product > 0 then
		table.insert(ret, cond.has_material_reaction_product .. '-producing')
	end

	return ret
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

	        local traits = get_condition_traits(v)

	    	table.insert(conditions, { 0, ws.satisfied[i], itemname, matname, traits, v.compare_type, v.compare_val })
	    end

	    for i,v in ipairs(order.order_conditions) do
	    	local target = order_find_by_id(v.order_id)
	    	local s = target and ordertitle(target, true) or '#invalid order#'
	    	table.insert(conditions, { 1, ws.anon_1[i], s, v.condition })
	    end

	    return { ordertitle(order, true), order.id, conditions, order.frequency, order.status.whole }
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

local function is_trait_set(cond, trait)
	if trait.mat_index ~= -1 and trait.mat_index == cond.inorganic_bearing then
		return true
	end
	
	if #trait.product_desc > 0 and trait.product_desc == cond.has_material_reaction_product then
		return true
	end
	
	if #trait.item_desc > 0 and trait.item_desc == cond.reaction_class then
		return true
	end
	
	if trait.type >= 1 and trait.type <= 3 then
		return bit32.band(cond['flags'..trait.type], trait.flags.whole) ~= 0
	end

	return false
end

--luacheck: in=number
function manager_order_condition_get_trait_choices(id, condidx)
    local order = id ~= -1 and order_find_by_id(id)
    local cond = order and condidx ~= -1 and order.item_conditions[condidx]

	local q = df.viewscreen_workquota_conditionst:new()
	local o = df.manager_order:new()

	q.order = o

	local ret = {}

	gui.simulateInput(q, K'WORK_ORDER_CONDITION_ADD_ITEM')
	gui.simulateInput(q, K'WORK_ORDER_CONDITION_ITEM_TRAITS')

	for i,v in ipairs(q.traits) do
		local on = cond and is_trait_set(cond, v) or false
		table.insert(ret, { dfhack.df2utf(v.name), i, on })
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

	if #order.item_conditions + #order.order_conditions == 0 then
		order.frequency = 0
	end

	return true
end

-- print(pcall(function() return json:encode(manager_order_conditions_get(0)) end))
-- print(pcall(function() return json:encode(manager_order_condition_get_item_choices()) end))
-- print(pcall(function() return json:encode(manager_order_condition_get_material_choices()) end))
-- print(pcall(function() return json:encode(manager_order_condition_get_trait_choices(0,0)) end))
-- print(pcall(function() return json:encode(manager_order_condition_set_item(0,1,10)) end))
-- print(pcall(function() return json:encode(manager_order_condition_set_material(0,1,10)) end))
-- print(pcall(function() return json:encode(manager_order_condition_set_traits(0,0,{2,4,6})) end))
-- print(pcall(function() return json:encode(manager_order_conditions_set_frequency(0,2)) end))
-- print(pcall(function() return json:encode(manager_order_condition_set_compare(0,1,1,13)) end))
-- print(pcall(function() return json:encode(manager_order_condition_get_order_choices(0)) end))
