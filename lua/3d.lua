local utils = require 'utils'

function istrue(v)
    return v ~= nil and v ~= false and v ~= 0
end

function is_space(tt)
	return tt == df.tiletype.OpenSpace
end

function is_floor(tt)
	return tt and df.tiletype.attrs[tt].shape == df.tiletype_shape.FLOOR
end

function is_wall(tt)
	return tt and df.tiletype.attrs[tt].shape == df.tiletype_shape.WALL or false
end

function is_ramp(tt)
	return tt and df.tiletype.attrs[tt].shape == df.tiletype_shape.RAMP
end

function is_upstair(tt)
	return tt and df.tiletype.attrs[tt].shape == df.tiletype_shape.STAIR_UP
end

function is_downstair(tt)
	return tt and df.tiletype.attrs[tt].shape == df.tiletype_shape.STAIR_DOWN
end

function is_updownstair(tt)
	return tt and df.tiletype.attrs[tt].shape == df.tiletype_shape.STAIR_UPDOWN
end

function tt(x,y,z)
	return dfhack.maps.getTileType(x,y,z)
end

local biome_region_offsets = { {-1,-1}, {0,-1}, {1,-1}, {-1,0}, {0,0}, {1,0}, {-1,1}, {0,1}, {1,1} }

function tileconstmatinfo(x,y,z)
	for i,v in ipairs(df.global.world.constructions) do
		local pos = v.pos
		if pos.x == x and pos.y == y and pos.z == z then
			return dfhack.matinfo.decode(v.mat_type, v.mat_index)
		end
	end

	return nil
end

function tilematinfo(x,y,z)
	local block = dfhack.maps.getTileBlock(x,y,z)
    local biome_offset_idx = block.region_offset[block.designation[x%16][y%16].biome]
    local geolayer_idx = block.designation[x%16][y%16].geolayer_index

    local offset = biome_region_offsets[biome_offset_idx+1]
    local rpos = { bit32.rshift(df.global.world.map.region_x,4) + offset[1], bit32.rshift(df.global.world.map.region_y,4) + offset[2] }
    local rbio = dfhack.maps.getRegionBiome(table.unpack(rpos))
    local geobiome = df.world_geo_biome.find(rbio.geo_index)
    local layer = geobiome.layers[geolayer_idx]
    local matinfo = dfhack.matinfo.decode(0, layer.mat_index)

    return matinfo
end

function tileplantmatinfo(x,y,z)
    local mapcol = df.global.world.map.column_index[math.floor(x/48)*3][math.floor(y/48)*3]
    
    --print(bx,by)
    for i,p in ipairs(mapcol.plants) do
        if not p.tree_info then
            local pos = p.pos
            if pos.x == x and pos.y == y and pos.z == z then
                local plant = df.plant_raw.find(p.material)
                return dfhack.matinfo.decode(plant.material_defs.type_basic_mat, plant.material_defs.idx_basic_mat)
            end
        end
    end

    return nil
end

function tileplantcolor(x,y,z, dead)
    local mapcol = df.global.world.map.column_index[math.floor(x/48)*3][math.floor(y/48)*3]
    
    --print(bx,by)
    for i,p in ipairs(mapcol.plants) do
        if not p.tree_info then
            local pos = p.pos
            if pos.x == x and pos.y == y and pos.z == z then
                local plant = df.plant_raw.find(p.material)
                if dead then
                	return plant.colors.dead_tree_color[0]+plant.colors.dead_tree_color[2]*8
                else
                	return plant.colors.tree_color[0]+plant.colors.tree_color[2]*8
                end
            end
        end
    end

    return nil
end

function tilefloorcolor(x,y,z)
	local fg = -1
	local bg = -1
	local mi = tilematinfo(x,y,z)
	if mi then
		local c = df.descriptor_color.find(mi.material.state_color.Solid)
		fg = c.color + 8*c.bold
	end

	return fg
end

local buildings_placed = {}

