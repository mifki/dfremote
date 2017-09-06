local utils = require 'utils'
local tilemat = require 'tile-material'

local biome_region_offsets = { {-1,-1}, {0,-1}, {1,-1}, {-1,0}, {0,0}, {1,0}, {-1,1}, {0,1}, {1,1} }

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

function td(x,y,z)
	local b = dfhack.maps.getTileBlock(x,y,z)
	return b and b.designation[x%16][y%16] or nil
end

function tileconstmatinfo(x,y,z)
	local const = df.construction.find({x=x,y=y,z=z})
	if const then
		return dfhack.matinfo.decode(v.mat_type, v.mat_index)
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

function is_obscuring1(od, tt)
	return not od or od.hidden or (df.tiletype.attrs[tt].material ~= df.tiletype_material.TREE and df.tiletype.attrs[tt].material ~= df.tiletype_material.AIR and df.tiletype.attrs[tt].shape ~= df.tiletype_shape.BROOK_TOP)
end

function is_obscuring2(od, tt)
	return not od or od.hidden or (df.tiletype.attrs[tt].material ~= df.tiletype_material.TREE and df.tiletype.attrs[tt].shape == df.tiletype_shape.WALL)
end

local function compare(a,b)
    if a < b then
        return -1
    elseif a > b then
        return 1
    else
        return 0
    end
end

local function _cmp(t1, t2)
	local r = compare(t1[1], t2[1])
	if r ~= 0 then
		return r
	end

	r = compare(t1[2], t2[2])
	if r ~= 0 then
		return r
	end

	r = compare(t1[3], t2[3])
	if r ~= 0 then
		return r
	end

	return r
end

