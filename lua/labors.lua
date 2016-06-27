local labor_groups = {
    { "Mining", 7, {
        { "Miner", df.profession.MINER, df.unit_labor.MINE, df.job_skill.MINING, true }
    } },
    { "Woodworking", 14, {
        { "Carpenter", df.profession.CARPENTER, df.unit_labor.CARPENTER, df.job_skill.CARPENTRY },
        { "Bowyer", df.profession.BOWYER, df.unit_labor.BOWYER, df.job_skill.BOWYER },
        { "Wood Cutter", df.profession.WOODCUTTER, df.unit_labor.CUTWOOD, df.job_skill.WOODCUTTING, true }
    } },
    { "Stoneworking", 15, {
        { "Mason", df.profession.MASON, df.unit_labor.MASON, df.job_skill.MASONRY },
        { "Engraver", df.profession.ENGRAVER, df.unit_labor.DETAIL, df.job_skill.DETAILSTONE }
    } },
    { "Hunting/Related", 2, {
        { "Trainer", df.profession.ANIMAL_TRAINER, df.unit_labor.ANIMALTRAIN, df.job_skill.ANIMALTRAIN },
        { "Caretaker", df.profession.ANIMAL_CARETAKER, df.unit_labor.ANIMALCARE, df.job_skill.ANIMALCARE },
        { "Hunter", df.profession.HUNTER, df.unit_labor.HUNT, df.job_skill.SNEAK, true },
        { "Trapper", df.profession.TRAPPER, df.unit_labor.TRAPPER, df.job_skill.TRAPPING },
        { "Dissector", df.profession.ANIMAL_DISSECTOR, df.unit_labor.DISSECT_VERMIN, df.job_skill.DISSECT_VERMIN }
    } },
    { "Healthcare", 5, {
        { "Diagnoser", df.profession.DIAGNOSER, df.unit_labor.DIAGNOSE, df.job_skill.DIAGNOSE }, 
        { "Surgeon", df.profession.SURGEON, df.unit_labor.SURGERY, df.job_skill.SURGERY }, 
        { "Bone Setter", df.profession.BONE_SETTER, df.unit_labor.BONE_SETTING, df.job_skill.SET_BONE }, 
        { "Suturer", df.profession.SUTURER, df.unit_labor.SUTURING, df.job_skill.SUTURE }, 
        { "Dresser", df.profession.DOCTOR, df.unit_labor.DRESSING_WOUNDS, df.job_skill.DRESS_WOUNDS }, 
        { "Feeder", df.profession.NONE, df.unit_labor.FEED_WATER_CIVILIANS, df.job_skill.NONE }, 
        { "Recover Wounded", df.profession.NONE, df.unit_labor.RECOVER_WOUNDED, df.job_skill.NONE }
    } },
    { "Farming/Related", 6, {
        { "Butcher", df.profession.BUTCHER, df.unit_labor.BUTCHER, df.job_skill.BUTCHER }, 
        { "Tanner", df.profession.TANNER, df.unit_labor.TANNER, df.job_skill.TANNER }, 
        { "Planter", df.profession.PLANTER, df.unit_labor.PLANT, df.job_skill.PLANT }, 
        { "Dyer", df.profession.DYER, df.unit_labor.DYER, df.job_skill.DYER }, 
        { "Soap Maker", df.profession.SOAP_MAKER, df.unit_labor.SOAP_MAKER, df.job_skill.SOAP_MAKING }, 
        { "Wood Burner", df.profession.WOOD_BURNER, df.unit_labor.BURN_WOOD, df.job_skill.WOOD_BURNING }, 
        { "Potash Maker", df.profession.POTASH_MAKER, df.unit_labor.POTASH_MAKING, df.job_skill.POTASH_MAKING }, 
        { "Lye Maker", df.profession.LYE_MAKER, df.unit_labor.LYE_MAKING, df.job_skill.LYE_MAKING }, 
        { "Miller", df.profession.MILLER, df.unit_labor.MILLER, df.job_skill.MILLING }, 
        { "Brewer", df.profession.BREWER, df.unit_labor.BREWER, df.job_skill.BREWING }, 
        { "Herbalist", df.profession.HERBALIST, df.unit_labor.HERBALIST, df.job_skill.HERBALISM }, 
        { "Thresher", df.profession.THRESHER, df.unit_labor.PROCESS_PLANT, df.job_skill.PROCESSPLANTS }, 
        { "Cheese Maker", df.profession.CHEESE_MAKER, df.unit_labor.MAKE_CHEESE, df.job_skill.CHEESEMAKING }, 
        { "Milker", df.profession.MILKER, df.unit_labor.MILK, df.job_skill.MILK }, 
        { "Gelder", df.profession.GELDER, df.unit_labor.GELD, df.job_skill.GELD },
        { "Shearer", df.profession.SHEARER, df.unit_labor.SHEARER, df.job_skill.SHEARING }, 
        { "Spinner", df.profession.SPINNER, df.unit_labor.SPINNER, df.job_skill.SPINNING }, 
        { "Cook", df.profession.COOK, df.unit_labor.COOK, df.job_skill.COOK }, 
        { "Presser", df.profession.PRESSER, df.unit_labor.PRESSING, df.job_skill.PRESSING }, 
        { "Beekeeper", df.profession.BEEKEEPER, df.unit_labor.BEEKEEPING, df.job_skill.BEEKEEPING },
    } },
    { "Fishing/Related", 1, {
        { "Fisher", df.profession.FISHERMAN, df.unit_labor.FISH, df.job_skill.FISH }, 
        { "Cleaner", df.profession.FISH_CLEANER, df.unit_labor.CLEAN_FISH, df.job_skill.PROCESSFISH }, 
        { "Dissector", df.profession.FISH_DISSECTOR, df.unit_labor.DISSECT_FISH, df.job_skill.DISSECT_FISH }
    } },
    { "Metalsmithing", 8, {
        { "Furnace Operator", df.profession.FURNACE_OPERATOR, df.unit_labor.SMELT, df.job_skill.SMELT }, 
        { "Weaponsmith", df.profession.WEAPONSMITH, df.unit_labor.FORGE_WEAPON, df.job_skill.FORGE_WEAPON }, 
        { "Armorer", df.profession.ARMORER, df.unit_labor.FORGE_ARMOR, df.job_skill.FORGE_ARMOR }, 
        { "Blacksmith", df.profession.BLACKSMITH, df.unit_labor.FORGE_FURNITURE, df.job_skill.FORGE_FURNITURE }, 
        { "Metalcrafter", df.profession.METALCRAFTER, df.unit_labor.METAL_CRAFT, df.job_skill.METALCRAFT }
    } },
    { "Jewelry", 10, {
        { "Cutter", df.profession.GEM_CUTTER, df.unit_labor.CUT_GEM, df.job_skill.CUTGEM }, 
        { "Setter", df.profession.GEM_SETTER, df.unit_labor.ENCRUST_GEM, df.job_skill.ENCRUSTGEM }
    } },
    { "Crafts", 9, {
        { "Leatherworker", df.profession.LEATHERWORKER, df.unit_labor.LEATHER, df.job_skill.LEATHERWORK }, 
        { "Woodcrafter", df.profession.WOODCRAFTER, df.unit_labor.WOOD_CRAFT, df.job_skill.WOODCRAFT }, 
        { "Stonecrafter", df.profession.STONECRAFTER, df.unit_labor.STONE_CRAFT, df.job_skill.STONECRAFT }, 
        { "Bone Carver", df.profession.BONE_CARVER, df.unit_labor.BONE_CARVE, df.job_skill.BONECARVE }, 
        { "Glassmaker", df.profession.GLASSMAKER, df.unit_labor.GLASSMAKER, df.job_skill.GLASSMAKER }, 
        { "Weaver", df.profession.WEAVER, df.unit_labor.WEAVER, df.job_skill.WEAVING }, 
        { "Clothier", df.profession.CLOTHIER, df.unit_labor.CLOTHESMAKER, df.job_skill.CLOTHESMAKING }, 
        { "Strand Extractor", df.profession.STRAND_EXTRACTOR, df.unit_labor.EXTRACT_STRAND, df.job_skill.EXTRACT_STRAND }, 
        { "Potter", df.profession.POTTER, df.unit_labor.POTTERY, df.job_skill.POTTERY }, 
        { "Glazer", df.profession.GLAZER, df.unit_labor.GLAZING, df.job_skill.GLAZING }, 
        { "Waxer", df.profession.WAX_WORKER, df.unit_labor.WAX_WORKING, df.job_skill.WAX_WORKING }
    } },
    { "Engineering", 12, {
        { "Siege Engineer", df.profession.SIEGE_ENGINEER, df.unit_labor.SIEGECRAFT, df.job_skill.SIEGECRAFT }, 
        { "Siege Operator", df.profession.SIEGE_OPERATOR, df.unit_labor.SIEGEOPERATE, df.job_skill.SIEGEOPERATE }, 
        { "Mechanic", df.profession.MECHANIC, df.unit_labor.MECHANIC, df.job_skill.MECHANICS }, 
        { "Pump Operator", df.profession.PUMP_OPERATOR, df.unit_labor.OPERATE_PUMP, df.job_skill.OPERATE_PUMP }
    } },
    { "Other Jobs", 4, {
        { "Architect", df.profession.ARCHITECT, df.unit_labor.ARCHITECT, df.job_skill.DESIGNBUILDING }, 
        { "Alchemist", df.profession.ALCHEMIST, df.unit_labor.ALCHEMIST, df.job_skill.ALCHEMY }, 
        { "Cleaning", df.profession.NONE, df.unit_labor.CLEAN, df.job_skill.NONE }, 
        { "Lever Operator", df.profession.NONE, df.unit_labor.PULL_LEVER, df.job_skill.NONE }, 
        { "Construction Removal", df.profession.NONE, df.unit_labor.REMOVE_CONSTRUCTION, df.job_skill.NONE }
    } },
    { "Hauling", 3, {
        { "Stone", df.profession.NONE, df.unit_labor.HAUL_STONE, df.job_skill.NONE }, 
        { "Wood", df.profession.NONE, df.unit_labor.HAUL_WOOD, df.job_skill.NONE },
        { "Items", df.profession.NONE, df.unit_labor.HAUL_ITEM, df.job_skill.NONE }, 
        { "Burial", df.profession.NONE, df.unit_labor.HAUL_BODY, df.job_skill.NONE }, 
        { "Food", df.profession.NONE, df.unit_labor.HAUL_FOOD, df.job_skill.NONE }, 
        { "Refuse", df.profession.NONE, df.unit_labor.HAUL_REFUSE, df.job_skill.NONE }, 
        { "Furniture", df.profession.NONE, df.unit_labor.HAUL_FURNITURE, df.job_skill.NONE }, 
        { "Animals", df.profession.NONE, df.unit_labor.HAUL_ANIMALS, df.job_skill.NONE }, 
        { "Vehicles", df.profession.NONE, df.unit_labor.HANDLE_VEHICLES, df.job_skill.NONE }, 
        { "Trade Goods", df.profession.NONE, df.unit_labor.HAUL_TRADE, df.job_skill.NONE }, 
        { "Water", df.profession.NONE, df.unit_labor.HAUL_WATER, df.job_skill.NONE }
    } },
};

