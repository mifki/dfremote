#include "df/building_drawbuffer.h"

#include "df/building_animaltrapst.h"
#include "df/building_archerytargetst.h"
#include "df/building_armorstandst.h"
#include "df/building_axle_horizontalst.h"
#include "df/building_axle_verticalst.h"
#include "df/building_bars_floorst.h"
#include "df/building_bars_verticalst.h"
#include "df/building_bedst.h"
#include "df/building_bookcasest.h"
#include "df/building_boxst.h"
#include "df/building_bridgest.h"
#include "df/building_cabinetst.h"
#include "df/building_cagest.h"
#include "df/building_chainst.h"
#include "df/building_chairst.h"
#include "df/building_civzonest.h"
#include "df/building_coffinst.h"
#include "df/building_constructionst.h"
#include "df/building_doorst.h"
#include "df/building_farmplotst.h"
#include "df/building_floodgatest.h"
#include "df/building_furnacest.h"
#include "df/building_gear_assemblyst.h"
#include "df/building_grate_floorst.h"
#include "df/building_grate_wallst.h"
#include "df/building_hatchst.h"
#include "df/building_hivest.h"
#include "df/building_instrumentst.h"
#include "df/building_nest_boxst.h"
#include "df/building_nestst.h"
#include "df/building_road_dirtst.h"
#include "df/building_road_pavedst.h"
#include "df/building_rollersst.h"
#include "df/building_screw_pumpst.h"
#include "df/building_shopst.h"
#include "df/building_siegeenginest.h"
#include "df/building_slabst.h"
#include "df/building_statuest.h"
#include "df/building_stockpilest.h"
#include "df/building_supportst.h"
#include "df/building_tablest.h"
#include "df/building_traction_benchst.h"
#include "df/building_tradedepotst.h"
#include "df/building_trapst.h"
#include "df/building_wagonst.h"
#include "df/building_water_wheelst.h"
#include "df/building_weaponrackst.h"
#include "df/building_weaponst.h"
#include "df/building_wellst.h"
#include "df/building_windmillst.h"
#include "df/building_window_gemst.h"
#include "df/building_window_glassst.h"
#include "df/building_windowst.h"
#include "df/building_workshopst.h"

