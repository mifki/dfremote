#define MAX_LEVELS_RENDER_EVER 30

int get_menu_width()
{
    uint8_t menu_width, area_map_width;
    Gui::getMenuWidth(menu_width, area_map_width);
    int32_t menu_w = 0;

    bool menuforced = (ui->main.mode != df::ui_sidebar_mode::Default || df::global::cursor->x != -30000);

    if ((menuforced || menu_width == 1) && area_map_width == 2) // Menu + area map
        menu_w = 55;
    else if (menu_width == 2 && area_map_width == 2) // Area map only
        menu_w = 24;
    else if (menu_width == 1) // Wide menu
        menu_w = 55;
    else if (menuforced || (menu_width == 2 && area_map_width == 3)) // Menu only
        menu_w = 31; 

    return menu_w;
}

void render_remote_map()
{
    render_mutex.lock();
    rendering_remote_map = true;

    uint8_t menu_width, area_map_width;
    Gui::getMenuWidth(menu_width, area_map_width);

    gmenu_w = get_menu_width();

    int tdimx = gps->dimx;
    int tdimy = gps->dimy;

    uint8_t *sctop                     = gps->screen;
    TEXPOS_TYPE *screentexpostop       = gps->screentexpos;
    int8_t *screentexpos_addcolortop   = gps->screentexpos_addcolor;
    uint8_t *screentexpos_grayscaletop = gps->screentexpos_grayscale;
    uint8_t *screentexpos_cftop        = gps->screentexpos_cf;
    uint8_t *screentexpos_cbrtop       = gps->screentexpos_cbr;

    // In fort mode render_map() will render starting at (1,1)
    // and will use dimensions from init->display.grid to calculate map region to render
    // but dimensions from gps to calculate offsets into screen buffer.
    // So we adjust all this so that it renders to our gdimx x gdimy buffer starting at (0,0).
    gps->screen       = gscreen - 4*newheight - 4;
    gps->screen_limit = gscreen + newwidth * newheight * 4;
    gps->screentexpos           = gscreentexpos           - newheight - 1;
    gps->screentexpos_addcolor  = gscreentexpos_addcolor  - newheight - 1;
    gps->screentexpos_grayscale = gscreentexpos_grayscale - newheight - 1;
    gps->screentexpos_cf        = gscreentexpos_cf        - newheight - 1;
    gps->screentexpos_cbr       = gscreentexpos_cbr       - newheight - 1;

    init->display.grid_x = newwidth + gmenu_w + 2;
    init->display.grid_y = newheight + 2;
    gps->dimx = curwidth = newwidth;
    gps->dimy = curheight = newheight;
    gps->clipx[1] = curwidth;
    gps->clipy[1] = curheight;

    waiting_render = true;

    gwindow_x = *df::global::window_x = wx;
    gwindow_y = *df::global::window_y = wy;
    gwindow_z = *df::global::window_z = std::max(0, std::min(*df::global::window_z, world->map.z_count-1));

    memset(gscreen_under, 0, curwidth*curheight*sizeof(uint32_t));
    screen_under_ptr = gscreen_under;
    screen_ptr = gscreen;        
    mwindow_x = gwindow_x;

    if (maxlevels > 1 && *df::global::window_z > 0)
        patch_rendering(false);

    render_map();

    if (maxlevels > 1 && *df::global::window_z > 0)
    {
        gps->screen                 = mscreen                 - 4*curheight - 4;
        gps->screen_limit           = mscreen                 + curwidth * curheight * 4;
        gps->screentexpos           = mscreentexpos           - curheight - 1;
        gps->screentexpos_addcolor  = mscreentexpos_addcolor  - curheight - 1;
        gps->screentexpos_grayscale = mscreentexpos_grayscale - curheight - 1;
        gps->screentexpos_cf        = mscreentexpos_cf        - curheight - 1;
        gps->screentexpos_cbr       = mscreentexpos_cbr       - curheight - 1;

        // memset(mscreen_under, 0, curwidth*curheight*sizeof(uint32_t));
        screen_under_ptr = mscreen_under;
        screen_ptr = mscreen;

        bool lower_level_rendered = false;
        int p = 1;
        int x0 = 0;
        int zz0 = *df::global::window_z; // Current "top" zlevel
        int maxp = std::min(maxlevels-1, zz0);   

        do
        {
            (*df::global::window_z)--;

            lower_level_rendered = false;
            int x00 = x0;
            int zz = zz0 - p + 1; // Last rendered zlevel in gscreen, the tiles of which we're checking below

            int x1 = std::min(curwidth, world->map.x_count-*df::global::window_x);
            int y1 = std::min(curheight, world->map.y_count-*df::global::window_y);
            bool empty_tiles_left = false;
            for (int x = x0; x < x1; x++)
            {
                for (int y = 0; y < y1; y++)
                {
                    const int tile = x * curheight + y, stile = tile * 4;

                    unsigned char ch = gscreen[stile+0];
                    if (ch != 0 && ch != 31)
                        continue;

                    int xx = *df::global::window_x + x;
                    int yy = *df::global::window_y + y;
                    if (xx < 0 || yy < 0)
                        continue;

                    //TODO: bring this back
                    // bool must_render_tile = (p < maxp || !rendered_tiles[zz*256*256 + xx+yy*256]);
                    // if (!must_render_tile)
                    //     continue;

                    int xxquot = xx >> 4, xxrem = xx & 15;
                    int yyquot = yy >> 4, yyrem = yy & 15;                    

                    // If the tile looks like a ramp, check that it's really a ramp
                    // Also, no need to go deeper if the ramp is covered with water
                    if (ch == 31)
                    {
                        df::map_block *block0 = world->map.block_index[xxquot][yyquot][zz];
                        if (block0->tiletype[xxrem][yyrem] != df::tiletype::RampTop || block0->designation[xxrem][yyrem].bits.flow_size)
                            continue;
                    }

                    // If the tile is empty, render the next zlevel (if not rendered already)
                    if (!lower_level_rendered)
                    {
                        // All tiles to the left were not empty, so skip them
                        x0 = x;

                        (*df::global::window_x) += x0;
                        init->display.grid_x -= x0;
                        mwindow_x = gwindow_x + x0;

                        memset(mscreen_under, 0, (curwidth-x0)*curheight*sizeof(uint32_t));
                        render_map();

                        (*df::global::window_x) -= x0;
                        init->display.grid_x += x0;

                        x00 = x0;

                        lower_level_rendered = true;
                    }

                    const int tile2 = (x-(x00)) * curheight + y, stile2 = tile2 * 4;

                    int d = p;
                    ch = mscreen[stile2+0];

                    // Special checks to ensure there are no certain tiles left on the last level
                    if (p == maxp && p < MAX_LEVELS_RENDER_EVER)
                    {
                        // If there's still no tile and it has never been rendered, go deeper
                        if (ch == 0)
                        {
                            // mscreen[stile2+0] = 1;
                            if (!rendered_tiles[zz*256*256 + xx+yy*256])
                            {
                                maxp = p + 1;
                                x0 = x;
                            }
                        }

                        // If it's a ramp top, just change it to a ramp on the lower level
                        // We don't care about missing a unit or an item on slope that deep
                        else if (ch == 31)
                        {
                            df::map_block *block1 = world->map.block_index[xxquot][yyquot][zz-1];
                            df::tiletype t1 = block1->tiletype[xxrem][yyrem];
                            if (t1 == df::tiletype::RampTop && !block1->designation[xxrem][yyrem].bits.flow_size)
                            {
                                mscreen[stile2+0] = 30;
                                d++;
                            }
                        }
                    }

                    *((int*)gscreen + tile) = *((int*)mscreen + tile2);
                    *((uint32_t*)gscreen_under + tile) = *((uint32_t*)mscreen_under + tile2);
                    if (*(mscreentexpos+tile2))
                    {
                        *(gscreentexpos + tile) = *(mscreentexpos + tile2);
                        *(gscreentexpos_addcolor + tile) = *(mscreentexpos_addcolor + tile2);
                        *(gscreentexpos_grayscale + tile) = *(mscreentexpos_grayscale + tile2);
                        *(gscreentexpos_cf + tile) = *(mscreentexpos_cf + tile2);
                        *(gscreentexpos_cbr + tile) = *(mscreentexpos_cbr + tile2);
                    }
                    gscreen[stile+3] = (d << 1) | (gscreen[stile+3]&1);
                }
            }

            if (p == maxp)
                break;
            p++;
        } while(lower_level_rendered);

        (*df::global::window_z) = zz0;

        patch_rendering(true);            
    }

    waiting_render = false;

    init->display.grid_x = gps->dimx = tdimx;
    init->display.grid_y = gps->dimy = tdimy;
    gps->clipx[1] = gps->dimx - 1;
    gps->clipy[1] = gps->dimy - 1;

    gps->screen = enabler->renderer->screen = sctop;
    gps->screen_limit = gps->screen + gps->dimx * gps->dimy * 4;
    gps->screentexpos           = screentexpostop;
    gps->screentexpos_addcolor  = screentexpos_addcolortop;
    gps->screentexpos_grayscale = screentexpos_grayscaletop;
    gps->screentexpos_cf        = screentexpos_cftop;
    gps->screentexpos_cbr       = screentexpos_cbrtop;

    rendering_remote_map = false;
    render_mutex.unlock();
}


