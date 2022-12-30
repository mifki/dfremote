local crime_type_names = {
	'Violation of Production Order',
	'Violation of Export Prohibition',
	'Violation of Job Order',
	'Conspiracy to Slow Labor',
	'Murder', --of ...
	'Disorderly Conduct',
	'Building Destruction',
	'Vandalism',
	'Theft',
	'Robbery',
	'Blood-drinking',
	'Embezzlement',
	'Attempted Murder',
	'Kidnapping',
	'Attempted Kidnapping',
	'Attempted Theft',
	'Treason',
	'Espionage',
	'Bribery'
}

function crime_name(crime)
	local mode = crime.mode
	local crime_name = crime_type_names[mode+1] or '#Unknown crime#'

	if crime.mode == df.crime.T_mode.Murder then
		local unit = df.unit.find(crime.victim_data.victim)
		if unit then
			crime_name = crime_name .. ' of ' .. unit_fulltitle(unit)
		end

	elseif crime.mode == df.crime.T_mode.Espionage then
		local agreement = df.agreement.find(crime.agreement_id)

		if agreement and #agreement.details > 0 and agreement.details[0].type == df.agreement_details_type.PlotInfiltrationCoup then
			local entity_id = agreement.details[0].data.PlotInfiltrationCoup.target
			local entity = df.historical_entity.find(entity_id)
			if entity then
				crime_name = crime_name .. ' against ' .. translatename(entity.name, true)
			end
		end

	elseif crime.mode == df.crime.T_mode.Theft then
		local agreement = df.agreement.find(crime.agreement_id)

		if agreement and #agreement.details > 0 and agreement.details[0].type == df.agreement_details_type.PlotStealArtifact then
			local artifact_id = agreement.details[0].data.PlotStealArtifact.artifact_id
			local artifact_record = df.artifact_record.find(artifact_id)
			if artifact_record then
				crime_name = crime_name .. ' of ' .. translatename(artifact_record.name, true)
			end
		end
	end

	return crime_name
end

--luacheck: in=
function justice_get_data()	
    if not have_noble('SHERIFF') and not have_noble('CAPTAIN_OF_THE_GUARD') then
        return { false }
    end

    return execute_with_status_page(status_pages.Justice, function(ws)
    	local ws = ws --as:df.viewscreen_justicest
    	
		local function process_crimes(ret, cases)
			for i,v in ipairs(ws.cases) do
				local convict_id = v.convict_data.convicted
				local convict_name = convict_id ~= -1 and unit_fulltitle(df.unit.find(convict_id)) or ''

				local accused = {}
				local accused_cnt = 0
				for j,w in ipairs(v.witnesses) do
					if w.accused_id ~= -1 and not accused[w.accused_id] then
						accused[w.accused_id] = true
						accused_cnt = accused_cnt + 1
					end
				end

				table.insert(ret,
					{ crime_name(v), v.id, v.mode,
					  mp.NIL, -1, --unused
					  #v.witnesses, accused_cnt,
					  convict_name, convict_id,
					  v.flags.needs_trial })
			end
		end

		local recent_cases = {}
		process_crimes(recent_cases)

		local cold_cases = {}
		gui.simulateInput(ws, K'CHANGETAB')
		process_crimes(cold_cases)

		local convicts = {}
		for i,v in ipairs(ws.convicts) do
			local fullname = unit_fulltitle(v)

			local punishment = mp.NIL
			for j,w in ipairs(df.global.ui.punishments) do
				if v.id == w.criminal then
					punishment = { w.beating, w.hammer_strikes, math.ceil((w.prison_counter+1)/TU_PER_DAY*10) } --todo: why *10 ?
				end
			end

			table.insert(convicts, { fullname, v.id, punishment, C_unit_dead(v) })
		end

		return { true, recent_cases, cold_cases, convicts, ws.jails_needed, ws.jails_present }
	end)
end

