#include <df/viewscreen_choose_start_sitest.h>

struct embark_hook : public df::viewscreen_choose_start_sitest
{
    typedef df::viewscreen_choose_start_sitest interpose_base;

    DEFINE_VMETHOD_INTERPOSE(void, render, ())
    {
        // Stopping location finder sometimes crashes the game,
        // I guess because the screen is rendering at that time. 
        // So let's not render the finder page.
        if (this->page == df::viewscreen_choose_start_sitest::T_page::Find)
            return;
        
        INTERPOSE_NEXT(render)();
    }
};

IMPLEMENT_VMETHOD_INTERPOSE_PRIO(embark_hook, render, -300);
