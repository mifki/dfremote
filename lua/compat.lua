local augments = {
	['<type: abstract_building_contents>'] = {
		count_goblets='unk_f8',
		count_instruments='unk_fc',
		count_paper='unk_100',
	},

	['BitArray<>'] = {
		GELDABLE=38,
	},

	['<type: unit>'] = {
		['social_activities'] = function(o)
			local v = { val=o.anon_1 }
			setmetatable(v, {
				__index = function(a, b)
					local _,actid = df.sizeof(a.val[b])
					return actid
				end
			})

			return v
		end,
	},
}

local augmeta = {
	__index = function(q,t)
		local r = q.aug[t]
		if r then
			if type(r) == 'function' then
				return r(q)
			else
				return q.val[r]
			end
		end
		
		return q.val[t]
	end
}

function augment(o)
	if not o then return o end

	local as = augments[tostring(o._type)]
	if as then
		local v = { aug=as, val=o }
		setmetatable(v, augmeta)

		return v	
	end

	return o
end

return augment

--print(A(dfhack.gui.getCurViewscreen().locations[0].contents).count_goblets)

--print(A(df.global.world.raws.creatures.all[22].caste[0].body_info.body_parts[8].flags).GELDABLE)

--print(A(dfhack.gui.getSelectedUnit()).social_activities[0])