--[[local labor_groups2 = {
    { "Mining", 7, {
        { "Mining", df.profession.MINER, df.unit_labor.MINE, df.job_skill.MINING, true }
    } },
    { "Woodworking", 14, {
        { "Carpentry", df.profession.CARPENTER, df.unit_labor.CARPENTER, df.job_skill.CARPENTRY },
        { "Bowyer", df.profession.BOWYER, df.unit_labor.BOWYER, df.job_skill.BOWYER },
        { "Wood Cutter", df.profession.WOODCUTTER, df.unit_labor.CUTWOOD, df.job_skill.WOODCUTTING, true }
    } },
    { "Stoneworking", 15, {
        { "Mason", df.profession.MASON, df.unit_labor.MASON, df.job_skill.MASONRY },
        { "Engraver", df.profession.ENGRAVER, df.unit_labor.DETAIL, df.job_skill.DETAILSTONE }
    } },
    { "Hunting/Related", 2, {
        { "Trainer", df.profession.ANIMAL_TRAINER, df.unit_labor.ANIMALTRAIN, df.job_skill.ANIMALTRAIN },
        { "Caretaker", df.profession.ANIMAL_CARETAKER, df.unit_labor.ANIMALCARE, df.job_skill.ANIMALCARE },
        { "Hunter", df.profession.HUNTER, df.unit_labor.HUNT, df.job_skill.SNEAK, true },
        { "Trapper", df.profession.TRAPPER, df.unit_labor.TRAPPER, df.job_skill.TRAPPING },
        { "Dissector", df.profession.ANIMAL_DISSECTOR, df.unit_labor.DISSECT_VERMIN, df.job_skill.DISSECT_VERMIN }
    } },
    { "Healthcare", 5, {
        { "Diagnoser", df.profession.DIAGNOSER, df.unit_labor.DIAGNOSE, df.job_skill.DIAGNOSE }, 
        { "Surgeon", df.profession.SURGEON, df.unit_labor.SURGERY, df.job_skill.SURGERY }, 
        { "Bone Setter", df.profession.BONE_SETTER, df.unit_labor.BONE_SETTING, df.job_skill.SET_BONE }, 
        { "Suturer", df.profession.SUTURER, df.unit_labor.SUTURING, df.job_skill.SUTURE }, 
        { "Dresser", df.profession.DOCTOR, df.unit_labor.DRESSING_WOUNDS, df.job_skill.DRESS_WOUNDS }, 
        { "Feeder", df.profession.NONE, df.unit_labor.FEED_WATER_CIVILIANS, df.job_skill.NONE }, 
        { "Re", df.profession.NONE, df.unit_labor.RECOVER_WOUNDED, df.job_skill.NONE }
    } },
    { "Farming/Related", 6, {
        { "Butcher", df.profession.BUTCHER, df.unit_labor.BUTCHER, df.job_skill.BUTCHER }, 
        { "Tanner", df.profession.TANNER, df.unit_labor.TANNER, df.job_skill.TANNER }, 
        { "Planter", df.profession.PLANTER, df.unit_labor.PLANT, df.job_skill.PLANT }, 
        { "Dyer", df.profession.DYER, df.unit_labor.DYER, df.job_skill.DYER }, 
        { "Soap Maker", df.profession.SOAP_MAKER, df.unit_labor.SOAP_MAKER, df.job_skill.SOAP_MAKING }, 
        { "Wood Burner", df.profession.WOOD_BURNER, df.unit_labor.BURN_WOOD, df.job_skill.WOOD_BURNING }, 
        { "Potash Maker", df.profession.POTASH_MAKER, df.unit_labor.POTASH_MAKING, df.job_skill.POTASH_MAKING }, 
        { "Lye Maker", df.profession.LYE_MAKER, df.unit_labor.LYE_MAKING, df.job_skill.LYE_MAKING }, 
        { "Miller", df.profession.MILLER, df.unit_labor.MILLER, df.job_skill.MILLING }, 
        { "Brewer", df.profession.BREWER, df.unit_labor.BREWER, df.job_skill.BREWING }, 
        { "Herbalist", df.profession.HERBALIST, df.unit_labor.HERBALIST, df.job_skill.HERBALISM }, 
        { "Thresher", df.profession.THRESHER, df.unit_labor.PROCESS_PLANT, df.job_skill.PROCESSPLANTS }, 
        { "Cheese Maker", df.profession.CHEESE_MAKER, df.unit_labor.MAKE_CHEESE, df.job_skill.CHEESEMAKING }, 
        { "Milker", df.profession.MILKER, df.unit_labor.MILK, df.job_skill.MILK }, 
        { "Gelder", df.profession.GELDER, df.unit_labor.GELD, df.job_skill.GELD },
        { "Shearer", df.profession.SHEARER, df.unit_labor.SHEARER, df.job_skill.SHEARING }, 
        { "Spinner", df.profession.SPINNER, df.unit_labor.SPINNER, df.job_skill.SPINNING }, 
        { "Cook", df.profession.COOK, df.unit_labor.COOK, df.job_skill.COOK }, 
        { "Presser", df.profession.PRESSER, df.unit_labor.PRESSING, df.job_skill.PRESSING }, 
        { "Beekeeper", df.profession.BEEKEEPER, df.unit_labor.BEEKEEPING, df.job_skill.BEEKEEPING }
    } },
    { "Fishing/Related", 1, {
        { "Fisher", df.profession.FISHERMAN, df.unit_labor.FISH, df.job_skill.FISH }, 
        { "Cleaner", df.profession.FISH_CLEANER, df.unit_labor.CLEAN_FISH, df.job_skill.PROCESSFISH }, 
        { "Dissector", df.profession.FISH_DISSECTOR, df.unit_labor.DISSECT_FISH, df.job_skill.DISSECT_FISH }
    } },
    { "Metalsmithing", 8, {
        { "Furnace Op", df.profession.FURNACE_OPERATOR, df.unit_labor.SMELT, df.job_skill.SMELT }, 
        { "Weaponsmith", df.profession.WEAPONSMITH, df.unit_labor.FORGE_WEAPON, df.job_skill.FORGE_WEAPON }, 
        { "Armorer", df.profession.ARMORER, df.unit_labor.FORGE_ARMOR, df.job_skill.FORGE_ARMOR }, 
        { "Blacksmith", df.profession.BLACKSMITH, df.unit_labor.FORGE_FURNITURE, df.job_skill.FORGE_FURNITURE }, 
        { "Metalcrafter", df.profession.METALCRAFTER, df.unit_labor.METAL_CRAFT, df.job_skill.METALCRAFT }
    } },
    { "Jewelry", 10, {
        { "Cutter", df.profession.GEM_CUTTER, df.unit_labor.CUT_GEM, df.job_skill.CUTGEM }, 
        { "Setter", df.profession.GEM_SETTER, df.unit_labor.ENCRUST_GEM, df.job_skill.ENCRUSTGEM }
    } },
    { "Crafts", 9, {
        { "Leatherworking", df.profession.LEATHERWORKER, df.unit_labor.LEATHER, df.job_skill.LEATHERWORK }, 
        { "Woodcrafting", df.profession.WOODCRAFTER, df.unit_labor.WOOD_CRAFT, df.job_skill.WOODCRAFT }, 
        { "Stonecrafting", df.profession.STONECRAFTER, df.unit_labor.STONE_CRAFT, df.job_skill.STONECRAFT }, 
        { "Bone Carving", df.profession.BONE_CARVER, df.unit_labor.BONE_CARVE, df.job_skill.BONECARVE }, 
        { "Glassmaking", df.profession.GLASSMAKER, df.unit_labor.GLASSMAKER, df.job_skill.GLASSMAKER }, 
        { "Weaving", df.profession.WEAVER, df.unit_labor.WEAVER, df.job_skill.WEAVING }, 
        { "Clothesmaking", df.profession.CLOTHIER, df.unit_labor.CLOTHESMAKER, df.job_skill.CLOTHESMAKING }, 
        { "Strand Extraction", df.profession.STRAND_EXTRACTOR, df.unit_labor.EXTRACT_STRAND, df.job_skill.EXTRACT_STRAND }, 
        { "Pottery", df.profession.POTTER, df.unit_labor.POTTERY, df.job_skill.POTTERY }, 
        { "Glazing", df.profession.GLAZER, df.unit_labor.GLAZING, df.job_skill.GLAZING }, 
        { "Wax Working", df.profession.WAX_WORKER, df.unit_labor.WAX_WORKING, df.job_skill.WAX_WORKING }
    } },
    { "Engineering", 12, {
        { "Siege Engineering", df.profession.SIEGE_ENGINEER, df.unit_labor.SIEGECRAFT, df.job_skill.SIEGECRAFT }, 
        { "Siege Operating", df.profession.SIEGE_OPERATOR, df.unit_labor.SIEGEOPERATE, df.job_skill.SIEGEOPERATE }, 
        { "Mechanics", df.profession.MECHANIC, df.unit_labor.MECHANIC, df.job_skill.MECHANICS }, 
        { "Pump Operating", df.profession.PUMP_OPERATOR, df.unit_labor.OPERATE_PUMP, df.job_skill.OPERATE_PUMP }
    } },
    { "Other Jobs", 4, {
        { "Architecture", df.profession.ARCHITECT, df.unit_labor.ARCHITECT, df.job_skill.DESIGNBUILDING }, 
        { "Alchemy", df.profession.ALCHEMIST, df.unit_labor.ALCHEMIST, df.job_skill.ALCHEMY }, 
        { "Cleaning", df.profession.NONE, df.unit_labor.CLEAN, df.job_skill.NONE }, 
        { "Lever Operation", df.profession.NONE, df.unit_labor.PULL_LEVER, df.job_skill.NONE }, 
        { "Construction Removal", df.profession.NONE, df.unit_labor.REMOVE_CONSTRUCTION, df.job_skill.NONE }
    } },
    { "Hauling", 3, {
        { "Stone", df.profession.NONE, df.unit_labor.HAUL_STONE, df.job_skill.NONE }, 
        { "Wood", df.profession.NONE, df.unit_labor.HAUL_WOOD, df.job_skill.NONE },
        { "Items", df.profession.NONE, df.unit_labor.HAUL_ITEM, df.job_skill.NONE }, 
        { "Burial", df.profession.NONE, df.unit_labor.HAUL_BODY, df.job_skill.NONE }, 
        { "Food", df.profession.NONE, df.unit_labor.HAUL_FOOD, df.job_skill.NONE }, 
        { "Refuse", df.profession.NONE, df.unit_labor.HAUL_REFUSE, df.job_skill.NONE }, 
        { "Furniture", df.profession.NONE, df.unit_labor.HAUL_FURNITURE, df.job_skill.NONE }, 
        { "Animals", df.profession.NONE, df.unit_labor.HAUL_ANIMALS, df.job_skill.NONE }, 
        { "Vehicles", df.profession.NONE, df.unit_labor.HANDLE_VEHICLES, df.job_skill.NONE }, 
        { "Trade Goods", df.profession.NONE, df.unit_labor.HAUL_TRADE, df.job_skill.NONE }, 
        { "Water", df.profession.NONE, df.unit_labor.HAUL_WATER, df.job_skill.NONE }
    } },
};]]

