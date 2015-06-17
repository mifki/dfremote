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
        int menu_width = *df::global::ui_menu_width, area_map_width = *df::global::ui_area_map_width;

        //*df::global::ui_menu_width = 3;
        //*df::global::ui_area_map_width = 3;
        gmenu_w = get_menu_width();

        int tdimx = gps->dimx;
        int tdimy = gps->dimy;

        uint8_t *sctop                     = enabler->renderer->screen;
        int32_t *screentexpostop           = enabler->renderer->screentexpos;
        int8_t *screentexpos_addcolortop   = enabler->renderer->screentexpos_addcolor;
        uint8_t *screentexpos_grayscaletop = enabler->renderer->screentexpos_grayscale;
        uint8_t *screentexpos_cftop        = enabler->renderer->screentexpos_cf;
        uint8_t *screentexpos_cbrtop       = enabler->renderer->screentexpos_cbr;

        // In fort mode render_map() will render starting at (1,1)
        // and will use dimensions from init->display.grid to calculate map region to render
        // but dimensions from gps to calculate offsets into screen buffer.
        // So we adjust all this so that it renders to our gdimx x gdimy buffer starting at (0,0).
        gps->screen                 = enabler->renderer->screen                 = gscreen - 4*newheight - 4;
        gps->screen_limit           = gscreen + newwidth * newheight * 4;
        gps->screentexpos           = enabler->renderer->screentexpos           = gscreentexpos           - newheight - 1;
        gps->screentexpos_addcolor  = enabler->renderer->screentexpos_addcolor  = gscreentexpos_addcolor  - newheight - 1;
        gps->screentexpos_grayscale = enabler->renderer->screentexpos_grayscale = gscreentexpos_grayscale - newheight - 1;
        gps->screentexpos_cf        = enabler->renderer->screentexpos_cf        = gscreentexpos_cf        - newheight - 1;
        gps->screentexpos_cbr       = enabler->renderer->screentexpos_cbr       = gscreentexpos_cbr       - newheight - 1;

        init->display.grid_x = newwidth + gmenu_w + 2;
        init->display.grid_y = newheight + 2;
        gps->dimx = newwidth;
        gps->dimy = newheight;
        gps->clipx[1] = newwidth;
        gps->clipy[1] = newheight;

        waiting_render = true;

        gwindow_x = *df::global::window_x = wx;
        gwindow_y = *df::global::window_y = wy;
        gwindow_z = *df::global::window_z = std::max(0, std::min(*df::global::window_z, world->map.z_count-1));
        //*out2 << "rendering " << gwindow_x << " " << gwindow_y << std::endl;
        render_map();
        waiting_render = false;

        //*df::global::ui_menu_width = menu_width;
        //*df::global::ui_area_map_width = area_map_width;        

        init->display.grid_x = gps->dimx = tdimx;
        init->display.grid_y = gps->dimy = tdimy;
        gps->clipx[1] = gps->dimx - 1;
        gps->clipy[1] = gps->dimy - 1;

        gps->screen = enabler->renderer->screen = sctop;
        gps->screen_limit = gps->screen + gps->dimx * gps->dimy * 4;
        gps->screentexpos = enabler->renderer->screentexpos = screentexpostop;
        gps->screentexpos_addcolor = enabler->renderer->screentexpos_addcolor = screentexpos_addcolortop;
        gps->screentexpos_grayscale = enabler->renderer->screentexpos_grayscale = screentexpos_grayscaletop;
        gps->screentexpos_cf = enabler->renderer->screentexpos_cf = screentexpos_cftop;
        gps->screentexpos_cbr = enabler->renderer->screentexpos_cbr = screentexpos_cbrtop;
}


struct dwarfmode_hook2 : public df::viewscreen_dwarfmodest
{
    typedef df::viewscreen_dwarfmodest interpose_base;


    DEFINE_VMETHOD_INTERPOSE(void, render, ())
    {
        INTERPOSE_NEXT(render)();
        /*if (force_render_ui)
            INTERPOSE_NEXT(render)();
        else
            memset(gps->screen, 32, gps->dimx*gps->dimy*4);

        int y = 2;
        Screen::paintString(Screen::Pen(' ', 15, 0), 2, y, "This fortress is controlled with DF Remote.");
        y += 2;

        if (publish_name.size())
        {
            char s1[] = "Use the name";
            char s2[] = "to connect to this server.";
            Screen::paintString(Screen::Pen(' ', 15, 0), 2, y, s1);
            Screen::paintString(Screen::Pen(' ', 2+8, 0), 2+sizeof(s1), y, publish_name);
            Screen::paintString(Screen::Pen(' ', 15, 0), 2+sizeof(s1)+publish_name.size()+1, y, s2);
            y += 2;
        }*/

        Screen::fillRect(Screen::Pen(' ', 4, 4, false), 0, gps->dimy-2, gps->dimx-1, gps->dimy-1);

        char s0[] = "This fortress is controlled with DF Remote.";
        Screen::paintString(Screen::Pen(' ', 15, 4), 1, gps->dimy-2, s0);

        if (client_peer)
        {
            char s1[] = "Client connected from";
            Screen::paintString(Screen::Pen(' ', 15, 4), 1+sizeof(s0), gps->dimy-2, s1);
            Screen::paintString(Screen::Pen(' ', 10, 4), 1+sizeof(s0)+sizeof(s1), gps->dimy-2, client_addr);
            Screen::paintString(Screen::Pen(' ', 14, 4), 1, gps->dimy-1, "Do not interact with the game directly when DF Remote is active.");
        }
        else if (publish_name.size())
        {
            //char s1[] = "Use the name";
            //char s2[] = "to connect to this server.";
            char s3[] = "Server name";
            Screen::paintString(Screen::Pen(' ', 15, 4), 2, gps->dimy-1, s3);
            Screen::paintString(Screen::Pen(' ', 10, 4), 2+sizeof(s3), gps->dimy-1, publish_name);
            //Screen::paintString(Screen::Pen(' ', 15, 0), 2+sizeof(s1)+publish_name.size()+1, gps->dimy-1, s2);
        }

        if (map_render_enabled || render_initial)
        {
            render_remote_map();
            render_initial = false;
        }
    }
};

IMPLEMENT_VMETHOD_INTERPOSE_PRIO(dwarfmode_hook2, render, 300);
