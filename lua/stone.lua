function stone_is_economic(raw)
	return (#raw.economic_uses>0 and raw.material.flags.IS_STONE) or raw.flags.METAL_ORE
		or raw.id == 'RAW_ADAMANTINE' or raw.id == 'OBSIDIAN'
end

function stone_is_other(raw)
	return #raw.economic_uses==0 and raw.material.flags.IS_STONE and not raw.flags.METAL_ORE and not raw.material.flags.NO_STONE_STOCKPILE
		and raw.id ~= 'RAW_ADAMANTINE'
end

--luacheck: in=
function stone_get()
	local economic = {}
	local other = {}

	for i,raw in ipairs(df.global.world.raws.inorganics) do 
		local mat = raw.material
		local name = capitalize(#mat.stone_name > 0 and mat.stone_name or mat.state_name[0])
		local magmasafe = mat.heat.ignite_point > 12000 and mat.heat.melting_point > 12000
		local restricted = istrue(df.global.ui.economic_stone[i])
		local flags = packbits(restricted,magmasafe)

		if stone_is_economic(raw) then
			table.insert(economic, { name, i, flags })
		elseif stone_is_other(raw) then
			table.insert(other, { name, i, flags })
		end
	end

  	table.sort(economic, function(a,b) return a[1] < b[1] end)
  	table.sort(other, function(a,b) return a[1] < b[1] end)

	return { economic, other }
end

--luacheck: in=number,bool
function stone_set(idx, eco)
	df.global.ui.economic_stone[idx] = istrue(eco) and 1 or 0

	return true
end