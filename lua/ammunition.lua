function ammunition_get_list()
	local ret = {}

	local function process_specs(specs)
		local ammolist = {}

		for i,ammo in ipairs(specs) do
			local f = ammo.item_filter
			local title = generic_item_name(f.item_type, f.item_subtype, f.material_class, f.mattype, f.matindex)
			table.insert(ammolist, { title, ammo.amount, ammo.flags.whole })
		end

		return ammolist		
	end

	table.insert(ret, { 'Hunters', -1, process_specs(df.global.ui.equipment.hunter_ammunition) })

	for i,squad in ipairs(find_fortress_squads()) do
		local sqname = squadname(squad)
		local ammolist = process_specs(squad.ammunition)

		table.insert(ret, { sqname, squad.id, ammolist })
	end

	return ret
end

function ammunition_get_list_short()
	local ret = {}

	table.insert(ret, { 'Hunters', -1, #df.global.ui.equipment.hunter_ammunition })

	for i,squad in ipairs(find_fortress_squads()) do
		local sqname = squadname(squad)

		table.insert(ret, { sqname, squad.id, #squad.ammunition })
	end

	return ret
end

function ammunition_get_squad(id)
	local function process_specs(specs)
		local ammolist = {}

		for i,ammo in ipairs(specs) do
			local f = ammo.item_filter
			local title = generic_item_name(f.item_type, f.item_subtype, f.material_class, f.mattype, f.matindex)
			table.insert(ammolist, { title, ammo.amount, ammo.flags.whole })
		end

		return ammolist		
	end

	if id == -1 then
		return process_specs(df.global.ui.equipment.hunter_ammunition)
	end

	local squad = df.squad.find(id)
	if not squad then
		return
	end

	return process_specs(squad.ammunition)
end

--todo: can do this directly, without employing UI
function ammunition_get_additem()
    return execute_with_military_screen(function(ws)
        gui.simulateInput(ws, 'D_MILITARY_AMMUNITION')
        gui.simulateInput(ws, 'D_MILITARY_AMMUNITION_ADD_ITEM')
        gui.simulateInput(ws, 'SELECT')
        gui.simulateInput(ws, 'D_MILITARY_AMMUNITION_MATERIAL')
        gui.simulateInput(ws, 'LEAVESCREEN')
        gui.simulateInput(ws, 'D_MILITARY_AMMUNITION_REMOVE_ITEM')

        local items = {}
        for i,v in ipairs(ws.ammo.add_item.type) do
        	local type = v
        	local subtype = ws.ammo.add_item.subtype[i]
        	local title = generic_item_name(type, subtype, -1, -1, -1)
        	
        	table.insert(items, { title, { type, subtype }, ws.ammo.add_item.foreign[i] })
        end

        --xxx: return only material classes and inorganics, skipping numerous types of wood and bone
        local mats = {}
        for i,v in ipairs(ws.ammo.material.specific.mat_type) do
        	if v == -1 then
        		local matclass = ws.ammo.material.generic[i]
        		local title = mat_category_names[matclass]
        		if title then
	        		table.insert(mats, { title, { matclass, -1, -1 } })
	        	end

	        elseif v == 0 then
	        	local matindex = ws.ammo.material.specific.mat_index[i]
	        	local mi = dfhack.matinfo.decode(v, matindex)
	        	if mi then
	        		local title = mi.material.state_name.Solid
	        		table.insert(mats, { title, { -1, v, matindex } })
	        	end
	        else
	        	break
        	end
        end

        return { items, mats }
    end)
end

function ammunition_item_add(squadid, itemspec, matspec)
	local specs

	if squadid == -1 then
		specs = df.global.ui.equipment.hunter_ammunition
	else
		local squad = df.squad.find(squadid)
		if not squad then
			return
		end

		specs = squad.ammunition
	end

	local record = df.squad_ammo_spec:new()

	local f = record.item_filter
	f.item_type = itemspec[1]
	f.item_subtype = itemspec[2]
	f.material_class = matspec[1]
	if f.material_class == -1 then
		f.mattype = matspec[2]
		f.matindex = matspec[3]
	else
		f.mattype = -1
		f.matindex = -1
	end

	record.amount = 100
	record.flags.use_combat = true
	record.flags.use_training = true

	specs:insert(#specs, record)

	df.global.ui.equipment.update.ammo = true
	--todo: this could return the new item, so that app doesn't need to reload
end

--todo: maybe do this directly, without employing UI, just don't forget to set df.global.ui.equipment.update.ammo
function ammunition_item_remove(squadid, idx)
    execute_with_military_screen(function(ws)
        gui.simulateInput(ws, 'D_MILITARY_AMMUNITION')

        for i,v in ipairs(ws.ammo.squads) do
        	if (not v and squadid == -1) or (v and v.id == squadid) then
        		if i > 0 then
        			if idx < 0 or idx >= #v.ammunition then
        				return
        			end
			        ws.layer_objects[0].cursor = i - 1
			        gui.simulateInput(ws, 'STANDARDSCROLL_DOWN')
			    else
        			if idx < 0 or idx >= #df.global.ui.equipment.hunter_ammunition then
        				return
        			end
			    end

				ws.layer_objects[0].active = false
				ws.layer_objects[1].active = true
		        ws.layer_objects[1].cursor = idx
		        gui.simulateInput(ws, 'D_MILITARY_AMMUNITION_REMOVE_ITEM')

		        break
        	end
        end
    end)	
end

function ammunition_get_assigned(squadid, idx)
	local spec
	local obj

	if squadid == -1 then
		spec = df.global.ui.equipment.hunter_ammunition[idx]
		obj = df.global.ui.equipment
	else
		local squad = df.squad.find(squadid)
		if not squad then
			return
		end

		spec = squad.ammunition[idx]
		obj = squad
	end

	local ret = {}

	for i,v in ipairs(spec.assigned) do
		local item = df.item.find(v)
		if item then
			local name = itemname(item, 3, true)
			local in_use = utils.binsearch(obj.ammo_items, v) ~= nil

			table.insert(ret, { name, in_use })
		end
	end

	return ret
end

function ammunition_set_amount(squadid, idx, amount)
	local spec

	if squadid == -1 then
		spec = df.global.ui.equipment.hunter_ammunition[idx]
	else
		local squad = df.squad.find(squadid)
		if not squad then
			return
		end

		spec = squad.ammunition[idx]
	end

	spec.amount = amount

	df.global.ui.equipment.update.ammo = true
	return true
end

function ammunition_set_flags(squadid, idx, flags)
	local spec

	if squadid == -1 then
		spec = df.global.ui.equipment.hunter_ammunition[idx]
	else
		local squad = df.squad.find(squadid)
		if not squad then
			return
		end

		spec = squad.ammunition[idx]
	end

	spec.flags.whole = flags

	df.global.ui.equipment.update.ammo = true
	return true
end

--print(pcall(function() return json:encode(ammunition_get_additem()) end))
--print(pcall(function() return json:encode(ammunition_item_add(140, { 38,0 }, { 14,-1,-1 })) end))
--print(pcall(function() return json:encode(ammunition_item_remove(-1,1)) end))
--print(pcall(function() return json:encode(ammunition_get()) end))
--print(pcall(function() return json:encode(ammunition_get_assigned(140,2)) end))