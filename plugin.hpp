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
    //DFHACK_LUA_FUNCTION(init_dummy_gfx),
    DFHACK_LUA_END
};

void allocate_buffers(int tiles)
{
#define REALLOC(var,type,count) var = (type*)realloc(var, (count) * sizeof(type));

    int extra_tiles = 256 + 1;

    REALLOC(gscreen_origin,                 uint8_t, (tiles+extra_tiles) * 4)
    REALLOC(gscreentexpos_origin,           TEXPOS_TYPE, tiles+extra_tiles);
    REALLOC(gscreentexpos_addcolor_origin,  int8_t,  tiles+extra_tiles);
    REALLOC(gscreentexpos_grayscale_origin, uint8_t, tiles+extra_tiles);
    REALLOC(gscreentexpos_cf_origin,        uint8_t, tiles+extra_tiles);
    REALLOC(gscreentexpos_cbr_origin,       uint8_t, tiles+extra_tiles);

    REALLOC(mscreen_origin,                 uint8_t, (tiles+extra_tiles) * 4)
    REALLOC(mscreentexpos_origin,           TEXPOS_TYPE, tiles+extra_tiles);
    REALLOC(mscreentexpos_addcolor_origin,  int8_t,  tiles+extra_tiles);
    REALLOC(mscreentexpos_grayscale_origin, uint8_t, tiles+extra_tiles);
    REALLOC(mscreentexpos_cf_origin,        uint8_t, tiles+extra_tiles);
    REALLOC(mscreentexpos_cbr_origin,       uint8_t, tiles+extra_tiles);

    REALLOC(gscreen_under,                  uint8_t, tiles * 4);
    REALLOC(mscreen_under,                  uint8_t, tiles * 4);

    gscreen                 = gscreen_origin                 + extra_tiles * 4;
    gscreentexpos           = gscreentexpos_origin           + extra_tiles;
    gscreentexpos_addcolor  = gscreentexpos_addcolor_origin  + extra_tiles;
    gscreentexpos_grayscale = gscreentexpos_grayscale_origin + extra_tiles;
    gscreentexpos_cf        = gscreentexpos_cf_origin        + extra_tiles;
    gscreentexpos_cbr       = gscreentexpos_cbr_origin       + extra_tiles;

    mscreen                 = mscreen_origin                 + extra_tiles * 4;
    mscreentexpos           = mscreentexpos_origin           + extra_tiles;
    mscreentexpos_addcolor  = mscreentexpos_addcolor_origin  + extra_tiles;
    mscreentexpos_grayscale = mscreentexpos_grayscale_origin + extra_tiles;
    mscreentexpos_cf        = mscreentexpos_cf_origin        + extra_tiles;
    mscreentexpos_cbr       = mscreentexpos_cbr_origin       + extra_tiles;

    // We need to zero out these buffers because game doesn't change them for tiles without creatures,
    // so there will be garbage that will cause every tile to be updated each frame and other bad things
    memset(gscreen,                 0, tiles * 4);
    memset(gscreentexpos,           0, tiles * sizeof(TEXPOS_TYPE));
    memset(gscreentexpos_addcolor,  0, tiles);
    memset(gscreentexpos_grayscale, 0, tiles);
    memset(gscreentexpos_cf,        0, tiles);
    memset(gscreentexpos_cbr,       0, tiles);
    memset(mscreentexpos,           0, tiles * sizeof(long));
}

void free_buffers()
{
#define FREE(a) { free(a); a = NULL; }

    FREE(gscreen_origin);
    FREE(gscreentexpos_origin);
    FREE(gscreentexpos_addcolor_origin);
    FREE(gscreentexpos_grayscale_origin);
    FREE(gscreentexpos_cf_origin);
    FREE(gscreentexpos_cbr_origin);

    FREE(mscreen_origin);
    FREE(mscreentexpos_origin);
    FREE(mscreentexpos_addcolor_origin);
    FREE(mscreentexpos_grayscale_origin);
    FREE(mscreentexpos_cf_origin);
    FREE(mscreentexpos_cbr_origin);
}

DFhackCExport command_result plugin_init ( color_ostream &out, vector <PluginCommand> &commands)
{
    out2 = &out;
    allocate_buffers(256*256);
    rendered_tiles = (bool*)malloc(256*256*256*sizeof(bool));

    #ifdef WIN32
        _render_map = (RENDER_MAP) (A_RENDER_MAP + Core::getInstance().vinfo->getRebaseDelta());
    #elif defined(__APPLE__)
        _render_map = (RENDER_MAP) A_RENDER_MAP;
    #else
        _render_map = (RENDER_MAP) A_RENDER_MAP;
    #endif

    render_world_map = (RENDER_WORLD_MAP) A_RENDER_WORLD_MAP;

    L = Lua::Open(*out2, NULL);
    if (!remote_print_version())
        return CR_OK;
       
    commands.push_back(PluginCommand(
        "remote", "Dwarf Fortress Remote Server (mifki.com/df)",
        remote_cmd, false,
        "  on | off           - Enable or disable remote server\n"
        "  publish <name>     - Publish server to be accessible outside of local network\n"
        "  unpublish          - Stop publishing\n"
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

        world_map = REALLOC(world_map, uint8_t, df::global::world->world_data->world_width*df::global::world->world_data->world_height*4);
    }

    return CR_OK;
}

DFhackCExport command_result plugin_shutdown ( color_ostream &out )
{
    remote_stop();
    enet_deinitialize();
    free_buffers();
    free(world_map);
    free(rendered_tiles);
    lua_close(L);

    return CR_OK;
}