--luacheck: in=number
function justice_get_crime_details(crimeid)
	local v = df.crime.find(crimeid)
	if not v then
		error('no crime '..tostring(crimeid))
	end

	local victim_id = v.victim_data.victim
	local victim_name = victim_id ~= -1 and unit_fulltitle(df.unit.find(victim_id)) or ''

	local convict_id = v.convict_data.convicted
	local convict = df.unit.find(convict_id)
	local convict_name = convict_id ~= -1 and unit_fulltitle(convict) or ''

	local witnesses = {}
	for j,w in ipairs(v.witnesses) do
		local witness_id = w.witness_id
		local witness_unit = df.unit.find(witness_id)
		local witness_hf = df.historical_figure.find(w.witness_data.unk_hfid2) --game uses this value for display
		local witness_name = witness_id ~= -1 and (witness_unit and unit_fulltitle(witness_unit) or hfname(witness_hf,true)) or ''

		local accused_id = w.accused_id
		local accused_unit = df.unit.find(accused_id)
		local accused_hf = df.historical_figure.find(w.accused_data.unk_hfid2) --game uses this value for display
		local accused_name = accused_id ~= -1 and (accused_unit and unit_fulltitle(accused_unit) or hfname(accused_hf,true)) or ''

		local event_str = format_date(w.year, w.tick)
		local report_str = format_date(w.reported_year, w.reported_tick)

		table.insert(witnesses, {
			witness_name, witness_id,
			accused_name, accused_id,
			event_str, report_str, w.witness_claim
		})
	end

	return { crime_name(v), v.id, v.mode,
			 victim_name, victim_id,
			 convict_name, convict_id, convict and C_unit_dead(convict) or false,
			 witnesses, v.flags.needs_trial }
end

--luacheck: in=number
function justice_get_convict_info(unitid)
	local unit = df.unit.find(unitid)
	if not unit then
		error('no unit '..tostring(unitid))
	end

	local officer_id = nil
	local officer_name = mp.NIL

	local punishment = mp.NIL
	for j,w in ipairs(df.global.ui.punishments) do
		if w.criminal == unitid then
			local prison_days = w.prison_counter > 0 and math.ceil((w.prison_counter+1)/TU_PER_DAY*10) or 0 --todo: why *10 ?
			punishment = { w.beating, w.hammer_strikes, prison_days } 

			officer_id = w.officer
			officer_name = officer_id ~= -1 and unit_fulltitle(df.unit.find(officer_id)) or 'None assigned'

			break
		end
	end

	local crimes = {}
	for i,v in ipairs(df.global.world.crimes.all) do
		if v.convict_data.convicted == unitid then
			local victim_id = v.victim_data.victim
			local victim_name = victim_id ~= -1 and unit_fulltitle(df.unit.find(victim_id)) or ''

			table.insert(crimes, { crime_name(v), v.id, v.mode, victim_name, victim_id })
		end
	end

	return { unit_fulltitle(unit), unit.id, C_unit_dead(unit), punishment, crimes, officer_name, officer_id }
end

local function focus_crime(ws, crimeid)
	local idx = -1
	for i,v in ipairs(ws.cases) do
		if v.id == crimeid then
			idx = i
			break
		end
	end

	if idx == -1 then
		gui.simulateInput(ws, K'CHANGETAB')
		for i,v in ipairs(ws.cases) do
			if v.id == crimeid then
				idx = i
				break
			end
		end
	end

	if idx == -1 then
		return nil
	end

	ws.sel_idx_current = idx

	return ws.cases[idx]
end

