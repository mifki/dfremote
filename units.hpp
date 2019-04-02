#include "df/unit.h"

struct unit_hook : public df::unit
{
   typedef df::unit interpose_base;

    DEFINE_VMETHOD_INTERPOSE(uint8_t, getCreatureTile, ())
    {
        if (rendering_remote_map)
        {
            df::coord _pos = Units::getPosition(this);
            if (pos.x-gwindow_x >= 0 && pos.y-gwindow_y >= 0 && pos.x-gwindow_x < curwidth && pos.y-gwindow_y < curheight)
                // if (!((uint32_t*)screen_under_ptr)[(_pos.x-gwindow_x)*r->gdimy + _pos.y-gwindow_y])
                    ((uint32_t*)screen_under_ptr)[(_pos.x-gwindow_x)*curheight + _pos.y-gwindow_y] = ((uint32_t*)screen_ptr)[(_pos.x-gwindow_x)*curheight + _pos.y-gwindow_y];
        }

        return INTERPOSE_NEXT(getCreatureTile)();
    }

    DEFINE_VMETHOD_INTERPOSE(uint8_t, getCorpseTile, ())
    {
        if (rendering_remote_map)
        {
            df::coord _pos = Units::getPosition(this);
            if (pos.x-gwindow_x >= 0 && pos.y-gwindow_y >= 0 && pos.x-gwindow_x < curwidth && pos.y-gwindow_y < curheight)
                // if (!((uint32_t*)screen_under_ptr)[(_pos.x-gwindow_x)*r->gdimy + _pos.y-gwindow_y])
                    ((uint32_t*)screen_under_ptr)[(_pos.x-gwindow_x)*curheight + _pos.y-gwindow_y] = ((uint32_t*)screen_ptr)[(_pos.x-gwindow_x)*curheight + _pos.y-gwindow_y];
        }

        return INTERPOSE_NEXT(getCorpseTile)();
    }

    DEFINE_VMETHOD_INTERPOSE(uint8_t, getGlowTile, ())
    {
        if (rendering_remote_map)
        {
            df::coord _pos = Units::getPosition(this);
            if (pos.x-gwindow_x >= 0 && pos.y-gwindow_y >= 0 && pos.x-gwindow_x < curwidth && pos.y-gwindow_y < curheight)
                // if (!((uint32_t*)screen_under_ptr)[(_pos.x-gwindow_x)*r->gdimy + _pos.y-gwindow_y])
                    ((uint32_t*)screen_under_ptr)[(_pos.x-gwindow_x)*curheight + _pos.y-gwindow_y] = ((uint32_t*)screen_ptr)[(_pos.x-gwindow_x)*curheight + _pos.y-gwindow_y];
        }
        
        return INTERPOSE_NEXT(getGlowTile)();
    }
};

IMPLEMENT_VMETHOD_INTERPOSE(unit_hook, getCreatureTile);
IMPLEMENT_VMETHOD_INTERPOSE(unit_hook, getCorpseTile);
IMPLEMENT_VMETHOD_INTERPOSE(unit_hook, getGlowTile);

void enable_unit_hooks()
{
    INTERPOSE_HOOK(unit_hook, getCreatureTile).apply(true);
    INTERPOSE_HOOK(unit_hook, getCorpseTile).apply(true);
    INTERPOSE_HOOK(unit_hook, getGlowTile).apply(true);
}
