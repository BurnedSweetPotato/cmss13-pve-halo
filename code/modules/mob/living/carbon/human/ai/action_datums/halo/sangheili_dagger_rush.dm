// Sangheili Dagger Rush
//
// On acquiring a target there is a flat chance the Sangheili commits to a melee
// charge. It approaches while fire_at_target handles shooting normally. When it
// reaches melee range it holsters the rifle, deploys the gauntlet dagger, and
// swings each tick until the target dies or flees. On exit the dagger retracts.

#define SANGHEILI_DAGGER_RUSH_CHANCE 10

/datum/ai_action/sangheili_dagger_rush
	name = "Sangheili Dagger Rush"
	species_restricted = SPECIES_SANGHEILI
	// No leg/hand flags — the base auto-conflict system would block us behind every
	// other ongoing leg action. We manage conflicts explicitly below.
	action_flags = null

	var/charging = FALSE
	var/at_melee = FALSE
	/// One roll per target — assoc list brain -> target
	var/list/rolled_brains = list()
	/// Ref to the deployed dagger for cleanup
	var/obj/item/weapon/energy_dagger/deployed_dagger

/datum/ai_action/sangheili_dagger_rush/get_weight(datum/human_ai_brain/brain)
	if(!GLOB.sangheili_melee_behaviors_enabled)
		return 0

	if(!brain.current_target || !brain.in_combat || brain.hold_position || brain.sniper_home)
		return 0

	// One roll per target
	if((brain in rolled_brains) && rolled_brains[brain] == brain.current_target)
		return 0

	// Gauntlets must have a stored dagger
	var/obj/item/clothing/gloves/marine/sangheili/gauntlets = brain.tied_human.gloves
	if(!istype(gauntlets) || !gauntlets.stored_dagger || QDELETED(gauntlets.stored_dagger))
		return 0

	rolled_brains[brain] = brain.current_target

	if(!prob(SANGHEILI_DAGGER_RUSH_CHANCE))
		return 0

	return 12

/datum/ai_action/sangheili_dagger_rush/get_conflicts(datum/human_ai_brain/brain)
	. = ..()
	. += /datum/ai_action/walk_melee
	. += /datum/ai_action/take_cover
	. += /datum/ai_action/keep_distance
	// Intentionally NOT conflicting with fire_at_target or chase_target —
	// shooting continues normally during approach.

/datum/ai_action/sangheili_dagger_rush/Added()
	charging = TRUE
	at_melee = FALSE
	brain.tied_human.visible_message(SPAN_DANGER("[brain.tied_human] tenses, its gaze locked on its prey."))

/datum/ai_action/sangheili_dagger_rush/Destroy(force, ...)
	charging = FALSE
	at_melee = FALSE
	if(brain && !QDELETED(brain.tied_human))
		var/mob/living/carbon/human/tied_human = brain.tied_human
		var/obj/item/clothing/gloves/marine/sangheili/gauntlets = tied_human.gloves
		if(istype(gauntlets) && deployed_dagger && !QDELETED(deployed_dagger))
			if(deployed_dagger.loc == tied_human)
				gauntlets.retract_dagger(tied_human)
		// Re-equip the primary weapon if it was holstered for melee
		if(at_melee && brain.primary_weapon)
			brain.unholster_primary()
	deployed_dagger = null
	return ..()

/datum/ai_action/sangheili_dagger_rush/trigger_action()
	. = ..()

	if(!charging)
		return ONGOING_ACTION_COMPLETED

	var/mob/living/carbon/human/tied_human = brain.tied_human
	var/mob/living/target = brain.current_target

	if(!target || QDELETED(target) || target.stat == DEAD)
		return ONGOING_ACTION_COMPLETED

	var/dist = get_dist(tied_human, target)

	if(dist <= 1)
		// First arrival at melee — holster gun and deploy dagger
		if(!at_melee)
			at_melee = TRUE
			if(brain.primary_weapon)
				brain.holster_primary()
			var/obj/item/clothing/gloves/marine/sangheili/gauntlets = tied_human.gloves
			if(istype(gauntlets) && gauntlets.stored_dagger && !QDELETED(gauntlets.stored_dagger))
				gauntlets.toggle_dagger(tied_human)
				deployed_dagger = gauntlets.stored_dagger

		// Swing dagger each tick
		if(deployed_dagger && !QDELETED(deployed_dagger) && deployed_dagger.loc == tied_human)
			if(tied_human.get_inactive_hand() == deployed_dagger)
				tied_human.swap_hand()
			tied_human.a_intent_change(INTENT_HARM)
			tied_human.face_atom(target)
			INVOKE_ASYNC(tied_human, TYPE_PROC_REF(/mob, do_click), target, "", list())
		else
			// Dagger missing or dropped — give up
			return ONGOING_ACTION_COMPLETED

		return ONGOING_ACTION_UNFINISHED

	// Still approaching — move toward target; fire_at_target handles shooting
	brain.move_to_next_turf(get_turf(target))
	tied_human.face_atom(target)
	return ONGOING_ACTION_UNFINISHED

#undef SANGHEILI_DAGGER_RUSH_CHANCE
