if df_ver >= 4000 and df_ver <= 4199 then
	require 'remote.compat_40'
end

if df_ver >= 4200 and df_ver <= 4399 then
	require 'remote.compat_42'
end

if df_ver >= 4300 and df_ver <= 4399 then
	require 'remote.compat_43'
end
