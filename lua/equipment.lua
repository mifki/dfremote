local function equipment_set_update_all()
	local u = df.global.ui.equipment.update
	u.weapon   = true
	u.armor    = true
	u.shoes    = true
	u.shield   = true
	u.helm     = true
	u.gloves   = true
	u.ammo     = true
	u.pants    = true
	u.backpack = true
	u.quiver   = true
	u.flask    = true	
end

--luacheck: in=number,number
function equipment_get(squadid, unitid)
    return execute_with_military_screen(function(ws)
    	gui.simulateInput(ws, 'D_MILITARY_EQUIP')

    	local sqidx = list_select_item_by_id(ws, 0, ws.equip.squads, squadid)

        ws.layer_objects[0].active = false
        ws.layer_objects[1].active = true

        local unitidx = list_select_item_by_id(ws, 1, ws.equip.units, unitid)

        local items = {}
        for i,spec in ipairs(ws.equip.assigned.spec) do
			local f = spec.item_filter

			local type = f.item_type
			local subtype = f.item_subtype

			local mat_class = f.material_class
			local mattype = f.mattype
			local matindex = f.matindex

			local title

			if spec.item ~= -1 then
				local item = df.item.find(spec.item)
				title = item and itemname(item, 1, true) or '#unkown item#'
			elseif spec.indiv_choice.whole ~= 0 then
				if spec.indiv_choice.any then
					title = 'Weapon of choice'
				elseif spec.indiv_choice.melee then
					title = 'Melee weapon of choice'
				elseif spec.indiv_choice.ranged then
					title = 'Ranged weapon of choice'
				end

			    if mat_class ~= -1 then
			        local n = mat_category_names[mat_class]
			        if n then
			            title = capitalize(n) .. ' ' .. title:lower()
			        end
			    elseif mattype ~= -1 or matindex ~= -1 then
		        	local mi = dfhack.matinfo.decode(mattype, matindex)
		        	if mi then
			            title = capitalize(mi.material.state_name.Solid) .. ' ' .. title:lower()
		        	end
			    end

			else
				title = generic_item_name(type, subtype, mat_class, mattype, matindex)
			end        	

			local is_equipped = #spec.assigned > 0
			local can_set_material = spec.item == -1

        	table.insert(items, { title, is_equipped, can_set_material })
        end

		local uni_flags = ws.equip.squads[sqidx].positions[unitidx].flags.whole

        return { items, uni_flags }
    end)  	
end

--luacheck: in=number,number,number
function equipment_set_flags(squadid, unitid, flags)
	local squad = df.squad.find(squadid)
	if not squad then
		return
	end

	for i,pos in ipairs(squad.positions) do
		local hf = pos.occupant ~= -1 and df.historical_figure.find(pos.occupant)

		if hf and hf.unit_id == unitid then
			pos.flags.whole = flags

			equipment_set_update_all()
			break
		end
	end
end

--luacheck: in=number,number,number
function equipment_item_delete(squadid, unitid, idx)
    return execute_with_military_screen(function(ws)
    	gui.simulateInput(ws, 'D_MILITARY_EQUIP')

    	list_select_item_by_id(ws, 0, ws.equip.squads, squadid)

        ws.layer_objects[0].active = false
        ws.layer_objects[1].active = true

    	list_select_item_by_id(ws, 1, ws.equip.units, unitid)

        ws.layer_objects[1].active = false
        ws.layer_objects[2].active = true
        ws.layer_objects[2].cursor = idx --hint:df.layer_object_listst
        gui.simulateInput(ws, 'SELECT')

		return true
    end)  		
end

--luacheck: in=number,number,number
function equipment_item_get_matchoices(squadid, unitid, idx)
    return execute_with_military_screen(function(ws)
    	gui.simulateInput(ws, 'D_MILITARY_EQUIP')

    	list_select_item_by_id(ws, 0, ws.equip.squads, squadid)

        ws.layer_objects[0].active = false
        ws.layer_objects[1].active = true

    	list_select_item_by_id(ws, 1, ws.equip.units, unitid)

        ws.layer_objects[1].active = false
        ws.layer_objects[2].active = true

        if idx > 0 then
            ws.layer_objects[2].cursor = idx-1 --hint:df.layer_object_listst
            gui.simulateInput(ws, 'STANDARDSCROLL_DOWN')            
        end

        gui.simulateInput(ws, 'D_MILITARY_ADD_MATERIAL')

        local mats = {}
        for i,v in ipairs(ws.equip.material.specific.mat_type) do
        	if v == -1 then
        		local matclass = ws.equip.material.generic[i]
        		local title = mat_category_names[matclass]
        		if title then
	        		table.insert(mats, { title, { matclass, -1, -1 } })
	        	end

	        elseif v == 0 then
	        	local matindex = ws.equip.material.specific.mat_index[i]
	        	local mi = dfhack.matinfo.decode(v, matindex)
	        	if mi then
	        		local title = mi.material.state_name.Solid
	        		table.insert(mats, { title, { -1, v, matindex } })
	        	end
	        else
	        	break
        	end
        end

        return { mats }
    end)  		
