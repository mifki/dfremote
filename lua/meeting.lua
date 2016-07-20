--todo: do this in C
function charptr_to_string(charptr)
	--[[if not charptr then
		return ''
	end]]

	local ret = ''

	while true do
		local c = charptr[#ret]
		if c == 0 then
			break
		end

		if c < 0 then
			c = 256 + c
		end
		ret = ret .. string.char(c)
	end

	return ret
end

function read_meeting_screen()
    local text = ''
	local nl = false
	local actions = {}
	local reply = false

	for j=2,df.global.gps.dimy-2 do
		local empty = true
		local line = ''

		for i=2,df.global.gps.dimx-2 do
			local char = df.global.gps.screen[(i*df.global.gps.dimy+j)*4]

			if char ~= 0 then
				if char ~= 32 then
					--todo: this is wrong
					--[[if empty and #line > 0 then
						line = line .. ' '
					end]]
					empty = false
				end

				if not empty and not (char == 32 and line:byte(#line) == 32) then
					line = line .. string.char(char)
				end
			end
		end

		if #line > 0 then
			if line:sub(#line, #line) == ' ' then
				line = line:sub(1, #line-1)
			end

			if line:find('^[a-z] %-') then
				local opt = line:sub(5)
				if opt:sub(#opt) == '.' then
					opt = opt:sub(1, #opt-1)
				end
				table.insert(actions, dfhack.df2utf(opt))

			elseif line:find(':$') then
				reply = true
			else
				-- if text:sub(#text,#text) == '.' and line:find('^[A-Z]') then
				-- 	nl = true
				-- end

				text = text .. (#text > 0 and (nl and '</p><p align=justify>' or ' ') or '<p align=justify>') .. dfhack.df2utf(line)
				nl = false
			end
		else
			nl = true
		end
	end

	text = text .. '</p>'

	return text, reply, actions
end

--luacheck: in=
function meeting_get()
    local ws = dfhack.gui.getCurViewscreen()

    local text, actions, activity
    local reply = false

    if ws._type == df.viewscreen_textviewerst and ws.parent._type == df.viewscreen_meetingst then
    	local ws = ws --as:df.viewscreen_textviewerst
    	text = ''
    	for i,v in ipairs(ws.formatted_text) do
	    	text = text .. dfhack.df2utf(charptr_to_string(v.text)) .. ' '
	    end

    	activity = ws.parent.dipscript_popup.activity --hint:df.viewscreen_meetingst
    	actions = { 'Done' }
    end

    if ws._type == df.viewscreen_topicmeetingst then
    	local ws = ws --as:df.viewscreen_topicmeetingst
    	activity = ws.popup.activity

    	--todo: include all lines here! :)
    	if #ws.text > 0 then
    		text = '<p align=justify>'
    		for i,v in ipairs(ws.text) do
    			local line = dfhack.df2utf(v.value:gsub('%s+', ' '))
				
				if text:sub(#text,#text) == '.' and line:find('^[A-Z]') then
					text = text .. '</p><p align=justify>'
				end
    			
    			text = text .. line
    		end
    		text = text .. '</p>'
    		--ws.text[0].value

    		text = text:gsub('The latest news from (%w+)', 'The latest news from <b>%1</b>')
    		text = text:gsub('The %u%w+ %u%w+', '<i>%0</i>')
    		text = text:gsub('The %u%w+ of %u%w+', '<i>%0</i>')
    		--text = text:gsub('(%u.-) ', '<i>%1</i> ')

    		actions = { 'Finish peeking in on conversation' }
    	else
	    	text, reply, actions = read_meeting_screen()
    	end
    end

    --todo: this is temporary to avoid app crash. anyway I don't understand how this happens
    if not activity then
    	return { text or 'Could not read meeting screen.', actions or { 'Done' }, '', '', false }
    end

    local actor_name  = unitname(activity.unit_actor)
	local actor_fullname = actor_name .. ', ' .. unitprof(activity.unit_actor)
	local noble_fullname = unitname(activity.unit_noble) .. ', ' .. unitprof(activity.unit_noble)

	text = text:gsub('^'..actor_name..': ', '')

	return { text, actions, actor_fullname, noble_fullname, reply }
end

--luacheck: in=number
function meeting_action(idx)
	local ws = dfhack.gui.getCurViewscreen()

	local key

	if ws._type == df.viewscreen_textviewerst and ws.parent._type == df.viewscreen_meetingst then
		key = K'LEAVESCREEN'
    end

    if ws._type == df.viewscreen_topicmeetingst then
    	key = K('OPTION' .. tostring(idx+1))
    end

	gui.simulateInput(ws, key)
end

local function itemdefname(id)
	local adj = id.adjective
	return (#adj > 0 and adj .. ' ' or '') .. id.name_plural
end

local function itemdefname2(id)
	local adj = id.adjective
	local mat = id.material_placeholder
	return (#adj > 0 and adj .. ' ' or '') .. (#mat > 0 and mat .. ' ' or '') .. id.name_plural
end	

function get_sell_items(civ_id)
	local ent = df.historical_entity.find(civ_id)
	local res = ent.resources

	local function f00(s,i)
		return i
	end

	local function f0(s,i)
		return s[i]
	end

	local function f1(s, i)
		return dfhack.matinfo.decode(0, s[i])
	end

	local function f2(s, i)
		return dfhack.matinfo.decode(s.mat_type[i], s.mat_index[i])
	end

	--todo: sex for all creatures
	local cats = {
		{
			'Leather', df.entity_sell_category.Leather, res.organic.leather, f2,
			function (mi) return mi.creature.name[0] .. ' leather' end, true
		},

		{
			'Cloth (Plant)', df.entity_sell_category.ClothPlant, res.organic.fiber, f2,
			function (mi) return mi.plant.adj .. ' fiber cloth' end, true
		},
		{
			'Cloth (Silk)', df.entity_sell_category.ClothSilk, res.organic.silk, f2,
			function (mi) return mi.creature.name[0] .. ' Silk cloth' end, true
		},

		{
			'Crafts', df.entity_sell_category.Crafts, res.misc_mat.crafts, f2,
			function (mi) return (mi.creature and mi.creature.name[0] .. ' ' or '') ..  mi.material.state_name.Solid .. ' crafts' end, false
		},

		{
			'Wood', df.entity_sell_category.Wood, res.organic.wood, f2,
			function (mi) return mi.plant.adj .. ' Wood Logs' end, true
		},		

		{
			'Metal Bars', df.entity_sell_category.MetalBars, res.metals, f1,
			function (mi) return mi.material.state_adj.Solid .. ' bars' end, false
		},			

		{
			'Small Cut Gems', df.entity_sell_category.SmallCutGems, res.gems, f1,
			function (mi) return mi.material.state_name.Solid end, false --todo: plural !!
		},				

		{
			'Large Cut Gems', df.entity_sell_category.LargeCutGems, res.gems, f1,
			function (mi) return 'Large ' .. mi.material.state_name.Solid end, false --todo: plural !!
		},		

		{
			'Stone Blocks', df.entity_sell_category.StoneBlocks, res.stones, f1,
			function (mi) return mi.material.state_adj.Solid .. ' blocks' end, false
		},	

		{
			'Seeds', df.entity_sell_category.Seeds, res.seeds, f2,
			function (mi) return mi.plant.seed_plural or (mi.plant.adj .. ' seeds') end, false
		},		

		{
			'Anvils', df.entity_sell_category.Anvils, res.metal.anvil, f2,
			function (mi) return mi.material.state_adj.Solid .. ' anvils' end, false
		},

		{
			'Weapons', df.entity_sell_category.Weapons, res.weapon_type, f0,
			function (i) return itemdefname(df.global.world.raws.itemdefs.weapons[i]) end, false
		},		
	
		{
			'Training Weapons', df.entity_sell_category.TrainingWeapons, res.training_weapon_type, f0,
			function (i) return itemdefname(df.global.world.raws.itemdefs.weapons[i]) end, false
		},	

		{
			'Ammo', df.entity_sell_category.Ammo, res.ammo_type, f0,
			function (i) return itemdefname(df.global.world.raws.itemdefs.ammo[i]) end, false
		},			

		{
			'Trap Components', df.entity_sell_category.TrapComponents, res.trapcomp_type, f0,
			function (i) return itemdefname(df.global.world.raws.itemdefs.trapcomps[i]) end, false
		},		

		{
			'Digging Implements', df.entity_sell_category.DiggingImplements, res.digger_type, f0,
			function (i) return df.global.world.raws.itemdefs.weapons[i].name_plural end, false
		},	

		{
			'Bodywear', df.entity_sell_category.Bodywear, res.armor_type, f0,
			function (i) return itemdefname2(df.global.world.raws.itemdefs.armor[i]) end, false
		},

		{
			'Headwear', df.entity_sell_category.Headwear, res.helm_type, f0,
			function (i) return itemdefname(df.global.world.raws.itemdefs.helms[i]) end, false
		},		
		{
			'Handwear', df.entity_sell_category.Handwear, res.gloves_type, f0,
			function (i) return itemdefname(df.global.world.raws.itemdefs.gloves[i]) end, false
		},		
		{
			'Footwear', df.entity_sell_category.Footwear, res.shoes_type, f0,
			function (i) return itemdefname(df.global.world.raws.itemdefs.shoes[i]) end, false
		},		
		{
			'Legwear', df.entity_sell_category.Legwear, res.pants_type, f0,
			function (i) return itemdefname(df.global.world.raws.itemdefs.pants[i]) end, false
		},	
		{
			'Shields', df.entity_sell_category.Shields, res.shield_type, f0,
			function (i) return itemdefname(df.global.world.raws.itemdefs.shields[i]) end, false
		},	
		
		{
			'Toys', df.entity_sell_category.Toys, res.toy_type, f0,
			function (i) return df.global.world.raws.itemdefs.toys[i].name_plural end, false
		},	

		{
			'Instruments', df.entity_sell_category.Instruments, res.instrument_type, f0,
			function (i) return df.global.world.raws.itemdefs.instruments[i].name_plural end, false
		},		

		{
			'Pets', df.entity_sell_category.Pets, res.animals.pet_races, f00,
			function (i) return df.global.world.raws.creatures.all[res.animals.pet_races[i]].caste[res.animals.pet_castes[i]].caste_name[0] end, false
		},	

		{
			'Drinks', df.entity_sell_category.Drinks, res.misc_mat.booze, f2,
			function (mi) return mi.material.state_name.Liquid end, true
		},
		{
			'Cheeses', df.entity_sell_category.Cheese, res.misc_mat.cheese, f2,
			function (mi) return mi.material.state_name.Solid end, true
		},
		{
			'Powders', df.entity_sell_category.Powders, res.misc_mat.powders, f2,
			function (mi) return mi.material.state_name.Solid end, false
		},
		{
			'Extracts', df.entity_sell_category.Extracts, res.misc_mat.extracts, f2,
			function (mi) return mi.material.state_name.Liquid end, false
		},

		--todo: fix this
		{
			'Meat', df.entity_sell_category.Meat, res.misc_mat.meat, f2,
			function (mi) return (mi.creature.name[0] .. ' ' .. mi.material.state_name.Solid) end, true
		},		
		
		{
			'Fish', df.entity_sell_category.Fish, res.fish_races, f00,
			function (i) return df.global.world.raws.creatures.all[res.fish_races[i]].caste[res.fish_castes[i]].caste_name[0] end, true
		},	

		{
			'Plants', df.entity_sell_category.Plants, res.plants, f2,
			function (mi) return mi.plant.name_plural end, false
		},	

		--todo: FruitsNuts, GardenVegetables, MeatFishRecipes, OtherRecipes,

		{
			'Stone', df.entity_sell_category.Stone, res.stones, f1,
			function (mi) return mi.material.state_name.Solid end, false
		},
		{
			'Cages', df.entity_sell_category.Cages, res.misc_mat.cages, f2,
			function (mi) return (mi.material.state_name.Solid .. ' cages') end, false
		},

		{
			'Bags (Leather)', df.entity_sell_category.BagsLeather, res.organic.leather, f2,
			function (mi) return mi.creature.name[0] .. ' leather bags' end, true
		},
		{
			'Bags (Plant)', df.entity_sell_category.BagsPlant, res.organic.fiber, f2,
			function (mi) return mi.plant.adj .. ' fiber thread' end, true
		},
		{
			'Bags (Silk)', df.entity_sell_category.BagsSilk, res.organic.silk, f2,
			function (mi) return mi.creature.name[0] .. ' Silk thread' end, true
		},

		{
			'Thread (Plant)', df.entity_sell_category.ThreadPlant, res.organic.fiber, f2,
			function (mi) return mi.plant.adj .. ' fiber thread' end, true
		},
		{
			'Thread (Silk)', df.entity_sell_category.ThreadSilk, res.organic.silk, f2,
			function (mi) return mi.creature.name[0] .. ' Silk thread' end, true
		},

		{
			'Ropes (Plant)', df.entity_sell_category.RopesPlant, res.organic.fiber, f2,
			function (mi) return mi.plant.adj .. ' fiber ropes' end, true
		},
		{
			'Ropes (Silk)', df.entity_sell_category.RopesSilk, res.organic.silk, f2,
			function (mi) return mi.creature.name[0] .. ' Silk ropes' end, true
		},

		{
			'Barrels', df.entity_sell_category.Barrels, res.misc_mat.barrels, f2,
			function (mi) return (mi.material.state_name.Solid .. ' barrels') end, true
		},
		{
			'Flasks & Waterskins', df.entity_sell_category.FlasksWaterskins, res.misc_mat.flasks, f2,
			function (mi) return mi.creature and (mi.creature.name[0] .. ' ' .. mi.material.state_name.Solid .. ' waterskins') or (mi.material.state_name.Solid .. ' flasks') end, true
		},
		{
			'Quivers', df.entity_sell_category.Quivers, res.misc_mat.quivers, f2,
			function (mi) return mi.creature.name[0] .. ' ' .. mi.material.state_name.Solid .. ' quivers' end, true
		},
		{
			'Backpacks', df.entity_sell_category.Backpacks, res.misc_mat.backpacks, f2,
			function (mi) return mi.creature.name[0] .. ' ' .. mi.material.state_name.Solid .. ' backpacks' end, true
		},
		{
			'Sand', df.entity_sell_category.Sand, res.misc_mat.sand, f2,
			function (mi) return (mi.material.state_name.Solid) end, false
		},
		{
			'Glass', df.entity_sell_category.Glass, res.misc_mat.glass, f2,
			function (mi) return ('raw ' .. mi.material.state_name.Solid) end, false
		},
		
		{
			'Miscellaneous', df.entity_sell_category.Miscellaneous, res.wood_products.material.mat_type, f00,
			function (i)
				local mi = dfhack.matinfo.decode(res.wood_products.material.mat_type[i], res.wood_products.material.mat_index[i])
				if res.wood_products.item_type[i] == df.item_type.LIQUID_MISC then
					return mi.material.state_name.Liquid
				end

				if res.wood_products.item_type[i] == df.item_type.BAR then
					if mi.material.id == 'COAL' then
						return res.wood_products.material.mat_index[i] == 1 and 'Charcoal' or 'Coke'
					end

					return mi.material.state_name.Solid
				end

				return '?!'
			end, false
		},

		{
			'Buckets', df.entity_sell_category.Buckets, res.misc_mat.barrels, f2,
			function (mi) return (mi.material.state_name.Solid .. ' buckets') end, true
		},
		{
			'Splints', df.entity_sell_category.Splints, res.misc_mat.barrels, f2,
			function (mi) return (mi.material.state_name.Solid .. ' splints') end, true
		},
		{
			'Crutches', df.entity_sell_category.Crutches, res.misc_mat.barrels, f2,
			function (mi) return (mi.material.state_name.Solid .. ' crutches') end, true
		},

		{
			'Eggs', df.entity_sell_category.Eggs, res.egg_races, f00,
			function (i) return df.global.world.raws.creatures.all[res.egg_races[i]].caste[res.egg_castes[i]].caste_name[0] .. ' egg' end, true
		},	

		{
			'Bags (Yarn)', df.entity_sell_category.BagsYarn, res.organic.wool, f2,
			function (mi) return mi.creature.name[0] .. ' wool bags' end, true
		},
		{
			'Ropes (Yarn)', df.entity_sell_category.RopesYarn, res.organic.wool, f2,
			function (mi) return mi.creature.name[0] .. ' wool ropes' end, true
		},
		{
			'Cloth (Yarn)', df.entity_sell_category.ClothYarn, res.organic.wool, f2,
			function (mi) return mi.creature.name[0] .. ' wool cloth' end, true
		},
		{
			'Thread (Yarn)', df.entity_sell_category.ThreadYarn, res.organic.wool, f2,
			function (mi) return mi.creature.name[0] .. ' wool thread' end, true
		},

		{
			'Tools', df.entity_sell_category.Tools, res.tool_type, f0,
			function (i) return df.global.world.raws.itemdefs.tools[i].name_plural end, false
		},	

		{
			'Clay', df.entity_sell_category.Clay, res.misc_mat.clay, f2,
			function (mi) return mi.material.state_name.Solid end, false
		},
	}

	return cats
end

--luacheck: in=
function import_req_get_items()
	local ws = dfhack.gui.getCurViewscreen() --as:df.viewscreen_topicmeeting_takerequestsst
	if ws._type ~= df.viewscreen_topicmeeting_takerequestsst then
		return
	end

	local civ_id = ws.meeting.civ_id
	local cats = get_sell_items(civ_id)

	local ret = {}
	for i,cat in ipairs(cats) do
		--print ('-----------------------------', cat[1])

		local s = cat[3]
		local sf = cat[4]
		local nf = cat[5]
		local n
		if s._type == df.material_vec_ref then
			n = #s.mat_type
		else
			n = #s
		end

		local items = {}
		for j=0,n-1 do
			local name = capitalize(nf(sf(s,j)))
			--print (name)
			table.insert(items, { name })
		end

		table.insert(ret, { cat[1], cat[2], items, cat[6] })
	end

	return ret
end

--luacheck: in=number[][],bool
function import_req_set(changes, close)
	local ws = dfhack.gui.getCurViewscreen() --as:df.viewscreen_topicmeeting_takerequestsst
	if ws._type ~= df.viewscreen_topicmeeting_takerequestsst then
		return
	end

	local priorities = ws.meeting.sell_requests.priority

	for j=1,#changes,2 do
		local cat = priorities[changes[j]]
		local reqs = changes[j+1]

		for j=1,#reqs,2 do
			cat[reqs[j]] = reqs[j+1]
		end
	end

	if istrue(close) then
		gui.simulateInput(ws, K'LEAVESCREEN')
	end
end

function process_sell_agreement(civ_id, reqs)
	local ret = {}

	local cats = get_sell_items(civ_id)
	for i,cat in ipairs(cats) do
		local s = cat[3]
		local sf = cat[4]
		local nf = cat[5]
		local n

		if s._type == df.material_vec_ref then
			n = #s.mat_type
		else
			n = #s
		end

		local items = {}
		for j=0,n-1 do
			local name = capitalize(nf(sf(s,j)))
			table.insert(items, { name, reqs.items.priority[cat[2]][j], math.floor(reqs.price[cat[2]][j]/128*100) })
		end

		table.insert(ret, { cat[1], cat[2], items })
	end

	return ret	
end

--luacheck: in=
function import_agreement_get()
	local ws = dfhack.gui.getCurViewscreen() --as:df.viewscreen_tradeagreementst
	if ws._type ~= df.viewscreen_tradeagreementst then
		return
	end

	local civ_id = ws.civ_id
	local reqs = ws.requests

	local ret = process_sell_agreement(civ_id, reqs)

	return { ret, translatename(ws.civ.name) }
end

local item_type_names_pl = {
    'Bars',
    'Cut Gems',
    'Blocks',
    'ROUGH',
    'BOULDER',
    'WOOD',
    'Doors',
    'Floodgates',
    'Beds',
    'CHAIR',
    {
    	[0]='Chains',
    	[shft(df.dfhack_material_category.cloth)]='Ropes',
    	[shft(df.dfhack_material_category.silk)]='Ropes',
    	[shft(df.dfhack_material_category.yarn)]='Ropes',
	},
    {
    	[0]='Flasks',
    	[shft(df.dfhack_material_category.leather)]='Waterskins',
    	[shft(df.dfhack_material_category.glass)]='Vials',
	},
    'Goblets',
    { [0]='Musical Instruments', function (i) return df.global.world.raws.itemdefs.instruments[i].name_plural end },
    { [0]='Toys', function (i) return df.global.world.raws.itemdefs.toys[i].name_plural end },
    'Windows',
    'CAGE',
    'BARREL',
    'BUCKET',
    'ANIMALTRAP',
    'TABLE',
    'COFFIN',
    'STATUE',
    'CORPSE',
    { [0]='Weapons', function(i) return itemdefname(df.global.world.raws.itemdefs.weapons[i]) end },
    { [0]='Armor', function (i) return itemdefname2(df.global.world.raws.itemdefs.armor[i]) end },
    { [0]='Footwear', function (i) return itemdefname(df.global.world.raws.itemdefs.shoes[i]) end },
    { [0]='Shields & Bucklers', function (i) return itemdefname(df.global.world.raws.itemdefs.shields[i]) end },
    { [0]='Headwear', function (i) return itemdefname(df.global.world.raws.itemdefs.helms[i]) end },
    { [0]='Handwear', function (i) return itemdefname(df.global.world.raws.itemdefs.gloves[i]) end },
    {
    	[0]='BOX',
    	[shft(df.dfhack_material_category.wood)]='Chests',
    	[shft(df.dfhack_material_category.wood2)]='Chests',
    	[shft(df.dfhack_material_category.glass)]='Boxes',
    	[shft(df.dfhack_material_category.leather)]='Bags', 
    	[shft(df.dfhack_material_category.cloth)]='Bags',
    	[shft(df.dfhack_material_category.silk)]='Bags',
    	[shft(df.dfhack_material_category.yarn)]='Bags',
    	[shft(df.dfhack_material_category.stone)]='Coffers',
	},
    'BIN',
    'ARMORSTAND',
    'WEAPONRACK',
    'CABINET',
    'FIGURINE',
    'Amulets',
    'Scepters',
    { [0]='Ammunition', function (i) return itemdefname(df.global.world.raws.itemdefs.ammo[i]) end },
    'Crowns',
    'Rings',
    'Earrings',
    'Bracelets',
    'Large Gems',
    'Anvils',
    'CORPSEPIECE',
    'REMAINS',
    'Meat',
    'Fish',
    'FISH_RAW',
    'VERMIN',
    'PET',
    'Seeds',
    'Plants',
    'Tanned Hides',
    'PLANT_GROWTH',
    'Thread',
    'Cloth',
    'TOTEM',
    { [0]='Legwear', function (i) return itemdefname(df.global.world.raws.itemdefs.pants[i]) end },
    'Backpacks',
    'Quivers',
    'CATAPULTPARTS',
    'BALLISTAPARTS',
    { [0]='Siege Ammo', function (i) return df.global.world.raws.itemdefs.siege_ammo[i].name_plural end },
    'BALLISTAARROWHEAD',
    'TRAPPARTS',
    { [0]='Trap Components', function (i) return itemdefname(df.global.world.raws.itemdefs.trapcomps[i]) end },
    'Drinks',
    'Powder',
    'Cheese',
    { [0]='Prepared Meals', function (i) return df.global.world.raws.itemdefs.food[i].name end }, --subtype is ignored in game
    'LIQUID_MISC',
    'COIN',
    'GLOB',
    'ROCK',
    'PIPE_SECTION',
    'HATCH_COVER',
    'GRATE',
    'QUERN',
    'MILLSTONE',
    'Splints',
    'Crutches',
    'TRACTION_BENCH',
    'ORTHOPEDIC_CAST',
    { [0]='Tools', function (i) return df.global.world.raws.itemdefs.tools[i].name_plural end },
    'SLAB',
    'EGG',
    'BOOK'
}

local mat_cat_names = { --as:string[]
	[shft(df.dfhack_material_category.plant)] = 'plant',
	[shft(df.dfhack_material_category.wood)] = 'wooden',
	[shft(df.dfhack_material_category.cloth)] = 'cloth',
	[shft(df.dfhack_material_category.silk)] = 'silk',
	[shft(df.dfhack_material_category.leather)] = 'leather',
	[shft(df.dfhack_material_category.bone)] = 'bone',
	[shft(df.dfhack_material_category.shell)] = 'shell',
	[shft(df.dfhack_material_category.wood2)] = 'wooden',
	[shft(df.dfhack_material_category.soap)] = 'soap',
	[shft(df.dfhack_material_category.tooth)] = 'ivory/tooth',
	[shft(df.dfhack_material_category.horn)] = 'horn',
	[shft(df.dfhack_material_category.pearl)] = 'pearl',
	[shft(df.dfhack_material_category.yarn)] = 'yarn',
}

function process_buy_agreement(reqs)
	local ret = {}

	for i,v in ipairs(reqs.items.item_type) do
		local title = ''

		local mat_cat = df.dfhack_material_category:new()
		mat_cat.whole = reqs.items.mat_cats[i].whole

		if mat_cat.whole ~= 0 then
			title = (mat_cat_names[mat_cat.whole] or 'unknown material') .. ' '

		elseif reqs.items.mat_types[i] ~= -1 then
			local mi = dfhack.matinfo.decode(reqs.items.mat_types[i], reqs.items.mat_indices[i])
			--todo: always use Solid ?
			title = (mi and mi.material.state_adj.Solid or 'unknown material') .. ' '

			if mi.material.flags.IS_GLASS then
				mat_cat.glass = true
			elseif mi.material.flags.IS_STONE then
				mat_cat.stone = true
			end
		end

		local name
		local subtype = reqs.items.item_subtype[i]
		if subtype == -1 then
			name = item_type_names_pl[v+1]
			if type(name) == 'table' then --as:name=number[]
				name = name[mat_cat.whole] or name[0]
			end
		
		else
			name = item_type_names_pl[v+1][1](subtype)
		end

		--todo: for bars + material the game shows only material eg. 'ash', but 'bars' if no material
		title = title .. name
		table.insert(ret, { capitalize(title), reqs.items.priority[i], math.floor(reqs.price[i]/128*100) })
	end

	return ret	
end

--luacheck: in=
function export_agreement_get()
	local ws = dfhack.gui.getCurViewscreen() --as:df.viewscreen_requestagreementst
	if ws._type ~= df.viewscreen_requestagreementst then
		return
	end

	local reqs = ws.requests
	local ret = process_buy_agreement(reqs)

	return { ret, translatename(ws.civ.name) }
end

--luacheck: in=
function landholders_get()
	local ws = dfhack.gui.getCurViewscreen() --as:df.viewscreen_topicmeeting_fill_land_holder_positionsst
	if ws._type ~= df.viewscreen_topicmeeting_fill_land_holder_positionsst then
		return
	end

	local candidates = {}

	for i,v in ipairs(ws.candidate_histfig_ids) do
		local hf = df.historical_figure.find(v)
		local unit = df.unit.find(hf.unit_id)
		local fullname = unit_fulltitle(unit)
		table.insert(candidates, { fullname, v })
	end

	return { candidates, 'A Barony' }
end

--luacheck: in=number,bool
function landholders_set(hfid, close)
	local ws = dfhack.gui.getCurViewscreen() --as:df.viewscreen_topicmeeting_fill_land_holder_positionsst
	if ws._type ~= df.viewscreen_topicmeeting_fill_land_holder_positionsst then
		return
	end

	if not df.historical_figure.find(hfid) then
		return
	end

	if #ws.selected_histfig_ids > 0 then
		ws.selected_histfig_ids[0] = hfid
	else
		ws.selected_histfig_ids:insert(0, hfid)
	end

	if istrue(close) then
		gui.simulateInput(ws, K'LEAVESCREEN')
	end	
end