function process(x,y,z, basex, basey, basez, map)
	local t = tt(x,y,z)

	local xx = x - basex
	local yy = y - basey
	local zz = z - basez

	if is_wall(t) then
		if df.tiletype.attrs[t].material == df.tiletype_material.TREE then
			table.insert(map, { xx,yy,zz, { 'trunk' } })
		else
			local ew = {bottom=1}
			local ef = {top=1}
			if x ~= minx and is_wall(tt(x-1,y,z)) then ew.w=1 ; ef.w=1 end
			if x ~= maxx and is_wall(tt(x+1,y,z)) then ew.e=1 ; ef.e=1 end
			if y ~= miny and is_wall(tt(x,y-1,z)) then ew.n=1 ; ef.n=1 end
			if y ~= maxy and is_wall(tt(x,y+1,z)) then ew.s=1 ; ef.s=1 end

			local fg = -1
			local bg = -1
			if df.tiletype.attrs[t].material == df.tiletype_material.CONSTRUCTION then
				local mi = tileconstmatinfo(x,y,z)
				if mi then
					local c = df.descriptor_color.find(mi.material.state_color.Solid)
					fg = c.color + 8*c.bold
				end
			end

			table.insert(map, { xx,yy,zz, { 'floor', ef, fg, bg }, { 'wall', ew, fg, bg } })
		end

		return
	end	

	local tb = dfhack.maps.getTileBlock(x,y,z)
	if not tb then return end
	local occ = tb.occupancy[x%16][y%16]

	if occ.building ~= 0 then
		for i,bld in ipairs(df.global.world.buildings.all) do
			if bld.z == z and bld.x1 <= x and bld.x2 >= x and bld.y1 <= y and bld.y2 >= y and
				bld._type ~= df.building_civzonest and bld._type ~= df.building_stockpilest then
				if not utils.binsearch(buildings_placed, bld.id) then
					utils.insert_sorted(buildings_placed, bld.id)

					local fg = -1
					local bg = -1
					local mat = dfhack.matinfo.decode(bld.mat_type, bld.mat_index)
					if mat then
						--fg = mat.material.build_color[0] + 8*mat.material.build_color[2]
						--bg = mat.material.build_color[1]
						local c = df.descriptor_color.find(mat.material.state_color.Solid)
						fg = c.color + 8*c.bold
					end

					local btype = bld:getType()
					local btypename = df.building_type[btype]:lower()
					if btypename == 'roadpaved' then
						for bx = bld.x1,bld.x2 do
							for by = bld.y1,bld.y2 do
								table.insert(map, { bx-minx,by-miny,zz, { 'building', 'pavement', {}, fg, bg } })
							end
						end
					
					elseif btypename == 'door' then
						local t1 = tt(x-1,y,z)
						local t2 = tt(x+1,y,z)
						local d
						if is_wall(t1) or is_wall(t2) then --todo: and ?
							d = 'door-we'
						else
							d = 'door-ns'
						end
						table.insert(map, { bld.x1-minx,bld.y1-miny,zz, { 'floor',{}, tilefloorcolor(x,y,z) }, { 'building', d, {bottom=1}, fg, bg } })
					
					elseif btypename == 'cabinet' then
						local d
						if is_wall(tt(x-1,y,z)) then
							d = 'cabinet-w'
						elseif is_wall(tt(x+1,y,z)) then
							d = 'cabinet-e'
						elseif is_wall(tt(x,y-1,z)) then
							d = 'cabinet-n'
						elseif is_wall(tt(x,y+1,z)) then
							d = 'cabinet-s'
						else
							d = 'cabinet'
						end
						table.insert(map, { bld.x1-minx,bld.y1-miny,zz, { 'floor',{}, tilefloorcolor(x,y,z) }, { 'building', d, {bottom=1}, fg, bg } })
					
					else
						table.insert(map, { bld.x1-minx,bld.y1-miny,zz, { 'floor',{}, tilefloorcolor(x,y,z) }, { 'building', btypename, {bottom=1}, fg, bg } })
					end
				end

				return
			end
		end
	end

	if is_downstair(t) then
		table.insert(map, { xx,yy,zz, { 'floor_downstair',{}, tilefloorcolor(x,y,z) } })

	elseif is_upstair(t) then
		table.insert(map, { xx,yy,zz, { 'floor', {}, tilefloorcolor(x,y,z) }, { 'stair', {bottom=1} } })

	elseif is_updownstair(t) then
		table.insert(map, { xx,yy,zz, { 'floor_downstair',{}, tilefloorcolor(x,y,z) }, { 'stair' } })

	elseif is_floor(t) then
		local ef = {}
		if x ~= minx and is_floor(tt(x-1,y,z)) then ef.w=1 end
		if x ~= maxx and is_floor(tt(x+1,y,z)) then ef.e=1 end
		if y ~= miny and is_floor(tt(x,y-1,z)) then ef.n=1 end
		if y ~= maxy and is_floor(tt(x,y+1,z)) then ef.s=1 end

		--[[local fg = -1
		local bg = -1
		local mi = tilematinfo(x,y,z)
		if mi then
			local c = df.descriptor_color.find(mi.material.state_color.Solid)
			fg = c.color + 8*c.bold
		end]]

		table.insert(map, { xx,yy,zz, { 'floor', ef, tilefloorcolor(x,y,z) } })

	elseif is_ramp(t) then
		local fg = tilefloorcolor(x,y,z)
		--todo: may be constructed !!!
		table.insert(map, { xx,yy,zz, { 'floor',fg }, { 'ramp',{bottom=1},fg } })

	elseif df.tiletype.attrs[t].shape == df.tiletype_shape.PEBBLES then
		table.insert(map, { xx,yy,zz, { 'floor', {}, tilefloorcolor(x,y,z) }, { 'pebbles',{bottom=1} } })

	elseif df.tiletype.attrs[t].shape == df.tiletype_shape.SAPLING then

		--[[local fg = -1
		local bg = -1
		local mi = tileplantmatinfo(x,y,z)
		if mi then
			local c = df.descriptor_color.find(mi.material.state_color.Solid)
			fg = c.color + 8*c.bold
		end]]
		local fg = tileplantcolor(x,y,z, df.tiletype.attrs[t].special==df.tiletype_special.DEAD)
		local bg = -1

		table.insert(map, { xx,yy,zz, { 'floor',{}, tilefloorcolor(x,y,z) }, { 'sapling',{bottom=1}, fg, bg } })

	elseif df.tiletype.attrs[t].shape == df.tiletype_shape.SHRUB then
		--[[local fg = -1
		local bg = -1
		local mi = tileplantmatinfo(x,y,z)
		if mi then
			local c = df.descriptor_color.find(mi.material.state_color.Solid)
			fg = c.color + 8*c.bold
		end]]

		local fg = tileplantcolor(x,y,z, df.tiletype.attrs[t].special==df.tiletype_special.DEAD)
		local bg = -1

		table.insert(map, { xx,yy,zz, { 'floor',{}, tilefloorcolor(x,y,z) }, { 'shrub',{bottom=1}, fg, bg } })		

	elseif df.tiletype.attrs[t].shape == df.tiletype_shape.BOULDER then
		local fg = tilefloorcolor(x,y,z)
		table.insert(map, { xx,yy,zz, { 'floor',{},fg }, { 'boulder',{bottom=1},fg } })		
	end

	if tb.designation[x%16][y%16].flow_size == 7 then
		table.insert(map, { xx,yy,zz, { 'water-7' } })				
	elseif tb.designation[x%16][y%16].flow_size == 6 then
		table.insert(map, { xx,yy,zz, { 'water-6' } })				
	end
end

function threed_get_block_map(blockx, blocky, z)
    local minz = df.global.window_z+z-5
    local maxz = df.global.window_z+z
    local minx = blockx*16
    local miny = blocky*16
    local maxx = blockx*16+15
    local maxy = blocky*16+15

    local map = {}
    
    for z=minz,maxz do
    	for x=minx,maxx do
    		for y=miny,maxy do
    			process(x,y,z, minx, miny, minz, map)
    		end
    	end
    end

    return map    

end