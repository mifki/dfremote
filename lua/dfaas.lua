--luacheck: in=string,string
function dfaas_get_status(clientver, pwd)
    local idle_time = os.time() - STATE.last_cmd_time
    
    return { setup_get_server_info(clientver, pwd), idle_time }
end

--luacheck: in=string
function dfaas_save_game(pwd)
    if not native.verify_pwd(pwd or '') then
        error('invalid password')
    end

    --todo: need to return to main screen!

    save_game()    
    return true
end

--luacheck: in=string
function dfaas_save_done(pwd)
    if not native.verify_pwd(pwd or '') then
        error('invalid password')
    end

    --todo: need to return to main screen!

    return (df.global.ui.main.autosave_request ~= true)
end

--luacheck: in=string
function dfaas_savegames_refresh(pwd)
    if not native.verify_pwd(pwd or '') then
        error('invalid password')
    end
    
    return savegames_refresh()
end