--luacheck: in=
function schedule_get_overview()
	local squads = {}
	for i,squad in ipairs(find_fortress_squads()) do
		local alerts = {}
		for j,a in ipairs(squad.schedule) do
			local months = {}
			for m,sched in ipairs(a) do
				if #sched.orders > 0 then
					if #sched.orders > 1 then
						local last = nil
						local same = true
						for i,sched_order in ipairs(sched.orders) do
							local order = sched_order.order
							local otype = order:getType()
							
							if last and otype ~= last then
								same = false
							end
							last = otype
						end

						table.insert(months, { same and last or -2, sched.sleep_mode, sched.uniform_mode })

					else
						local sched_order = sched.orders[0]
						local order = sched_order.order
						local otype = order:getType()

						table.insert(months, { otype, sched.sleep_mode, sched.uniform_mode })
					end

				else
					table.insert(months, { -1, sched.sleep_mode, sched.uniform_mode })
				end
			end
			table.insert(alerts, months)
		end
		table.insert(squads, { squadname(squad), squad.id, alerts })
	end

	local alerts = {}
    for i,alert in ipairs(df.global.ui.alerts.list) do
    	table.insert(alerts, { alertname(alert), alert.id })
	end	

	return { squads, alerts }
end

--luacheck: in=
function schedule_get_overview2()
	local squads = {}
	for i,squad in ipairs(find_fortress_squads()) do
		local alerts = {}
		for j,a in ipairs(squad.schedule) do
			local months = {}
			for m,sched in ipairs(a) do
				if #sched.orders > 0 then
					if #sched.orders > 1 then
						local last = nil
						local same = true
						for i,sched_order in ipairs(sched.orders) do
							local order = sched_order.order
							local otype = order:getType()
							
							if last and otype ~= last then
								same = false
							end
							last = otype
						end

						table.insert(months, same and last or -2)

					else
						--todo: can be >1 ??
						local sched_order = sched.orders[0]
						local order = sched_order.order
						local otype = order:getType()
						
						table.insert(months, otype)
					end
				else
					table.insert(months, -1)
				end
			end
			table.insert(alerts, months)
		end
		table.insert(squads, { squadname(squad), squad.id, alerts })
	end

	local alerts = {}
    for i,alert in ipairs(df.global.ui.alerts.list) do
    	table.insert(alerts, { alertname(alert), alert.id })
	end	

	return { squads, alerts }
end

--luacheck: in=number,number
function schedule_get_months(squadid, alertid)
	local alertidx = alert_id2index(alertid)
	if alertidx == -1 then
		return
	end

	local squad = df.squad.find(squadid)

	local months = {}
	for m,sched in ipairs(squad.schedule[alertidx]) do
		if #sched.orders > 0 then
			if #sched.orders > 1 then
				local last = nil
				local same = true
				for i,sched_order in ipairs(sched.orders) do
					local order = sched_order.order
					local otype = order:getType()
					
					if last and otype ~= last then
						same = false
					end
					last = otype
				end

				table.insert(months, { same and last or -2, sched.sleep_mode, sched.uniform_mode, -1 })

			else
				local sched_order = sched.orders[0]
				local order = sched_order.order
				local otype = order:getType()

				table.insert(months, { otype, sched.sleep_mode, sched.uniform_mode, sched_order.min_count })
			end
		else
			table.insert(months, { -1, sched.sleep_mode, sched.uniform_mode, -1 })
		end
	end

	local cur_month = math.floor(df.global.cur_year_tick / 33600)

	return { months, cur_month }
end

