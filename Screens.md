# Screens
## Nobles `n`
* list
* assign
* -> view unit / demands
* bookkeeper settings
	* df.global.ui.bookkeeper_settings

## Status `z`
* df.global.ui.tasks
* Overall
	* Food
		* df.global.ui.tasks.food
		* df.global.ui.tasks.wealth
	* Unit counts
		* maybe this section should differ from the game, ie. group dwarves slightly differently ?
* Animals
	* availability seems to be in unit.flags3.unk27
	* or are caged and can be tamed !!!
	* need to check caste.flags.PET ?
	* The word "stray" indicates that the animal is not any Dwarf's pet. In the case of war or hunting animals, it means the animal has not been assigned to a dwarf.

	* training_assignment
		* bit 0 - any trainer
		* bit 1 - any unassigned
		* bit 2 - war training
		* bit 3 - hunting training
		* no bits 0/1 - trainer_id must be set
* Kitchen
	* list
	* set cook / brew
* Stone
	* viewscreen_layer_stone_restrictionst
* Stocks
	* list economic / other + tasks
	* toggle restriction
	* !! how to get proper name for some metals, like 'gold nuggets' instead of 'native gold'
* Health
	* list + bits
	* view unit health
		* viewscreen_layer_unit_healthst
		* status
		* wounds
		* treatment
		* history
* Justice

## Workshops

## Unit info
*  if u.curse.name_visible and not isBlank(u.curse.name) then prof = prof..' '..u.curse.name end
* dfhack.units.getVisibleName(u) !!!

## Military `m`
* Squads / Positions
* Equipment
* Uniforms
* Ammo
* Alerts
	* When deleting an alert, cur_alert_idx in squads and civ_alert_idx may have to be shifted !!!

## Depot
	* seems after changing trader requested in flags need to create or remove appropriate job object
	* when changing only broker may trade flag no additional actions seem to be required
	* foreign items can't be offered!
	* price for quiver is incorrect (should be 20 instead of 10) !

## Schedule

## Announcements
* df.global.world.status.announcements

## Buildings
* bld->jobs.size() == 1 && bld->jobs[0]->job_type == job_type::DestroyBuilding -> building is unusable