struct dwarfmode_hook : public df::viewscreen_dwarfmodest
{
    typedef df::viewscreen_dwarfmodest interpose_base;

    DEFINE_VMETHOD_INTERPOSE(void, feed, (std::set<df::interface_key> *input))
    {
        // The game will try to make sure cursor is visible and not near the edge of the screen
        // Some operations will fail if we don't do that ourselves beforehand
        if (df::global::ui->main.mode > 0 && df::global::cursor->x != -30000)
        {
            int mapw = init->display.grid_x - get_menu_width() - 2;
            int maph = init->display.grid_y - 2;
            int oldwx = *df::global::window_x;
            int oldwy = *df::global::window_y;

            *df::global::window_x = std::max(0, std::min(df::global::cursor->x - 10, df::global::world->map.x_count-mapw));
            *df::global::window_y = std::max(0, std::min(df::global::cursor->y - 10, df::global::world->map.y_count-maph));

            INTERPOSE_NEXT(feed)(input);

            *df::global::window_x = oldwx;
            *df::global::window_y = oldwy;
        }
        else
            INTERPOSE_NEXT(feed)(input);
    }

    DEFINE_VMETHOD_INTERPOSE(void, render, ())
    {
        INTERPOSE_NEXT(render)();

        Screen::fillRect(Screen::Pen(' ', 4, 4, false), 0, gps->dimy-2, gps->dimx-1, gps->dimy-1);

        char s0[] = "This fortress is controlled with DF Remote.";
        Screen::paintString(Screen::Pen(' ', 15, 4), 2, gps->dimy-2, s0);

        if (client_peer)
        {
            char s1[] = "Client connected from";
            Screen::paintString(Screen::Pen(' ', 15, 4), 2+sizeof(s0), gps->dimy-2, s1);
            Screen::paintString(Screen::Pen(' ', 10, 4), 2+sizeof(s0)+sizeof(s1), gps->dimy-2, client_addr);
            Screen::paintString(Screen::Pen(' ', 14, 4), 2, gps->dimy-1, "Do not interact with the game directly when DF Remote is active.");
        }
        else if (publish_name.size())
        {
            char s3[] = "Server name";
            Screen::paintString(Screen::Pen(' ', 15, 4), 2, gps->dimy-1, s3);
            Screen::paintString(Screen::Pen(' ', 10, 4), 2+sizeof(s3), gps->dimy-1, publish_name);
        }

        if (map_render_enabled || render_initial)
        {
            render_remote_map();
            render_initial = false;
        }
    }
};

IMPLEMENT_VMETHOD_INTERPOSE_PRIO(dwarfmode_hook, render, -300);
IMPLEMENT_VMETHOD_INTERPOSE_PRIO(dwarfmode_hook, feed, -300);