--todo: order objects we're deleting may be references somewhere else, so maybe it's better to do this using the UI
--luacheck: in=number,number,number
function schedule_month_duplicate_to_all(squadid, alertid, month)
	local alertidx = alert_id2index(alertid)
	if alertidx == -1 then
		return
	end

	local squad = df.squad.find(squadid)
	local sched = squad.schedule[alertidx][month]

	for m,sched2 in ipairs(squad.schedule[alertidx]) do
		if m ~= month then
			sched2.name = sched.name
			sched2.sleep_mode = sched.sleep_mode
			sched2.uniform_mode = sched.uniform_mode

			for i,o in ipairs(sched2.orders) do
				o.order:delete()
				o:delete()
			end
			sched2.orders:resize(0)

			for i,sched_order in ipairs(sched.orders) do
				local sched_order2 = df.squad_schedule_order:new()
				
				sched_order2.order = sched_order.order:clone()
				sched_order2.min_count = sched_order.min_count

				--xxx: sched_order2.positions:insert(j,pos) crashes for some reason
				sched_order2.positions:resize(#sched_order.positions)
				for j,pos in ipairs(sched_order.positions) do
					sched_order2.positions[j] = pos
				end

				sched2.orders:insert(i, sched_order2)
			end

			--todo: order_assignments ?
		end
	end
end

--luacheck: in=number,number,number,number,number
function schedule_set_options(squadid, alertid, month, sleep_mode, uniform_mode)
	local alertidx = alert_id2index(alertid)
	if alertidx == -1 then
		return
	end

	local squad = df.squad.find(squadid)
	local sched = squad.schedule[alertidx][month]

	sched.sleep_mode = sleep_mode
	sched.uniform_mode = uniform_mode	
end

--luacheck: in=number,number,number
function schedule_get_orders(squadid, alertid, month)
	local alertidx = alert_id2index(alertid)
	if alertidx == -1 then
		return
	end

	local squad = df.squad.find(squadid)
	local sched = squad.schedule[alertidx][month]

	local orders = {}
	for i,sched_order in ipairs(sched.orders) do
		local order = sched_order.order
		local otype = order:getType()
		local title = utils.call_with_string(order, 'getDescription')

		table.insert(orders, { title, otype, sched_order.min_count })
	end

	return { orders, sched.sleep_mode, sched.uniform_mode }
end

--luacheck: in=number,number,number,number
function schedule_order_get(squadid, alertid, month, orderidx)
	local alertidx = alert_id2index(alertid)
	if alertidx == -1 then
		return
	end

	local squad = df.squad.find(squadid)
	local sched = squad.schedule[alertidx][month]
	local sched_order = sched.orders[orderidx]
	local order = sched_order.order

	local otype = order:getType()
	local title = utils.call_with_string(order, 'getDescription')

	return { title, otype, sched_order.min_count }
end

--luacheck: in=number,number,number,number,number
function schedule_order_set_mincount(squadid, alertid, month, orderidx, min_count)
	local alertidx = alert_id2index(alertid)
	if alertidx == -1 then
		return
	end

	local squad = df.squad.find(squadid)
	local sched = squad.schedule[alertidx][month]
	local sched_order = sched.orders[orderidx]

	sched_order.min_count = min_count
end

--luacheck: in=number,number,number,number
function schedule_order_cancel(squadid, alertid, month, orderidx)
	local alertidx = alert_id2index(alertid)
	if alertidx == -1 then
		return
	end

	local squad = df.squad.find(squadid)
	local sched = squad.schedule[alertidx][month]
	local sched_order = sched.orders[orderidx]

	sched.orders:erase(orderidx)
	sched_order.order:delete()
	sched_order:delete()
end

--luacheck: in=number
function schedule_order_get_choices(type)
	if type == df.squad_order_type.DEFEND_BURROWS then
		return burrows_get_list()
	elseif type == df.squad_order_type.MOVE then
		return waypoints_get_points()
	elseif type == df.squad_order_type.PATROL_ROUTE then
		return routes_get_list(true)
	end
end

--luacheck: in=number,number,number,number,number[]
function schedule_order_add(squadid, alertid, month, type, targets)
	local alertidx = alert_id2index(alertid)
	if alertidx == -1 then
		return
	end

	if type ~= df.squad_order_type.TRAIN and (not targets or #targets == 0) then
		return
	end

	local squad = df.squad.find(squadid)
	local sched = squad.schedule[alertidx][month]
	local order = nil

	if type == df.squad_order_type.TRAIN then
		local train = df.squad_order_trainst:new()
		order = train

		train.unk_v40_1 = -1
		train.unk_v40_2 = -1
		train.unk_v40_3 = 0

	elseif type == df.squad_order_type.DEFEND_BURROWS then
		local defend = df.squad_order_defend_burrowsst:new()
		order = defend
		
		defend.unk_v40_1 = -1
		defend.unk_v40_2 = -1
		defend.unk_v40_3 = 0

		for i,v in ipairs(targets) do
			defend.burrows:insert(#defend.burrows, v)
		end
		
	elseif type == df.squad_order_type.PATROL_ROUTE then
		local patrol = df.squad_order_patrol_routest:new()
		order = patrol
		
		patrol.unk_v40_1 = -1
		patrol.unk_v40_2 = -1
		patrol.unk_v40_3 = 0
		patrol.route_id = targets[1]

	elseif type == df.squad_order_type.MOVE then
		local pt = waypoint_find_by_id(targets[1])
		if not pt then
			return
		end

		local move = df.squad_order_movest:new()
		order = move
		
		move.unk_v40_1 = -1
		move.unk_v40_2 = -1
		move.unk_v40_3 = 0
		move.point_id = pt.id
		move.pos.x = pt.pos.x
		move.pos.y = pt.pos.y
		move.pos.z = pt.pos.z
	end

	if not order then
		return
	end

	order.year = df.global.cur_year
	order.year_tick = df.global.cur_year_tick	

	local sched_order = df.squad_schedule_order:new()
	sched_order.min_count = 10
	sched_order.order = order

	--xxx: sched_order.positions:insert(j,pos) crashes for some reason
	sched_order.positions:resize(10)
	for j,pos in ipairs(sched_order.positions) do
		sched_order.positions[j] = false
	end

	sched.orders:insert(#sched.orders, sched_order)

	return true
end


--print(pcall(function() return json:encode(schedule_get_overview2()) end))
--print(pcall(function() return json:encode(schedule_get_months(23,1)) end))
--print(pcall(function() return json:encode(schedule_get_orders(104,1,0)) end))
--print(pcall(function() return json:encode(schedule_month_duplicate_to_all(137,1,0)) end))