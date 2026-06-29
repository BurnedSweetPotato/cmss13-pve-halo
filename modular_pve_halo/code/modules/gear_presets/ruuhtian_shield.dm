// ====================== KIG-YAR SHIELD BEARER PRESETS ====================== //
//
// Adds a "shield bearer" variant to each ruuhtian rank.  The only difference
// from the standard presets is that no weapon is given — the left hand is kept
// free to hold the gauntlet shield (stylistically), and the shield gauntlet
// gloves are already equipped via add_jackal_minor/major/ultra.
// Weapon packages are still added so the AI can fire back.

// ── Shared setup helper ──────────────────────────────────────────────────────

/datum/equipment_preset/proc/add_jackal_shield_minor(mob/living/carbon/human/new_human)
	if(!istype(new_human))
		return
	add_jackal_basics(new_human)
	add_jackal_minor(new_human)

/datum/equipment_preset/proc/add_jackal_shield_major(mob/living/carbon/human/new_human)
	if(!istype(new_human))
		return
	add_jackal_basics(new_human)
	add_jackal_major(new_human)

/datum/equipment_preset/proc/add_jackal_shield_ultra(mob/living/carbon/human/new_human)
	if(!istype(new_human))
		return
	add_jackal_basics(new_human)
	add_jackal_ultra(new_human)

// ── Minor shield bearer ───────────────────────────────────────────────────────

/datum/equipment_preset/covenant/ruuhtian/minor/shield
	name = "Kig-Yar Ruuhtian Minor Shield (Plasma Pistol)"

/datum/equipment_preset/covenant/ruuhtian/minor/shield/load_gear(mob/living/carbon/human/new_human)
	add_jackal_shield_minor(new_human)
	add_plasma_pistol_package(new_human)

/datum/equipment_preset/covenant/ruuhtian/minor/shield/needler
	name = "Kig-Yar Ruuhtian Minor Shield (Needler)"

/datum/equipment_preset/covenant/ruuhtian/minor/shield/needler/load_gear(mob/living/carbon/human/new_human)
	add_jackal_shield_minor(new_human)
	add_needler_package(new_human)

// ── Major shield bearer ───────────────────────────────────────────────────────

/datum/equipment_preset/covenant/ruuhtian/major/shield
	name = "Kig-Yar Ruuhtian Major Shield (Plasma Pistol)"

/datum/equipment_preset/covenant/ruuhtian/major/shield/load_gear(mob/living/carbon/human/new_human)
	add_jackal_shield_major(new_human)
	add_plasma_pistol_package(new_human)

/datum/equipment_preset/covenant/ruuhtian/major/shield/needler
	name = "Kig-Yar Ruuhtian Major Shield (Needler)"

/datum/equipment_preset/covenant/ruuhtian/major/shield/needler/load_gear(mob/living/carbon/human/new_human)
	add_jackal_shield_major(new_human)
	add_needler_package(new_human)

// ── Ultra shield bearer ───────────────────────────────────────────────────────

/datum/equipment_preset/covenant/ruuhtian/ultra/shield
	name = "Kig-Yar Ruuhtian Ultra Shield (Carbine)"

/datum/equipment_preset/covenant/ruuhtian/ultra/shield/load_gear(mob/living/carbon/human/new_human)
	add_jackal_shield_ultra(new_human)
	add_cov_carbine_package(new_human)

/datum/equipment_preset/covenant/ruuhtian/ultra/shield/needler
	name = "Kig-Yar Ruuhtian Ultra Shield (Needler)"

/datum/equipment_preset/covenant/ruuhtian/ultra/shield/needler/load_gear(mob/living/carbon/human/new_human)
	add_jackal_shield_ultra(new_human)
	add_needler_package(new_human)

/datum/equipment_preset/covenant/ruuhtian/ultra/shield/plasma_rifle
	name = "Kig-Yar Ruuhtian Ultra Shield (Plasma Rifle)"

/datum/equipment_preset/covenant/ruuhtian/ultra/shield/plasma_rifle/load_gear(mob/living/carbon/human/new_human)
	add_jackal_shield_ultra(new_human)
	add_plasma_rifle_package(new_human)
