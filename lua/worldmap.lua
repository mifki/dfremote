--luacheck: in=
function worldmap_enter()
	return execute_with_main_mode(df.ui_sidebar_mode.Default, function(ws)
		gui.simulateInput(ws, K'D_CIVLIST')
		return true
	end, true)
end
