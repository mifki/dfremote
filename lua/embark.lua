local finder_params = {
	{ 'Savagery', df.embark_finder_option.Savagery, { 'Low', 'Medium', 'High' } },
	{ 'Evil', df.embark_finder_option.Evil, { 'Low', 'Medium', 'High' } },
	{ 'Elevation', df.embark_finder_option.Elevation, { 'Low', 'Medium', 'High' } },
	{ 'Temperature', df.embark_finder_option.Temperature, { 'Low', 'Medium', 'High' } },
	{ 'Rain', df.embark_finder_option.Rain, { 'Low', 'Medium', 'High' } },
	{ 'Drainage', df.embark_finder_option.Drainage, { 'Low', 'Medium', 'High' } },
	{ 'Flux Stone Layer', df.embark_finder_option.FluxStone, { 'No', 'Yes' } },
	{ 'Aquifer', df.embark_finder_option.Aquifer, { 'No', 'Yes' } },
	{ 'River', df.embark_finder_option.River, { 'No', 'Yes' } },
	{ 'Shallow Metal', df.embark_finder_option.ShallowMetal, { 'None', 'Yes', 'Multiple' } },
	{ 'Deep Metal', df.embark_finder_option.DeepMetal, { 'None', 'Yes', 'Multiple' } },
	{ 'Soil', df.embark_finder_option.Soil, { 'No', '≤ Little', '≤ Some', '≤ Deep' } },
	{ 'Clay', df.embark_finder_option.Clay, { 'No', 'Yes' } },
}

--[[function embark_checkloaded()
    local ws = dfhack.gui.getCurViewscreen()

    if ws._type == df.viewscreen_choose_start_sitest then
        return true
    end

    return false
end]]

