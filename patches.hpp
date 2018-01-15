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
