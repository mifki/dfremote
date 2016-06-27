function get_load_game_screen()
    local ws = dfhack.gui.getCurViewscreen()

    if ws._type == df.viewscreen_loadgamest then
        return ws
    end

    -- Check that we're on title screen or its subscreens
    while ws and ws.parent and ws._type ~= df.viewscreen_titlest do
        ws = ws.parent
    end
    if ws._type ~= df.viewscreen_titlest then
        return nil
    end

    -- Return to title screen
    ws = dfhack.gui.getCurViewscreen()
    while ws and ws.parent and ws._type ~= df.viewscreen_titlest do
        local parent = ws.parent
        parent.child = nil
        ws:delete()
        ws = parent
    end
    ws.breakdown_level = df.interface_breakdown_types.NONE
    
    local titlews = ws --as:df.viewscreen_titlest
    
    if #titlews.arena_savegames-#titlews.start_savegames == 1 then
        return nil, true
    end

    titlews.sel_subpage = df.viewscreen_titlest.T_sel_subpage.None
    titlews.sel_menu_line = 0
    gui.simulateInput(titlews, 'SELECT')

    -- This is to deal with the custom dfhack load screen
    ws = dfhack.gui.getCurViewscreen()
    while ws and ws.parent and ws._type ~= df.viewscreen_loadgamest do
        ws = ws.parent
    end

    return ws
end

--luacheck: in=
function savegame_list()
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
            gui.simulateInput(ws, 'SELECT')

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
    local ws = dfhack.gui.getCurViewscreen()

    -- Check that we're on title screen or its subscreens
    while ws and ws.parent and ws._type ~= df.viewscreen_titlest do
        ws = ws.parent
    end
    if ws._type ~= df.viewscreen_titlest then
        return nil
    end

    -- Get the title screen
    ws = dfhack.gui.getCurViewscreen()
    while ws and ws.parent and ws._type ~= df.viewscreen_titlest do
        ws = ws.parent
    end

    local titlews = ws --as:df.viewscreen_titlest
    local ret = {}

    for i,v in ipairs(titlews.start_savegames) do
        local folder = v.save_dir
        local name = dfhack.df2utf(v.world_name_str)

        table.insert(ret, { name, folder })
    end

    return ret
end

worldgen_params = nil

function create_new_world(params)
    if #params ~= 7 then
        return
    end

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

    ws.sel_subpage = 0
    -- whether there's a 'continue playing' and/or 'start playing' menu items
    ws.sel_menu_line = (#ws.arena_savegames-#ws.start_savegames > 1 and 1 or 0) + (#ws.start_savegames > 0 and 1 or 0)
    gui.simulateInput(ws, 'SELECT')

    worldgen_params = params

    --todo: temporary
    df.global.world.worldgen_status.state = 0    

    native.set_timer(2, 'progress_worldgen')
end

function progress_worldgen()
    local ws = dfhack.gui.getCurViewscreen()
    print('check', ws._type)

    if ws._type ~= df.viewscreen_new_regionst then
        worldgen_params = nil
        return
    end    

    -- If finished loading raws
    if ws.unk_b4 == 0 then
        -- Close 'Welcome to ...' message
        if #ws.welcome_msg > 0 then
            gui.simulateInput(ws, 'LEAVESCREEN')
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

                gui.simulateInput(ws, 'MENU_CONFIRM')
                worldgen_params = nil
            end

            return
        end    
    end

    native.set_timer(2, 'progress_worldgen')
end
