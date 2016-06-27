--todo: access to .anon_1 will crash on Windows !!

--luacheck: in=
function petitions_get_list()
	local ret = {}

	for i,v in ipairs(df.global.ui.petitions) do
		local agreement = utils.binsearch(df.global.world.agreements.all, v, 'anon_1')
		if agreement and #agreement.anon_2 == 2 and #agreement.anon_4 == 1 and agreement.anon_4[0].type == 2 then
			local reason = agreement.anon_4[0].data.data1.anon_1
			local hf_id = agreement.anon_2[0].anon_2[0]
			local hf = df.historical_figure.find(hf_id)
			local unit_id = hf and hf.unit_id or -1
			local unit = df.unit.find(unit_id)
			local unitname = unit and unit_fulltitle(unit) or '#unknown unit#'

			table.insert(ret, { unitname, v, unit_id, reason-41 })
		end
	end

	return ret
end

--luacheck: in=number,bool
function petition_respond(id, approve)
	return execute_with_petitions_screen(function(ws)
		for i,v in ipairs(ws.anon_1) do
			local p = df.reinterpret_cast(df.agreement, v)

			if p.anon_1 == id then
				ws.cursor = i
				gui.simulateInput(ws, istrue(approve) and 'OPTION1' or 'OPTION2')

				return true
			end
		end

        error('no petition '..tostring(id))		
	end)
end

--print(pcall(function() return json:encode(petition_respond(1,false)) end))