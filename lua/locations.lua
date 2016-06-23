function location_find_by_id(id)
	local site = df.world_site.find(df.global.ui.site_id)

	--todo: use binsearch if it's sorted
	for i,loc in ipairs(site.buildings) do
		if loc.id == id then
			return loc
		end
	end

	return nil
end

--todo: use list from the locations screen
function locations_get_list()
	local site = df.world_site.find(df.global.ui.site_id)

	local list = {}

	for i,loc in ipairs(site.buildings) do
		local ltype = loc:getType()

		-- if not retired
		if not loc.flags[1] and
		   (ltype == df.abstract_building_type.TEMPLE or ltype == df.abstract_building_type.INN_TAVERN or
		   ltype == df.abstract_building_type.LIBRARY) then

			local allow_residents = loc.flags[5]
			local allow_outsiders = loc.flags[4]
			local mode = allow_outsiders and 2 or (allow_residents and 1 or 0)

			local item = { locname(loc), loc.id, ltype, mode }

			if ltype == df.abstract_building_type.TEMPLE then
				local deity = loc.deity ~= -1 and df.historical_figure.find(loc.deity)
				local deity_name = deity and hfname(deity, true) or mp.NIL

				table.insert(item, deity_name)
			end

			table.insert(list, item)
		end
	end

	local site_occupations_count = 0
	local group_id = df.global.ui.group_id
	for i,v in ipairs(df.global.world.occupations.all) do
		if v.anon_1 == group_id and v.unit_id ~= -1 then
			site_occupations_count = site_occupations_count + 1
		end
	end

	return { list, { translatename(site.name), site_occupations_count } }
end

local function count_buildings(loc, count_type)
	local cnt = 0
	
	for i,v in ipairs(loc.contents.unk_108) do
		local bld = df.building.find(v)

		if bld then
			local btype = bld:getType()
			if btype == df.building_type.Civzone then
				for j,bld2 in ipairs(bld.children) do
					if bld2:getType() == count_type then
						cnt = cnt + 1
					end
				end

			elseif btype == count_type then
				cnt = cnt + 1
			end
		end
	end

	return cnt
end

local occupation_names = {
    'Tavern Keeper',
    'Performer',
    'Scholar',
    'Mercenary',
    'Monster Slayer',
    'Scribe'	
}

function location_get_info(id)
	if id == -1 then
		local site = df.world_site.find(df.global.ui.site_id)
		local group_id = df.global.ui.group_id

		local occupations = {}

		for i,occ in ipairs(df.global.world.occupations.all) do
			if occ.anon_1 == group_id and occ.unit_id ~= -1 then
				local unit = df.unit.find(occ.unit_id)
				local unitname = unit and unit_fulltitle(unit) or '#unknown unit#'

				local pos = #occupations + 1
				for j,v in ipairs(occupations) do
					--[[if v[5] == -1 and occ.type == v[3] then
						pos = occ.unit_id == -1 and 0 or j
						break
					end]]
					if v[3] > occ.type then
						pos = j
						break
					end
				end				

				table.insert(occupations, pos, { occupation_names[occ.type+1], occ.id, occ.type, unitname, occ.unit_id })
			end
		end

		return { translatename(site.name), -1, occupations }
	end

	return execute_with_locations_screen(function(ws)
		for j,loc in ipairs(ws.locations) do
			if loc and loc.id == id then
				local ltype = loc:getType()

				local info
				local params
				if ltype == df.abstract_building_type.LIBRARY then
					local count_written = ws.anon_1[j]
					local count_paper = loc.contents.unk_100

					info = {
						count_buildings(loc, df.building_type.Bookcase), count_written,
						count_buildings(loc, df.building_type.Box), count_paper,
						count_buildings(loc, df.building_type.Table), count_buildings(loc, df.building_type.Chair)
					}

					params = { loc.contents.desired_copies, loc.contents.desired_paper }

				elseif ltype == df.abstract_building_type.INN_TAVERN then
					local count_goblets = loc.contents.unk_f8
					local count_instruments = loc.contents.unk_fc
					local dance_area = { ws.dance_floor_x[j], ws.dance_floor_y[j] }

					local rented_rooms = 0
					local total_rooms = 0
					
					for i,v in ipairs(loc.contents.unk_108) do
						local bld = df.building.find(v)

						if bld then
							local btype = bld:getType()
							if btype == df.building_type.Bed then
								total_rooms = total_rooms + 1
								if bld.owner_id ~= -1 then
									rented_rooms = rented_rooms + 1
								end
							end
						end
					end		

					info = {
						count_buildings(loc, df.building_type.Box),
						count_goblets, count_instruments,
						rented_rooms, total_rooms,
						dance_area,
					}

					params = { loc.contents.desired_goblets, loc.contents.desired_instruments }

				elseif ltype == df.abstract_building_type.TEMPLE then
					local count_instruments = loc.contents.unk_fc
					local dance_area = { ws.dance_floor_x[j], ws.dance_floor_y[j] }

					local deity = loc.deity ~= -1 and df.historical_figure.find(loc.deity)
					local deity_name = deity and hfname(deity, true) or mp.NIL

					info = {
						count_buildings(loc, df.building_type.Box), count_instruments,
						dance_area, deity_name,
					}

					params = { loc.contents.desired_instruments }
				end

				local occupations = {}
				for i,occ in ipairs(loc.occupations) do
					local unit = occ.unit_id ~= -1 and df.unit.find(occ.unit_id) or nil
					local unitname = occ.unit_id ~= -1 and (unit and unit_fulltitle(unit) or '#unknown unit#') or mp.NIL

					-- grouping by occupation type, and not allowing >1 unassigned occupation of one type
					local pos = #occupations + 1
					for j,v in ipairs(occupations) do
						if v[5] == -1 and occ.type == v[3] then
							pos = occ.unit_id == -1 and 0 or j
							break
						end
						if v[3] > occ.type then
							pos = j
							break
						end
					end

					if pos > 0 then
						table.insert(occupations, pos, { occupation_names[occ.type+1], occ.id, occ.type, unitname, occ.unit_id })
					end
				end

				local allow_residents = loc.flags[5]
				local allow_outsiders = loc.flags[4]
				local mode = allow_outsiders and 2 or (allow_residents and 1 or 0)

				return { locname(loc), loc.id, ltype, mode, info, occupations, params }
			
			else
				gui.simulateInput(ws, 'STANDARDSCROLL_DOWN')
			end
		end

		error('no location '..tostring(id))		
	end)
