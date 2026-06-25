// Flee Grenade Carrier
//
// Any Covenant AI within range of a friendly holding an active plasma grenade
// will prioritise moving away from them over normal combat positioning.
// Triggers for all AI, but only fires when a dangerous friendly is nearby.

/datum/ai_action/flee_grenade_carrier
	name = "Flee Grenade Carrier"
	action_flags = ACTION_USING_LEGS

	/// The friendly mob we are currently fleeing
	var/mob/living/carbon/human/dangerous_friendly

/datum/ai_action/flee_grenade_carrier/get_weight(datum/human_ai_brain/brain)
	// Don't flee if we ourselves are the kamikaze
	if(istype(brain, /datum/human_ai_brain/unggoy_kamikaze))
		return 0

	var/mob/living/carbon/human/tied_human = brain.tied_human

	for(var/mob/living/carbon/human/nearby in range(6, tied_human))
		if(nearby == tied_human)
			continue
		// Only flee friendlies
		if(!brain.faction_check(nearby))
			continue
		// Check if they are holding an active plasma grenade in either hand
		if(is_carrying_active_plasma_grenade(nearby))
			dangerous_friendly = nearby
			return 15 // Higher than keep_distance (10) and chase_target (6)

	dangerous_friendly = null
	return 0

/datum/ai_action/flee_grenade_carrier/proc/is_carrying_active_plasma_grenade(mob/living/carbon/human/carrier)
	for(var/obj/item/explosive/grenade/high_explosive/plasma/grenade in list(carrier.get_item_by_slot(WEAR_L_HAND), carrier.get_item_by_slot(WEAR_R_HAND)))
		if(!grenade)
			continue
		if(grenade.active)
			return TRUE
	return FALSE

/datum/ai_action/flee_grenade_carrier/get_conflicts(datum/human_ai_brain/brain)
	. = ..()
	. += /datum/ai_action/keep_distance
	. += /datum/ai_action/chase_target
	. += /datum/ai_action/walk_melee

/datum/ai_action/flee_grenade_carrier/trigger_action()
	. = ..()

	if(!dangerous_friendly || QDELETED(dangerous_friendly))
		return ONGOING_ACTION_COMPLETED

	// Stop fleeing once the grenade is no longer active
	if(!is_carrying_active_plasma_grenade(dangerous_friendly))
		return ONGOING_ACTION_COMPLETED

	var/mob/living/carbon/human/tied_human = brain.tied_human
	var/dist = get_dist(tied_human, dangerous_friendly)

	// Safe distance reached — 5 tiles clear of the blast radius
	if(dist >= 6)
		return ONGOING_ACTION_COMPLETED

	// Back away from the grenade carrier
	var/relative_dir = Get_Compass_Dir(dangerous_friendly, tied_human)
	for(var/direction in list(relative_dir, turn(relative_dir, 45), turn(relative_dir, -45), turn(relative_dir, 90), turn(relative_dir, -90)))
		var/turf/destination = get_step(tied_human, direction)
		if(!destination || destination.density)
			continue
		if(brain.move_to_next_turf(destination))
			return ONGOING_ACTION_UNFINISHED

	// Blocked — nothing we can do
	return ONGOING_ACTION_COMPLETED
