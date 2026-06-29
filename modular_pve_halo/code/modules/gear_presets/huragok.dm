// ====================== HURAGOK GEAR PRESETS ====================== //
//
// Equips the Huragok with species, faction, and swaps in the Huragok AI
// brain so it only runs its two custom behaviours (approach allies / flee
// enemies).  No weapon is given — it projects shields, not plasma.

/datum/equipment_preset/covenant/huragok
	name = "Huragok (Shield Projector)"
	flags = EQUIPMENT_PRESET_EXTRA
	idtype = null
	ethnicity = HURAGOK_ETHNICITY
	assignment = "Huragok"
	rank = "Huragok"
	paygrades = list(PAY_SHORT_COV_MINOR = JOB_PLAYTIME_TIER_0)
	role_comm_title = "Engineer"
	skills = /datum/skills/covenant/unggoy
	languages = list(LANGUAGE_SANGHEILI)
	faction = FACTION_COVENANT

/datum/equipment_preset/covenant/huragok/load_gear(mob/living/carbon/human/new_human)
	new_human.set_species(SPECIES_HURAGOK)
	new_human.faction = FACTION_COVENANT
	var/datum/component/human_ai/comp = new_human.GetComponent(/datum/component/human_ai)
	if(comp)
		QDEL_NULL(comp.ai_brain)
		comp.ai_brain = new /datum/human_ai_brain/huragok(new_human)

// ── AI spawner panel entry ────────────────────────────────────────────────

/datum/human_ai_equipment_preset/covenant/huragok
	name = "Huragok (Shield Projector)"
	desc = "A Covenant Engineer that drifts near allies and projects a 500-HP energy shield onto the nearest friendly mob. Resistant to explosions. Flees from enemies rather than fighting."
	faction = FACTION_COVENANT
	path = /datum/equipment_preset/covenant/huragok
	spawner_mob_type = /mob/living/carbon/human/huragok
