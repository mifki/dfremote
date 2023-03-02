#include "df/unit.h"

struct unit_hook : public df::unit
{
   typedef df::unit interpose_base;

    DEFINE_VMETHOD_INTERPOSE(uint8_t, getCreatureTile, ())
    {
        if (rendering_remote_map && !this->flags1.bits.inactive)
        {
            df::coord _pos = Units::getPosition(this);

            if (df::global::cursor->x != _pos.x || df::global::cursor->y != _pos.y || df::global::cursor->z != _pos.z || ui->main.mode == df::ui_sidebar_mode::Default)
                if (pos.x-mwindow_x >= 0 && pos.y-gwindow_y >= 0 && pos.x-mwindow_x < curwidth && pos.y-gwindow_y < curheight)
                    if (!((uint32_t*)screen_under_ptr)[(_pos.x-mwindow_x)*curheight + _pos.y-gwindow_y])
                        ((uint32_t*)screen_under_ptr)[(_pos.x-mwindow_x)*curheight + _pos.y-gwindow_y] = ((uint32_t*)screen_ptr)[(_pos.x-mwindow_x)*curheight + _pos.y-gwindow_y];
        }

        return INTERPOSE_NEXT(getCreatureTile)();
    }

    // Corpses are rendered as items so this is not needed
    /*DEFINE_VMETHOD_INTERPOSE(uint8_t, getCorpseTile, ())
    {
        if (rendering_remote_map)
        {
            df::coord _pos = Units::getPosition(this);

            if (df::global::cursor->x != _pos.x || df::global::cursor->y != _pos.y || df::global::cursor->z != _pos.z || ui->main.mode == df::ui_sidebar_mode::Default)
                if (pos.x-mwindow_x >= 0 && pos.y-gwindow_y >= 0 && pos.x-mwindow_x < curwidth && pos.y-gwindow_y < curheight)
                    if (!((uint32_t*)screen_under_ptr)[(_pos.x-mwindow_x)*curheight + _pos.y-gwindow_y])
                        ((uint32_t*)screen_under_ptr)[(_pos.x-mwindow_x)*curheight + _pos.y-gwindow_y] = ((uint32_t*)screen_ptr)[(_pos.x-mwindow_x)*curheight + _pos.y-gwindow_y];
        }

        return INTERPOSE_NEXT(getCorpseTile)();
    }*/

    DEFINE_VMETHOD_INTERPOSE(uint8_t, getGlowTile, ())
    {
        if (rendering_remote_map && !this->flags1.bits.inactive)
        {
            df::coord _pos = Units::getPosition(this);

            if (df::global::cursor->x != _pos.x || df::global::cursor->y != _pos.y || df::global::cursor->z != _pos.z || ui->main.mode == df::ui_sidebar_mode::Default)
                if (pos.x-mwindow_x >= 0 && pos.y-gwindow_y >= 0 && pos.x-mwindow_x < curwidth && pos.y-gwindow_y < curheight)
                    if (!((uint32_t*)screen_under_ptr)[(_pos.x-mwindow_x)*curheight + _pos.y-gwindow_y])
                        ((uint32_t*)screen_under_ptr)[(_pos.x-mwindow_x)*curheight + _pos.y-gwindow_y] = ((uint32_t*)screen_ptr)[(_pos.x-mwindow_x)*curheight + _pos.y-gwindow_y];
        }
        
        return INTERPOSE_NEXT(getGlowTile)();
    }
};

IMPLEMENT_VMETHOD_INTERPOSE(unit_hook, getCreatureTile);
// IMPLEMENT_VMETHOD_INTERPOSE(unit_hook, getCorpseTile);
IMPLEMENT_VMETHOD_INTERPOSE(unit_hook, getGlowTile);

void enable_unit_hooks()
{
    INTERPOSE_HOOK(unit_hook, getCreatureTile).apply(true);
    // INTERPOSE_HOOK(unit_hook, getCorpseTile).apply(true);
    INTERPOSE_HOOK(unit_hook, getGlowTile).apply(true);
}