function threed_get_block_map(blockx, blocky, z, dict)
    local minz = df.global.window_z-16
    local maxz = df.global.window_z+z
    local minx = blockx*16
    local miny = blocky*16
    local maxx = blockx*16+15
    local maxy = blocky*16+15

    local map = {}
    local const = 0
    local plants = 0

	for z = maxz, minz,-1 do
		local slice = {}
	    local block = dfhack.maps.getBlock(blockx, blocky, z)
		local godown = true
		local allhidden = true
		local allair = true

		for x=0,15 do
			for y=0,15 do
				local d = block.designation[x][y]

				local hidden = d.hidden

				--[[if not hidden and z < df.global.window_z then
					local h = true
                        
                    for oz = z+1, df.global.window_z do
                    	local od0 = td(blockx*16+x, blocky*16+y, oz)
                    	local od1 = td(blockx*16+x, blocky*16+y-1, oz)
                    	local od2 = td(blockx*16+x, blocky*16+y+1, oz)
                    	local od3 = td(blockx*16+x-1, blocky*16+y, oz)
                    	local od4 = td(blockx*16+x+1, blocky*16+y, oz)

                    	local tt0 = tt(blockx*16+x, blocky*16+y, oz)
                    	local tt1 = tt(blockx*16+x, blocky*16+y-1, oz)
                    	local tt2 = tt(blockx*16+x, blocky*16+y+1, oz)
                    	local tt3 = tt(blockx*16+x-1, blocky*16+y, oz)
                    	local tt4 = tt(blockx*16+x+1, blocky*16+y, oz)

                    	if is_obscuring1(od0,tt0) and
	                    	is_obscuring2(od1,tt1) and
    	                	is_obscuring2(od2,tt2) and
        	            	is_obscuring2(od3,tt3) and
            	        	is_obscuring2(od4,tt4) then
                    		hidden = true
                    		break
                    	end
                    end 
				end]]

				if not hidden then
					allhidden = false
					local tti = block.tiletype[x][y]
					local tshape = df.tiletype.attrs[tti].shape
					local tmaterial = df.tiletype.attrs[tti].material

					if tmaterial ~= df.tiletype_material.AIR and tshape ~= df.tiletype_shape.BROOK_TOP then
						allair = false
		                local biome_offset_idx = block.region_offset[d.biome]
		                local geolayer_idx = d.geolayer_index

		                if biome_offset_idx >= 9 then
		                	table.insert(slice, {0, 0})
		                else
			                local offset = biome_region_offsets[biome_offset_idx+1]
			                local rpos = { bit32.rshift(df.global.world.map.region_x,4) + offset[1], bit32.rshift(df.global.world.map.region_y,4) + offset[2] }
			                local rbio = dfhack.maps.getRegionBiome(table.unpack(rpos))
			                local geobiome = df.world_geo_biome.find(rbio.geo_index)
			                local layer = geobiome.layers[geolayer_idx]
			                local matinfo = dfhack.matinfo.decode(0, layer.mat_index)

			                local floorcolor = matinfo.material.basic_color[0]+matinfo.material.basic_color[1]*8

			                local tcolor = 0

			                if true and tmaterial == df.tiletype_material.CONSTRUCTION then
			                	const = const + 1
			                	local v = df.construction.find({x=minx+x,y=miny+y,z=z})
			                	if v then
                					local mi = dfhack.matinfo.decode(v.mat_type, v.mat_index)
									local color = mi.material.basic_color[0] + mi.material.basic_color[1]*8

									if mi.material.id:sub(1,6) == 'GLASS_' then
										-- support transparent floor and walls only currently
										if tshape == df.tiletype_shape.FLOOR or tshape == df.tiletype_shape.WALL then
											color = 100 + color
										end
									end

									tcolor = color
									if tshape == df.tiletype_shape.FLOOR or df.tiletype.attrs[v.original_tile].shape == df.tiletype_shape.EMPTY then
										floorcolor = color
									end
								end
			                else
				                local tmat = tilemat.GetTileMat(blockx*16+x, blocky*16+y, z)
								local m = tmat and (tmat.material._type == 'vector<material*>' and tmat.material[0] or tmat.material) or nil
								tcolor = m and (m.basic_color[0]+m.basic_color[1]*8) or 0
			                end

			                if tmaterial == df.tiletype_material.GRASS_DARK then
			                	floorcolor = 2
			                elseif tmaterial == df.tiletype_material.GRASS_LIGHT then
			                	floorcolor = 2 -- +8
			                elseif tmaterial == df.tiletype_material.GRASS_DEAD then
			                	floorcolor = 6
			                elseif tmaterial == df.tiletype_material.GRASS_DRY then
			                	floorcolor = 6
			                elseif tmaterial == df.tiletype_material.FROZEN_LIQUID then
			                	floorcolor = 15
			                elseif tmaterial == df.tiletype_material.PLANT then
			                	tcolor = df.tiletype.attrs[tti].special == df.tiletype_special.DEAD and 6 or 2
			                end

			                if tmaterial == df.tiletype_material.PLANT then
			                	plants = plants + 1
			                end

		                	if tshape == df.tiletype_shape.RAMP and tmaterial ~= df.tiletype_material.CONSTRUCTION then
		                		tcolor = floorcolor
		                	end

		                	if tshape == df.tiletype_shape.BRANCH or tshape == df.tiletype_shape.TWIG then
		                		floorcolor = -1
		                		tcolor = 2
		                	end

		                	if (tshape == df.tiletype_shape.WALL or tshape == df.tiletype_shape.RAMP) and tmaterial == df.tiletype_material.TREE then
		                		floorcolor = 6
		                		tcolor = 6
		                	end

							local t = d.flow_size > 0 and {tshape, floorcolor, tcolor, d.flow_size+bit(3, d.liquid_type)} or {tshape, floorcolor, tcolor}

		                	if dict and #t == 3 then
		                		local item = utils.binsearch(dict, t, 1, _cmp)
		                		if not item then
		                			item = { t, #dict+1 }
		                			utils.insert_sorted(dict, item, 1, _cmp)
		                		end
		                		table.insert(slice, item[2])
		                	else
		                		table.insert(slice, t)
		                	end
						end
					else
						--todo: still need to send flow amount
						godown = true
						if d.flow_size > 0 then
							allair = false
							table.insert(slice, {0, d.flow_size+bit(3, d.liquid_type)})
						else
							table.insert(slice, 0)
						end
						
					end
				else
					table.insert(slice, -1)
				end
			end
		end

		if allhidden then
			table.insert(map, -1)
		elseif allair then
			table.insert(map, 0)
		else
			table.insert(map, slice)
		end

		if not godown then
			break
		end
	end

	--[[if false and const > 0 then
		for i,v in ipairs(df.global.world.constructions) do
			local p = v.pos
			if p.z >= minz and p.z <= maxz and p.x >= minx and p.x <= maxx and p.y >= miny and p.y <= maxy then
				local x = v.pos.x - minx
				local y = v.pos.y - miny
				local z = maxz - p.z

				local m = map[1 + z*16*16 + x*16 + y]
				if m and #m > 2 then
					local mi = dfhack.matinfo.decode(v.mat_type, v.mat_index)
					local color = mi.material.basic_color[0] + mi.material.basic_color[1]*8

					if mi.material.id:sub(1,6) == 'GLASS_' then
						-- support transparent floor and walls only currently
						if m[1] == df.tiletype_shape.FLOOR or m[1] == df.tiletype_shape.WALL then
							color = 100 + color
						end
					end

					m[3] = color
					if m[1] == df.tiletype_shape.FLOOR or df.tiletype.attrs[v.original_tile].shape == df.tiletype_shape.EMPTY then
						m[2] = color
					end
				end
			end
		end
	end

	if false and plants > 0 then
		for _, v in ipairs(df.global.world.plants.all) do
	        if v.tree_info == nil then

				local p = v.pos
				if p.z >= minz and p.z <= maxz and p.x >= minx and p.x <= maxx and p.y >= miny and p.y <= maxy then
					local x = v.pos.x - minx
					local y = v.pos.y - miny
					local z = maxz - p.z

					local mi = dfhack.matinfo.decode(419, v.material)
					local color = mi.material.basic_color[0] + mi.material.basic_color[1]*8

					local m = map[1 + z*16*16 + x*16 + y]
					if m and #m > 2 then
						m[3] = color
					end
				end
	        end
	    end	
	end]]

    return map
end

local function upload(path, content)
	local l = require'plugins.luasocket'

	local s = l.tcp:connect('assets.mifki.com.s3.amazonaws.com', 80)
	s:setBlocking(true)
	s:setTimeout(10)
	s:send('PUT '..path..' HTTP/1.1\nHost: assets.mifki.com.s3.amazonaws.com\nConnection: close\nContent-Length:'..tostring(#content)..'\nx-amz-acl: public-read\n\n'..content..'\n')

	print (s:receive('*l'))
end

local seasons = { 'Spring', 'Summer', 'Autumn', 'Winter' }
local seasonparts = { 'Early ', 'Mid-', 'Late ' }
local site_ranks = { 'Outpost', 'Hamlet', 'Village', 'Town', 'City', 'Metropolis' }
local function test_upload_map()
	local json = require'json'
	local key = 'test2'

	local dict = nil --{}
	local combined = {}

	for j=0,df.global.world.map.y_count_block-1 do
		for i=0,df.global.world.map.x_count_block-1 do
			local b = threed_get_block_map(i, j, 0, dict)
			table.insert(combined, b)
		end
	end

    local site = df.world_site.find(df.global.ui.site_id)
    local is_mountainhome = have_noble('MONARCH') --todo: what if monarch dies? there should be more correct way
    local site_title = (is_mountainhome and 'Mountainhome' or site_ranks[df.global.ui.fortress_rank+1]) .. ' ' .. translatename(site.name) .. ', "' .. dfhack.TranslateName(site.name, true) .. '"'

    local month = math.floor(df.global.cur_year_tick / TU_PER_MONTH)
    local datestr = format_date(df.global.cur_year, df.global.cur_year_tick) .. ', ' .. seasonparts[month%3+1] .. seasons[math.floor(month/3)+1]	

	local info = { 1, df.global.world.map.x_count_block, df.global.world.map.y_count_block, site_title, datestr }
	local mpdata = mp.pack({ info, combined, dict })

	print ('uploading '..tostring(math.floor(#mpdata/1024))..' Kb...')
	upload('/df3dview/maps/'..key..'/combined.mp', mpdata)
end

-- test_upload_map()