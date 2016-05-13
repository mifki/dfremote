function manager_get_orders()
    local have_manager = have_noble('MANAGER')

	local orders = {}

	for i,o in ipairs(df.global.world.manager_orders) do
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
		local title = utils.call_with_string(btn, 'getLabel')

		table.insert(orders, { title, o.amount_left, o.amount_total, o.is_validated })
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

			local ot = {}
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

function manager_new_order(idx, amount)
	--xxx: this temporary fixes the bug in the app where templates are not reloaded when connected to another server
	if not order_templates or #order_templates == nil then
		populate_order_templates()
	end

	local ot = order_templates[idx + 1]
	local o = df.manager_order:new()

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
end

function manager_delete_order(idx)
	df.global.world.manager_orders:erase(idx)
end

function manager_reorder(fromidx, toidx)
    local j = df.global.world.manager_orders[fromidx]
    df.global.world.manager_orders:erase(fromidx)
    df.global.world.manager_orders:insert(toidx, j)
end