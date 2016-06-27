if df_ver <= 40 then
	require 'remote.compat_40'
end

if df_ver <= 42 then
	require 'remote.compat_42'
end

if df_ver <= 43 then
	require 'remote.compat_43'
end





function C_ws_cases(ws)
	return ws.cases --recent_cases before 0.42
end

function C_ws_set_sel_idx_current(ws, idx)
	ws.sel_idx_current = idx --anon_1 before 0.42
end

function C_pet_set_available(item, val)
	item.pet_flags.available_for_adoption = val --anon_2 before 0.42 and use "val and 1 or 0"
end

function C_pet_available(item)
	return item.pet_flags.available_for_adoption --anon_2 before 0.42 and use istrue()
end

function C_pet_ownerid(item)
	return item.owner_id --item['item_petst.anon_1'] before 0.42
end