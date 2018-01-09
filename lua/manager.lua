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
function order_conditions_get(id)
    local order = order_find_by_id(id)
    if not order then
        error('no order '..tostring(id))
    end

    local conditions = {}

    for i,v in ipairs(order.item_conditions) do
    	--local itemname = generic_item_name(v.item_type, v.item_subtype, -1, -1, -1, false)
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

    	table.insert(conditions, { 0, false, itemname, matname, v.compare_type, v.compare_val })
    end

    for i,v in ipairs(order.order_conditions) do
    	local target = order_find_by_id(v.order_id)
    	local s = target and ordertitle(target, true) or '#invalid order#'
    	table.insert(conditions, { 1, false, s, v.condition })
    end

    --todo: frequency, etc.
    return { ordertitle(order), order.id, conditions }
end

print(pcall(function() return json:encode(order_conditions_get(14)) end))
