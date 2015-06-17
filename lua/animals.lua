--todo: convert this to use list from animals screen
--todo: support vermin
function animals_get()
	local ret = {}

	for i,unit in ipairs(df.global.world.units.active) do
		--todo: or are caged and can be tamed !!
		if unit.civ_id == df.global.ui.civ_id and unit.flags1.tame and not unit.flags1.dead and not unit.flags1.forest then

			--local uname = unit.name.has_name and unitname(unit) or nil --todo: any need to use dfhack.units.getVisibleName() for animals ?
			local prof = dfhack.units.getProfessionName(unit) --xxx: no nobles, so always capitalized, no need to use unitprof()
			local work = (unit.profession == df.profession.TRAINED_WAR or unit.profession == df.profession.TRAINED_HUNT)
			local ownerid = unit.relations.pet_owner_id
			local owner = (ownerid ~= -1) and df.unit.find(ownerid) or nil
			local ownername = owner and (unitname(owner) .. ', ' .. unitprof(owner)) or false

			local caste = df.creature_raw.find(unit.race).caste[unit.caste]
			local adoptable = not caste.flags.ADOPTS_OWNER
			local available = unit.flags3.unk27
			local slaughter = unit.flags2.slaughter

			local geld = unit.flags3[29]
			local gelded = unit.flags3.gelded
			local can_geld = unit.sex == 1 --todo: set this properly - stores somewhere in race/caste
			
			local trainable = not work and not owner and unit.profession ~= df.profession.CHILD
			local trainable_war = trainable and caste.flags.TRAINABLE_WAR 
			local trainable_hunting = trainable and caste.flags.TRAINABLE_HUNTING 

			local fullname = unit_fulltitle(unit) --(uname and uname .. ', ' or '') .. (owner and '' or 'Stray ') .. prof

			local training = (trainable_war or trainable_hunting) and df.training_assignment.find(unit.id)
			local trainer = (training and training.trainer_id ~= -1) and df.unit.find(training.trainer_id) or nil
			local trainername = trainer and (unitname(trainer) .. ', ' .. unitprof(trainer)) or false

			--xxx: I'm quite sure there will be no units with id 0,1,2, so let's use these values for our special cases
			local trainerid = training and (trainer and trainer.id or bit32.band(training.auto_mode, 3)) or 0

			local training_war = training and bit32.band(training.auto_mode, 4) ~= 0
			local training_hunting = training and bit32.band(training.auto_mode, 8) ~= 0

			local flags = bit(0,work) + bit(1,adoptable) + bit(2,available) + bit(3,trainable_war) + bit(4,trainable_hunting)
						+ bit(5,slaughter) + bit(6,training_war) + bit(7,training_hunting)
						+ bit(8,geld) + bit(9,can_geld) + bit(10,gelded)

			table.insert(ret, { fullname, unit.id, unit.sex, ownername, flags, trainername, trainerid })
		end
	end

	return ret
end

function animals_set_slaughter(unitid, val)
	--xxx: should check if it's a valid action here?

	local unit = df.unit.find(unitid)

	if not unit then
		return false
	end

	unit.flags2.slaughter = istrue(val)
	return true
end

function animals_set_geld(unitid, val)
	--xxx: should check if it's a valid action here?

	local unit = df.unit.find(unitid)

	if not unit then
		return false
	end

	unit.flags3[29] = istrue(val)
	return true
end

function animals_set_available(unitid, val)
	--xxx: should check if it's a valid action here?

	local unit = df.unit.find(unitid)

	if not unit then
		return false
	end

	unit.flags3.unk27 = istrue(val)
	return true
end

function animals_train_war(unitid, val)
	local unit = df.unit.find(unitid)

	if not unit then
		return false
	end

	local training = df.training_assignment.find(unit.id)

	if not training then
		training = df.training_assignment:new()
		training.animal_id = unit.id
		training.auto_mode = 1 -- any

		utils.insert_sorted(df.global.ui.equipment.training_assignments, training, 'animal_id')
	end

	local mode = training.auto_mode
	mode = bit32.band(mode, 3) + (istrue(val) and 4 or 0)
	training.auto_mode = mode

	return true
end

function animals_train_hunting(unitid, val)
	local unit = df.unit.find(unitid)

	if not unit then
		return false
	end

	local training = df.training_assignment.find(unit.id)

	if not training then
		training = df.training_assignment:new()
		training.animal_id = unit.id
		training.auto_mode = 1 -- any

		utils.insert_sorted(df.global.ui.equipment.training_assignments, training, 'animal_id')
	end

	local mode = training.auto_mode
	mode = bit32.band(mode, 3) + (istrue(val) and 8 or 0)
	training.auto_mode = mode

	return true
end

function animals_trainer_get_choices()
	local ret = {}

	for i,unit in ipairs(df.global.world.units.active) do
		if dfhack.units.isCitizen(unit) then
			local uname = unitname(unit)
		    local prof = unitprof(unit)
		    local fullname = uname .. ', ' .. prof

		    if unit.status.labors[df.unit_labor.ANIMALTRAIN] then
		    	table.insert(ret, { fullname, unit.id })
		    end
		end
	end

	return ret
end

function animals_trainer_set(animalid, trainerid)
	local animal = df.unit.find(animalid)
	local trainer = df.unit.find(trainerid)

	if not animal or (trainerid > 2 and not trainer) then
		return false
	end

	if trainerid == 0 then
		utils.erase_sorted_key(df.global.ui.equipment.training_assignments, animalid, 'animal_id')
	end

	local mode = trainerid <= 2 and trainerid or 0
	trainerid = trainerid > 2 and trainerid or -1

	local training = df.training_assignment.find(animalid)

	if not training then
		training = df.training_assignment:new()
		training.animal_id = animalid

		utils.insert_sorted(df.global.ui.equipment.training_assignments, training, 'animal_id')
	end

	training.trainer_id = trainerid
	training.auto_mode = bit32.band(training.auto_mode, 12) + mode

	return true
end