end

function location_occupation_get_candidates(locid, occid)
	return execute_with_locations_screen(function(ws)
		for i,loc in ipairs(ws.locations) do
			if loc and loc.id == locid then
				for j,occ in ipairs(ws.occupations) do
					if occ.id == occid then
						ws.menu = 1
						ws.occupation_idx = j
						gui.simulateInput(ws, 'SELECT')

						local ret = {}
						for k,unit in ipairs(ws.units) do
							if unit then
								table.insert(ret, { unit_fulltitle(unit), unit.id })
							else
								table.insert(ret, { 'Nobody', -1 })
							end
						end

						return ret
					end
				end

				error('no occupation ' .. tostring(occid))
			end

			gui.simulateInput(ws, 'STANDARDSCROLL_DOWN')
		end

		error('no location ' .. tostring(locid))
	end)
end

function location_occupation_assign(locid, occid, unitid)
	return execute_with_locations_screen(function(ws)
		for i,loc in ipairs(ws.locations) do
			if loc and loc.id == locid then
				for j,occ in ipairs(ws.occupations) do
					if occ.id == occid then
						ws.menu = 1
						ws.occupation_idx = j
						gui.simulateInput(ws, 'SELECT')

						for k,unit in ipairs(ws.units) do
							if (unit and unit.id == unitid) or (not unit and unitid == -1) then
								ws.unit_idx = k
								gui.simulateInput(ws, 'SELECT')

								return true
							end
						end

						error('no unit ' .. tostring(unitid))
					end
				end

				error('no occupation ' .. tostring(occid))
			end

			gui.simulateInput(ws, 'STANDARDSCROLL_DOWN')
		end

		error('no location ' .. tostring(locid))
	end)
end

function location_retire(id)
	return execute_with_locations_screen(function(ws)
		for i,loc in ipairs(ws.locations) do
			if loc and loc.id == id then
				gui.simulateInput(ws, 'LOCATION_RETIRE')
			end

			gui.simulateInput(ws, 'STANDARDSCROLL_DOWN')
		end

		error('no location ' .. tostring(locid))
	end)
end

function location_set_restriction(id, mode)
	local loc = location_find_by_id(id)
	if not loc then
		error('no location '..tostring(id))
	end

	local allow_residents = mode > 0
	local allow_outsiders = mode == 2

	loc.flags[5] = allow_residents
	loc.flags[4] = allow_outsiders

	return true	
end

function location_set_parameter(id, idx, val)
	local loc = location_find_by_id(id)
	if not loc then
		error('no location '..tostring(id))
	end

	local ltype = loc:getType()

	if ltype == df.abstract_building_type.INN_TAVERN then
		if idx == 0 then
			loc.contents.desired_goblets = val
		elseif idx == 1 then
			loc.contents.desired_instruments = val
		end

	elseif ltype == df.abstract_building_type.LIBRARY then
		if idx == 0 then
			loc.contents.desired_copies = val
		elseif idx == 1 then
			loc.contents.desired_paper = val
		end

	elseif ltype == df.abstract_building_type.TEMPLE then
		if idx == 0 then
			loc.contents.desired_instruments = val
		end
	end	

	return true
