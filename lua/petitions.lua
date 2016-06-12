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

function petition_respond(id, approve)
end

--print(pcall(function() return json:encode(petitions_get_list()) end))