function embark_newgame(folder)
    local ws = dfhack.gui.getCurViewscreen()

    -- Check that we're on title screen or its subscreens
    while ws and ws.parent and ws._type ~= df.viewscreen_titlest do
        ws = ws.parent
    end

    if ws._type ~= df.viewscreen_titlest then
        return
    end

    -- Return to title screen
    ws = dfhack.gui.getCurViewscreen()
    while ws and ws.parent and ws._type ~= df.viewscreen_titlest do
        local parent = ws.parent
        parent.child = nil
        ws:delete()
        ws = parent
    end
    ws.breakdown_level = 0

    local idx = -1
    for i,v in ipairs(ws.start_savegames) do
        if folder == v.save_dir then
        	idx = i
        	break
        end
	end

	if idx == -1 then
		return
	end

    ws.sel_subpage = 0
    -- whether there's a 'continue playing' menu item
    ws.sel_menu_line = (#ws.arena_savegames-#ws.start_savegames > 1 and 1 or 0)
    gui.simulateInput(ws, 'SELECT')
    ws:logic()
    ws:render()

    if ws.sel_subpage == df.viewscreen_titlest.T_sel_subpage.StartSelectWorld then
    	ws.sel_submenu_line = idx
	    gui.simulateInput(ws, 'SELECT')
	    ws:logic()
	    ws:render()

	elseif not (ws.sel_subpage == df.viewscreen_titlest.T_sel_subpage.StartSelectMode and #ws.start_savegames == 1) then
		return
    end

    if ws.sel_subpage ~= df.viewscreen_titlest.T_sel_subpage.StartSelectMode then
    	return
    end

	ws.sel_menu_line = 0
    gui.simulateInput(ws, 'SELECT')
end

function embark_get_overview()
	local ws = dfhack.gui.getCurViewscreen()

	if ws._type == df.viewscreen_choose_start_sitest then
		local civs = {}
		for i,civ in ipairs(ws.available_civs) do
			local name = dfhack.df2utf(dfhack.TranslateName(civ.name, true))
			table.insert(civs, { name })
		end

		local fparams = {}
		for i,v in ipairs(finder_params) do
			table.insert(fparams, { v[1], v[3] })
		end

		--todo: move fparams data to finder 'ready' state return (together with actual values probably)
		return { 'loc', civs, ws.civ_idx, fparams, #df.global.world.world_data.old_sites }
	end

	if ws._type == df.viewscreen_setupdwarfgamest then
		--todo: handle (set to 1) ws.show_play_now ~= 1

		local profiles = {}

		--xxx: ws.choices is holding the list of profiles, but the structure is unknown. the first field is string and is the name
		--xxx: so we reinterpret pointers as some other class that has string name as first field, just to access it from Lua easily
		for i,v in ipairs(ws.choices) do
			if ws.choice_types[i] == 2 then
				local name = df.reinterpret_cast(df.interaction,v).name

				table.insert(profiles, { name })
			end
		end

		local fort_name = translatename(ws.fort_name, false)
		local fort_name_eng = dfhack.TranslateName(ws.fort_name, true)
		return { 'profile', profiles, fort_name, fort_name_eng }
	end

    --todo: handle (close) viewscreen_selectitemst - won't be supported

	return nil
end

function embark_get_reclaim_sites()
	local ws = dfhack.gui.getCurViewscreen()
	if ws._type ~= df.viewscreen_choose_start_sitest then
		error('wrong screen')
	end

	if #df.global.world.world_data.old_sites == 0 then
		return {}
	end

	ws.finder.search_x = -1
	ws.finder.finder_state = -1

	local ret = {}
	for i,v in ipairs(df.global.world.world_data.old_sites) do
		local site = df.world_site.find(v)
		if not site then goto continue end

		local name = translatename(site.name)
		local name_eng = translatename(site.name, true)

		ws.page = df.viewscreen_choose_start_sitest.T_page.Biome
		ws.reclaim_idx = i
		gui.simulateInput(ws, 'SETUP_RECLAIM')
		gui.simulateInput(ws, 'CHANGETAB')
		ws:render()

		local site_info = ''
		for j,s in ipairs(ws.site_info) do
			if #s.value == 1 then
				site_info = site_info .. '\n'
			else
				site_info = site_info .. dfhack.df2utf(s.value)
			end
		end

		local ab = ws.site_abandoned
		local retired = ab and ab._type == df.history_event_site_retiredst or false

		table.insert(ret, { name, name_eng, site_info, retired })

		::continue::
	end

	ws.page = df.viewscreen_choose_start_sitest.T_page.Biome

	return ret
end

--print(pcall(function() print(json:encode(embark_get_reclaim_sites())) end))

function embark_set_civ(idx)
	local ws = dfhack.gui.getCurViewscreen()
	if ws._type ~= df.viewscreen_choose_start_sitest then
		return
	end

	if idx >= 0 and idx < #ws.available_civs then
		ws.civ_idx = idx
	end
end

local function read_region_info_line(y)
	local line = ''
	local color = 7

	for x = df.global.gps.dimx - 29, df.global.gps.dimx-2 do
		local char = df.global.gps.screen[(x*df.global.gps.dimy+y)*4]
		if char == string.byte':' then
			line = ''
		elseif char ~= 0 and (char ~= 32 or (#line > 0 and line:byte(#line) ~= 32)) then
			line = line .. string.char(char)
			color = df.global.gps.screen[(x*df.global.gps.dimy+y)*4+1] + df.global.gps.screen[(x*df.global.gps.dimy+y)*4+3]*8
		end
	end

	--line = line:sub(1, #line-1)
	return {line,color}
end

local function embark_site_info()
	local ws = dfhack.gui.getCurViewscreen()
	if ws._type ~= df.viewscreen_choose_start_sitest then
		error('wrong screen')
	end

	local loc = ws.location
	local maprgn = dfhack.maps.getRegionBiome(loc.region_pos)

	local biomes = {}
	ws.page = df.viewscreen_choose_start_sitest.T_page.Biome

	for i=0,#loc.biome_rgn.x-1 do
		ws.biome_idx = i
		ws:render()

		local biome_maprgn = dfhack.maps.getRegionBiome(loc.biome_rgn.x[i], loc.biome_rgn.y[i])
		local biome_region = df.world_region.find(biome_maprgn.region_id)
		local name = dfhack.TranslateName(biome_region.name, true)

		local landscape = read_region_info_line(4)[1]
		local temp = read_region_info_line(5)
		local trees = read_region_info_line(6)
		local veg = read_region_info_line(7)
		local sur = read_region_info_line(8)

		local features = {}
		for y=14,df.global.gps.dimy-4 do
			local line = read_region_info_line(y)
			if #line[1] == 0 then
				break
			end
			table.insert(features, line)
		end

		table.insert(biomes, { name, landscape,temp,trees,veg,sur, features })
	end

	local ret = {
		biomes
	}

	return ret
end

local matches = {}
function embark_finder_find(w, h, params)
	local ws = dfhack.gui.getCurViewscreen()
	if ws._type ~= df.viewscreen_choose_start_sitest then
		return
	end

	if #params ~= #finder_params then
		return
	end

	ws.page = df.viewscreen_choose_start_sitest.T_page.Find
	ws.finder.search_x = -1
	ws.finder.finder_state = -1

	ws.finder.options.DimensionX = w
	ws.finder.options.DimensionY = h

	for i,v in ipairs(params) do
		local idx = finder_params[i][2]
		ws.finder.options[idx] = v
	end

	gui.simulateInput(ws, 'SELECT')
	matches = {}
end

function embark_finder_status()
	local ws = dfhack.gui.getCurViewscreen()
	if ws._type ~= df.viewscreen_choose_start_sitest then
		error('wrong screen')
	end

	--[[if ws.page ~= df.viewscreen_choose_start_sitest.T_page.Find then
		return nil
	end]]

	if ws.finder.search_x ~= -1 then
		local w = math.floor(df.global.world.world_data.world_width / 16) + 1
		local h = math.floor(df.global.world.world_data.world_height / 16) + 1
		local total = w * h
		local cur = ws.finder.search_x * w + ws.finder.search_y + 1
		if cur > total then cur = total end
		return { 'searching', cur, total } --todo: include cur/max
	end

	-- this probably can't happen
	if ws.finder.finder_state == 0 then
		return { 'match-none' }
	end

	if ws.finder.finder_state == 1 then
		local unmatched = {}
		for i,v in ipairs(finder_params) do
			if ws.finder.unmatched[v[2]] then
				table.insert(unmatched, i-1)
			end
		end
		return { 'match-partial', embark_site_info(), unmatched }
	end

	if ws.finder.finder_state == 2 then
		return { 'match-full', embark_site_info() }
	end

	return { 'ready' }
end

function embark_finder_next()
	local ws = dfhack.gui.getCurViewscreen()
	if ws._type ~= df.viewscreen_choose_start_sitest then
		error('wrong screen')
	end

	--todo: handle case when there's no search matches
	--todo: handle case when there's no search - return any
	--todo: handle case if we're in reclaim mode

	if ws.finder.search_x ~= -1 or ws.finder.finder_state < 1 then
		return nil
	end

	ws.page = df.viewscreen_choose_start_sitest.T_page.Biome

	if #matches == 0 then
		local wdata = df.global.world.world_data
		for i=0,wdata.world_width-1 do
			for j=0,wdata.world_height-1 do
				if i ~= ws.location.region_pos.x or j ~= ws.location.region_pos.y then
					local rgn = dfhack.maps.getRegionBiome(i,j)
					if rgn.finder_rank ~= -1 then
						table.insert(matches, { i,j })
					end
				end
			end
		end
	end

	if #matches > 0 then
		local idx = math.floor(math.random() * #matches) + 1
		local match = matches[idx]

		local dx = match[1] - ws.location.region_pos.x
		local dy = match[2] - ws.location.region_pos.y
		table.remove(matches, idx)

		ws.location.region_pos.x = match[1]-1
		ws.location.region_pos.y = match[2]
		gui.simulateInput(ws, 'CURSOR_RIGHT')

		--ws:render()
	end

	return embark_finder_status()
end

function embark_finder_clear()
	local ws = dfhack.gui.getCurViewscreen()
	if ws._type ~= df.viewscreen_choose_start_sitest then
		return
	end

	ws.finder.search_x = -1
	ws.finder.finder_state = -1
end

function embark_finder_stop()
	local ws = dfhack.gui.getCurViewscreen()
	if ws._type ~= df.viewscreen_choose_start_sitest then
		return
	end

	ws.finder.search_x = -1

	return embark_finder_status()
end

function embark_cancel()
	local ws = dfhack.gui.getCurViewscreen()
	if ws._type ~= df.viewscreen_choose_start_sitest then
		return
	end

    local optsws = df.viewscreen_optionst:new()

    optsws.options:insert(0, 5) -- abort game
    optsws.parent = ws
    ws.child = optsws

    gui.simulateInput(optsws, 'SELECT')

	ws = dfhack.gui.getCurViewscreen()
end

function embark_embark()
	local ws = dfhack.gui.getCurViewscreen()
	if ws._type ~= df.viewscreen_choose_start_sitest then
		return
	end

	gui.simulateInput(ws, 'SETUP_EMBARK')
	ws = dfhack.gui.getCurViewscreen()

	-- We're still on the embark map screen, likely a message box is displayed
	if ws._type == df.viewscreen_choose_start_sitest then
		if ws.in_embark_aquifer or ws.in_embark_salt or ws.in_embark_large or ws.in_embark_normal then
			--todo: should return this message to the app instead of accepting silently
			gui.simulateInput(ws, 'SELECT')
			ws = dfhack.gui.getCurViewscreen()
		end
	end
end

function embark_reclaim(idx)
	local ws = dfhack.gui.getCurViewscreen()
	if ws._type ~= df.viewscreen_choose_start_sitest then
		return
	end

	ws.finder.search_x = -1
	ws.finder.finder_state = -1
	ws.page = df.viewscreen_choose_start_sitest.T_page.Biome
	ws.reclaim_idx = idx
	gui.simulateInput(ws, 'SETUP_RECLAIM')
	ws:render()
	gui.simulateInput(ws, 'SETUP_EMBARK')

	local ws = dfhack.gui.getCurViewscreen()
	printall (ws)
	if ws._type == df.viewscreen_setupdwarfgamest and ws.breakdown_level == 2 then
        local parent = ws.parent
        parent.child = nil
        ws:delete()
        ws = parent
	end

    if ws._type == df.viewscreen_textviewerst then
    	local text = ''
    	for i,v in ipairs(ws.formatted_text) do
	    	text = text .. dfhack.df2utf(charptr_to_string(v.text)) .. ' '
	    end
	    text = text:gsub('%s+', ' ')

        local title = ws.title
        title = title:gsub("^%s+", ""):gsub("%s+$", "")

	    return { title, text }
	end

	return { '' }
end

function embark_play(idx)
	local ws = dfhack.gui.getCurViewscreen()
	if ws._type ~= df.viewscreen_setupdwarfgamest then
		return
	end

	ws.show_play_now = 1

	if idx == -1 then
		ws.choice = 0
	elseif idx >= 0 and idx < #ws.choices - 2 then
		ws.choice = idx + 2
	else
		return
	end

    --native.set_timer(1, 'embark_play_go')

    gui.simulateInput(ws, 'SELECT')

	local ws = dfhack.gui.getCurViewscreen()

	--todo: should send these issues to the app, should not just accept as is !!
	if ws._type == df.viewscreen_setupdwarfgamest and (istrue(ws.in_problems) or ws.points_remaining > 0) then
		ws.in_problems = 0
		ws.points_remaining = 0
		gui.simulateInput(ws, 'SETUP_EMBARK')
		ws = dfhack.gui.getCurViewscreen()
	end

    if ws._type == df.viewscreen_textviewerst then
    	local text = ''
    	for i,v in ipairs(ws.formatted_text) do
	    	text = text .. dfhack.df2utf(charptr_to_string(v.text)) .. ' '
	    end
	    text = text:gsub('%s+', ' ')

        local title = ws.title
        title = title:gsub("^%s+", ""):gsub("%s+$", "")

	    return { title, text }
	end

	return { '' }
end

function embark_back_to_map()
	local ws = dfhack.gui.getCurViewscreen()
	if ws._type ~= df.viewscreen_setupdwarfgamest then
		error('wrong screen')
	end

	ws.parent.breakdown_level = 0
	ws.breakdown_level = 2
end

