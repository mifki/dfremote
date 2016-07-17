--luacheck: in=
function petitions_get_list()
	local ret = {}

	for i,v in ipairs(df.global.ui.petitions) do
		local agreement = df.agreement.find(v)
		-- type = 2 - residency, type = 3 - citizenship
		if agreement and #agreement.parties == 2 and #agreement.details == 1
		   and (agreement.details[0].type == 2 or agreement.details[0].type == 3) then
			local hf_id = agreement.parties[0].histfig_ids[0]
			local hf = df.historical_figure.find(hf_id)
			local unit_id = hf and hf.unit_id or -1
			local unit = df.unit.find(unit_id)
			local unitname = unit and unit_fulltitle(unit) or '#unknown unit#'

			--todo: enum item should be used instead of 41 once it's available in dfhack
			local reason = (agreement.details[0].type == 3) and 4 or (agreement.details[0].data.data1.reason - 41)

			table.insert(ret, { unitname, v, unit_id, reason })
		end
	end

	return ret
end

--luacheck: in=number
function petition_get_info(id)
	local agreement = df.agreement.find(id)	
	if not agreement then
		error('no agreement '..tostring(id))
	end

	local atype = agreement.details[0].type
	local txt = '#unknown petition type#'
	local unitname = '#unknown unit#'
	local reason = -1

	if atype == 2 then -- residency
		local hf_id = agreement.parties[0].histfig_ids[0]
		local hf = df.historical_figure.find(hf_id)
		local unit_id = hf and hf.unit_id or -1
		local unit = df.unit.find(unit_id)
		unitname = unit and unit_fulltitle(unit) or '#unknown unit#'

		reason = agreement.details[0].data.data1.reason - 41
		--{ @"Monster Hunting", @"Entertaining", @"Soldiering", @"Study" }

		txt = 'residency'

	elseif atype == 3 then -- citizenship
		local hf_id = agreement.parties[0].histfig_ids[0]
		local hf = df.historical_figure.find(hf_id)
		local unit_id = hf and hf.unit_id or -1
		local unit = df.unit.find(unit_id)
		unitname = unit and unit_fulltitle(unit) or '#unknown unit#'
		
		local entity_id = agreement.parties[1].entity_ids[0]
		local entity = df.historical_entity.find(entity_id)
		
		local site = df.world_site.find(df.global.ui.site_id)

		reason = 4

		txt = '[C:2:0:1]' .. unitname .. ' [C:7:0:1]wishes to join [C:6:0:1]' .. translatename(entity.name, true)
		txt = txt .. ' [C:7:0:1]as a citizen of [C:6:0:1]' .. translatename(site.name, true) .. '.'
	end

	return { unitname, agreement.id, txt, reason }
end

--luacheck: in=number,bool
function petition_respond(id, approve)
	return execute_with_petitions_screen(function(ws)
		for i,v in ipairs(ws.list) do
			if v.id == id then
				ws.cursor = i
				gui.simulateInput(ws, istrue(approve) and 'OPTION1' or 'OPTION2')

				return true
			end
		end

        error('no petition '..tostring(id))		
	end)
end

--print(pcall(function() return json:encode(petition_respond(1,false)) end))