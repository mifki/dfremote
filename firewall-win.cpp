#include <windows.h>
#include <crtdbg.h>
#include <netfw.h>
#include <objbase.h>
#include <oleauto.h>
#include <stdio.h>
#include <comutil.h>
#include <tchar.h>
#include <strsafe.h>

#include "Core.h"

#pragma comment( lib, "ole32.lib" )
#pragma comment( lib, "oleaut32.lib" )
#pragma comment( lib, "mpr.lib" )

using namespace DFHack;

void check_open_firewall(color_ostream *out2, int port)
{
	HRESULT hr, comInit;
    INetFwMgr* fwMgr = NULL;

    // Initialize COM. Ignore RPC_E_CHANGED_MODE; this just means that COM has already been initialized
	// with a different mode. Since we don't care what the mode is, we'll just use the existing mode.
    comInit = CoInitializeEx(0, COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE);
	if (FAILED(comInit) && comInit != RPC_E_CHANGED_MODE)
	{
	    *out2 << COLOR_LIGHTRED << "CoInitializeEx failed " << comInit << std::endl;
	    *out2 << COLOR_RESET;
		goto error;
	}

    hr = CoCreateInstance(__uuidof(NetFwMgr), NULL, CLSCTX_INPROC_SERVER, __uuidof(INetFwMgr), (void**)&fwMgr);
    if (FAILED(hr))
    {
	    *out2 << COLOR_LIGHTRED << "WindowsFirewallInitialize failed " << hr << std::endl;
	    *out2 << COLOR_RESET;
        goto error;
    }

	TCHAR fwProcessImageFileName[MAX_PATH+1];
	GetModuleFileName(NULL, fwProcessImageFileName, MAX_PATH);

	WCHAR temp;
    char *unibuf = NULL;
    DWORD bufsize = 0;
    TCHAR *fwProcessImageFileNameFull = fwProcessImageFileName;

    if (WNetGetUniversalName(fwProcessImageFileName, UNIVERSAL_NAME_INFO_LEVEL, (LPVOID) &temp, &bufsize) == ERROR_MORE_DATA)
    {
        unibuf = new char[bufsize];
        if (WNetGetUniversalName(fwProcessImageFileName, UNIVERSAL_NAME_INFO_LEVEL, (LPVOID) unibuf, &bufsize) == NO_ERROR)
        	fwProcessImageFileNameFull = ((UNIVERSAL_NAME_INFO*)unibuf)->lpUniversalName;
    }	

    CharLower(fwProcessImageFileNameFull);

	BSTR fwBstrProcessImageFileName = SysAllocString(fwProcessImageFileNameFull);
	VARIANT allowed, restricted;

	hr = fwMgr->IsPortAllowed(fwBstrProcessImageFileName, NET_FW_IP_VERSION_ANY, port, NULL, NET_FW_IP_PROTOCOL_UDP, &allowed, &restricted);
	SysFreeString(fwBstrProcessImageFileName);

    if (FAILED(hr))
    {
	    *out2 << COLOR_LIGHTRED << "IsPortAllowed failed " << hr << std::endl;
	    *out2 << COLOR_RESET;
        goto error;
    }

	if (allowed.boolVal == VARIANT_FALSE || restricted.boolVal == VARIANT_TRUE)
	{
		if (MessageBox(NULL, _T("Do you want Dwarf Fortress Remote to adjust firewall settings to allow connections to your game?"), _T("Firewall Is Blocking Dwarf Fortress Remote"), MB_YESNO|MB_ICONEXCLAMATION|MB_APPLMODAL) == IDYES)
		{
			int cmdlen = _tcslen(fwProcessImageFileNameFull) * 2 + 256;
			TCHAR *cmd = new TCHAR[cmdlen];
			StringCchPrintf(cmd, cmdlen, _T("/C netsh advfirewall firewall delete rule name=all program=\"%s\" & netsh advfirewall firewall add rule name=\"Dwarf Fortress Remote\" dir=in protocol=UDP action=allow program=\"%s\" enable=yes"), fwProcessImageFileNameFull, fwProcessImageFileNameFull);

			SHELLEXECUTEINFO shExInfo = { 0 };
			shExInfo.cbSize = sizeof(shExInfo);
			shExInfo.fMask = SEE_MASK_NOCLOSEPROCESS;
			shExInfo.hwnd = 0;
			shExInfo.lpVerb = _T("runas");
			shExInfo.lpFile = _T("cmd");
			shExInfo.lpParameters = cmd;
			shExInfo.lpDirectory = 0;
			shExInfo.nShow = SW_HIDE;
			shExInfo.hInstApp = 0;  

		    *out2 << COLOR_YELLOW << "Dwarf Fortress Remote will now update firewall settings" << std::endl;
		    *out2 << COLOR_RESET;

			DWORD exitCode = -1;
			if (ShellExecuteEx(&shExInfo))
			{
				WaitForSingleObject(shExInfo.hProcess, INFINITE);
				GetExitCodeProcess(shExInfo.hProcess, &exitCode);
				CloseHandle(shExInfo.hProcess);
			}

			if (!exitCode)
			{
			    *out2 << COLOR_LIGHTGREEN << "Dwarf Fortress Remote has successfully updated firewall settings" << std::endl;
			    *out2 << COLOR_RESET;					
			}
			else
			{
			    *out2 << COLOR_LIGHTRED << "Dwarf Fortress Remote could not update firewall settings" << std::endl;
			    *out2 << COLOR_RESET;					
			}

			delete[] cmd;
		}
	}

	error:

	if (unibuf)
		delete[] unibuf;

    if (fwMgr != NULL)
        fwMgr->Release();

    if (SUCCEEDED(comInit))
        CoUninitialize();
}