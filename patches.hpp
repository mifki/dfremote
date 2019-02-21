#define MAX_PATCH_LEN 32

struct patchdef {
    intptr_t addr;
    int len;
    bool hasdata;
    unsigned char data[MAX_PATCH_LEN];
};

static void apply_patch(MemoryPatcher *mp, patchdef &p)
{
    static unsigned char nops[32];
    if (!nops[0])
        memset(nops, 0x90, sizeof(nops));

    intptr_t addr = p.addr;
    #ifdef WIN32
        addr += Core::getInstance().vinfo->getRebaseDelta();
    #endif

    unsigned char *data = p.hasdata ? p.data : nops;

    if (mp)
        mp->write((void*)addr, data, p.len);
    else
        memcpy((void*)addr, data, p.len);
}


#if defined(DF_04305)
    #ifdef WIN32
        #define A_LOAD_MULTI_PDIM 0x140a36ad0
        #define A_RENDER_MAP      0x1408170b0
        #define A_RENDER_UPDOWN   0x140593f30

        static patchdef p_display = { 0x14035c4cb, 5 };

        static patchdef p_dwarfmode_render = { 0x14031266a, 5 };

        static patchdef p_advmode_render[] = {
            { 0x0140265a6b, 5+5 }, { 0x140265abc, 5+5 }, { 0x140265b06, 5+5 }, { 0x140265ff4, 5+5 },
        };

        static patchdef p_render_lower_levels = {
            0x140b7f500, 9, true, { 0x48, 0x8B, 0x44, 0x24, 0x28,  0xC6, 0x00, 0x00,  0xC3 }
        };
        
        #define A_MAINLOOP        0x140630640
        #define A_MAINLOOP_CALL   0x14035c0c1

    #elif defined(__APPLE__)
        #define A_LOAD_MULTI_PDIM 0x10106a9b0

        #define A_RENDER_MAP      0x100a7eb10
        #define A_RENDER_UPDOWN   0x100815cd0

        static patchdef p_display = { 0x1010003cb, 5 };

        static patchdef p_dwarfmode_render = { 0x100457447, 5 };

        static patchdef p_advmode_render[] = {
            { 0x100404a31, 5+3+5 }, { 0x100404aca, 5+7+5 }, { 0x10040501a, 5+3+5 }, { 0x10040532b, 5+3+5 }
        };

        static patchdef p_render_lower_levels = {
            0x100d075c0, 5, true, { 0x41, 0xc6, 0x00, 0x00, 0xC3 }
        };
        
        #define A_MAINLOOP        0x1006daea0
        #define A_MAINLOOP_CALL   0x100fff563

    #else
        #define A_RENDER_MAP      0x00d537c0
        #define A_RENDER_UPDOWN   0x00b345f0

        #define NO_DISPLAY_PATCH

        static patchdef p_dwarfmode_render = { 0x00720ae5, 5 };

        static patchdef p_advmode_render[] = {
            { 0x006aa202, 5+5+5 }, { 0x006aa802, 5+5+5 }, { 0x006aa841, 5+5+5 }, { 0x006aa89d, 5+5+5 }
        };

        static patchdef p_render_lower_levels = {
            0x00fc8fa0, 5, true, { 0x41, 0xc6, 0x00, 0x00, 0xC3 }
        };
        
        #define A_MAINLOOP        dlsym(RTLD_DEFAULT, "_Z8mainloopv")
        #define A_MAINLOOP_CALL   ((int64_t)dlsym(RTLD_DEFAULT, "_ZN9enablerst10async_loopEv") + 0xb0)
    #endif        

#elif defined(DF_04412)
    #ifdef WIN32
        #define A_LOAD_MULTI_PDIM 0x140aeb200
        #define A_RENDER_MAP      0x1408b9f20
        #define A_RENDER_UPDOWN   0x140600c10

        static patchdef p_display = { 0x1403a134b, 5 };

        static patchdef p_dwarfmode_render = { 0x14035644a, 5 };

        static patchdef p_advmode_render[] = {
            { 0x14029cb0b, 5+5 }, { 0x14029cb5c, 5+5 }, { 0x14029cba6, 5+5 }, { 0x14029d073, 5+5 }
        };

        static patchdef p_render_lower_levels = {
            0x140c37e60, 9, true, { 0x48, 0x8b, 0x44, 0x24, 0x28, 0xc6, 0x00, 0x00, 0xc3 }
        };
        
        #define A_MAINLOOP        0x1406bf1f0
        #define A_MAINLOOP_CALL   0x1403a0f41
        
    #elif defined(__APPLE__)
        #define A_LOAD_MULTI_PDIM 0x1011aa460
        #define A_RENDER_MAP      0x100b30bc0
        #define A_RENDER_UPDOWN   0x10089e2e0

        static patchdef p_display = { 0x10113de0b, 5 };

        static patchdef p_dwarfmode_render = { 0x10049587a, 5 };

        static patchdef p_advmode_render[] = {
            { 0x10043c0e1, 5+3+5 }, { 0x10043c17a, 5+7+5 }, { 0x10043c6da, 5+3+5 }, { 0x10043c9eb, 5+3+5 }
        };

        static patchdef p_render_lower_levels = {
            0x100dd1a20, 5, true, { 0x41, 0xc6, 0x00, 0x00, 0xc3 }
        };
        
        #define A_MAINLOOP        0x1007429f0
        #define A_MAINLOOP_CALL   0x10113cfa3
        
    #else
        #define A_RENDER_MAP      0xe1f9f0
        #define A_RENDER_UPDOWN   0xbea660
        #define NO_DISPLAY_PATCH

        static patchdef p_dwarfmode_render = { 0x720395, 5 };

        static patchdef p_advmode_render[] = {
            { 0x6ee94a, 5+5+5 }, { 0x6eef62, 5+5+5 }, { 0x6eefa1, 5+5+5 }, { 0x6eeffd, 5+5+5 }
        };

        static patchdef p_render_lower_levels = {
            0x10a2f30, 5, true, { 0x41, 0xc6, 0x00, 0x00, 0xc3 }
        };
        
        #define A_MAINLOOP        dlsym(RTLD_DEFAULT, "_Z8mainloopv")
        #define A_MAINLOOP_CALL   ((int64_t)dlsym(RTLD_DEFAULT, "_ZN9enablerst10async_loopEv") + 0xb0)
    #endif

#else
    #error Unsupported DF version
#endif
