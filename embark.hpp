#include <df/viewscreen_choose_start_sitest.h>

struct embark_hook : public df::viewscreen_choose_start_sitest
{
    typedef df::viewscreen_choose_start_sitest interpose_base;

    DEFINE_VMETHOD_INTERPOSE(void, render, ())
    {
        FastCoreSuspender suspend(2);
        INTERPOSE_NEXT(render)();
    }
};

IMPLEMENT_VMETHOD_INTERPOSE_PRIO(embark_hook, render, -300);
