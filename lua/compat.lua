if df_ver >= 4000 and df_ver <= 4199 then --dfver:4000-4199
	require 'remote.compat_40'
	require 'remote.compat_4303'
end

if df_ver >= 4300 and df_ver <= 4399 then --dfver:4300-4304
	require 'remote.compat_43'
	require 'remote.compat_4303'
end

if df_ver >= 4300 and df_ver <= 4399 then --dfver:4305-4399
	require 'remote.compat_43'
	require 'remote.compat_4305'
end
