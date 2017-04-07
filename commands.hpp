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
        else if (cmd == "publish" && args.size() == 2)
        {
            remote_publish(args[1]);
            save_config();
        }
        else if (cmd == "unpublish")
        {
            remote_unpublish();
            save_config();
        }
        else if (cmd == "connect")
        {
#define HAS_FLAG(f) (std::find(args.begin()+1, args.end(), f) != args.end())
            bool debug = HAS_FLAG("-debug");
            bool no_external = HAS_FLAG("-no-external");
            bool no_publish = HAS_FLAG("-no-publish");
            bool randomize = HAS_FLAG("-randomize");
            remote_connect(debug, no_external, no_publish, randomize);
            save_config();
        }
        else if (cmd == "password" || cmd == "pwd" || cmd == "pass")
        {
            if (args.size() == 2)
            {
                remote_setpwd(args[1]);
                save_config();
            }
            else if (args.size() == 1)
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
            else
                return CR_WRONG_USAGE;
        }
        else if (cmd == "port" && args.size() == 2)
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
        else if (cmd == "debug" && args.size() == 2)
        {
            string &arg1 = args[1];
            if (arg1 == "on" || arg1 == "1")
                debug = true;
            else
                debug = false;
        }
        else if (cmd == "reload")
        {
            remote_unload_lua();
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
        else if (cmd == "advflags")
        {
            if (args.size() == 3)
            {
                int bit, val;
                if (parse_int(args[1], bit) && parse_int(args[2], val) && bit >= 0 && bit <= 15)
                {
                    if (val)
                        advflags |= (1<<bit);
                    else
                        advflags &= ~(1<<bit);
                }
            }

            for (int i = 15; i >= 0; i--)
                *out2 << (advflags&(1<<i) ? 1 : 0);
            *out2 << "=" << advflags << std::endl;
            
            save_config();                        
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