local special_labors = { df.unit_labor.MINE, df.unit_labor.CUTWOOD, df.unit_labor.HUNT }

function is_special_labor(laboridx)
    for i,v in pairs(special_labors) do
        if v == laboridx then
            return true
        end
    end

    return false
end

function labors_get_labors()

    local labor_counts = labors_get_counts()

    local groups = {}

    for i,grp in ipairs(labor_groups) do
        local labors = {}

        for j,labor in ipairs(grp[3]) do
            table.insert(labors, { labor[1], labor[3], labor[5] or false })
        end

        table.insert(groups, { grp[1], grp[2], labors })
    end

    return groups
end

--todo: don't count common labors like hauling
--luacheck: in=
function labors_get_counts()
    local ret = {}

    for i=0,df.unit_labor._last_item do
        table.insert(ret, 0)
    end
    
    for i,unit in ipairs(df.global.world.units.active) do
        if dfhack.units.isCitizen(unit) then
        	local ulabors = unit.status.labors
            for i=0,df.unit_labor._last_item do
                if ulabors[i] then
                    ret[i+1] = ret[i+1] + 1
                end
            end
        end
    end

    return ret
end

function find_labor_obj(laboridx)
    for i,grp in ipairs(labor_groups) do
        local labors = {}

        for j,labor in ipairs(grp[3]) do
        	if labor[3] == laboridx then
        		return labor
        	end
        end
    end