## Workshops
* Game determines whether a job is in progress not by job.flags.working (if it's set to 0, still showing 'A') !

## Farm plot
* turning fertilization on creates 8 jobs, turning season fert. on doesn't
* df.global.ui.available_seeds
* df.global.ui.selected_farm_crops
* df.global.ui.farm_crops and df.global.ui.farm_seasons - ??

## Reports

## Civilizations
* View civ
	* Leaders
	* Import / Export
	* Agreements

## Burrows

## Build
* df.global.ui_build_selector.unk4 - warnings, like no soil for farm
* df.global.world.building_width, df.global.world.building_height

### Stages
* construction inactive (jobs[0].flags.fetching/bringing/working) / suspended
* 0 - waiting for construction, needs blah blah / if needsDesign() then if .design.flags.designed then designed else waiting for architect
	* 'construction initiated' - when??
* 1 - partially constructed
* 2 - contstruction nearly done

## Move goods to/from depot
* viewscreen_layer_assigntradest

## Stockpile settings
* viewscreen_layer_stockpilest

## DFHack
* item quality marks should go after '(' for foreign items

## Building sidebar
### Squad use
* df.global.ui_sidebar_menus.barracks

### Add job
* interface_button_building_new_jobst.is_custom seems to be true for unavailable

# Main Screen
## Build Menu

*
// ignore vampires, they should be treated like normal dwarves
bool isUndead(df::unit* unit)
{
    return (unit->flags3.bits.ghostly ||
            ( (unit->curse.add_tags1.bits.OPPOSED_TO_LIFE || unit->curse.add_tags1.bits.NOT_LIVING)
             && !unit->curse.add_tags1.bits.BLOODSUCKER ));
}

void doMarkForSlaughter(df::unit* unit)
{
    unit->flags2.bits.slaughter = 1;
}

// check if creature is tame
bool isTame(df::unit* creature)
{
    bool tame = false;
    if(creature->flags1.bits.tame)
    {
        switch (creature->training_level)
        {
        case df::animal_training_level::SemiWild: //??
        case df::animal_training_level::Trained:
        case df::animal_training_level::WellTrained:
        case df::animal_training_level::SkilfullyTrained:
        case df::animal_training_level::ExpertlyTrained:
        case df::animal_training_level::ExceptionallyTrained:
        case df::animal_training_level::MasterfullyTrained:
        case df::animal_training_level::Domesticated:
            tame=true;
            break;
        case df::animal_training_level::Unk8:     //??
        case df::animal_training_level::WildUntamed:
        default:
            tame=false;
            break;
        }
    }
    return tame;
}

// check if creature is domesticated
// seems to be the only way to really tell if it's completely safe to autonestbox it (training can revert)
bool isDomesticated(df::unit* creature)
{
    bool tame = false;
    if(creature->flags1.bits.tame)
    {
        switch (creature->training_level)
        {
        case df::animal_training_level::Domesticated:
            tame=true;
            break;
        default:
            tame=false;
            break;
        }
    }
    return tame;
}

// check if trained (might be useful if pasturing war dogs etc)
bool isTrained(df::unit* unit)
{
    // case a: trained for war/hunting (those don't have a training level, strangely)
    if(isWar(unit) || isHunter(unit))
        return true;

    // case b: tamed and trained wild creature, gets a training level
    bool trained = false;
    switch (unit->training_level)
    {
    case df::animal_training_level::Trained:
    case df::animal_training_level::WellTrained:
    case df::animal_training_level::SkilfullyTrained:
    case df::animal_training_level::ExpertlyTrained:
    case df::animal_training_level::ExceptionallyTrained:
    case df::animal_training_level::MasterfullyTrained:
    //case df::animal_training_level::Domesticated:
        trained = true;
        break;
    default:
        break;
    }
    return trained;
}
	
# Stockpile settings
	* animals
		* -> creatures
		* + empty cages, empty animal traps
	* food
		* meat, fish, ... -> materials
		* + prepared food
	* furniture / siege ammo
		* type -> types
		* stone/clay, metal, other -> materials
		* quality...
	* corpses
	* refuse
		* item types -> types
		* corpses, body parts, skulls, bones, shells, teeth, horns/hooves, hair/wool -> cratures
	* stone
		* metal ores, economic, other stone, clay -> materials
	* ammo
		* type -> bolts, arrows, blowdarts
		* metal -> materials
		* other materials -> bone, wood
		* quality...
	* coins
		* -> materials
	* bars/blocks
		* bars: metal -> materials
		* bars: other -> coal, potash, ash, ...
		* blocks: stone/clay, metal, other -> materials
	* gems
		* rough gem, rough glass, cut gem, cut glass, cut stone -> materials
	* finished goods
		* type -> chains, flasks, goblets, ...
		* stone/clay -> materials
		* metal -> materials
		* gem -> materials
		* other materials -> ...
		* quality...

	* leather
		* -> materials
	* cloth
		* thread (silk, plant, yarn, metal) -> materials
		* cloth (silk, plant, yarn, metal) -> materials
	* wood
		* -> tree names
	* weapons / trap comps
		* weapons -> types
		* trap comps -> types
		* metal -> materials
		* stone -> materials
		* other materials -> ...
		* core quality -> ...
		* total quality -> ...
		* + usable/unusable
	* armor
		* body, head, feet, hands, legs, shield -> types
		* metal -> materials
		* other materials -> wood, plant cloth, bone, shell, ...
		* core quality -> standard .. artifact
		* total quality -> standard .. artifact
		* + usable/unusable

	* + additional settings
