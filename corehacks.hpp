#include <mutex>

#include "df/viewscreen_barterst.h"

static uint32_t saved_frames;

std::recursive_mutex mutex;

typedef char (*MAINLOOP)();
static MAINLOOP _mainloop;

static uint32_t mainloop_addr_orig;

void core_unhack();

static uint8_t save[13];
static uint64_t fnptr;

static void protected_mainloop()
{
    mutex.lock();

    if (_mainloop())
    {
#if defined(DF_04305)
        MemoryPatcher p(Core::getInstance().p);
#else
        MemoryPatcher p(Core::getInstance().p.get());
#endif
    
#ifdef WIN32
        uint64_t addr = A_MAINLOOP_CALL + Core::getInstance().vinfo->getRebaseDelta();
#else
        uint64_t addr = A_MAINLOOP_CALL;
#endif

        uint8_t opcode[] = { 0xe9 };
        uint64_t jneaddr = *(uint32_t*)(save + 13 - 4) + addr + 13;
        uint64_t retptr = addr + 2+8+2;
        int32_t data = jneaddr - retptr - 5;

        p.write((void*)(retptr), &opcode, 1);
        p.write((void*)(retptr+1), &data, 4);
        return;
    }
    
    mutex.unlock();
}

void core_hack()
{
#if defined(DF_04305)
    MemoryPatcher p(Core::getInstance().p);
#else
    MemoryPatcher p(Core::getInstance().p.get());
#endif

#ifdef WIN32
    uint64_t addr = A_MAINLOOP_CALL + Core::getInstance().vinfo->getRebaseDelta();
#else
    uint64_t addr = A_MAINLOOP_CALL;
#endif

#if defined(WIN32) || defined(__APPLE__)
    _mainloop = (MAINLOOP) (*(int32_t*)(addr+1) + addr + 5);
#else
    uint8_t *_mainloop_jmp = (uint8_t*) (*(int32_t*)(addr+1) + addr + 5);
    void *_mainloop_ptr_addr = (*(int32_t*)(_mainloop_jmp+2) + _mainloop_jmp + 6);
    _mainloop = *(MAINLOOP*) _mainloop_ptr_addr;
#endif
    
    memcpy(save, (void*)addr, 13);

    uint8_t opcode1[] = { 0x48, 0xbf };
    fnptr = (uint64_t)&protected_mainloop;
    uint64_t data = (uint64_t)&fnptr;
    uint8_t opcode2[] = { 0xff,0x17, 0x90 };

    p.write((void*)(addr), &opcode1, 2);
    p.write((void*)(addr+2), &data, 8);
    p.write((void*)(addr+2+8), &opcode2, 3);
}

void core_unhack()
{
 #if defined(DF_04305)
    MemoryPatcher p(Core::getInstance().p);
#else
    MemoryPatcher p(Core::getInstance().p.get());
#endif

#ifdef WIN32
    uint64_t addr = A_MAINLOOP_CALL + Core::getInstance().vinfo->getRebaseDelta();
#else
    uint64_t addr = A_MAINLOOP_CALL;
#endif

    p.write((void*)addr, save, 13);
}

void core_suspend_fast(int a)
{
    mutex.lock();
}

void core_resume_fast(int a)
{
    mutex.unlock();
}

// Suspender that does not wait till the next graphics frame
class FastCoreSuspender {
    int a;
public:
    FastCoreSuspender(int a=0) :a(a) { core_suspend_fast(a); }
    ~FastCoreSuspender() { core_resume_fast(a); }
};


//TODO: may start render while updating
void core_force_render()
{
    SDL_SemWait(enabler->async_tobox.sem);
    df::enabler::T_async_tobox::T_queue command;
    command.cmd = df::enabler::T_async_tobox::T_queue::render;
    enabler->async_tobox.queue.push_back(command);
    SDL_SemPost(enabler->async_tobox.sem);
    SDL_SemPost(enabler->async_tobox.sem_fill);

    //TODO: should wait specifically for 'complete' msg
    SDL_SemWait(enabler->async_frombox.sem_fill);
    SDL_SemWait(enabler->async_frombox.sem);
    if (!enabler->async_frombox.queue.empty())
        enabler->async_frombox.queue.pop_front();
    SDL_SemPost(enabler->async_frombox.sem);
}
