static uint32_t saved_frames;

void core_suspend_fast()
{
    volatile unsigned int *frames = &enabler->async_frames;
    volatile bool *paused = &enabler->async_paused;

    // Claim channel lock early to make sure no commands posted
    SDL_SemWait(enabler->async_tobox.sem);

    // If async_frames is zero, mainloop() has already finished or wasn't requested.
    // So we're safe to proceed in either case.
    if (!*frames)
    {
        *paused = true;
        saved_frames = 0;
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
