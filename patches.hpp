#define MAX_PATCH_LEN 32

struct patchdef {
    unsigned long addr;
    int len;
    bool hasdata;
    unsigned char data[MAX_PATCH_LEN];
};

static void apply_patch(MemoryPatcher *mp, patchdef &p)
{
    static unsigned char nops[32];
    if (!nops[0])
        memset(nops, 0x90, sizeof(nops));

    long addr = p.addr;
    #ifdef WIN32
        addr += Core::getInstance().vinfo->getRebaseDelta();
    #endif

    unsigned char *data = p.hasdata ? p.data : nops;

    if (mp)
        mp->write((void*)addr, data, p.len);
    else
        memcpy((void*)addr, data, p.len);
}


#if defined(DF_04024)
    #ifdef WIN32
        #define A_LOAD_MULTI_PDIM 0x00bb4190

        #define A_RENDER_MAP      0x009fad60
        #define A_RENDER_UPDOWN   0x008215c0

        static patchdef p_display = { 0x00675571, 5 };

        static patchdef p_dwarfmode_render = { 0x0064039f, 6 };
        
        static patchdef p_advmode_render[] = {
            { 0x005b9005, 2+5+5 }, { 0x005b9050, 2+5+5 }, { 0x005b90a1, 2+5+5 }, { 0x005b90f8, 2+5+5 }, { 0x005b95a5, 2+5+5 }
        };

        static patchdef p_render_lower_levels = {
            0x00cd72f0, 15, true, { 0x36,0x8b,0x84,0x24,0x0C,0x00,0x00,0x00, 0x3e,0xc6,0x00,0x00, 0xC2,0x1C,0x00 }
        };

    #elif defined(__APPLE__)
        #define A_LOAD_MULTI_PDIM 0x00fa1500

        #define A_RENDER_MAP      0x009e6170
        #define A_RENDER_UPDOWN   0x007780a0

        static patchdef p_display = { 0x00f35db1, 5 };

        static patchdef p_dwarfmode_render = { 0x0041016a, 5 };
        
        static patchdef p_advmode_render[] = {
            { 0x003c8550, 5+3+5 }, { 0x003c8bad, 5+3+5 }, { 0x003c8f76, 5+3+5 }, { 0x003c8fd9, 5+3+5 }, { 0x003c905a, 5+3+5 }
        };

        static patchdef p_render_lower_levels = {
            0x00c94100, 13, true, { 0x36,0x8b,0x84,0x24,0x14,0x00,0x00,0x00, 0x3e,0xc6,0x00,0x00, 0xC3 }
        };

    #else
        #define A_RENDER_MAP      0x08a43270
        #define A_RENDER_UPDOWN   0x087e1d30

        #define NO_DISPLAY_PATCH

        static patchdef p_dwarfmode_render = { 0x08394a0f, 5 };
        
        static patchdef p_advmode_render[] = {
            { 0x0834b4dd, 5+7+5 }, { 0x0834b591, 5+7+5 }, { 0x0834bb9c, 5+7+5 }, { 0x0834bfca, 5+7+5 }
        };

        static patchdef p_render_lower_levels = {
            0x08d1f8f0, 13, true, { 0x36,0x8b,0x84,0x24,0x14,0x00,0x00,0x00, 0x3e,0xc6,0x00,0x00, 0xC3 }
        };

    #endif 

#elif defined(DF_04303)
    #ifdef WIN32
        #define A_LOAD_MULTI_PDIM 0x00cfa020
        #define A_RENDER_MAP      0x00b1f6c0
        #define A_RENDER_UPDOWN   0x008f8a70

        static patchdef p_display = { 0x006f7351, 5 };

        static patchdef p_dwarfmode_render = { 0x006ba48e, 6 };

        static patchdef p_advmode_render[] = {
            { 0x00611395, 2+5+5 }, { 0x006113e0, 2+5+5 }, { 0x00611431, 2+5+5 }, { 0x00611488, 2+5+5 }, { 0x006118fd, 1+5+5 }
        };

        static patchdef p_render_lower_levels = {
            0x00e1cea0, 15, true, { 0x36,0x8b,0x84,0x24,0x0C,0x00,0x00,0x00, 0x3e,0xc6,0x00,0x00, 0xC2,0x1C,0x00 }
        };

    #elif defined(__APPLE__)
        #define A_LOAD_MULTI_PDIM 0x0120cbb0

        #define A_RENDER_MAP      0x00b9ea70
        #define A_RENDER_UPDOWN   0x008f3180

        static patchdef p_display = { 0x0119e101, 5 };

        static patchdef p_dwarfmode_render = { 0x004e442a, 5 };

        static patchdef p_advmode_render[] = {
            { 0x004832b2, 5+3+5 }, { 0x0048396d, 5+3+5 }, { 0x00483d48, 5+3+5 }, { 0x00483dab, 5+3+5 }, { 0x00483e2c, 5+3+5 }
        };

        static patchdef p_render_lower_levels = {
            0x00e65740, 13, true, { 0x36,0x8b,0x84,0x24,0x14,0x00,0x00,0x00, 0x3e,0xc6,0x00,0x00, 0xC3 }
        };

    #else
        #define A_RENDER_MAP 0x08bf9b00
        #define A_RENDER_UPDOWN 0x08955b40

        #define NO_DISPLAY_PATCH

        static patchdef p_dwarfmode_render = { 0x08429f12, 5 };

        static patchdef p_advmode_render[] = {
            { 0x083c167d, 5+7+5 }, { 0x083c1731, 5+7+5 }, { 0x083c1d5c, 5+7+5 }, { 0x083c218a, 5+7+5 }
        };

        static patchdef p_render_lower_levels = {
            0x08ef43c0, 13, true, { 0x36,0x8b,0x84,0x24,0x14,0x00,0x00,0x00, 0x3e,0xc6,0x00,0x00, 0xC3 }
        };
    #endif

#elif defined(DF_04305)
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

    #else
        #define A_RENDER_MAP 0x00d537c0
        #define A_RENDER_UPDOWN 0x00b345f0

        #define NO_DISPLAY_PATCH

        static patchdef p_dwarfmode_render = { 0x00720ae5, 5 };

        static patchdef p_advmode_render[] = {
            { 0x006aa202, 5+5+5 }, { 0x006aa802, 5+5+5 }, { 0x006aa841, 5+5+5 }, { 0x006aa89d, 5+5+5 }
        };

        static patchdef p_render_lower_levels = {
            0x00fc8fa0, 5, true, { 0x41, 0xc6, 0x00, 0x00, 0xC3 }
        };
    #endif        

#else
    #error Unsupported DF version
#endif
