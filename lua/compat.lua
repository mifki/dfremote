if df_ver >= 4305 and df_ver <= 4399 then --dfver:4305-4399
	require 'remote.compat_43'
end

if df_ver >= 4412 and df_ver <= 4499 then --dfver:4412-4499
	require 'remote.compat_44'
end

if df_ver >= 4705 and df_ver <= 4799 then --dfver:4705-4799
	require 'remote.compat_47'
end
