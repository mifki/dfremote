-- we don't support compression for incoming commands globally, so json data here is compressed and then msgpacked as a parameter
function raws_apply_tileset(zjsondata)
    local jsondata = ''
    local function appenddata(ch)
        jsondata = jsondata .. string.char(ch)
    end

    require'remote.deflatelua'.inflate_zlib{input=zjsondata,output=appenddata}    
    local data = json:decode(jsondata)

    for id,v in pairs(data.creatures or {}) do
        local f = false
        for j,raw in ipairs(df.global.world.raws.creatures.all) do
            if raw.creature_id == id then
                f = true
                raw.creature_tile = v.t
                raw.creature_soldier_tile = v.s or 0
                raw.alttile = v.a or 0
                raw.soldier_alttile = v.o or 0
                raw.glowtile = v.g or 0
                break
            end
        end
        if not f then print('not found '..id) end
    end

    for id,v in pairs(data.tools or {}) do
        local f = false
        for j,raw in ipairs(df.global.world.raws.itemdefs.tools) do
            if raw.id == id then
                f = true
                raw.tile = v.t
                break
            end
        end
        if not f then print('not found '..id) end
    end

    for j,raw in ipairs(df.global.world.raws.inorganics) do
        raw.material.tile = 219
        raw.material.item_symbol = 7
    end

    for id,v in pairs(data.inorganics or {}) do
        local f = false
        for j,raw in ipairs(df.global.world.raws.inorganics) do
            if raw.id == id then
                f = true
                raw.material.tile = v.t
                if v.s then
                    raw.material.item_symbol = v.s
                end
                break
            end
        end
        if not f then print('not found '..id) end
    end

    local def_grass_tiles = { 46, 44, 96, 39 }
    for j,raw in ipairs(df.global.world.raws.plants.all) do
        raw.tiles.tree_tile = 24
        raw.tiles.dead_tree_tile = 198
        raw.tiles.sapling_tile = 231
        raw.tiles.dead_sapling_tile = 231
        raw.tiles.picked_tile = 231
        raw.tiles.dead_picked_tile = 169
        raw.tiles.shrub_tile = 34
        raw.tiles.dead_shrub_tile = 34

        for k=0,#raw.tiles.grass_tiles-1 do
            raw.tiles.grass_tiles[k] = def_grass_tiles[(k%#def_grass_tiles)+1]
        end

        for k=0,#raw.tiles.alt_grass_tiles-1 do
            raw.tiles.alt_grass_tiles[k] = def_grass_tiles[(k%#def_grass_tiles)+1]
        end                    

        for k=0,#raw.alt_period-1 do
            raw.alt_period[k] = 0
        end
    end

    for id,v in pairs(data.plants or {}) do
        local f = false
        for j,raw in ipairs(df.global.world.raws.plants.all) do
            if raw.id == id then
                f = true

                -- simple tiles
                if v.p then raw.tiles.picked_tile = v.p end
                if v.dp then raw.tiles.dead_picked_tile = v.dp end
                if v.s then raw.tiles.shrub_tile = v.s end
                if v.ds then raw.tiles.dead_shrub_tile = v.ds end
                if v.t then raw.tiles.tree_tile = v.t end
                if v.dt then raw.tiles.dead_tree_tile = v.dt end
                if v.a then raw.tiles.sapling_tile = v.a end
                if v.da then raw.tiles.dead_sapling_tile = v.da end

                -- grass tiles
                if v.r then
                    for k=0,#raw.tiles.grass_tiles-1 do
                        raw.tiles.grass_tiles[k] = v.r[(k%#v.r)+1]
                    end
                end

                -- alternate grass tiles and periods
                if v.ar and v.ap then
                    for k=0,#raw.tiles.alt_grass_tiles-1 do
                        raw.tiles.alt_grass_tiles[k] = v.ar[(k%#v.ar)+1]
                    end                    
                    for k=0,#raw.alt_period-1 do
                        raw.alt_period[k] = v.ap[k+1]
                    end
                end

                -- growths
                if v.g then
                    for gid,w in pairs(v.g) do
                        local gf = false
                        for k,graw in ipairs(raw.growths) do
                            if graw.id == gid then
                                gf = true

                                -- delete existing prints
                                for n,p in ipairs(graw.prints) do
                                    p:delete()
                                end
                                graw.prints:resize(0)

                                -- create new prints
                                for n,pi in ipairs(w) do
                                    local p = df.plant_growth_print:new()
                                    p.tile_growth = pi[1]
                                    p.tile_item = pi[2]
                                    p.color[0] = pi[3]
                                    p.color[1] = pi[4]
                                    p.color[2] = pi[5]
                                    p.timing_start = pi[6]
                                    p.timing_end = pi[7]
                                    p.priority = pi[8]

                                    graw.prints:insert(#graw.prints, p)
                                end
                            end
                        end
                        if not gf then print('not found '..id) end
                    end
                end

                break
            end
        end
        if not f then print('not found '..id) end
    end

    if data.sky then
        df.global.d_init.sky_tile = data.sky[1]
        df.global.d_init.sky_color[0] = data.sky[2]
        df.global.d_init.sky_color[1] = data.sky[3]
        df.global.d_init.sky_color[2] = data.sky[4]
    end

    if data.chasm then
        df.global.d_init.chasm_tile = data.chasm[1]
        df.global.d_init.chasm_color[0] = data.chasm[2]
        df.global.d_init.chasm_color[1] = data.chasm[3]
        df.global.d_init.chasm_color[2] = data.chasm[4]
    end

    if data.pillar then
        df.global.d_init.pillar_tile = data.pillar
    end

    if data.track then
        for i=0,14 do
            df.global.d_init.track_tiles[i] = data.track[i+1]
        end
    end
    if data.ramp then
        for i=0,14 do
            df.global.d_init.track_ramp_tiles[i] = data.ramp[i+1]
        end
    end
    if data.tracki then
        for i=0,14 do
            df.global.d_init.track_tile_invert[i] = data.tracki[i+1]
        end
    end
    if data.rampi then
        for i=0,14 do
            df.global.d_init.track_ramp_invert[i] = data.rampi[i+1]
        end
    end

    if data.tree then
        for i=0,103 do
            df.global.d_init.tree_tiles[i] = data.tree[i+1]
        end

        for j,raw in ipairs(df.global.world.raws.plants.all) do
            for i=0,103 do
                raw.tiles.tree_tiles[i] = data.tree[i+1]
            end
        end
    end

    print 'successfully patched raws in memory'

    return true
end