call "%VS100COMNTOOLS%vsvars32.bat"

set DFHACKDIR="C:\Users\vit\Desktop\buildagent\workspace\root\dfhack\0.43.03"
set DFHACKVER=0.43.03-r1
set DFVERNUM=04303

msbuild /p:Platform=Win32 /p:Configuration=Release /p:dfhack=%DFHACKDIR% /p:dfhackver=%DFHACKVER% /p:twbt_ver=%TWBT_VER% /p:dfvernum=%DFVERNUM% remote.vcxproj