--luacheck: in=number,bool,bool
function justice_get_convict_choices(crimeid, show_innocent, show_dead)
	show_innocent = istrue(show_innocent)
	show_dead = istrue(show_dead)

    return execute_with_status_page(status_pages.Justice, function(ws)
    	local ws = ws --as:df.viewscreen_justicest
    	local crime = focus_crime(ws, crimeid)

    	if not crime or crime.convict_data.convicted ~= -1 or not crime.flags.needs_trial then
    		error('no crime or convicted or no trial '..tostring(crimeid))
    	end

		gui.simulateInput(ws, K'SELECT')	

		if ws.cur_column ~= 2 then
			error('can not switch to choices list')
		end

		local ret = {}
		for i,unit in ipairs(ws.convict_choices) do
			if show_dead or not C_unit_dead(unit) then
				local name = unit_fulltitle(unit)

				local wcnt = 0
				for j,w in ipairs(crime.witnesses) do
					if w.accused_id == unit.id then
						wcnt = wcnt + 1
					end
				end

				if show_innocent or wcnt > 0 then
					table.insert(ret, { name, unit.id, C_unit_dead(unit), wcnt })
				end
			end
		end

		return ret
	end)
end

--luacheck: in=number,bool,bool
function justice_get_interrogate_choices(crimeid, show_innocent, show_dead)
	show_innocent = istrue(show_innocent)
	show_dead = istrue(show_dead)

    return execute_with_status_page(status_pages.Justice, function(ws)
    	local ws = ws --as:df.viewscreen_justicest
    	local crime = focus_crime(ws, crimeid)

    	if not crime then
    		error('no crime '..tostring(crimeid))
    	end

		gui.simulateInput(ws, K'JUSTICE_INTERROGATE')	

		if ws.cur_column ~= 3 then
			error('can not switch to choices list')
		end

		local ret = {}
		for i,unit in ipairs(ws.interrogate_choices) do
			if show_dead or not C_unit_dead(unit) then
				local name = unit_fulltitle(unit)

				local wcnt = 0
				for j,w in ipairs(crime.witnesses) do
					if w.accused_id == unit.id then
						wcnt = wcnt + 1
					end
				end

				if show_innocent or wcnt > 0 then
					local flags = ws.interrogate_status[i].whole
					table.insert(ret, { name, unit.id, C_unit_dead(unit), wcnt, flags })
				end
			end
		end

		return ret
	end)
end

--luacheck: in=number,number
function justice_convict(crimeid, unitid)
    return execute_with_status_page(status_pages.Justice, function(ws)
    	local ws = ws --as:df.viewscreen_justicest
    	local crime = focus_crime(ws, crimeid)

    	if not crime or crime.convict_data.convicted ~= -1 then
    		error('no crime or convicted or no trial '..tostring(crimeid))
    	end

		gui.simulateInput(ws, K'SELECT')	

		if ws.cur_column ~= 2 then
			error('can not switch to choices list')
		end

		for i,unit in ipairs(ws.convict_choices) do
			if unit.id == unitid then
				ws.cursor_right = i
				gui.simulateInput(ws, K'SELECT')

				return true
			end
		end

		error('can not find unit '..tostring(unitid))
	end)	
end

--luacheck: in=number,number
function justice_interrogate(crimeid, unitid)
    return execute_with_status_page(status_pages.Justice, function(ws)
    	local ws = ws --as:df.viewscreen_justicest
    	local crime = focus_crime(ws, crimeid)

    	if not crime then
    		error('no crime '..tostring(crimeid))
    	end

		gui.simulateInput(ws, K'JUSTICE_INTERROGATE')	

		if ws.cur_column ~= 3 then
			error('can not switch to choices list')
		end

		for i,unit in ipairs(ws.interrogate_choices) do
			if unit.id == unitid then
				ws.cursor_right = i
				gui.simulateInput(ws, K'SELECT')

				return true
			end
		end

		error('can not find unit '..tostring(unitid))
	end)	
end

--print(pcall(function() return json:encode(justice_get_data()) end))
--print(pcall(function() return json:encode(justice_get_convict_info(2520)) end))
--print(pcall(function() return json:encode(justice_get_crime_details(1)) end))
--print(pcall(function() return json:encode(justice_get_convict_choices(33)) end))
