local function get_load_game_screen()
    -- Always return to title and open load screen to force reload folders
    
    -- Check that we're on title screen or its subscreens
    local ws = screen_main()
    if ws._type ~= df.viewscreen_titlest then
        return nil
    end

    -- Return to title screen
    local ws2 = dfhack.gui.getCurViewscreen()
    while ws2 and ws2.parent and ws2 ~= ws do
        local parent = ws2.parent
        -- parent.child = nil
        -- ws2:delete()
        ws2.breakdown_level = df.interface_breakdown_types.STOPSCREEN
        ws2 = parent
    end
    
    local titlews = ws --as:df.viewscreen_titlest
    titlews.breakdown_level = df.interface_breakdown_types.NONE --todo: why was this needed?

    titlews.menu_line_id:insert(0, 0)
    titlews.sel_subpage = df.viewscreen_titlest.T_sel_subpage.None
    titlews.sel_menu_line = 0
    gui.simulateInput(titlews, K'SELECT')
    titlews.menu_line_id:erase(0)

    -- This is to deal with the custom dfhack load screen
    ws = dfhack.gui.getCurViewscreen()
    while ws and ws.parent and ws._type ~= df.viewscreen_loadgamest do
        ws = ws.parent
    end

    return ws
end

local function refresh_saves()
    local ws = screen_main()
    if ws._type ~= df.viewscreen_titlest then
        return
    end

    -- Return to title screen
    local ws2 = dfhack.gui.getCurViewscreen()
    while ws2 and ws2.parent and ws2 ~= ws do
        local parent = ws2.parent
        -- parent.child = nil
        -- ws2:delete()
        ws2.breakdown_level = df.interface_breakdown_types.STOPSCREEN
        ws2 = parent
    end
    
    -- This code will cause title screen to be recreated
    local worldgenws = df.viewscreen_new_regionst:new()
    worldgenws.simple_mode = 1
    
    worldgenws.parent = ws
    ws.child = worldgenws
    ws.breakdown_level = 2
    
    gui.simulateInput(worldgenws, K'LEAVESCREEN')

    return true
end


--luacheck: in=
function savegames_list()
    local ws,nogames = get_load_game_screen() --as:df.viewscreen_loadgamest
    if not ws then
        if nogames then
            return {}
        else
            return nil
        end
    end
    
    local ret = {}
    for i,s in ipairs(ws.saves) do
        local t = s.game_type
        if t == df.game_type.DWARF_MAIN or t == df.game_type.DWARF_RECLAIM or t == df.game_type.DWARF_UNRETIRE then
            table.insert(ret, { dfhack.df2utf(s.fort_name), dfhack.df2utf(s.world_name), s.year, s.folder_name, t })
        end
    end

    return ret
end

--luacheck: in=string
function savegame_load(folder)
    local ws = get_load_game_screen() --as:df.viewscreen_loadgamest
    if not ws then
        return
    end

    for i,s in ipairs(ws.saves) do
        if s.folder_name == folder then
            ws.sel_idx = i
            gui.simulateInput(ws, K'SELECT')

            return true
        end
    end
end

--luacheck: in=
function savegame_checkloaded()
    local ws = screen_main()

    if ws._type == df.viewscreen_dwarfmodest or ws._type == df.viewscreen_dungeonmodest then
        return true
    end

    return false
end

--luacheck: in=string
function savegame_delete(folder)
end

--luacheck: in=
function worlds_get_empty()
    --todo: should not do this all the time?
    refresh_saves()
    
    local ws = screen_main() --as:df.viewscreen_titlest
    if ws._type ~= df.viewscreen_titlest then
        return nil
    end

    local ret = {}
    for i,v in ipairs(ws.start_savegames) do
        local folder = v.save_dir
        local name = dfhack.df2utf(v.world_name_str)

        table.insert(ret, { name, folder })
    end

    return ret
end

worldgen_params = nil

--luacheck: in=number[]
function create_new_world(params)
    if #params ~= 7 then
        return
    end

    -- Check that we're on title screen or its subscreens
    local ws = screen_main()
    if ws._type ~= df.viewscreen_titlest then
        return nil
    end

    -- Return to title screen
    local ws2 = dfhack.gui.getCurViewscreen()
    while ws2 and ws2.parent and ws2 ~= ws do
        local parent = ws2.parent
        -- parent.child = nil
        -- ws2:delete()
        ws2.breakdown_level = df.interface_breakdown_types.STOPSCREEN
        ws2 = parent
    end
    
    local titlews = ws --as:df.viewscreen_titlest
    titlews.breakdown_level = df.interface_breakdown_types.NONE --todo: why was this needed?

    titlews.menu_line_id:insert(0, 2)
    titlews.sel_subpage = df.viewscreen_titlest.T_sel_subpage.None
    titlews.sel_menu_line = 0
    gui.simulateInput(titlews, K'SELECT')
    titlews.menu_line_id:erase(0)

    worldgen_params = params

    --todo: temporary
    df.global.world.worldgen_status.state = 0    

    native.set_timer(2, 'progress_worldgen')
end

--luacheck: in=
function progress_worldgen()
    local ws = dfhack.gui.getCurViewscreen() --as:df.viewscreen_new_regionst

    if ws._type ~= df.viewscreen_new_regionst then
        print('check', ws._type)
        worldgen_params = nil
        return
    end    

    -- If finished loading raws, start worldgen with the requested parameters
    if not istrue(ws.load_world_params) then
        -- Close 'Welcome to ...' message
        if #ws.welcome_msg > 0 then
            gui.simulateInput(ws, K'LEAVESCREEN')
        end    

        --xxx: the second condition is for the advanced worldgen mode which isn't supported
        if istrue(ws.simple_mode) or istrue(ws.in_worldgen) then
            if worldgen_params then
                local world_size, history, number_civs, number_sites, number_beasts, savagery, mineral_occurence = table.unpack(worldgen_params)
                ws.world_size = world_size
                ws.history = history
                ws.number_civs = number_civs
                ws.number_beasts = number_beasts
                ws.savagery = savagery
                ws.mineral_occurence = mineral_occurence

                gui.simulateInput(ws, K'MENU_CONFIRM')
                worldgen_params = nil
            end

            return
        end    
    end

    native.set_timer(2, 'progress_worldgen')
end