end

--luacheck: in=number
function labors_get_dwarves_with_labor(laboridx)
	local labor = find_labor_obj(laboridx)

    if not labor then
        error('no labor ' .. tostring(laboridx))
    end

    local enabled = {}
    local disabled = {}

	for i,unit in ipairs(df.global.world.units.active) do
		if unit.profession ~= df.profession.CHILD and unit.profession ~= df.profession.BABY and dfhack.units.isCitizen(unit) then
			--if unit.status.labors[laboridx] then
				local uname = unitname(unit)
			    local prof = unitprof(unit)
                
                local squad = unit_get_squad(unit)
                local sqname = squad and squadname(squad) or mp.NIL

				local rating = 0
				--todo: binary search
				if labor[2] == df.job_skill.NONE then
					rating = -1
				else
					for j,skill in ipairs(unit.status.current_soul.skills) do
						if skill.id == labor[4] then
							rating = skill.rating
							break
						end
					end
				end

                local laborcount = 0
                for i,v in pairs(unit.status.labors) do
                    if v then
                        laborcount = laborcount + 1
                    end
                end

                table.insert(unit.status.labors[laboridx] and enabled or disabled, { uname, unit.id, rating, prof, sqname, laborcount })
            --end
        end
    end    

    return { enabled, disabled }
