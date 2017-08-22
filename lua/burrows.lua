--luacheck: in=
function burrows_get_list()
	local ret = {}

	for i,v in ipairs(df.global.ui.burrows.list) do
		local name = burrowname(v)
		local limit_workshops = istrue(v.limit_workshops)

		table.insert(ret, { name, v.id, #v.units, limit_workshops })
	end

	return ret
end

--luacheck: in=
function burrows_add()
	execute_with_main_mode(df.ui_sidebar_mode.Default, function(ws)
		gui.simulateInput(ws, K'D_BURROWS')
		gui.simulateInput(ws, K'D_BURROWS_ADD')
	end)
end

--luacheck: in=number
function burrow_delete(id)
	for i,v in ipairs(df.global.ui.burrows.list) do
		if v.id == id then
			return execute_with_main_mode(df.ui_sidebar_mode.Default, function(ws)
				gui.simulateInput(ws, K'D_BURROWS')

				df.global.ui.burrows.sel_index = i
				df.global.ui.burrows.sel_id = id
				df.global.ui.burrows.in_confirm_delete = true
		
				gui.simulateInput(ws, K'MENU_CONFIRM')
				return true
			end)	
		end
	end
	
	error('no burrow '..tostring(id))
end

--luacheck: in=number
function burrow_get_info(id)
	if id == -1 then
		--todo: ideally must check for mode but this is called after editining has ended and mode is 0
		if true or df.global.ui.main.mode == df.ui_sidebar_mode.Burrows then
			id = df.global.ui.burrows.sel_id
		else
			return nil
		end
	end

	local burrow = df.burrow.find(id)
	if not burrow then
		error('no burrow '..tostring(id))
	end

	return { burrowname(burrow), id, #burrow.units, burrow.limit_workshops, burrow.name }
end

--luacheck: in=number,bool
function burrow_limit_workshops(id, limit)
	local burrow = df.burrow.find(id)
	if not burrow then
		error('no burrow '..tostring(id))
	end

	burrow.limit_workshops = istrue(limit) and 1 or 0

	return true
end

--luacheck: in=number
function burrow_start_edit(id)
	for i,v in ipairs(df.global.ui.burrows.list) do
		if v.id == id then
			return execute_with_main_mode(df.ui_sidebar_mode.Default, function(ws)
				gui.simulateInput(ws, K'D_BURROWS')
			
				df.global.ui.burrows.sel_index = i
				df.global.ui.burrows.sel_id = id
			
				gui.simulateInput(ws, K'D_BURROWS_DEFINE')
				return true
			end, true)
		end
	end
	
	error('no burrow '..tostring(id))
end

--luacheck: in=
function burrow_end_edit()
	reset_main()
end

--luacheck: in=bool
function burrow_set_brush_mode(erase)
	df.global.ui.burrows.brush_erasing = istrue(erase) and 1 or 0
end

--todo: convert to screen_ functions
--luacheck: in=number
function burrow_get_units(id)
	local burrow = df.burrow.find(id)
	if not burrow then
		error('no burrow '..tostring(id))
	end

	--local added = {}
	--local others = {}
	local ret = {}

    for i,unit in ipairs(unitlist_get_units(df.viewscreen_unitlist_page.Citizens)) do

        local q = utils.binsearch(unit.burrows, burrow.id)
		local unitinfo = { unit_fulltitle(unit), unit.id, q ~= nil }

        --[[if q then
        	table.insert(added, unitinfo)
        else
        	table.insert(others, unitinfo)
        end]]

        table.insert(ret, unitinfo)
    end

	return ret --{ added, others }
end

--luacheck: in=number,number,bool
function burrow_set_unit(id, unitid, enable)
	local burrow = df.burrow.find(id)
	if not burrow then
		error('no burrow '..tostring(id))
	end

	local unit = df.unit.find(unitid)
	if not unit then
		error('no unit '..tostring(unitid))
	end

	dfhack.burrows.setAssignedUnit(burrow, unit, istrue(enable))

	return true
end

--luacheck: in=number,string
function burrow_set_name(id, name)
	local burrow = df.burrow.find(id)
	if not burrow then
		error('no burrow '..tostring(id))
	end

	burrow.name = name

	return true
end

--luacheck: in=number
function burrow_zoom(id)
	local idx,b = utils.linear_index(df.global.ui.burrows.list, id, 'id')
	
	if not b then
		error('no burrow '..tostring(id))
	end

	if #b.block_x == 0 then
		return
	end

	local ws = dfhack.gui.getCurViewscreen()

	-- enter burrows mode so that the burrow is actually visible
	reset_main()
	gui.simulateInput(ws, K'D_BURROWS')

	df.global.ui.burrows.sel_index = idx
	df.global.ui.burrows.sel_id = id	

   	local xbase = df.global.world.map.region_x * 3
   	local ybase = df.global.world.map.region_y * 3
   	local zbase = df.global.world.map.region_z

   	local bx = b.block_x[0] - xbase
	local by = b.block_y[0] - ybase
	local bz = b.block_z[0] - zbase

	-- If burrow includes several unconnected areas, we don't want to zoom to an empty space
	-- So let's take the first block only and find the center in that block

	local block = dfhack.maps.getBlock(bx,by,bz)

	local minx = 15
	local miny = 15
	local maxx = 0
	local maxy = 0

	local lnk = block.block_burrows
	while lnk do
		local bb = lnk.item
		if bb then
			for _y=0,15 do
				local rowbits = bb.tile_bitmask.bits[_y]
				if rowbits > 0 then
					if _y < miny then
						miny = _y
					end
					if _y > maxy then
						maxy = _y
					end

					for _x=0,15 do
						if hasbit(rowbits, _x) then
							if _x < minx then
								minx = _x
							end
							if _x > maxx then
								maxx = _x
							end
						end
					end
				end
			end
		end

		lnk = lnk.next
	end

	local cx = math.floor((minx+maxx)/2)
	local cy = math.floor((miny+maxy)/2)

	recenter_view(bx*16+cx, by*16+cy, bz)	
end

--pcall(function() burrow_zoom(4) end)