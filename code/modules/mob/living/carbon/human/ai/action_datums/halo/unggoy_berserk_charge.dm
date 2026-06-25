// Unggoy Berserk Charge
//
// Timing math:
//   Plasma grenade det_time = 40 ds (4 seconds).
//   Unggoy run speed: base 2 ds/tile + slowdown 0.1 = ~2.1 ds/tile.
//   In 40 ds the grunt can cover ~19 tiles — plenty to close any realistic combat gap.
//
// Strategy: arm both grenades the INSTANT the charge begins, then sprint.
// Detonate (ai_use) when within 1-2 tiles so the explosion catches the target.
// If the grunt can't reach within the fuse window, it throws rather than dying alone.

/datum/ai_action/unggoy_berserk_charge
	name = "Unggoy Berserk Charge"
	action_flags = ACTION_USING_LEGS|ACTION_USING_HANDS

	/// TRUE once the charge is committed — locks priority and blocks re-trigger
	var/charging = FALSE
	/// Grenade in left hand, armed at charge start
	var/obj/item/explosive/grenade/high_explosive/plasma/grenade_left
	/// Grenade in right hand, armed at charge start
	var/obj/item/explosive/grenade/high_explosive/plasma/grenade_right
	/// World time when the grenades were armed — used to know how much fuse is left
	var/arm_time = 0
	/// det_time of the plasma grenade in deciseconds
	var/fuse_ds = 40
	/// Unggoy run speed in ds/tile (base 2 + slowdown 0.1)
	var/tiles_per_ds = 1 / 2.1

/datum/ai_action/unggoy_berserk_charge/get_weight(datum/human_ai_brain/brain)
	// Only kamikaze brains may use this action
	if(!istype(brain, /datum/human_ai_brain/unggoy_kamikaze))
		return 0

	if(charging)
		return 20

	if(!brain.current_target || !brain.in_combat)
		return 0

	if(!prob(35))
		return 0

	return 20

/datum/ai_action/unggoy_berserk_charge/get_conflicts(datum/human_ai_brain/brain)
	. = ..()
	. += /datum/ai_action/chase_target
	. += /datum/ai_action/fire_at_target
	. += /datum/ai_action/walk_melee
	. += /datum/ai_action/take_cover
	. += /datum/ai_action/throw_grenade
	. += /datum/ai_action/keep_distance

/datum/ai_action/unggoy_berserk_charge/Added()
	if(charging)
		return
	begin_charge()

/datum/ai_action/unggoy_berserk_charge/Destroy(force, ...)
	grenade_left = null
	grenade_right = null
	return ..()

/datum/ai_action/unggoy_berserk_charge/proc/begin_charge()
	var/mob/living/carbon/human/tied_human = brain.tied_human

	// Drop primary weapon so both hands are free
	if(brain.primary_weapon)
		tied_human.drop_held_item(brain.primary_weapon)
		brain.primary_weapon = null

	// Spawn and equip grenades
	grenade_left  = new /obj/item/explosive/grenade/high_explosive/plasma(tied_human)
	grenade_right = new /obj/item/explosive/grenade/high_explosive/plasma(tied_human)
	tied_human.equip_to_slot_or_del(grenade_left,  WEAR_L_HAND)
	tied_human.equip_to_slot_or_del(grenade_right, WEAR_R_HAND)

	// ARM BOTH GRENADES IMMEDIATELY — fuse starts now
	if(!QDELETED(grenade_left) && grenade_left.loc == tied_human)
		grenade_left.activate()
	if(!QDELETED(grenade_right) && grenade_right.loc == tied_human)
		grenade_right.activate()

	arm_time = world.time

	// Play a random berserk voiceline at the charge start
	var/list/berserk_sounds = list(
		'modular_pve_halo/sound/covenant/unggoy/grunt_berserk_1.ogg',
		'modular_pve_halo/sound/covenant/unggoy/grunt_berserk_2.ogg',
		'modular_pve_halo/sound/covenant/unggoy/grunt_berserk_3.ogg'
	)
	playsound(tied_human, pick(berserk_sounds), 75, TRUE)

	charging = TRUE

/datum/ai_action/unggoy_berserk_charge/trigger_action()
	. = ..()

	if(!charging)
		return ONGOING_ACTION_COMPLETED

	var/mob/living/carbon/human/tied_human = brain.tied_human
	var/mob/living/target = brain.current_target

	if(!target || QDELETED(target) || target.stat == DEAD)
		return ONGOING_ACTION_COMPLETED

	// Abort if grenades are already gone (primed/thrown elsewhere)
	var/left_live  = !QDELETED(grenade_left)  && grenade_left.loc  == tied_human
	var/right_live = !QDELETED(grenade_right) && grenade_right.loc == tied_human
	if(!left_live && !right_live)
		return ONGOING_ACTION_COMPLETED

	var/turf/target_turf = get_turf(target)
	var/dist = get_dist(tied_human, target_turf)

	// How much fuse remains (ds)
	var/elapsed    = world.time - arm_time
	var/remaining  = fuse_ds - elapsed

	// Tiles we can still cover before detonation
	var/reachable_tiles = remaining * tiles_per_ds

	// If the target is within 1-2 tiles, detonate now
	if(dist <= 2)
		tied_human.face_atom(target)
		if(left_live)
			INVOKE_ASYNC(grenade_left,  TYPE_PROC_REF(/obj/item, ai_use), tied_human, brain, target_turf)
		if(right_live)
			INVOKE_ASYNC(grenade_right, TYPE_PROC_REF(/obj/item, ai_use), tied_human, brain, target_turf)
		return ONGOING_ACTION_COMPLETED

	// Fuse almost out and we won't close the gap — throw instead of wasting death
	if(remaining <= 6 && reachable_tiles < dist)
		tied_human.face_atom(target)
		if(left_live)
			INVOKE_ASYNC(grenade_left,  TYPE_PROC_REF(/obj/item, ai_use), tied_human, brain, target_turf)
		if(right_live)
			INVOKE_ASYNC(grenade_right, TYPE_PROC_REF(/obj/item, ai_use), tied_human, brain, target_turf)
		return ONGOING_ACTION_COMPLETED

	// Still time — keep sprinting
	brain.move_to_next_turf(target_turf)
	tied_human.face_atom(target)

	return ONGOING_ACTION_UNFINISHED