end

--luacheck: in=
function labors_get_all_dwarves()
    local allowed = {}
    local disallowed = {}

	for i,unit in ipairs(df.global.world.units.active) do
		if dfhack.units.isCitizen(unit) then
			local uname = unitname(unit)
		    local prof = unitprof(unit)
			if unit.profession ~= df.profession.CHILD and unit.profession ~= df.profession.BABY then
	            local squad = unit_get_squad(unit)
	            local sqname = squad and squadname(squad) or mp.NIL

	            local laborcount = 0
	            for i,v in pairs(unit.status.labors) do
	                if v then
	                    laborcount = laborcount + 1
	                end
	            end

	            table.insert(allowed, { uname, unit.id, -1, prof, sqname, laborcount })
		    else
		    	table.insert(disallowed, { uname, unit.id, -1, prof, mp.NIL, 0 })
	        end
	    end
    end    

    return { allowed, disallowed }
end

--luacheck: in=number
function labors_get_dwarf_labors(unitid)
	local unit = df.unit.find(unitid)
    if not unit then
        error('no unit '..tostring(unitid))
    end

	local ulabors = unit.status.labors
	local uskills = unit.status.current_soul.skills

	local ret = {}

    for i=0,df.unit_labor._last_item do
        table.insert(ret, 0)
    end	

    for i,grp in ipairs(labor_groups) do
        for j,labor in ipairs(grp[3]) do
            local rating = 0

			if labor[2] == df.job_skill.NONE then
				rating = -1
			else
	            --todo: binary search
	            for k,skill in ipairs(uskills) do
	                if skill.id == labor[4] then
	                    rating = skill.rating
	                    break
	                end
	            end
	        end

            ret[labor[3]+1] = { ulabors[labor[3]], rating }
        end
    end
    
	return ret	
end

--todo: allow to pass changes as an array in second argument (?) array of 2-value arrays ?
--luacheck: in=number
function labors_set(unitid, ...)
	local unit = df.unit.find(unitid)
	local ulabors = unit.status.labors
    local changes = {...}

    for i=1,#changes,2 do
        local idx = changes[i]
        local on = istrue(changes[i+1])

		ulabors[idx] = on

        if on then
            if is_special_labor(idx) then
                for i,v in pairs(special_labors) do
                    if v ~= idx then
                        ulabors[v] = false
                    end
                end

                unit.military.pickup_flags.update = true
            end
        end
	end

    return true
end
