// Unggoy Kamikaze — a Minor that may snap and charge the nearest enemy with live grenades.

// Brain subtype — strips cover-seeking so a charging grunt doesn't duck mid-run.
// The berserk charge action gates itself on istype(brain, /datum/human_ai_brain/unggoy_kamikaze)
// so only kamikazes will ever trigger it.
/datum/human_ai_brain/unggoy_kamikaze
	combat_decay_time_min = 20 SECONDS
	combat_decay_time_max = 40 SECONDS
	cover_without_gun = FALSE

/datum/human_ai_brain/unggoy_kamikaze/New(mob/living/carbon/human/tied_human)
	. = ..()
	action_blacklist = list(/datum/ai_action/take_cover)

// Equipment preset — standard Minor loadout plus two belt grenades.
// After gear is applied we reach into the existing human_ai component and swap
// just the brain object, avoiding any component duplication issues.
/datum/equipment_preset/covenant/unggoy/kamikaze
	name = "Unggoy Kamikaze"
	flags = EQUIPMENT_PRESET_EXTRA|EQUIPMENT_PRESET_MARINE
	idtype = /obj/item/card/id/covenant
	access = list(ACCESS_MARINE_PREP)
	assignment = JOB_COV_MINOR
	rank = JOB_COV_MINOR
	paygrades = list(PAY_SHORT_COV_MINOR = JOB_PLAYTIME_TIER_0)
	role_comm_title = "Minor"
	skills = /datum/skills/covenant/unggoy
	languages = list(LANGUAGE_SANGHEILI, LANGUAGE_UNGGOY)

/datum/equipment_preset/covenant/unggoy/kamikaze/load_gear(mob/living/carbon/human/new_human)
	add_grunt_basics(new_human)
	add_grunt_minor(new_human)
	add_plasma_pistol_package(new_human)
	add_plasma_grenade_low(new_human)
	// Swap the brain inside the existing component — avoids component dupe conflicts
	var/datum/component/human_ai/comp = new_human.GetComponent(/datum/component/human_ai)
	if(comp)
		QDEL_NULL(comp.ai_brain)
		comp.ai_brain = new /datum/human_ai_brain/unggoy_kamikaze(new_human)

// AI spawner panel entry.
/datum/human_ai_equipment_preset/covenant/unggoy/kamikaze
	name = "Unggoy Kamikaze (Berserk)"
	desc = "An Unggoy Minor with a plasma pistol and plasma grenades. Has a chance to snap, drop its gun, grab two grenades and charge the nearest enemy."
	faction = FACTION_UNGGOY
	path = /datum/equipment_preset/covenant/unggoy/kamikaze
