local designations = { --as:{1:string,2:string,3:number,4:"{1:string,2:string,3:number}[]"}[]
    { 'Mine', 'd', df.interface_key.DESIGNATE_DIG },
    { 'Channel', 'h', df.interface_key.DESIGNATE_CHANNEL },
    { 'Up Ramp', 'r', df.interface_key.DESIGNATE_RAMP },
    { 'Up Stair', 'u', df.interface_key.DESIGNATE_STAIR_UP },
    { 'Down Stair', 'j', df.interface_key.DESIGNATE_STAIR_DOWN },
    { 'Up-Down Stair', 'i', df.interface_key.DESIGNATE_STAIR_UPDOWN },
    { 'Chop Down Trees', 't', df.interface_key.DESIGNATE_CHOP },
    { 'Gather Plants', 'p', df.interface_key.DESIGNATE_PLANTS },
    { 'Smooth Stone', 's', df.interface_key.DESIGNATE_SMOOTH },
    { 'Engrave Stone', 'e', df.interface_key.DESIGNATE_ENGRAVE },
    { 'Carve Fortifications', 'F', df.interface_key.DESIGNATE_FORTIFY },
    { 'Carve Track', 'T', df.interface_key.DESIGNATE_TRACK },
    { 'Toggle Engravings', 'v', df.interface_key.DESIGNATE_TOGGLE_ENGRAVING },
    --{ 'Toggle Standard / Marking', 'M', df.interface_key.DESIGNATE_TOGGLE_MARKER },

    { 'Item & Bld. Actions', 'b', df.interface_key.DESIGNATE_BITEM, {
        { 'Reclaim', 'c', df.interface_key.DESIGNATE_CLAIM },
        { 'Forbid', 'f', df.interface_key.DESIGNATE_UNCLAIM },
        { 'Melt', 'm', df.interface_key.DESIGNATE_MELT },
        { 'Remove Melt', 'M', df.interface_key.DESIGNATE_NO_MELT },
        { 'Dump', 'd', df.interface_key.DESIGNATE_DUMP },
        { 'Remove Dump', 'D', df.interface_key.DESIGNATE_NO_DUMP },
        { 'Hide', 'h', df.interface_key.DESIGNATE_HIDE },
        { 'Unhide', 'H', df.interface_key.DESIGNATE_NO_HIDE },
    } },

    { 'Set Traffic Areas', 'o', df.interface_key.DESIGNATE_TRAFFIC, {
        { 'High Traffic', 'h', df.interface_key.DESIGNATE_TRAFFIC_HIGH },
        { 'Normal Traffic', 'n', df.interface_key.DESIGNATE_TRAFFIC_NORMAL },
        { 'Low Traffic', 'l', df.interface_key.DESIGNATE_TRAFFIC_LOW },
        { 'Restricted', 'r', df.interface_key.DESIGNATE_TRAFFIC_RESTRICTED },
    } },

    { 'Remove\nDesignation', 'x', df.interface_key.DESIGNATE_UNDO },    
    { 'Remove\nUp Stairs & Ramps', 'z', df.interface_key.DESIGNATE_DIG_REMOVE_STAIRS_RAMPS },
    { 'Remove\nConstruction', 'n', df.interface_key.DESIGNATE_REMOVE_CONSTRUCTION },
    
    { 'Toggle Markers', 'M', df.interface_key.DESIGNATE_TOGGLE_MARKER },
}