end

function location_assign_get_list(bldid)
    local zone = df.building.find(bldid)
    if not zone or zone:getType() ~= df.building_type.Civzone then
        error('no zone or not a zone'..tostring(bldid))
    end

    if not zone.zone_flags.meeting_area then
    	error('not a meeting area'..tostring(zone.zone_flags.whole))
    end

    return execute_with_selected_zone(bldid, function(ws)
    	gui.simulateInput(ws, 'ASSIGN_LOCATION')

    	local list = {}
    	
    	for i,loc in ipairs(df.global.ui_sidebar_menus.location.list) do
    		if loc then
	    		table.insert(list, { locname(loc), loc.id, loc:getType() })
	    	end
    	end

    	return { list, zone.location_id }
    end)
end

function location_assign(bldid, locid)
    local zone = df.building.find(bldid)
    if not zone or zone:getType() ~= df.building_type.Civzone then
        error('no zone or not a zone'..tostring(bldid))
    end

    if not zone.zone_flags.meeting_area then
    	error('not a meeting area'..tostring(zone.zone_flags.whole))
    end

    if zone.location_id == locid then
    	return
    end

    return execute_with_selected_zone(bldid, function(ws)
    	gui.simulateInput(ws, 'ASSIGN_LOCATION')

    	for i,loc in ipairs(df.global.ui_sidebar_menus.location.list) do
    		if (locid == -1 and not loc) or (loc and loc.id == locid) then
    			df.global.ui_sidebar_menus.location.cursor = i
    			gui.simulateInput(ws, 'SELECT')
    			return true
    		end
    	end

    	error('no location '..tostring(locid))
    end)
end

function locations_add_get_deity_choices(bldid)
    return execute_with_selected_zone(bldid, function(ws)
    	gui.simulateInput(ws, 'ASSIGN_LOCATION')
		gui.simulateInput(ws, 'LOCATION_NEW')
		gui.simulateInput(ws, 'LOCATION_TEMPLE')

		local ret = {}

    	for i,hf in ipairs(df.global.ui_sidebar_menus.location.deities) do
    		if hf ~= nil then
    			local worshippers = 0
    			for j,unit in ipairs(df.global.world.units.active) do
    				--todo: I'm not completely sure these conditions are correct
    				if not unit.flags1.dead and not unit.flags3[31] and dfhack.units.isOwnCiv(unit) then
    					local uhf = df.historical_figure.find(unit.hist_figure_id)
    					if uhf then
    						for k,l in ipairs(uhf.histfig_links) do
    							if l:getType() == df.histfig_hf_link_type.DEITY and l.target_hf == hf.id then
    								worshippers = worshippers + 1
    								break
    							end
    						end
    					end
    				end
    			end

    			local spheres = {}
    			for j,v in ipairs(hf.info.spheres) do
    				table.insert(spheres, capitalize(df.sphere_type[v]:lower()))
    			end

    			table.insert(ret, { hfname(hf, true), hf.id, worshippers, spheres })
    		end
    	end

    	return ret
    end)	
end

function locations_add(bldid, tp, deityid)
    return execute_with_selected_zone(bldid, function(ws)
    	gui.simulateInput(ws, 'ASSIGN_LOCATION')
		gui.simulateInput(ws, 'LOCATION_NEW')

		if tp == 1 then
			gui.simulateInput(ws, 'LOCATION_INN_TAVERN')
		elseif tp == 2 then
			gui.simulateInput(ws, 'LOCATION_LIBRARY')
		elseif tp == 3 then
			gui.simulateInput(ws, 'LOCATION_TEMPLE')

	    	for i,hf in ipairs(df.global.ui_sidebar_menus.location.deities) do
	    		if (deityid == -1 and not hf) or (hf and hf.id == deityid) then
	    			df.global.ui_sidebar_menus.location.cursor_deity = i
	    			gui.simulateInput(ws, 'SELECT')
	    			return true
	    		end
	    	end		

	    	error('no deity '..tostring(deityid))
		end
    end)	
end

-- print(pcall(function() return json:encode(locations_get_list()) end))
-- print(pcall(function() return json:encode(location_get_info(-1)) end))
-- print(pcall(function() return json:encode(location_occupation_get_candidates(2,108)) end))
-- print(pcall(function() return json:encode(location_assign(670,-1)) end))
-- print(pcall(function() return json:encode(locations_add_get_deity_choices(670)) end))