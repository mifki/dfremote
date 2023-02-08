#include <sys/types.h>
#include <string.h> 

#ifdef WIN32
	#include <winsock.h>
	#include <ws2tcpip.h>
#else
	#include <sys/ioctl.h>
	#include <ifaddrs.h>
	#include <netinet/in.h> 
	#include <arpa/inet.h>
	#include <unistd.h>
	#include <net/if.h>
	#include <netdb.h>
#endif

#include "QR_Encode.h"

string format_ip(uint32_t ip)
{
	struct in_addr a;
	a.s_addr = ip;
	
	return inet_ntoa(a);
}

bool get_ip_with_inet(uint32_t *ip) 
{
    int sock = socket(AF_INET, SOCK_DGRAM, 0);

    struct sockaddr_in serv = { 0 };
    serv.sin_family = AF_INET;
    serv.sin_addr.s_addr = inet_addr("8.8.8.8");
    serv.sin_port = htons(53);

    if (connect(sock, (const sockaddr*) &serv, sizeof(serv)))
    	return false;

    sockaddr_in name;
    socklen_t namelen = sizeof(name);
    
    if (getsockname(sock, (sockaddr*) &name, &namelen))
    	return false;

    *ip = name.sin_addr.s_addr;

#ifdef WIN32
    closesocket(sock);
#else
    close(sock);
#endif
    
    return true;
}

bool get_all_ips(vector<uint32_t> &ips)
{
#ifdef WIN32

    char szBuffer[1024];

    if(gethostname(szBuffer, sizeof(szBuffer)) == -1)
    	return false;

    struct hostent *host = gethostbyname(szBuffer);
    if(!host)
      return false;

  	bool found = false;
	for (int i = 0; host->h_addr_list[i]; i++)
	{
		uint32_t ip = ((struct in_addr*)host->h_addr_list[i])->s_addr;
		if ((ip & htonl(0xff000000)) != htonl(0x7f000000))
		{
			ips.push_back(ip);
			found = true;
		}
    }

    return found;

#else

	struct ifaddrs *ifas;
	if (getifaddrs (&ifas))
		return false;

  	bool found = false;
	for (struct ifaddrs *ifa = ifas; ifa; ifa = ifa->ifa_next)
	{
		if (!ifa->ifa_addr || ifa->ifa_addr->sa_family != AF_INET)
			continue;

		if ((ifa->ifa_flags & IFF_LOOPBACK) || !(ifa->ifa_flags & IFF_RUNNING))
			continue;

		uint32_t ip = ((struct sockaddr_in*)ifa->ifa_addr)->sin_addr.s_addr;
		ips.push_back(ip);
		found = true;
	}
	
	freeifaddrs (ifas);
	return true;

#endif
}

bool get_private_ip_list(color_ostream &out, vector<uint32_t> &ips, bool debug)
{
	// First try finding address of an interface with a route to Internet (8.8.8.8)
	uint32_t ip;
	if (get_ip_with_inet(&ip))
	{
		if (debug)
			out << "Found IP with Internet route: " << format_ip(ip) << std::endl;
		ips.push_back(ip);
		return true;
	}

	// If that fails, get addresses for all network adapters, and send them all to the app
	if (get_all_ips(ips))
	{
		if (debug)
		{
			out << "Found all IPs:";
			for (auto it = ips.cbegin(); it < ips.cend();it++)
				out << " " << format_ip(*it);
			out << std::endl;
		}

		return true;
	}

	return false;
}

bool get_public_ip(uint32_t *ip, int *port)
{
    ENetAddress mediation_address;
    enet_address_set_host (&mediation_address, "dfmed.mifki.com");
    mediation_address.port = 1233;

    ip_check_done = false;
    ip_check_peer = enet_host_connect (server, &mediation_address, 2, 0);
    if (!ip_check_peer)
    	return false;

    // Wait for the network thread to do the job
    enet_uint32 start = enet_time_get();
    do {
#ifdef WIN32
		Sleep (200); // 200 milliseconds 
#else
	    usleep(200*1000); // 200 milliseconds in microseconds
#endif
	} while (!ip_check_done && enet_time_get() - start < 5000);

    //TODO: call enet_peer_disconnect() ? enet_peer_disconnect_now() ?
    enet_peer_reset(ip_check_peer);
    ip_check_peer = NULL;

    if (ip_check_done)
    {
    	*ip = ext_addr.host;
    	*port = ext_addr.port;
    	return true;
    }

    return false;
}

void ensure_publish_details(bool debug, bool randomize)
{
	// Generate name and password
	// Don't generate password if there was a name, i.e. user deliberately didn't set password

#ifdef arc4random
    #define RND arc4random
#else
    srand(time(NULL));    
    #define RND rand    
#endif 

	if (randomize || !publish_name.size())
	{
		string s = "";
		for (int j = 0; j < 3; j++)
		{
			for (int i = 0; i < 4; i++)
				s += 'a' + (RND()%26);
			if (j < 2)
				s += '-';
		}

		publish_name = s;
        save_config();

		if (randomize || !pwd_hash.size())
		{
			string s = "";
			for (int i = 0; i < 16; i++)
				s += 1 + (RND()%255);
			pwd_hash = hash_password(s);
	        save_config();
		}
	}
}

