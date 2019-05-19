void render_remote_world_map()
{
    // render_mutex.lock();
    // rendering_remote_map = true;

    // uint8_t menu_width, area_map_width;
    // Gui::getMenuWidth(menu_width, area_map_width);

    // gmenu_w = get_menu_width();

    int w = world->world_data->world_width, h = world->world_data->world_height;

    int tdimx = gps->dimx;
    int tdimy = gps->dimy;

    uint8_t *sctop                     = gps->screen;

    gps->screen       = world_map;
    gps->screen_limit = gscreen + w * h * 4;

    init->display.grid_x = w;
    init->display.grid_y = h;
    gps->dimx = w;
    gps->dimy = h;
    gps->clipx[1] = w;
    gps->clipy[1] = h;

    // waiting_render = true;

    // gwindow_x = *df::global::window_x = wx;
    // gwindow_y = *df::global::window_y = wy;
    // gwindow_z = *df::global::window_z = std::max(0, std::min(*df::global::window_z, world->map.z_count-1));

    // memset(gscreen_under, 0, curwidth*curheight*sizeof(uint32_t));
    // screen_under_ptr = gscreen_under;
    // screen_ptr = gscreen;        
    // mwindow_x = gwindow_x;

    // if (maxlevels > 1 && *df::global::window_z > 0)
    //     patch_rendering(false);

    render_world_map(world->world_data, 0, 0, 0, 0, w, h, 0, 0, 0, 0, 0, 0);

    // waiting_render = false;

    init->display.grid_x = gps->dimx = tdimx;
    init->display.grid_y = gps->dimy = tdimy;
    gps->clipx[1] = gps->dimx - 1;
    gps->clipy[1] = gps->dimy - 1;

    gps->screen = enabler->renderer->screen = sctop;
    gps->screen_limit = gps->screen + gps->dimx * gps->dimy * 4;

    // rendering_remote_map = false;
    // render_mutex.unlock();
}


struct civlist_hook : public df::viewscreen_civlistst
{
    typedef df::viewscreen_civlistst interpose_base;

    DEFINE_VMETHOD_INTERPOSE(void, render, ())
    {
        INTERPOSE_NEXT(render)();

        render_remote_world_map();
    }
};

IMPLEMENT_VMETHOD_INTERPOSE_PRIO(civlist_hook, render, -300);
