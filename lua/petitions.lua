function petition_unitname(agreement)
	if #agreement.parties[0].histfig_ids > 0 then
		local hf_id = agreement.parties[0].histfig_ids[0]
		local hf = df.historical_figure.find(hf_id)
		local unit_id = hf and hf.unit_id or -1
		local unit = df.unit.find(unit_id)
		
		return unit and unit_fulltitle(unit) or '#unknown unit#'

	elseif #agreement.parties[0].entity_ids > 0 then
		local entity_id = agreement.parties[0].entity_ids[0]
		local entity = df.historical_entity.find(entity_id)

		return translatename(entity.name, true) or '#unknown entity#'
	end

	return '#unknown unit#'
end

--luacheck: in=
function petitions_get_list()
	local ret = {}

	for i,v in ipairs(df.global.ui.petitions) do
		local agreement = df.agreement.find(v)
		-- type = 2 - residency, type = 3 - citizenship
		if agreement and #agreement.parties == 2 and #agreement.details == 1
		   and (agreement.details[0].type == 2 or agreement.details[0].type == 3) then
			local unitname = petition_unitname(agreement)

			--todo: enum item should be used instead of 41 once it's available in dfhack
			local reason = (agreement.details[0].type == 3) and 4 or (agreement.details[0].data.data1.reason - 41)

			table.insert(ret, { unitname, v, reason })
		end
	end

	return ret
end

local petition_reasons_long = { 'monster hunting', 'entertaining citizens and visitors', 'soldiering', 'study' }

--luacheck: in=number
function petition_get_info(id)
	local agreement = df.agreement.find(id)	
	if not agreement then
		error('no agreement '..tostring(id))
	end

	local atype = agreement.details[0].type
	local txt = '#unknown petition type#'
	local unitname = petition_unitname(agreement)
	local reason = -1

	if atype == 2 then -- residency
		local site = df.world_site.find(df.global.ui.site_id)

		reason = agreement.details[0].data.data1.reason - 41

		txt = '[C:2:0:1]' .. unitname .. ' [C:7:0:1]wishes to reside in [C:6:0:1]' .. translatename(site.name, true)
		txt = txt .. ' [C:7:0:1]for the purpose of [C:2:0:1]' .. petition_reasons_long[reason+1] .. '.'

	elseif atype == 3 then -- citizenship
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
				gui.simulateInput(ws, istrue(approve) and K'OPTION1' or K'OPTION2')

				return true
			end
		end

        error('no petition '..tostring(id))		
	end)
end

--print(pcall(function() return json:encode(petition_respond(1,false)) end))