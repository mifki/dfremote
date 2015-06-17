command_result remote_cmd(color_ostream &out, std::vector <std::string> & args)
{
    if (args.size())
    {
    	std::string &cmd = args[0];

    	if (cmd == "on" || cmd == "1" || cmd == "start")
    	{
            remote_start();
            save_config();
    	}
    	else if (cmd == "off" || cmd == "0" || cmd == "stop")
    	{
            remote_stop();    		
            save_config();
    	}
        else if (cmd == "publish" && args.size() > 1)
        {
            remote_publish(args[1]);
            save_config();
        }
        else if (cmd == "unpublish")
        {
            remote_unpublish();
            save_config();
        }
        else if (cmd == "password" || cmd == "pwd" || cmd == "pass")
        {
            if (args.size() > 1)
            {
                remote_setpwd(args[1]);
                save_config();
            }
            else
            {
                DFHack::CommandHistory hist;
                std::string ret;

                int rv = Core::getInstance().getConsole().lineedit("Enter new password (Ctrl-C to cancel, blank to disable password): ", ret, hist);
                if (rv != -1)
                {
                    remote_setpwd(ret);
                    save_config();
                }
            }
        }
        else if (cmd == "port" && args.size() > 1)
        {
            if (remote_on)
            {
                out << "Stop using `remote off` first." << std::endl;
                return CR_OK;
            }

            int newport;
            if (parse_int(args[1], newport))
                enet_port = newport;
            else
                return CR_WRONG_USAGE;

            save_config();            
        }
        else if (cmd == "debug" && args.size() > 1)
        {
            string &arg1 = args[1];
            if (arg1 == "on" || arg1 == "1")
                debug = true;
            else
                debug = false;
        }
        else if (cmd == "reload")
        {
            remote_unload();
        }
        else if (cmd == "v" || cmd == "ver" || cmd == "version")
        {
            remote_print_version();
        }
        else if (cmd == "hideui")
        {
            force_render_ui = false;
        }
        else if (cmd == "unhideui")
        {
            force_render_ui = true;
        }
        else if (cmd == "noop")
        {
        }
        else
            return CR_WRONG_USAGE;
    }
    else
        return CR_WRONG_USAGE;

    return CR_OK;
}