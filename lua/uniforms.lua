function uniform_id2index(id)
    for i,v in ipairs(df.global.ui.main.fortress_entity.uniforms) do
        if v.id == id then
            return i
        end
    end

    return -1
end

function uniform_find_by_id(id)
	for i,v in ipairs(df.global.ui.main.fortress_entity.uniforms) do
		if v.id == id then
			return v
		end
	end

	return nil
end

--luacheck: in=
function uniforms_get_list()
	local ret = {}

	for i,v in ipairs(df.global.ui.main.fortress_entity.uniforms) do
		table.insert(ret, { uniformname(v), v.id })
	end

	return ret
end

--luacheck: in=
function uniforms_add()
    execute_with_military_screen(function(ws)
        gui.simulateInput(ws, 'D_MILITARY_UNIFORMS')
        gui.simulateInput(ws, 'D_MILITARY_ADD_UNIFORM')
    end)
end

function uniform_delete(id)
    local idx = uniform_id2index(id)
    if idx == -1 then
        return
    end

    execute_with_military_screen(function(ws)
        gui.simulateInput(ws, 'D_MILITARY_UNIFORMS')
        ws.layer_objects[0].cursor = idx --hint:df.layer_object_listst
        gui.simulateInput(ws, 'D_MILITARY_DELETE_UNIFORM')
    end)

    return true
end

--luacheck: in=number
function uniform_get_info(id)
	local uniform = uniform_find_by_id(id)
	if not uniform then
		error('no uniform '..tostring(id))
	end

	local items = {}

	--todo: maybe do this via UI to be sure the order is the same as in UI (for deletion)
	for i,infos in ipairs(uniform.uniform_item_info) do
		for j,info in ipairs(infos) do
			local type = uniform.uniform_item_types[i][j]
			local subtype = uniform.uniform_item_subtypes[i][j]

			local mat_class = info.material_class
			local mattype = info.mattype
			local matindex = info.matindex

			local title

			if info.indiv_choice.whole ~= 0 then
				if info.indiv_choice.any then
					title = 'Weapon of choice'
				elseif info.indiv_choice.melee then
					title = 'Melee weapon of choice'
				elseif info.indiv_choice.ranged then
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

			table.insert(items, { title, #items, i })
		end
	end

	return { uniformname(uniform), uniform.id, uniform.name, items, uniform.flags.whole }
end

--luacheck: in=number,string
function uniform_set_name(id, name)
	local uniform = uniform_find_by_id(id)
	if not uniform then
		error('no uniform '..tostring(id))
	end

	uniform.name = name

	return true
end

--luacheck: in=number,number
function uniform_set_flags(id, flags)
	local uniform = uniform_find_by_id(id)
	if not uniform then
		error('no uniform '..tostring(id))
	end

	uniform.flags.whole = flags

	return true
end

uniform_additem_keys = {
	'D_MILITARY_ADD_ARMOR',
	'D_MILITARY_ADD_PANTS',
	'D_MILITARY_ADD_HELM',
	'D_MILITARY_ADD_GLOVES',
	'D_MILITARY_ADD_BOOTS',
	'D_MILITARY_ADD_SHIELD',
	'D_MILITARY_ADD_WEAPON',
}

--luacheck: in=number
function uniform_get_additem(cat)
    return execute_with_military_screen(function(ws)
        gui.simulateInput(ws, 'D_MILITARY_UNIFORMS')
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
        	
        	table.insert(items, { title, i, ws.equip.add_item.foreign[i] })
        end

        return { items }
    end)
end

--luacheck: in=number,number,number
function uniform_item_add(uniformid, cat, itemspec)
    return execute_with_military_screen(function(ws)
        gui.simulateInput(ws, 'D_MILITARY_UNIFORMS')

    	list_select_item_by_id(ws, 0, ws.equip.uniforms, uniformid)

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

--luacheck: in=number,number
function uniform_item_get_matchoices(uniformid, itemidx)
    return execute_with_military_screen(function(ws)
        gui.simulateInput(ws, 'D_MILITARY_UNIFORMS')

    	list_select_item_by_id(ws, 0, ws.equip.uniforms, uniformid)

        ws.layer_objects[0].active = false
        ws.layer_objects[1].active = true
        ws.layer_objects[1].cursor = itemidx --hint:df.layer_object_listst

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

--luacheck: in=number,number,table
function uniform_item_set_material(uniformid, itemidx, matspec)
    return execute_with_military_screen(function(ws)
        gui.simulateInput(ws, 'D_MILITARY_UNIFORMS')

    	list_select_item_by_id(ws, 0, ws.equip.uniforms, uniformid)

        local info = ws.equip.uniform.info[itemidx]
		info.material_class = matspec[1]
		if info.material_class == -1 then
			info.mattype = matspec[2]
			info.matindex = matspec[3]
		else
			info.mattype = -1
			info.matindex = -1
		end

		return true
    end)	
end

--luacheck: in=number,number
function uniform_item_get_colorchoices(uniformid, itemidx)
end

--luacheck: in=number,number,number
function uniform_item_set_color(uniformid, itemidx, color)
end

--luacheck: in=number,number
function uniform_item_delete(uniformid, itemidx)
    return execute_with_military_screen(function(ws)
        gui.simulateInput(ws, 'D_MILITARY_UNIFORMS')

    	list_select_item_by_id(ws, 0, ws.equip.uniforms, uniformid)

		if itemidx < 0 or itemidx >= #ws.equip.uniform.info then
			return
		end

        ws.layer_objects[0].active = false
        ws.layer_objects[1].active = true
        ws.layer_objects[1].cursor = itemidx --hint:df.layer_object_listst

        gui.simulateInput(ws, 'SELECT')
        return true
    end)	
end

--luacheck: in=number,number,number
function uniform_apply(squadid, unitid, uniid)
	local uniidx = uniform_id2index(uniid)
	if not uniidx then
		return
	end

	--xxx: temporary until this is fixed in publicly available app version
	if unitid == 0 then
		unitid = -1
	end

    return execute_with_military_screen(function(ws)
    	gui.simulateInput(ws, 'D_MILITARY_EQUIP')
    	gui.simulateInput(ws, 'D_MILITARY_EQUIP_UNIFORM')

    	list_select_item_by_id(ws, 0, ws.equip.squads, squadid)

        ws.layer_objects[0].active = false

        if unitid ~= -1 then
	        ws.layer_objects[1].active = true
	    	list_select_item_by_id(ws, 1, ws.equip.units, unitid)
	        ws.layer_objects[1].active = false
	    end

        ws.layer_objects[2].active = true
        ws.layer_objects[2].cursor = uniidx --hint:df.layer_object_listst
		gui.simulateInput(ws, unitid == -1 and 'SEC_SELECT' or 'SELECT')

        return ret
    end)    
end

--print(pcall(function() return json:encode(uniform_item_get_matchoices(1,6)) end))