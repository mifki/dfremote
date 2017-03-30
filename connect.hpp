#include <sys/types.h>
#include <sys/ioctl.h>
#include <ifaddrs.h>
#include <netinet/in.h> 
#include <string.h> 
#include <arpa/inet.h>
#include <unistd.h>
#include <net/if.h>
#include <netdb.h>

#include "QR_Encode.h"

bool get_ip_with_inet(long *ip) 
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

    close(sock);

    return true;
}

bool get_all_ips(vector<long> &ips)
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
		long ip = ((struct in_addr*)host->h_addr_list[i])->s_addr;
		if ((ip & htonl(0xff000000)) != htonl(0x7f000000))
		{
			ips.push_back(ip);
			found = true;
		}
    }

    return found;

#else

	struct ifaddrs *_ifap, *_ifa;
	if (getifaddrs (&_ifap))
		return false;

  	bool found = false;
	for (_ifa = _ifap; _ifa; _ifa = _ifa->ifa_next)
	{
		if (!_ifa->ifa_addr || _ifa->ifa_addr->sa_family != AF_INET)
			continue;

		if ((_ifa->ifa_flags & IFF_LOOPBACK) || !(_ifa->ifa_flags & IFF_RUNNING))
			continue;

		long ip = ((struct sockaddr_in*)_ifa->ifa_addr)->sin_addr.s_addr;
		ips.push_back(ip);
		found = true;
	}
	
	freeifaddrs (_ifap);
	return true;

#endif
}

bool get_private_ip_list(vector<long> &ips)
{
	// First try finding address of an interface with a route to Internet (8.8.8.8)
	long ip;
	if (get_ip_with_inet(&ip))
	{
		ips.push_back(ip);
		return true;
	}

	// If that failes, get addresses for all network adapters
	if (get_all_ips(ips))
		return true;

	return false;
}

void output_qrcode(uint8_t *data, int width)
{
	for (int x = 0; x < width; x++)
		*out2 << "\033[47m  \033[0m";
	for (int y = 0; y < width; y++) {
		*out2 << "\033[47m  \033[0m";
		for (int x = 0; x < width; x++) {
			int byte = (x * width + y) / 8;
			int bit = (x * width + y) % 8;
			int value = data[byte] & (0x80 >> bit);
			*out2 << (value ? "\033[40m  \033[0m" : "\033[47m  \033[0m");
		}

		*out2 << "\033[47m  \033[0m";
		*out2 << std::endl;
	}
	for (int x = 0; x < width; x++)
		*out2 << "\033[47m  \033[0m";	
}

void remote_connect()
{
	vector<long> ips;
	
	get_private_ip_list(ips);

	for (auto it = ips.cbegin(); it<ips.cend();it++)
	{
		struct in_addr a;
		a.s_addr = *it;
		*out2 << inet_ntoa(a) << std::endl;
	}
*out2 << "test" << std::endl;
	uint8_t data[MAX_BITDATA] = {};
	long ip = ips[0];
	int width = EncodeData(QR_LEVEL_L, QR_VERSION_M, (char*)&ip, sizeof(long), data);

	output_qrcode(data, width);
}