end

--luacheck: in=number,number,number,number[]
function equipment_item_set_material(squadid, unitid, idx, matspec)
    return execute_with_military_screen(function(ws)
    	gui.simulateInput(ws, 'D_MILITARY_EQUIP')

    	list_select_item_by_id(ws, 0, ws.equip.squads, squadid)

        ws.layer_objects[0].active = false
        ws.layer_objects[1].active = true

    	list_select_item_by_id(ws, 1, ws.equip.units, unitid)

        local info = ws.equip.assigned.spec[idx].item_filter
		info.material_class = matspec[1]
		if info.material_class == -1 then
			info.mattype = matspec[2]
			info.matindex = matspec[3]
		else
			info.mattype = -1
			info.matindex = -1
		end        

		equipment_set_update_all()

        return true
    end)  		
end

--luacheck: in=number,number,number
function equipment_item_get_colorchoices(squadid, unitid, itemidx)
end

--luacheck: in=number,number,number,number
function equipment_item_set_color(squadid, unitid, itemidx, color)
end

--luacheck: in=number,number,number
function equipment_get_additem(squadid, unitid, cat)
    return execute_with_military_screen(function(ws)
    	gui.simulateInput(ws, 'D_MILITARY_EQUIP')

    	list_select_item_by_id(ws, 0, ws.equip.squads, squadid)

        ws.layer_objects[0].active = false
        ws.layer_objects[1].active = true

    	list_select_item_by_id(ws, 1, ws.equip.units, unitid)

        gui.simulateInput(ws, uniform_additem_keys[cat+1])

		local items = {}
        for i,v in ipairs(ws.equip.add_item.type) do
        	local type = v
        	local subtype = ws.equip.add_item.subtype[i]
            local indiv_choice = ws.equip.add_item.indiv_choice[i]

            local title

            if indiv_choice.whole ~= 0 then
                if indiv_choice.any then
                    title = 'Weapon of choice'
                elseif indiv_choice.melee then
                    title = 'Melee weapon of choice'
                elseif indiv_choice.ranged then
                    title = 'Ranged weapon of choice'
                end
            else
                title = generic_item_name(type, subtype, -1, -1, -1)
            end

			--xxx: this is handled on client side
			--[[if i == 0 then
				title = 'Specific ' .. title:lower()
			end]]
        	
        	table.insert(items, { title, i, ws.equip.add_item.foreign[i] })
        end

        return items
    end)
end

--luacheck: in=number,number,number,number
function equipment_item_add(squadid, unitid, cat, itemspec)
    return execute_with_military_screen(function(ws)
        gui.simulateInput(ws, 'D_MILITARY_EQUIP')

    	list_select_item_by_id(ws, 0, ws.equip.squads, squadid)

        ws.layer_objects[0].active = false
        ws.layer_objects[1].active = true

    	list_select_item_by_id(ws, 1, ws.equip.units, unitid)

        gui.simulateInput(ws, uniform_additem_keys[cat+1])
        ws.layer_objects[0].active = false
        ws.layer_objects[2].active = true

        if itemspec < 0 or itemspec >= #ws.equip.add_item.type then
        	return
        end

        ws.layer_objects[2].cursor = itemspec --hint:df.layer_object_listst
        gui.simulateInput(ws, 'SELECT')
        return true
    end)
end

--luacheck: in=number,number,number
function equipment_get_additem_specific(squadid, unitid, cat)
    return execute_with_military_screen(function(ws)
    	gui.simulateInput(ws, 'D_MILITARY_EQUIP')

    	list_select_item_by_id(ws, 0, ws.equip.squads, squadid)

        ws.layer_objects[0].active = false
        ws.layer_objects[1].active = true

    	list_select_item_by_id(ws, 1, ws.equip.units, unitid)

        gui.simulateInput(ws, uniform_additem_keys[cat+1])
        gui.simulateInput(ws, 'SELECT')

		local items = {}
        for i,item in ipairs(ws.equip.specific_items) do
        	local title = itemname(item, 1, true)
        	table.insert(items, { title, item.id })
        end

        return items
    end)
end

--luacheck: in=number,number,number,number
function equipment_item_add_specific(squadid, unitid, cat, itemid)
    return execute_with_military_screen(function(ws)
        gui.simulateInput(ws, 'D_MILITARY_EQUIP')

    	list_select_item_by_id(ws, 0, ws.equip.squads, squadid)

        ws.layer_objects[0].active = false
        ws.layer_objects[1].active = true

    	list_select_item_by_id(ws, 1, ws.equip.units, unitid)

        gui.simulateInput(ws, uniform_additem_keys[cat+1])
        ws.layer_objects[0].active = false
        ws.layer_objects[2].active = true

        gui.simulateInput(ws, 'SELECT')

    	list_select_item_by_id(ws, 2, ws.equip.specific_items, itemid)
        gui.simulateInput(ws, 'SELECT')

        return true
    end)
end

--print(pcall(function() return json:encode(equipment_item_get_matchoices(70,9391,5)) end))
--print(pcall(function() return json:encode(equipment_get_additem_specific(70,9391,5)) end))