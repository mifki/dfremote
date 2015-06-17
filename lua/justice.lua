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
	'Blood-drinking'
}

function justice_get_data()	
    if not have_noble('SHERIFF') and not have_noble('CAPTAIN_OF_THE_GUARD') then
        return { false }
    end

    return execute_with_status_page(status_pages.Justice, function(ws)
		local function process_crimes(ret, cases)
			for i,v in ipairs(ws.recent_cases) do
				local victim = df.unit.find(v.victim)
				local victim_name = victim and unit_fulltitle(victim) or mp.NIL

				local convict = df.unit.find(v.convicted)
				local convict_name = convict and unit_fulltitle(convict) or mp.NIL

				local accused = {}
				local accused_cnt = 0
				for j,w in ipairs(v.reports) do
					--[[local witness = df.unit.find(w.witness)
					local witness_name = unit_fulltitle(witness)

					local accused = df.unit.find(w.accuses)
					local accused_name = unit_fulltitle(accused)]]

					if not accused[w.accuses] then
						accused[w.accuses] = true
						accused_cnt = accused_cnt + 1
					end

					--table.insert(witnesses, { witness_name, witness.id, accused_name, accused.id })
				end

				table.insert(ret,
					{ crime_type_names[v.mode+1], v.id, v.mode,
					  victim_name, v.victim,
					  #v.reports, accused_cnt,
					  convict_name, v.convicted,
					  v.flags.needs_trial })
			end
		end

		local recent_cases = {}
		process_crimes(recent_cases)

		local cold_cases = {}
		gui.simulateInput(ws, 'CHANGETAB')
		process_crimes(cold_cases)

		local convicts = {}
		for i,v in ipairs(ws.convicts) do
			local fullname = unit_fulltitle(v)

			local punishment = mp.NIL
			for j,w in ipairs(df.global.ui.punishments) do
				if v.id == w.criminal.id then
					punishment = { w.beating, w.hammer_strikes, math.ceil((w.prison_counter+1)/TU_PER_DAY*10) } --todo: why *10 ?
				end
			end

			table.insert(convicts, { fullname, v.id, punishment, v.flags1.dead })
		end

		return { true, recent_cases, cold_cases, convicts, ws.jails_needed, ws.jails_present }
	end)
end

function justice_get_crime_details(crimeid)
	local v = df.crime.find(crimeid)
	if not v then
		return nil
	end

	local victim = df.unit.find(v.victim)
	local victim_name = victim and unit_fulltitle(victim) or mp.NIL

	local convict = df.unit.find(v.convicted)
	local convict_name = convict and unit_fulltitle(convict) or mp.NIL

	local witnesses = {}
	for j,w in ipairs(v.reports) do
		local witness = df.unit.find(w.witness)
		local witness_name = witness and unit_fulltitle(witness) or mp.NIL

		local accused = df.unit.find(w.accuses)
		local accused_name = accused and unit_fulltitle(accused) or mp.NIL

		local event_str = format_date(w.event_year, w.event_time)
		local report_str = format_date(w.report_year, w.report_time)

		--xxxdfhack: until found_body is in dfhack
		local found_body = istrue(w.unk1)

		table.insert(witnesses, { witness_name, witness and witness.id or -1, accused_name, accused and accused.id or -1, event_str, report_str, found_body })
	end

	return { crime_type_names[v.mode+1], v.id, v.mode,
			 victim_name, v.victim,
			 convict_name, v.convicted, convict and convict.flags1.dead or false,
			 witnesses, v.flags.needs_trial }
end

function justice_get_convict_info(unitid)
	local unit = df.unit.find(unitid)
	if not unit then
		return
	end

	local officer = nil
	local officer_name = mp.NIL

	local punishment = mp.NIL
	for j,w in ipairs(df.global.ui.punishments) do
		if w.criminal.id == unitid then
			punishment = { w.beating, w.hammer_strikes, math.ceil((w.prison_counter+1)/TU_PER_DAY*10) } --todo: why *10 ?

			officer = w.officer
			officer_name = officer and unit_fulltitle(officer) or mp.NIL

			break
		end
	end

	local crimes = {}
	for i,v in ipairs(df.global.world.crimes.all) do
		if v.convicted == unitid then
			local victim = df.unit.find(v.victim)
			local victim_name = victim and unit_fulltitle(victim) or mp.NIL

			table.insert(crimes, { crime_type_names[v.mode+1], v.id, v.mode, victim_name, victim and victim.id or -1 })
		end
	end

	return { unit_fulltitle(unit), unit.id, unit.flags1.dead, punishment, crimes, officer_name, officer and officer.id or -1 }
end

local function focus_crime(ws, crimeid)
	local idx = -1
	for i,v in ipairs(ws.recent_cases) do
		if v.id == crimeid then
			idx = i
			break
		end
	end

	if idx == -1 then
		gui.simulateInput(ws, 'CHANGETAB')
		for i,v in ipairs(ws.recent_cases) do
			if v.id == crimeid then
				idx = i
				break
			end
		end
	end

	if idx == -1 then
		return nil
	end

	--xxxdfhack: until it's renamed to sel_idx_current
	ws.anon_1 = idx

	return ws.recent_cases[idx]
end

function justice_get_convict_choices(crimeid, show_innocent, show_dead)
	show_innocent = istrue(show_innocent)
	show_dead = istrue(show_dead)

    return execute_with_status_page(status_pages.Justice, function(ws)
    	local crime = focus_crime(ws, crimeid)

    	if not crime or crime.convicted ~= -1 or not crime.flags.needs_trial then
    		return
    	end

		gui.simulateInput(ws, 'SELECT')	

		if ws.cur_column ~= 2 then
			return
		end

		local ret = {}
		for i,unit in ipairs(ws.convict_choices) do
			if show_dead or not unit.flags1.dead then
				local name = unit_fulltitle(unit)

				local wcnt = 0
				for j,w in ipairs(crime.reports) do
					if w.accuses == unit.id then
						wcnt = wcnt + 1
					end
				end

				if show_innocent or wcnt > 0 then
					table.insert(ret, { name, unit.id, unit.flags1.dead, wcnt })
				end
			end
		end

		return ret
	end)
end

function justice_convict(crimeid, unitid)
    return execute_with_status_page(status_pages.Justice, function(ws)
    	local crime = focus_crime(ws, crimeid)

    	if not crime or crime.convicted ~= -1 or not crime.flags.needs_trial then
    		return
    	end

		gui.simulateInput(ws, 'SELECT')	

		if ws.cur_column ~= 2 then
			return
		end

		for i,unit in ipairs(ws.convict_choices) do
			if unit.id == unitid then
				ws.cursor_right = i
				gui.simulateInput(ws, 'SELECT')

				return
			end
		end
	end)	
end

--print(pcall(function() return json:encode(justice_get_data()) end))
--print(pcall(function() return json:encode(justice_get_convict_info(2520)) end))
--print(pcall(function() return json:encode(justice_get_crime_details(1)) end))
--print(pcall(function() return json:encode(justice_get_convict_choices(33)) end))
