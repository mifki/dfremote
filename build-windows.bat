call "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat" amd64

set DFHACKDIR="C:\Users\vit\Desktop\buildagent\workspace\root\dfhack\0.43.05"
set DFHACKVER=0.43.05-r1
set DFVERNUM=04305


msbuild /p:Platform=x64 /p:Configuration=Release /p:dfhack=%DFHACKDIR% /p:dfhackver=%DFHACKVER% /p:twbt_ver=%TWBT_VER% /p:dfvernum=%DFVERNUM% remote64.vcxproj

copy dist\0.43.05-r1\remote.plug.dll z:\df_43_05_win\hack\plugins