--luacheck: in=
function setup_get_designations()
    local choices = {}

    STATE.designate_cmds = {}

    for i,v in ipairs(designations) do
        local sub = mp.NIL

        if v[4] then
            local subchoices = {}

            for j,w in ipairs(v[4]) do
                table.insert(STATE.designate_cmds, { v[3], w[3] })
                table.insert(subchoices, { w[1], w[2], #STATE.designate_cmds })
            end

            table.insert(choices, { v[1], v[2], subchoices })

        else
            table.insert(STATE.designate_cmds, { v[3] })
            table.insert(choices, { v[1], v[2], #STATE.designate_cmds })
        end

    end

    local data = {
        df.global.ui.main.traffic_cost_high,
        df.global.ui.main.traffic_cost_normal,
        df.global.ui.main.traffic_cost_low,
        df.global.ui.main.traffic_cost_restricted,
    }

    return { choices, data }
end        

local function get_choices_build()
    local choices = {}

    for i,choice in ipairs(df.global.ui_sidebar_menus.building.choices_all) do
        if choice._type == df.interface_button_construction_donest then
            break
        end

        local title = dfhack.df2utf(utils.call_with_string(choice, 'getLabel'):gsub(' %(%d+%)$', ''))
        local key = dfhack.screen.getKeyDisplay(choice.hotkey_id)
        if key == '?' then
            key = ''
        end
        
        if title == 'Traps/Levers' then
            title = 'Traps & Levers'
        elseif title == 'Up/Down Stair' then
            title = 'Up-Down Stair'
        elseif title == 'Wall/Floor/Stairs/Track' then
            title = 'Constructions\nWall, Floor, Stairs, ...'
        end

        --todo: don't try to clone for category buttons
        local btnclone = clone_build_button(choice)

        local subchoices = 0
        if choice._type == df.interface_button_construction_category_selectorst then
            local back = (choice.hotkey_id == 0)
            choice:click()
            if back then
                break
            end
            subchoices = get_choices_build()
        end

        table.insert(STATE.building_btns, btnclone or 0)
        table.insert(choices, { title, key, #STATE.building_btns, subchoices })
    end

    return choices            
end

--luacheck: in=
function setup_get_buildings()
    return execute_with_main_mode(0, function(ws)
        gui.simulateInput(ws, K'D_BUILDING')
        STATE.building_btns = {}
        return get_choices_build()
    end)
end

--todo: add a flag to return gamelist/worldgen detailed info straight away
--luacheck: in=string,string
function setup_get_server_info(clientver, pwd)
    --todo: no need to check pwd and match version if not foreign
    local ver = matching_version(clientver)

    if not native.verify_pwd(pwd or '') then
        return { ver, 'invalid-pwd' }
    end

    local ws = dfhack.gui.getCurViewscreen()

    -- Get rid of help and options screens
    if (ws._type == df.viewscreen_textviewerst and ws.page_filename:find('data/help/')) or ws._type == df.viewscreen_optionst then --hint:df.viewscreen_textviewerst
        local parent = ws.parent
        parent.child = nil
        ws:delete()
        ws = parent
    end

    -- Busy loading game
    if ws._type == df.viewscreen_loadgamest and istrue(ws.loading) then --hint:df.viewscreen_loadgamest
        return { ver, 'busy-loading-game' }
    end

    -- Busy updating world
    if ws._type == df.viewscreen_update_regionst then
        return { ver, 'busy-updating' }
    end

    -- Busy saving game
    if ws._type == df.viewscreen_savegamest or ws._type == df.viewscreen_export_regionst then
        return { ver, 'busy-saving' }
    end

    -- Busy unloading world
    if ws._type == df.viewscreen_game_cleanerst then
        return { ver, 'busy-unloading' }
    end

    -- Worldgen in progress (unlike other screens below, this screen is a child of the title screen)
    if ws._type == df.viewscreen_new_regionst then
        if worldgen_params or (not istrue(ws.simple_mode) and not istrue(ws.in_worldgen)) then --hint:df.viewscreen_new_regionst
            return { ver, 'worldgen' }
        end
    end

    ws = df.global.gview.view.child

    -- Dwarf mode
    --todo: handle 'abandoned' screen !!
    if ws._type == df.viewscreen_dwarfmodest then
        local site = df.world_site.find(df.global.ui.site_id)
        local site_name = site and string.utf8capitalize(dfhack.df2utf(dfhack.TranslateName(site.name))) or '#unknown site#'
        local world_name = string.utf8capitalize(dfhack.df2utf(dfhack.TranslateName(df.global.world.world_data.name)))

        return { ver, 'dwarfmode', site_name, world_name, df.global.cur_year, df.global.world.cur_savegame.save_dir }
    end

    -- Adventure mode
    if ws._type == df.viewscreen_dungeonmodest then
        return { ver, 'advmode' }
    end

    -- Embark preparations
    --todo: should return/show embark world/folder name
    if ws._type == df.viewscreen_choose_start_sitest then
        return { ver, 'embark' }
    end

    -- Legends mode
    if ws._type == df.viewscreen_legendsst then
        return { ver, 'legends' }
    end

    -- Title screen (or game list screen)
    if ws._type == df.viewscreen_titlest then
        return { ver, 'nogame' }
    end

    if ws._type == df.viewscreen_adopt_regionst then
        return { ver, 'busy-loading-world' }
    end

    --[[local line = ''
    for x = 1, df.global.gps.dimx-2 do
        local char = df.global.gps.screen[(x*df.global.gps.dimy+0)*4]
        if char ~= 0 and (char ~= 32 or (#line > 0 and line:byte(#line) ~= 32)) then
            line = line .. string.char(char)
        end
    end
    if line:find('Dwarf Fortress: Load World') then
        return { ver, 'busy-loading-world' }
    end]]

    return { ver, 'unknown' }
end

--luacheck: in=number
function setup_get_mapinfo(wtoken)
    local ws = screen_main()
    if ws._type ~= df.viewscreen_dwarfmodest then
        -- it's a common situation - app tries to connect to a game that has been closed
        if ws._type == df.viewscreen_titlest then
            return
        end
        
        error(errmsg_wrongscreen(ws))
    end

    --todo: detect world change here and reset cached designations, buildings, labors
    local matched = native.check_wtoken(wtoken)
    wtoken = native.update_wtoken()

    close_all()
    reset_main()

    if #df.global.world.status.announcements > 0 then
        lastann = df.global.world.status.announcements[#df.global.world.status.announcements-1].id
        lastannrep = df.global.world.status.announcements[#df.global.world.status.announcements-1].repeat_count
    else
        lastann = 0
    end

    local mapinfo = {
        df.global.window_x, df.global.window_y,
        df.global.world.map.x_count, df.global.world.map.y_count, df.global.world.map.z_count,
        df.global.world.map.region_z,
        df.global.window_z,
        matched, wtoken
    }

    --local ret = { mapinfo }

    return mapinfo
end

--luacheck: in=
function setup_get_settings()
    return { df.global.enabler.fps, df.global.enabler.calculated_fps }
end

--luacheck: in=number,number
function setup_set_setting(idx, value)
    if idx == 1 then
        if value < 10 then value = 10 end
        if value > 500 then value = 500 end

        df.global.enabler.fps = value
        return true
    end
end