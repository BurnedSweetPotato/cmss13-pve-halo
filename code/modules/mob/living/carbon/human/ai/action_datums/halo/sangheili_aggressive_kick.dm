/// Master toggle for Sangheili special melee behaviors (kick charge + dagger rush).
/// Controlled from the Game Master panel.
GLOBAL_VAR_INIT(sangheili_melee_behaviors_enabled, TRUE)

// Sangheili Aggressive Kick
//
// When a Sangheili acquires a target there is a flat chance it immediately charges
// to kick instead of shooting. Resets when the target changes so each new engagement
// gets a fresh roll.

#define SANGHEILI_KICK_CHANCE 10

/datum/ai_action/sangheili_aggressive_kick
	name = "Sangheili Aggressive Kick"
	species_restricted = SPECIES_SANGHEILI
	action_flags = ACTION_USING_LEGS|ACTION_USING_HANDS

	/// TRUE while closing to kick — lives on the action instance, not the singleton
	var/charging = FALSE
	/// Assoc list of brain -> current_target mob, tracks which engagements have been rolled.
	/// Keyed by brain ref on the singleton.
	var/list/aggro_rolled_brains = list()

/datum/ai_action/sangheili_aggressive_kick/get_weight(datum/human_ai_brain/brain)
	if(!GLOB.sangheili_melee_behaviors_enabled)
		return 0

	if(!brain.current_target || !brain.in_combat || brain.hold_position || brain.sniper_home)
		return 0

	// Feet must be intact to kick
	var/obj/limb/rf = brain.tied_human.get_limb("r_foot")
	var/obj/limb/lf = brain.tied_human.get_limb("l_foot")
	if(!rf?.is_usable() || !lf?.is_usable())
		return 0

	// If we already rolled for this target, skip
	if((brain in aggro_rolled_brains) && aggro_rolled_brains[brain] == brain.current_target)
		return 0

	// Mark this brain+target pair regardless of outcome so we only roll once per engagement
	aggro_rolled_brains[brain] = brain.current_target

	if(!prob(SANGHEILI_KICK_CHANCE))
		return 0

	return 18

/datum/ai_action/sangheili_aggressive_kick/get_conflicts(datum/human_ai_brain/brain)
	. = ..()
	. += /datum/ai_action/fire_at_target
	. += /datum/ai_action/keep_distance
	. += /datum/ai_action/chase_target
	. += /datum/ai_action/walk_melee
	. += /datum/ai_action/take_cover
	. += /datum/ai_action/kick

/datum/ai_action/sangheili_aggressive_kick/Added()
	charging = TRUE
	brain.end_cover()
	var/mob/living/carbon/human/tied_human = brain.tied_human
	if(brain.primary_weapon)
		brain.holster_primary()
	tied_human.a_intent_change(INTENT_HARM)

	var/list/aggro_sounds = list(
		'modular_pve_halo/sound/covenant/sangheili/sangheili_aggro_1.ogg',
		'modular_pve_halo/sound/covenant/sangheili/sangheili_aggro_2.ogg',
		'modular_pve_halo/sound/covenant/sangheili/sangheili_aggro_3.ogg'
	)
	playsound(tied_human, pick(aggro_sounds), 75, TRUE)

/datum/ai_action/sangheili_aggressive_kick/Destroy(force, ...)
	charging = FALSE
	if(brain?.primary_weapon)
		brain.unholster_primary()
	return ..()

/datum/ai_action/sangheili_aggressive_kick/trigger_action()
	. = ..()

	if(!charging)
		return ONGOING_ACTION_COMPLETED

	var/mob/living/carbon/human/tied_human = brain.tied_human
	var/mob/living/target = brain.current_target

	if(!target || QDELETED(target) || target.stat == DEAD)
		return ONGOING_ACTION_COMPLETED

	var/dist = get_dist(tied_human, target)

	if(dist <= 1)
		tied_human.face_atom(target)
		var/datum/action/human_action/activable/covenant/sangheili_kick/kick_action = locate(/datum/action/human_action/activable/covenant/sangheili_kick) in tied_human.actions
		if(kick_action && kick_action.action_cooldown_check())
			INVOKE_ASYNC(kick_action, TYPE_PROC_REF(/datum/action/human_action/activable/covenant/sangheili_kick, use_ability), target, tied_human)
		else
			tied_human.a_intent_change(INTENT_HARM)
			INVOKE_ASYNC(tied_human, TYPE_PROC_REF(/mob, do_click), target, "", list())
		charging = FALSE
		return ONGOING_ACTION_COMPLETED

	if(!brain.move_to_next_turf(get_turf(target)))
		return ONGOING_ACTION_COMPLETED

	tied_human.face_atom(target)
	return ONGOING_ACTION_UNFINISHED

#undef SANGHEILI_KICK_CHANCE
