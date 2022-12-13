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

--[[
        <enum-item name="eradicate_beasts">
            <item-attr name="caption" value="in order to eradicate beasts"/>
        </enum-item>
        <enum-item name="entertain_people">
            <item-attr name="caption" value="in order to entertain people"/>
        </enum-item>
        <enum-item name="make_a_living_as_a_warrior">
            <item-attr name="caption" value="in order to make a living as a warrior"/>
        </enum-item>
        <enum-item name="study">
            <item-attr name="caption" value="in order to study"/>
        </enum-item>
        <enum-item name="flight">
            <item-attr name="caption" value="in order to flee"/>
        </enum-item>
        <enum-item name="scholarship">
            <item-attr name="caption" value="in order to pursue scholarship"/>
        </enum-item>
        <enum-item name="be_with_master">
            <item-attr name="caption" value="in order to be with the master"/>
        </enum-item>
        <enum-item name="become_citizen">
            <item-attr name="caption" value="in order to become a citizen"/>
        </enum-item>
        <enum-item name="prefers_working_alone">
            <item-attr name="caption" value="in order to continue working alone"/>
        </enum-item>


]]

local petition_reason_short = {
	[df.history_event_reason.eradicate_beasts] = 'Monster Hunting',
	[df.history_event_reason.entertain_people] = 'Entertaining',
	[df.history_event_reason.make_a_living_as_a_warrior] = 'Soldiering',
	[df.history_event_reason.study] = 'Study'
}

local petition_reasons_long = {
	[df.history_event_reason.eradicate_beasts] = 'eradicating monsters',
	[df.history_event_reason.entertain_people] = 'entertaining citizens and visitors',
	[df.history_event_reason.make_a_living_as_a_warrior] = 'soldiering',
	[df.history_event_reason.study] = 'study'
}

--luacheck: in=
function petitions_get_list()
	local ret = {}

	for i,v in ipairs(df.global.ui.petitions) do
		local agreement = df.agreement.find(v)
		-- type = 2 - residency, type = 3 - citizenship
		if agreement and #agreement.parties == 2 and #agreement.details == 1 then
			local unitname = petition_unitname(agreement)
			local atype = agreement.details[0].type

			if atype == df.agreement_details_type.Residency then
				local reason = agreement.details[0].data.Residency.reason

				table.insert(ret, { unitname, v, petition_reason_short[reason] })

			elseif atype == df.agreement_details_type.Citizenship then
				table.insert(ret, { unitname, v, 'Citizenship' })
			end
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
	local unitname = petition_unitname(agreement)

	if atype == df.agreement_details_type.Residency then
		local site = df.world_site.find(agreement.details[0].data.Residency.site)

		local reason = agreement.details[0].data.Residency.reason

		txt = '[C:2:0:1]' .. unitname .. ' [C:7:0:1]wishes to reside in [C:6:0:1]' .. translatename(site.name, true)
		txt = txt .. ' [C:7:0:1]for the purpose of [C:2:0:1]' .. petition_reasons_long[reason] .. '.'

	elseif atype == df.agreement_details_type.Citizenship then
		local entity_id = agreement.parties[1].entity_ids[0]
		local entity = df.historical_entity.find(entity_id)
		
		local site = df.world_site.find(agreement.agreement.details[0].data.Residency.site)

		txt = '[C:2:0:1]' .. unitname .. ' [C:7:0:1]wishes to join [C:6:0:1]' .. translatename(entity.name, true)
		txt = txt .. ' [C:7:0:1]as a citizen of [C:6:0:1]' .. translatename(site.name, true) .. '.'
	end

	return { unitname, agreement.id, txt }
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