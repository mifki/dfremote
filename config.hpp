static bool parse_int(std::string &str, int &ret, int base=10)
{
    char *e;
    ret = strtol(str.c_str(), &e, base);
    return (*e == 0);
}

static bool parse_float(std::string &str, float &ret)
{
    char *e;
    ret = strtod(str.c_str(), &e);
    return (*e == 0);
}

template <class T>
static bool parse_enum_or_int(std::string &str, int &ret, int def=-1)
{
    T val;

    if (str.length())
    {
        if (!parse_int(str, ret))
        {  
            if (find_enum_item(&val, str))
                ret = val;
            else
                return false;
        }
    }
    else
        ret = def;

    return true;
}

static vector<string> split(const char *str, char c = ' ')
{
    vector<string> result;

    do
    {
        const char *begin = str;

        while(*str != c && *str)
            str++;

        result.push_back(string(begin, str));
    } while (0 != *str++);

    return result;
}

static bool load_config()
{
    bool enabled = false;

    std::ifstream fseed("data/init/remote.txt");
    if(!fseed.is_open())
        return false;
        
    char *pwd = getenv("DFREMOTE_PWD");
    if (pwd)
        pwd_hash = hash_password(std::string(pwd));
    else
        pwd_hash = getenv("DFREMOTE_PWD_HASH") ?: "";

    string str;
    while(std::getline(fseed,str))
    {
        size_t b = str.find("[");
        size_t e = str.rfind("]");

        if (b == string::npos || e == string::npos || str.find_first_not_of(" ") < b)
            continue;

        str = str.substr(b+1, e-1);
        vector<string> tokens = split(str.c_str(), ':');

        if (tokens[0] == "ENABLED" && tokens.size() == 2)
        {
            int val;
            if (parse_int(tokens[1], val))
                enabled = val;

            continue;
        }

        if (tokens[0] == "PORT" && tokens.size() == 2)
        {
            int val;
            if (parse_int(tokens[1], val))
                enet_port = val;

            continue;
        }

        if (tokens[0] == "PUBLISH_NAME" && tokens.size() == 2)
        {
            publish_name = tokens[1];
            continue;
        }

        if (tokens[0] == "PWD" && tokens.size() == 2)
        {
            pwd_hash = tokens[1];
            continue;
        }
        
        if (tokens[0] == "ADVFLAGS" && tokens.size() == 2)
        {
            int val;
            if (parse_int(tokens[1], val))
                advflags = val;

            continue;
        }
    }

    return enabled;
}

void save_config()
{
     std::ofstream ofs;
     ofs.open("data/init/remote.txt", std::ofstream::out|std::ofstream::trunc);

     if(!ofs.is_open())
        return;

    ofs << "[ENABLED:" << (int)remote_on << "]" << std::endl;
    ofs << "[PORT:" << enet_port << "]" << std::endl;
    ofs << "[PUBLISH_NAME:" << publish_name << "]" << std::endl;
    ofs << "[PWD:" << pwd_hash << "]" << std::endl;
    
    if (advflags)
        ofs << "[ADVFLAGS:" << advflags << "]" << std::endl;
}