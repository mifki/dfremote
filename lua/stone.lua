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

	local eco = df.global.ui.economic_stone

	for i,raw in ipairs(df.global.world.raws.inorganics) do 
		if stone_is_economic(raw) then
			table.insert(economic, { raw.material.state_name[0], i, eco[i] })
		elseif stone_is_other(raw) then
			table.insert(other, { raw.material.state_name[0], i, eco[i] })
		end
	end

	return { economic, other }
end

--luacheck: in=number,bool
function stone_set(idx, eco)
	df.global.ui.economic_stone[idx] = istrue(eco) and 1 or 0

	return true
end