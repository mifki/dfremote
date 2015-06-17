static uint32_t saved_frames;

void core_suspend_fast()
{
    // Request pause
    SDL_SemWait(enabler->async_tobox.sem);
    df::enabler::T_async_tobox::T_queue command;
    command.cmd = df::enabler::T_async_tobox::T_queue::pause;
    enabler->async_tobox.queue.push_back(command);
    SDL_SemPost(enabler->async_tobox.sem);
    SDL_SemPost(enabler->async_tobox.sem_fill);

    // Wait for request to complete
    SDL_SemWait(enabler->async_frombox.sem_fill);
    SDL_SemWait(enabler->async_frombox.sem);
    enabler->async_frombox.queue.pop_front();
    SDL_SemPost(enabler->async_frombox.sem);

    // At this point we can be sure mainloop() has finished and won't be called again

    saved_frames = enabler->async_frames;

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


void core_force_render()
{
    SDL_SemWait(enabler->async_tobox.sem);
    df::enabler::T_async_tobox::T_queue command;
    command.cmd = df::enabler::T_async_tobox::T_queue::render;
    enabler->async_tobox.queue.push_back(command);
    SDL_SemPost(enabler->async_tobox.sem);
    SDL_SemPost(enabler->async_tobox.sem_fill);


    SDL_SemWait(enabler->async_frombox.sem_fill);
    SDL_SemWait(enabler->async_frombox.sem);
    enabler->async_frombox.queue.pop_front();
    SDL_SemPost(enabler->async_frombox.sem);
}