void output_qrcode(color_ostream &out, uint8_t *data, int width)
{
#ifdef WIN32
	// On Windows, setting color passes the value directly to SetConsoleTextAttribute, which can set bg color too
	#define WHITE (color_value)(BACKGROUND_RED|BACKGROUND_GREEN|BACKGROUND_BLUE) << "  " 
	#define BLACK (color_value)0 << "  "
#else
	#define WHITE "\033[47m  \033[0m"
	#define BLACK "\033[40m  \033[0m"
#endif

	for (int x = 0; x < width+2; x++)
		out << WHITE;
	out << COLOR_RESET << std::endl;

	for (int y = 0; y < width; y++) {
		out << WHITE;
		for (int x = 0; x < width; x++) {
			int byte = (x * width + y) / 8;
			int bit = (x * width + y) % 8;
			int value = data[byte] & (0x80 >> bit);
			if (value)
				out << BLACK;
			else
				out << WHITE;
		}

		out << WHITE;
		out << COLOR_RESET << std::endl;
	}

	for (int x = 0; x < width+2; x++)
		out << WHITE;
	out << COLOR_RESET << std::endl;
}

void show_qrcode_with_data(color_ostream &out, uint8_t *rawdata, int rawsz)
{
	// Convert binary to numeric as built-in iOS QR Code decoding can return strings only
	char *buf = new char[rawsz*3];
	for (int i = 0; i < rawsz; i++)
		sprintf(buf+i*3, "%03d", rawdata[i]);

	//out << buf << std::endl;

	uint8_t data[MAX_BITDATA];
	int width = EncodeData(QR_LEVEL_L, 0, buf, 0, data);
	delete[] buf;

	output_qrcode(out, data, width);
}

void remote_connect(color_ostream &out, bool debug, bool no_external, bool no_publish, bool randomize, bool firewall)
{
#ifdef WIN32
	check_open_firewall(&out, enet_port);
#endif
	if (firewall)
		return;

	if (!remote_start())
	{
		out << COLOR_RED << "Error starting Remote server, can not proceed" << std::endl;
		out << COLOR_RESET;
		return;
	}

	vector<uint32_t> ips;
	get_private_ip_list(out, ips, debug);

	//TODO: check error and don't proceed if no ips
	//TODO: show warning if > 7 ips
	//TODO: check public ip only if private ip is from inet route

	bool publish = !no_publish;
	if (!no_external && publish_name.empty())
	{
		uint32_t pub_ip;
		int pub_port;
		bool pub_ok = get_public_ip(&pub_ip, &pub_port);

		if (enet_port == pub_port && std::find(ips.begin(), ips.end(), pub_ip) != ips.end())
		{
			out << "Computer seems to have an externally accessible IP " << format_ip(pub_ip) << std::endl;
			out << "therefore server will not be published; use `remote connect -no-external` to change this." << std::endl;

			ips.clear();
			ips.push_back(pub_ip);

			publish = false;			
		}
		else if (debug)
		{
			out << "External address " << format_ip(pub_ip) << ":" << pub_port << " does not match private IPs and port " << enet_port << std::endl;
		}
	}

	if (publish)
		ensure_publish_details(debug, randomize);

	bool has_pwd = !pwd_hash.empty();

	// Status byte + IPs + port + password (if any) + published name
	int rawsz = 1 + ips.size()*4 + 2 + (publish ? ((has_pwd ? 32 : 0) + publish_name.length()) : 0);
	uint8_t *rawdata = new uint8_t[rawsz];
	uint8_t *rawptr = rawdata;

	// 1. Status byte -  flags & number of IPs
	*rawptr++ = (publish << 4) | (has_pwd << 3) | (ips.size() & 3);

	// 2. List of IPs
	for (int i = 0; i < ips.size() & 3; i++)
	{
		*(uint32_t*)rawptr = ips[i];
		rawptr += 4;
	}

	// 3. Port
	*(uint16_t*)rawptr = enet_port;
	rawptr += 2;

	if (publish)
	{
		// 4. Password hash
		if (has_pwd)
		{
		    for (int i = 0; i < 32; i++)
		    	sscanf(pwd_hash.c_str()+i*2, "%02x", rawptr++);
		}

	    // 5. Published name
	    memcpy(rawptr, publish_name.c_str(), publish_name.length());
	    rawptr += publish_name.length();

	    if (debug)
	    	out << "Publishing server with name " << publish_name << " and password hash " << pwd_hash << std::endl;
	}

	out << COLOR_LIGHTGREEN << "Scan the QR code below with Dwarf Fortress Remote iOS app to connect to this server" << std::endl;

    show_qrcode_with_data(out, rawdata, rawsz);
    delete[] rawdata;

	out << COLOR_LIGHTGREEN << "Scan the QR code above with Dwarf Fortress Remote iOS app to connect to this server" << std::endl;

    // So that any messages from another thread during connection don't interrupt QR code output
    if (publish)
		remote_publish(publish_name);    	

	out << "If you like the game, consider supporting Dwarf Fortress authors, Tarn and Zach Adams. Visit bay12games.com/support.html" << std::endl;
}