function C_embark_get_profile_name(ws, idx)
	if dfhack.VERSION == '0.43.05-r1' then
		--xxx: ws.choices is holding a list of profiles, but the structure is unknown. the first field is string and is the name
		--xxx: so we reinterpret pointers as some other class that has string name as first field, just to access it from Lua easily
		--xxx: in 0.43.05-r1 this list is int32 instead of int64
		local ptr = (ws.choices[idx*2+1] << 32) + ws.choices[idx*2]
		local name = df.reinterpret_cast(df.interaction,ptr).name

		return name
	end

	return ws.choices[idx].name
end

function C_location_finder(finder)
	if dfhack.VERSION == '0.43.05-r1' then
		local size,addr = finder:sizeof()
		local _finder = df.reinterpret_cast(df.viewscreen_choose_start_sitest.T_finder, addr-4) --as:df.viewscreen_choose_start_sitest.T_finder
		return _finder
	end

	return finder
end