#define OVER1(cls) \
struct cls##_hook : public df::cls \
{ \
   typedef df::cls interpose_base; \
\
    DEFINE_VMETHOD_INTERPOSE(void, drawBuilding, (df::building_drawbuffer* dbuf, int16_t smth)) \
    { \
        INTERPOSE_NEXT(drawBuilding)(dbuf, smth); \
\
        if (!rendering_remote_map) \
            return; \
\
        int xmax = std::min(dbuf->x2-mwindow_x, curwidth-1); \
        int ymax = std::min(dbuf->y2-gwindow_y, curheight-1); \
\
        for (int x = dbuf->x1-mwindow_x; x <= xmax; x++) \
            for (int y = dbuf->y1-gwindow_y; y <= ymax; y++) \
                if (df::global::cursor->x != x+mwindow_x || df::global::cursor->y != y+gwindow_y || df::global::cursor->z != this->z || ui->main.mode == df::ui_sidebar_mode::Default) \
                    if (x >= 0 && y >= 0 && x < curwidth && y < curheight) \
                        ((uint32_t*)screen_under_ptr)[x*curheight + y] = ((uint32_t*)screen_ptr)[x*curheight + y]; \
    } \
}; \
IMPLEMENT_VMETHOD_INTERPOSE(cls##_hook, drawBuilding);

#define OVER1_ENABLE(cls) INTERPOSE_HOOK(cls##_hook, drawBuilding).apply(true);

OVER1(building_animaltrapst);
OVER1(building_archerytargetst);
OVER1(building_armorstandst);
OVER1(building_axle_horizontalst);
OVER1(building_axle_verticalst);
OVER1(building_bars_floorst);
OVER1(building_bars_verticalst);
OVER1(building_bedst);
OVER1(building_bookcasest);
OVER1(building_boxst);
OVER1(building_cabinetst);
OVER1(building_cagest);
OVER1(building_chainst);
OVER1(building_chairst);
OVER1(building_coffinst);
OVER1(building_doorst);
// OVER1(building_furnacest);
OVER1(building_gear_assemblyst);
OVER1(building_hatchst);
OVER1(building_hivest);
OVER1(building_instrumentst);
OVER1(building_nest_boxst);
OVER1(building_rollersst);
OVER1(building_screw_pumpst);
// OVER1(building_siegeenginest);
OVER1(building_slabst);
OVER1(building_statuest);
OVER1(building_supportst);
OVER1(building_tablest);
OVER1(building_traction_benchst);
// OVER1(building_tradedepotst);
OVER1(building_trapst);
OVER1(building_weaponrackst);
OVER1(building_weaponst);
OVER1(building_wellst);
// OVER1(building_workshopst);


struct stockpile_hook : public df::building_stockpilest
{
   typedef df::building_stockpilest interpose_base;

    DEFINE_VMETHOD_INTERPOSE(void, drawBuilding, (df::building_drawbuffer* dbuf, int16_t smth))
    {
        memset(dbuf->tile, 61, 31*31);
    }
}; 
IMPLEMENT_VMETHOD_INTERPOSE(stockpile_hook, drawBuilding);


struct building_workshopst_hook : public df::building_workshopst
{
   typedef df::building_workshopst interpose_base;

    DEFINE_VMETHOD_INTERPOSE(void, drawBuilding, (df::building_drawbuffer* dbuf, int16_t smth))
    {
        INTERPOSE_NEXT(drawBuilding)(dbuf, smth);

        if (!rendering_remote_map)
            return;

        int xmax = std::min(dbuf->x2-mwindow_x, curwidth-1);
        int ymax = std::min(dbuf->y2-gwindow_y, curheight-1);

        for (int x = dbuf->x1-mwindow_x; x <= xmax; x++)
        {
            for (int y = dbuf->y1-gwindow_y; y <= ymax; y++)
            {
                if (df::global::cursor->x == x+mwindow_x && df::global::cursor->y == y+gwindow_y && df::global::cursor->z == this->z && ui->main.mode != df::ui_sidebar_mode::Default)
                    continue;

                if (dbuf->tile[x-(dbuf->x1-mwindow_x)][y-(dbuf->y1-gwindow_y)] == 32)
                {
                    dbuf->tile[x-(dbuf->x1-mwindow_x)][y-(dbuf->y1-gwindow_y)] = 97;//108;//98;
                    dbuf->fore[x-(dbuf->x1-mwindow_x)][y-(dbuf->y1-gwindow_y)] = 15;
                }
                // if (dbuf->tile[x-(dbuf->x1-mwindow_x)][y-(dbuf->y1-gwindow_y)] == 176 || dbuf->tile[x-(dbuf->x1-mwindow_x)][y-(dbuf->y1-gwindow_y)] == 177)
                // {
                //     dbuf->tile[x-(dbuf->x1-mwindow_x)][y-(dbuf->y1-gwindow_y)] = 254;//
                //     // dbuf->fore[x-(dbuf->x1-mwindow_x)][y-(dbuf->y1-gwindow_y)] = 15;
                // }
                if (x >= 0 && y >= 0 && x < curwidth && y < curheight)
                {
                    // ((uint32_t*)screen_under_ptr)[x*curheight + y] = ((uint32_t*)screen_ptr)[x*curheight + y];

                    if (x == xmax && y == dbuf->y1-gwindow_y)
                        screen_under_ptr[(x*curheight + y)*4+0] = 106;
                    else if (x == dbuf->x1-mwindow_x && y == ymax)
                        screen_under_ptr[(x*curheight + y)*4+0] = 103;
                    else if (x == xmax && y == ymax)
                        screen_under_ptr[(x*curheight + y)*4+0] = 107;
                    else if (x == dbuf->x1-mwindow_x && y == dbuf->y1-gwindow_y)
                        screen_under_ptr[(x*curheight + y)*4+0] = 105;

                    else if (y == dbuf->y1-gwindow_y)
                        screen_under_ptr[(x*curheight + y)*4+0] = 101;
                    else if (x == dbuf->x1-mwindow_x)
                        screen_under_ptr[(x*curheight + y)*4+0] = 100;
                    else if (x == xmax)
                        screen_under_ptr[(x*curheight + y)*4+0] = 102;
                    else if (y == ymax)
                        screen_under_ptr[(x*curheight + y)*4+0] = 104;
                    
                    else
                        screen_under_ptr[(x*curheight + y)*4+0] = 99;

                    screen_under_ptr[(x*curheight + y)*4+1] = 15;
                    screen_under_ptr[(x*curheight + y)*4+2] = 0;
                    // screen_under_ptr[(x*curheight + y)*4+3] = 0; //TODO: dz !!!
                }
            }
        }
    }
}; 
IMPLEMENT_VMETHOD_INTERPOSE(building_workshopst_hook, drawBuilding);


struct building_furnacest_hook : public df::building_furnacest
{
   typedef df::building_furnacest interpose_base;

    DEFINE_VMETHOD_INTERPOSE(void, drawBuilding, (df::building_drawbuffer* dbuf, int16_t smth))
    {
        INTERPOSE_NEXT(drawBuilding)(dbuf, smth);

        if (!rendering_remote_map)
            return;

        int xmax = std::min(dbuf->x2-mwindow_x, curwidth-1);
        int ymax = std::min(dbuf->y2-gwindow_y, curheight-1);

        for (int x = dbuf->x1-mwindow_x; x <= xmax; x++)
        {
            for (int y = dbuf->y1-gwindow_y; y <= ymax; y++)
            {
                if (df::global::cursor->x == x+mwindow_x && df::global::cursor->y == y+gwindow_y && df::global::cursor->z == this->z && ui->main.mode != df::ui_sidebar_mode::Default)
                    continue;

                if (dbuf->tile[x-(dbuf->x1-mwindow_x)][y-(dbuf->y1-gwindow_y)] == 32)
                {
                    dbuf->tile[x-(dbuf->x1-mwindow_x)][y-(dbuf->y1-gwindow_y)] = 97;//108;//98;
                    dbuf->fore[x-(dbuf->x1-mwindow_x)][y-(dbuf->y1-gwindow_y)] = 15;
                }
                // if (dbuf->tile[x-(dbuf->x1-mwindow_x)][y-(dbuf->y1-gwindow_y)] == 176 || dbuf->tile[x-(dbuf->x1-mwindow_x)][y-(dbuf->y1-gwindow_y)] == 177)
                // {
                //     dbuf->tile[x-(dbuf->x1-mwindow_x)][y-(dbuf->y1-gwindow_y)] = 254;//
                //     // dbuf->fore[x-(dbuf->x1-mwindow_x)][y-(dbuf->y1-gwindow_y)] = 15;
                // }
                if (x >= 0 && y >= 0 && x < curwidth && y < curheight)
                {
                    if (x == xmax && y == dbuf->y1-gwindow_y)
                        screen_under_ptr[(x*curheight + y)*4+0] = 106;
                    else if (x == dbuf->x1-mwindow_x && y == ymax)
                        screen_under_ptr[(x*curheight + y)*4+0] = 103;
                    else if (x == xmax && y == ymax)
                        screen_under_ptr[(x*curheight + y)*4+0] = 107;
                    else if (x == dbuf->x1-mwindow_x && y == dbuf->y1-gwindow_y)
                        screen_under_ptr[(x*curheight + y)*4+0] = 105;

                    else if (y == dbuf->y1-gwindow_y)
                        screen_under_ptr[(x*curheight + y)*4+0] = 101;
                    else if (x == dbuf->x1-mwindow_x)
                        screen_under_ptr[(x*curheight + y)*4+0] = 100;
                    else if (x == xmax)
                        screen_under_ptr[(x*curheight + y)*4+0] = 102;
                    else if (y == ymax)
                        screen_under_ptr[(x*curheight + y)*4+0] = 104;
                    
                    else
                        screen_under_ptr[(x*curheight + y)*4+0] = 99;

                    screen_under_ptr[(x*curheight + y)*4+1] = 15;
                    screen_under_ptr[(x*curheight + y)*4+2] = 0;
                    // screen_under_ptr[(x*curheight + y)*4+3] = 0; //TODO: dz !!!
                }
            }
        }
    }
}; 
IMPLEMENT_VMETHOD_INTERPOSE(building_furnacest_hook, drawBuilding);


struct building_tradedepotst_hook : public df::building_tradedepotst
{
   typedef df::building_tradedepotst interpose_base;

    DEFINE_VMETHOD_INTERPOSE(void, drawBuilding, (df::building_drawbuffer* dbuf, int16_t smth))
    {
        INTERPOSE_NEXT(drawBuilding)(dbuf, smth);

        if (!rendering_remote_map)
            return;

        int xmax = std::min(dbuf->x2-mwindow_x, curwidth-1);
        int ymax = std::min(dbuf->y2-gwindow_y, curheight-1);

        for (int x = dbuf->x1-mwindow_x; x <= xmax; x++)
        {
            for (int y = dbuf->y1-gwindow_y; y <= ymax; y++)
            {
                if (df::global::cursor->x == x+mwindow_x && df::global::cursor->y == y+gwindow_y && df::global::cursor->z == this->z && ui->main.mode != df::ui_sidebar_mode::Default)
                    continue;

                if (dbuf->tile[x-(dbuf->x1-mwindow_x)][y-(dbuf->y1-gwindow_y)] == 32)
                {
                    dbuf->tile[x-(dbuf->x1-mwindow_x)][y-(dbuf->y1-gwindow_y)] = 97;//108;//98;
                    dbuf->fore[x-(dbuf->x1-mwindow_x)][y-(dbuf->y1-gwindow_y)] = 15;
                }
                if (x >= 0 && y >= 0 && x < curwidth && y < curheight)
                {
                    if (x == xmax && y == dbuf->y1-gwindow_y)
                        screen_under_ptr[(x*curheight + y)*4+0] = 106;
                    else if (x == dbuf->x1-mwindow_x && y == ymax)
                        screen_under_ptr[(x*curheight + y)*4+0] = 103;
                    else if (x == xmax && y == ymax)
                        screen_under_ptr[(x*curheight + y)*4+0] = 107;
                    else if (x == dbuf->x1-mwindow_x && y == dbuf->y1-gwindow_y)
                        screen_under_ptr[(x*curheight + y)*4+0] = 105;

                    else if (y == dbuf->y1-gwindow_y)
                        screen_under_ptr[(x*curheight + y)*4+0] = 101;
                    else if (x == dbuf->x1-mwindow_x)
                        screen_under_ptr[(x*curheight + y)*4+0] = 100;
                    else if (x == xmax)
                        screen_under_ptr[(x*curheight + y)*4+0] = 102;
                    else if (y == ymax)
                        screen_under_ptr[(x*curheight + y)*4+0] = 104;
                    
                    else
                        screen_under_ptr[(x*curheight + y)*4+0] = 99;

                    screen_under_ptr[(x*curheight + y)*4+1] = 15;
                    screen_under_ptr[(x*curheight + y)*4+2] = 0;
                    // screen_under_ptr[(x*curheight + y)*4+3] = 0; //TODO: dz !!!
                }
            }
        }
    }
}; 
IMPLEMENT_VMETHOD_INTERPOSE(building_tradedepotst_hook, drawBuilding);


struct building_siegeenginest_hook : public df::building_siegeenginest
{
   typedef df::building_siegeenginest interpose_base;

    DEFINE_VMETHOD_INTERPOSE(void, drawBuilding, (df::building_drawbuffer* dbuf, int16_t smth))
    {
        INTERPOSE_NEXT(drawBuilding)(dbuf, smth);

        if (!rendering_remote_map)
            return;

        int xmax = std::min(dbuf->x2-mwindow_x, curwidth-1);
        int ymax = std::min(dbuf->y2-gwindow_y, curheight-1);

        for (int x = dbuf->x1-mwindow_x; x <= xmax; x++)
        {
            for (int y = dbuf->y1-gwindow_y; y <= ymax; y++)
            {
                if (df::global::cursor->x == x+mwindow_x && df::global::cursor->y == y+gwindow_y && df::global::cursor->z == this->z && ui->main.mode != df::ui_sidebar_mode::Default)
                    continue;

                // if (dbuf->tile[x-(dbuf->x1-mwindow_x)][y-(dbuf->y1-gwindow_y)] == 32)
                // {
                //     dbuf->tile[x-(dbuf->x1-mwindow_x)][y-(dbuf->y1-gwindow_y)] = 97;//108;//98;
                //     dbuf->fore[x-(dbuf->x1-mwindow_x)][y-(dbuf->y1-gwindow_y)] = 15;
                // }
                if (x >= 0 && y >= 0 && x < curwidth && y < curheight)
                {
                    if (x == xmax && y == dbuf->y1-gwindow_y)
                        screen_under_ptr[(x*curheight + y)*4+0] = 106;
                    else if (x == dbuf->x1-mwindow_x && y == ymax)
                        screen_under_ptr[(x*curheight + y)*4+0] = 103;
                    else if (x == xmax && y == ymax)
                        screen_under_ptr[(x*curheight + y)*4+0] = 107;
                    else if (x == dbuf->x1-mwindow_x && y == dbuf->y1-gwindow_y)
                        screen_under_ptr[(x*curheight + y)*4+0] = 105;

                    else if (y == dbuf->y1-gwindow_y)
                        screen_under_ptr[(x*curheight + y)*4+0] = 101;
                    else if (x == dbuf->x1-mwindow_x)
                        screen_under_ptr[(x*curheight + y)*4+0] = 100;
                    else if (x == xmax)
                        screen_under_ptr[(x*curheight + y)*4+0] = 102;
                    else if (y == ymax)
                        screen_under_ptr[(x*curheight + y)*4+0] = 104;
                    
                    else
                        screen_under_ptr[(x*curheight + y)*4+0] = 99;

                    screen_under_ptr[(x*curheight + y)*4+1] = 15;
                    screen_under_ptr[(x*curheight + y)*4+2] = 0;
                    // screen_under_ptr[(x*curheight + y)*4+3] = 0; //TODO: dz !!!
                }
            }
        }
    }
}; 
IMPLEMENT_VMETHOD_INTERPOSE(building_siegeenginest_hook, drawBuilding);


void enable_building_hooks()
{
    OVER1_ENABLE(building_animaltrapst);
    OVER1_ENABLE(building_archerytargetst);
    OVER1_ENABLE(building_armorstandst);
    OVER1_ENABLE(building_axle_horizontalst);
    OVER1_ENABLE(building_axle_verticalst);
    OVER1_ENABLE(building_bars_floorst);
    OVER1_ENABLE(building_bars_verticalst);
    OVER1_ENABLE(building_bedst);
    OVER1_ENABLE(building_bookcasest);
    OVER1_ENABLE(building_boxst);
    OVER1_ENABLE(building_cabinetst);
    OVER1_ENABLE(building_cagest);
    OVER1_ENABLE(building_chainst);
    OVER1_ENABLE(building_chairst);    
    OVER1_ENABLE(building_coffinst);
    OVER1_ENABLE(building_doorst);
    OVER1_ENABLE(building_gear_assemblyst);
    OVER1_ENABLE(building_hatchst);
    OVER1_ENABLE(building_hivest);
    OVER1_ENABLE(building_instrumentst);
    OVER1_ENABLE(building_nest_boxst);
    OVER1_ENABLE(building_rollersst);
    OVER1_ENABLE(building_screw_pumpst);
    OVER1_ENABLE(building_siegeenginest);
    OVER1_ENABLE(building_slabst);
    OVER1_ENABLE(building_statuest);
    OVER1_ENABLE(building_supportst);
    OVER1_ENABLE(building_tablest);
    OVER1_ENABLE(building_traction_benchst);
    OVER1_ENABLE(building_tradedepotst);
    OVER1_ENABLE(building_trapst);
    OVER1_ENABLE(building_weaponrackst);
    OVER1_ENABLE(building_weaponst);
    OVER1_ENABLE(building_wellst);

    INTERPOSE_HOOK(building_furnacest_hook, drawBuilding).apply(true);
    INTERPOSE_HOOK(building_workshopst_hook, drawBuilding).apply(true);

    INTERPOSE_HOOK(stockpile_hook, drawBuilding).apply(false);
}