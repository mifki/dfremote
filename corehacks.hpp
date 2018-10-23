static uint32_t saved_frames;

void core_suspend_fast()
{
    volatile unsigned int *frames = &enabler->async_frames;
    volatile bool *paused = &enabler->async_paused;

    // Claim channel lock early to make sure no commands posted
    SDL_SemWait(enabler->async_tobox.sem);

    *paused = true;

    // If async_frames is zero, mainloop() has already finished or wasn't requested.
    // And since we've already set async_paused=true, mainloop() won't be called even if requested.
    // So we're safe to proceed in either case.
    if (!*frames)
    {
        saved_frames = 0;
        *paused = true;
        return;
    }

    df::enabler::T_async_tobox::T_queue command;
    command.cmd = df::enabler::T_async_tobox::T_queue::pause;
    enabler->async_tobox.queue.push_back(command);
    SDL_SemPost(enabler->async_tobox.sem);
    SDL_SemPost(enabler->async_tobox.sem_fill);

    do {
        SDL_SemWait(enabler->async_frombox.sem_fill);
        SDL_SemWait(enabler->async_frombox.sem);
        if (!enabler->async_frombox.queue.empty())
            enabler->async_frombox.queue.pop_front();
        SDL_SemPost(enabler->async_frombox.sem);    
    } while (!*paused);

    saved_frames = *frames;
    /* *frames = 0;

    // Trigger async_frames change
    df::enabler::T_async_tobox::T_queue command;
    command.cmd = df::enabler::T_async_tobox::T_queue::inc;
    command.val = 99999;
    enabler->async_tobox.queue.push_back(command);
    SDL_SemPost(enabler->async_tobox.sem);
    SDL_SemPost(enabler->async_tobox.sem_fill);

    // Wait for async_frames to change zero -> anything, either as the result of our call above
    // or after mainloop(), or by another request. Either case means we're not in the mainloop() anymore.
    // remote_on check is needed to avoid race condition when stopping or unloading from console,
    // and the loop is already suspended by DFHack core (and is waiting in SDL_NumJoysticks())
    while(!*frames && remote_on)
    {
#if !defined(__APPLE__) && !defined(WIN32)
        // Looks like in some cases (e.g. ending the game), this is getting reset to false, which
        // for some reason is causing this loop to never complete on single-core computers
        enabler->async_paused = true;
#endif
#ifdef WIN32
        __nop();
#else
        asm volatile ("nop");
#endif        
    }*/

    // At this point we can be sure mainloop() has finished and won't be called again
    
    //XXX: This is to prevent render command from being sent. It crashes the game at least while moving
    //XXX: region location on embark screen.
    //TODO: Still the situation when rendering has already been started is not covered.
    SDL_SemWait(enabler->async_tobox.sem);
}

void core_resume_fast()
{
    //SDL_SemWait(enabler->async_tobox.sem);
    {
        df::enabler::T_async_tobox::T_queue command;
        command.cmd = df::enabler::T_async_tobox::T_queue::start;
        enabler->async_tobox.queue.push_back(command);
    }
    {
        df::enabler::T_async_tobox::T_queue command;
        command.cmd = df::enabler::T_async_tobox::T_queue::inc;
        command.val = saved_frames;
        enabler->async_tobox.queue.push_back(command);
    }
    SDL_SemPost(enabler->async_tobox.sem);
    SDL_SemPost(enabler->async_tobox.sem_fill);
    SDL_SemPost(enabler->async_tobox.sem_fill);
}

// Suspender that does not wait till the next graphics frame
class FastCoreSuspender {
public:
    FastCoreSuspender() { core_suspend_fast(); }
    ~FastCoreSuspender() { core_resume_fast(); }
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
