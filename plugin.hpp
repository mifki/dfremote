DFHACK_PLUGIN("remote");

DFHACK_PLUGIN_LUA_FUNCTIONS {
    DFHACK_LUA_FUNCTION(itemcache_init),
    DFHACK_LUA_FUNCTION(itemcache_free),
    DFHACK_LUA_FUNCTION(itemcache_get),
    DFHACK_LUA_FUNCTION(itemcache_get_category),
    DFHACK_LUA_FUNCTION(itemcache_search),
    DFHACK_LUA_FUNCTION(set_timer),
    DFHACK_LUA_FUNCTION(verify_pwd),
    DFHACK_LUA_FUNCTION(check_wtoken),
    DFHACK_LUA_FUNCTION(update_wtoken),
    DFHACK_LUA_FUNCTION(start_update),
    DFHACK_LUA_FUNCTION(custom_command),
    DFHACK_LUA_END
};


void allocate_buffers(int tiles)
{
#define REALLOC(var,type,count) var = (type*)realloc(var, count * sizeof(type));

    REALLOC(gscreen,                 uint8_t, tiles * 4)
    REALLOC(gscreentexpos,           int32_t, tiles);
    REALLOC(gscreentexpos_addcolor,  int8_t,  tiles);
    REALLOC(gscreentexpos_grayscale, uint8_t, tiles);
    REALLOC(gscreentexpos_cf,        uint8_t, tiles);
    REALLOC(gscreentexpos_cbr,       uint8_t, tiles);

    REALLOC(mscreen,                 uint8_t, tiles * 4)
    REALLOC(mscreentexpos,           int32_t, tiles);
    REALLOC(mscreentexpos_addcolor,  int8_t,  tiles);
    REALLOC(mscreentexpos_grayscale, uint8_t, tiles);
    REALLOC(mscreentexpos_cf,        uint8_t, tiles);
    REALLOC(mscreentexpos_cbr,       uint8_t, tiles);

    // We need to zero out these buffers because game doesn't change them for tiles without creatures,
    // so there will be garbage that will cause every tile to be updated each frame and other bad things
    memset(gscreen,                 0, tiles * 4);
    memset(gscreentexpos,           0, tiles * sizeof(int32_t));
    memset(gscreentexpos_addcolor,  0, tiles);
    memset(gscreentexpos_grayscale, 0, tiles);
    memset(gscreentexpos_cf,        0, tiles);
    memset(gscreentexpos_cbr,       0, tiles);
}


DFhackCExport command_result plugin_init ( color_ostream &out, vector <PluginCommand> &commands)
{
    out2 = &out;
    allocate_buffers(256*256);

    #ifdef WIN32
        _render_map = (RENDER_MAP) (A_RENDER_MAP + Core::getInstance().vinfo->getRebaseDelta());
    #elif defined(__APPLE__)
        _render_map = (RENDER_MAP) A_RENDER_MAP;
    #else
        _render_map = (RENDER_MAP) A_RENDER_MAP;
    #endif

    L = Lua::Open(*out2, NULL);
    if (!remote_print_version())
        return CR_OK;
       
    commands.push_back(PluginCommand(
        "remote", "Dwarf Fortress Remote Server (mifki.com/df)",
        remote_cmd, false,
        "  on | off           - Enable or disable remote server\n"
        "  publish <name>     - Publish server to be accessible outside of local network\n"
        "  unpublish          - Stop publishing server"
        "  port <number>      - Change port number (default is 1235)\n"
        "  pwd                - Set password required to connect\n"
        "  reload             - Reload Lua code (for developers)"
    ));

    if (load_config())
        remote_start();

    return CR_OK;
}

DFhackCExport command_result plugin_onstatechange(color_ostream &out, state_change_event event)
{
    // If user (un)loaded game on server manually, we need to disconnect client, but we can't destinguish this
    // from normal (un)load from the app, so not doing anything for now. TODO://

    if (event == SC_WORLD_LOADED)
    {
        gmenu_w = -1;
        generate_new_world_token();

        wx = *df::global::window_x;
        wy = *df::global::window_y;
    }

    return CR_OK;
}

DFhackCExport command_result plugin_shutdown ( color_ostream &out )
{
    enet_deinitialize();
    remote_stop();

    return CR_OK;//FAILURE;

    /*if (enabled)
        restore_renderer();

    return CR_OK;*/
}