// ====================== HURAGOK (SHIELD PROJECTOR) ====================== //
//
// A Huragok NPC that drifts near allied mobs and projects up to 3 energy
// shields to the nearest friendlies, plus a permanent shield on itself.
// Projectiles that hit a shielded mob are cancelled before blood/pain fire.
// Melee/env hits are absorbed via the damage signal.
// Fleeing and clustering are driven by two custom AI actions.
// On death the Huragok plays escalating warning beeps then explodes, spraying gibs and debris.

// ── Species ───────────────────────────────────────────────────────────────

/datum/species/huragok
	group = SPECIES_HURAGOK
	name = "Huragok"
	name_plural = "Huragok"
	mob_flags = KNOWS_TECHNOLOGY
	flags = NO_SHRAPNEL
	mob_inherent_traits = list(
		TRAIT_COV_TECH,
		TRAIT_FOREIGN_BIO,
	)
	pain_type = /datum/pain/ruuhtian
	blood_color = "#AAFFFF"
	flesh_color = "#88CCFF"
	total_health = 200
	burn_mod = 1.0
	brute_mod = 1.0
	slowdown = -0.5

	// Ruuhtian icobase satisfies limb-damage internals without crashing;
	// update_body() on the mob overrides the visual with the Huragok sprite.
	icobase = 'icons/halo/mob/humans/species/ruuhtian/r_ruuhtian.dmi'
	deform = 'icons/halo/mob/humans/species/ruuhtian/r_ruuhtian.dmi'
	dam_icon = 'icons/halo/mob/humans/species/ruuhtian/dam_ruuhtian.dmi'
	blood_mask = 'icons/halo/mob/humans/species/ruuhtian/blood_mask.dmi'

	has_organ = list(
		"heart"   = /datum/internal_organ/heart/kigyar,
		"lungs"   = /datum/internal_organ/lungs/kigyar,
		"liver"   = /datum/internal_organ/liver/kigyar,
		"kidneys" = /datum/internal_organ/kidneys/kigyar,
		"brain"   = /datum/internal_organ/brain/kigyar,
		"eyes"    = /datum/internal_organ/eyes,
	)

/datum/species/huragok/handle_post_spawn(mob/living/carbon/human/H)
	GLOB.alive_human_list -= H
	H.blood_type = "H*"
	H.h_style = "Bald"
	for(var/obj/limb/limb in H.limbs)
		limb.min_broken_damage = 9999
		limb.max_damage = 9999
		limb.time_to_knit = -1

// ── Shield hit particles ──────────────────────────────────────────────────

/particles/huragok_shield_hit
	icon = 'icons/halo/effects/plasma.dmi'
	icon_state = list("shape_1" = 1, "shape_2" = 1, "shape_3" = 1, "shape_4" = 1)
	width = 64
	height = 64
	count = 5
	spawning = 5
	gradient = list("#8844FFFF", "#6622CCFF", "#220066FF")
	color_change = generator(GEN_NUM, 0.03, 0.01)
	lifespan = 10
	fade = generator(GEN_NUM, 20, 35)
	grow = -0.04
	velocity = generator(GEN_CIRCLE, 8, 4, NORMAL_RAND)
	scale = generator(GEN_NUM, 0.15, 0.22)
	friction = generator(GEN_NUM, 0.58, 0.12)

/obj/effect/temp_visual/huragok_shield_hit
	icon = null
	duration = 14
	layer = ABOVE_MOB_LAYER
	indestructible = TRUE
	light_on = FALSE

/obj/effect/temp_visual/huragok_shield_hit/Initialize(mapload)
	. = ..()
	particles = new /particles/huragok_shield_hit
	addtimer(VARSET_CALLBACK(particles, count, 0), 2)

// ── Shield Datum ──────────────────────────────────────────────────────────

/datum/huragok_shield
	/// The Huragok that owns this shield projection
	var/mob/living/carbon/human/owner
	/// The mob currently being shielded
	var/mob/living/carbon/human/shielded
	var/shield_hp = 500
	var/shield_max = 500
	/// Persistent tether beam drawn from owner to shielded mob (null for self-shield)
	var/datum/beam/tether_beam = null
	/// world.time of last damage absorbed — regen is blocked for 5s after this
	var/last_hit_time = 0

/datum/huragok_shield/New(mob/living/carbon/human/huragok_owner, mob/living/carbon/human/target)
	owner = huragok_owner
	shielded = target
	RegisterSignal(target, COMSIG_HUMAN_PRE_BULLET_ACT, PROC_REF(on_pre_bullet))
	RegisterSignal(target, COMSIG_HUMAN_TAKE_DAMAGE,    PROC_REF(on_damage))
	RegisterSignal(target, COMSIG_MOB_DEATH,            PROC_REF(on_target_death))
	target.add_filter("huragok_shield", 3, list(
		"type"  = "outline",
		"color" = "#0055FFAA",
		"size"  = 2,
	))
	if(owner != target)
		tether_beam = owner.beam(target, icon_state = "b_beam", color = "#FFFFFF", always_turn = FALSE)
		addtimer(CALLBACK(src, PROC_REF(_animate_tether)), 1)

/datum/huragok_shield/Destroy()
	QDEL_NULL(tether_beam)
	if(!QDELETED(shielded))
		UnregisterSignal(shielded, list(
			COMSIG_HUMAN_PRE_BULLET_ACT,
			COMSIG_HUMAN_TAKE_DAMAGE,
			COMSIG_MOB_DEATH,
		))
		shielded.remove_filter("huragok_shield")
	shielded = null
	owner = null
	return ..()

/// Intercepts projectiles before blood/pain effects fire.
/datum/huragok_shield/proc/on_pre_bullet(mob/living/carbon/human/target, obj/projectile/P)
	SIGNAL_HANDLER
	if(shield_hp <= 0)
		return
	last_hit_time = world.time
	shield_hp -= min(P.damage, shield_hp)
	playsound(target, pick(
		'sound/weapons/halo/jackal_shield/shield_hit1.wav',
		'sound/weapons/halo/jackal_shield/shield_hit3.wav',
		'sound/weapons/halo/jackal_shield/shield_hit10.wav',
		'sound/weapons/halo/jackal_shield/shield_hit11.wav',
	), 55, TRUE, 5)
	new /obj/effect/temp_visual/huragok_shield_hit(get_turf(target))
	if(shield_hp <= 0)
		INVOKE_ASYNC(src, PROC_REF(_shield_depleted))
	return COMPONENT_CANCEL_BULLET_ACT

/// Absorbs melee and environmental damage.
/datum/huragok_shield/proc/on_damage(mob/living/carbon/human/target, list/damagedata, damagetype)
	SIGNAL_HANDLER
	var/damage = damagedata["damage"]
	if(damage <= 0 || shield_hp <= 0)
		return
	last_hit_time = world.time
	playsound(target, pick(
		'sound/weapons/halo/jackal_shield/shield_hit1.wav',
		'sound/weapons/halo/jackal_shield/shield_hit3.wav',
		'sound/weapons/halo/jackal_shield/shield_hit10.wav',
		'sound/weapons/halo/jackal_shield/shield_hit11.wav',
	), 55, TRUE, 5)
	var/absorbed = min(damage, shield_hp)
	shield_hp -= absorbed
	damagedata["damage"] = damage - absorbed
	if(damagedata["damage"] <= 0)
		return COMPONENT_BLOCK_DAMAGE
	if(shield_hp <= 0)
		_shield_depleted()

/// Regenerates shield HP at 50/s if at least 5 seconds have passed since last hit.
/datum/huragok_shield/proc/try_regen(seconds)
	if(shield_hp >= shield_max)
		return
	if(world.time - last_hit_time < 5 SECONDS)
		return
	shield_hp = min(shield_max, shield_hp + 50 * seconds)

/datum/huragok_shield/proc/on_target_death(mob/living/carbon/human/target)
	SIGNAL_HANDLER
	if(!QDELETED(owner) && istype(owner, /mob/living/carbon/human/huragok))
		var/mob/living/carbon/human/huragok/hur = owner
		hur.notify_shield_lost(src)
	INVOKE_ASYNC(src, PROC_REF(_do_delete))

/datum/huragok_shield/proc/_shield_depleted()
	if(!QDELETED(shielded))
		playsound(shielded, 'sound/weapons/halo/jackal_shield/shield_pop.wav', 50, TRUE, 6)
	if(!QDELETED(owner) && istype(owner, /mob/living/carbon/human/huragok))
		var/mob/living/carbon/human/huragok/hur = owner
		hur.notify_shield_lost(src)
	INVOKE_ASYNC(src, PROC_REF(_do_delete))

/datum/huragok_shield/proc/_do_delete()
	qdel(src)

/// Starts the dark→light blue pulse on the tether beam visuals.
/// Called 1 tick after beam creation so Start()/INVOKE_ASYNC has time to set visuals.
/datum/huragok_shield/proc/_animate_tether()
	if(QDELETED(src) || !tether_beam || QDELETED(tether_beam) || !tether_beam.visuals)
		return
	tether_beam.visuals.color = "#001A66"
	animate(tether_beam.visuals, color = "#66BBFF", time = 20, loop = -1, easing = SINE_EASING)
	animate(color = "#C4EEFF", time = 15, easing = SINE_EASING)
	animate(color = "#001A66", time = 20, easing = SINE_EASING)

// ── Mob ───────────────────────────────────────────────────────────────────

/mob/living/carbon/human/huragok
	name = "Huragok"
	desc = "Gas sacs on its back enable it to float. It has a long snakelike neck and multiple tentacles extending into fine cilia."

	icon = 'modular_pve_halo/icons/mob/huragok/huragok.dmi'
	icon_state = "engineer"

	/// Permanent shield on the Huragok itself
	var/datum/huragok_shield/self_shield
	/// Active shield projections to allies (up to 3)
	var/list/active_shields = list()
	/// Associative: mob → world.time when cooldown expires
	var/list/shield_cooldowns = list()
	/// Cooldown before re-shielding a target after its shield broke
	var/shield_retarget_cooldown = 15 SECONDS
	/// Prevents begin_death_warning from being launched more than once
	var/death_sequence_started = FALSE
	/// world.time of the last unshielded hit — gates self-shield recreation for 5s
	var/self_last_hit_time = 0

/mob/living/carbon/human/huragok/Initialize(mapload)
	. = ..()
	bob_up()
	addtimer(CALLBACK(src, PROC_REF(shield_scan_loop)), 1 SECONDS, TIMER_STOPPABLE)
	// Pain vocalizations: only when the Huragok itself takes unshielded bullet hits
	RegisterSignal(src, COMSIG_HUMAN_PRE_BULLET_ACT, PROC_REF(on_own_bullet_pain))

/mob/living/carbon/human/huragok/Destroy()
	if(self_shield)
		qdel(self_shield)
		self_shield = null
	for(var/datum/huragok_shield/S in active_shields)
		qdel(S)
	active_shields.Cut()
	return ..()

/mob/living/carbon/human/huragok/update_body()
	remove_overlay(BODYPARTS_LAYER)
	remove_overlay(DAMAGE_LAYER)
	if(stat == DEAD)
		return  // let base human corpse rendering take over on death
	var/image/I = image('modular_pve_halo/icons/mob/huragok/huragok.dmi', "engineer", layer = -BODYPARTS_LAYER)
	overlays_standing[BODYPARTS_LAYER] = I
	apply_overlay(BODYPARTS_LAYER)

/mob/living/carbon/human/huragok/death(gibbed, deathmessage = "collapses with a mournful wheeze.", show_dead_message = TRUE)
	animate(src, pixel_y = 0, time = 8, easing = SINE_EASING)
	if(self_shield)
		qdel(self_shield)
		self_shield = null
	for(var/datum/huragok_shield/S in active_shields)
		qdel(S)
	active_shields.Cut()
	update_body()
	if(!death_sequence_started)
		death_sequence_started = TRUE
		INVOKE_ASYNC(src, PROC_REF(begin_death_warning))
	return ..()

/// Plays pain vocalizations only when the Huragok itself is hit by an unshielded bullet.
/// Registered in Initialize; fires before blood/pain effects.
/mob/living/carbon/human/huragok/proc/on_own_bullet_pain(mob/living/carbon/human/target, obj/projectile/P)
	SIGNAL_HANDLER
	// Skip if our self-shield still has HP — the shield's handler will cancel the bullet
	if(self_shield && !QDELETED(self_shield) && self_shield.shield_hp > 0)
		return
	self_last_hit_time = world.time
	playsound(src, pick(
		'modular_pve_halo/sound/covenant/huragok/eng_pain4.wav',
		'modular_pve_halo/sound/covenant/huragok/eng_pain5.wav',
		'modular_pve_halo/sound/covenant/huragok/eng_pain6.wav',
	), 55, TRUE, 8)

/mob/living/carbon/human/huragok/ex_act(severity, direction, datum/cause_data/cause_data)
	severity = max(1, severity * 0.5)
	return ..(severity, direction, cause_data)

/// Plays the three escalating warning beeps then triggers the explosion.
/mob/living/carbon/human/huragok/proc/begin_death_warning()
	if(QDELETED(src))
		return
	var/turf/T = get_turf(src)
	playsound(T, pick(
		'modular_pve_halo/sound/covenant/huragok/eng_death_warning1.wav',
		'modular_pve_halo/sound/covenant/huragok/eng_death_warning2.wav',
		'modular_pve_halo/sound/covenant/huragok/eng_death_warning3.wav',
	), 80, TRUE, 12)
	sleep(6 SECONDS)
	if(QDELETED(src))
		return
	huragok_explode()

/mob/living/carbon/human/huragok/proc/huragok_explode()
	if(QDELETED(src))
		return
	var/turf/T = get_turf(src)

	// Sound and visuals fire together
	playsound(T, 'sound/effects/explosion1.ogg', 80, TRUE, 10)
	new /obj/effect/temp_visual/plasma_explosion(T)
	new /obj/effect/spawner/gibspawner/huragok(T, null, null, species?.flesh_color, species?.blood_color)

	// Oil pool and scatter
	new /obj/effect/decal/cleanable/blood/oil(T)
	for(var/turf/open/floor/nearby in range(2, T))
		if(!prob(55))
			continue
		switch(rand(1, 4))
			if(1)
				var/obj/item/stack/rods/R = new(nearby)
				R.amount = rand(1, 3)
			if(2)
				var/obj/item/stack/cable_coil/C = new(nearby, rand(2, 8))
				C.color = "#7799AA"
			if(3, 4)
				new /obj/effect/decal/cleanable/blood/oil(nearby)

	qdel(src)

// ── Custom gib spawner (robot chassis + gel bio-matter) ──────────────────

/obj/effect/spawner/gibspawner/huragok
	sparks = TRUE
	gibtypes = list(
		/obj/effect/decal/cleanable/blood/gibs/robot/up,
		/obj/effect/decal/cleanable/blood/gibs/robot/down,
		/obj/effect/decal/cleanable/blood/gibs/robot,
		/obj/effect/decal/cleanable/blood/gibs/robot,
		/obj/effect/decal/cleanable/blood/gibs,
		/obj/effect/decal/cleanable/blood/gibs,
		/obj/effect/decal/cleanable/blood/gibs/core,
	)
	gibamounts = list(1, 1, 1, 1, 2, 1, 1)

/obj/effect/spawner/gibspawner/huragok/Initialize(mapload, list/viruses, mob/living/ml, fleshcolor, bloodcolor)
	gibdirections = list(
		list(NORTH, NORTHEAST, NORTHWEST),
		list(SOUTH, SOUTHEAST, SOUTHWEST),
		list(WEST,  NORTHWEST,  SOUTHWEST),
		list(EAST,  NORTHEAST,  SOUTHEAST),
		GLOB.alldirs,
		GLOB.alldirs,
		list(),
	)
	. = ..()

// ── Bobbing levitation ────────────────────────────────────────────────────

/mob/living/carbon/human/huragok/proc/bob_up()
	if(QDELETED(src) || stat == DEAD)
		return
	animate(src, pixel_y = 4, time = 10, easing = SINE_EASING)
	addtimer(CALLBACK(src, PROC_REF(bob_down)), 1 SECONDS, TIMER_STOPPABLE)

/mob/living/carbon/human/huragok/proc/bob_down()
	if(QDELETED(src) || stat == DEAD)
		return
	animate(src, pixel_y = -4, time = 10, easing = SINE_EASING)
	addtimer(CALLBACK(src, PROC_REF(bob_up)), 1 SECONDS, TIMER_STOPPABLE)

// ── Shield management ─────────────────────────────────────────────────────

/mob/living/carbon/human/huragok/proc/shield_scan_loop()
	if(QDELETED(src) || stat == DEAD)
		return
	update_shield_targets()
	addtimer(CALLBACK(src, PROC_REF(shield_scan_loop)), 2 SECONDS, TIMER_STOPPABLE)

/// Called by a shield datum when it ends (break or target death).
/mob/living/carbon/human/huragok/proc/notify_shield_lost(datum/huragok_shield/lost)
	if(lost == self_shield)
		self_shield = null
		self_last_hit_time = world.time  // block recreation for 5s after shield breaks
		return
	var/mob/target = lost.shielded
	active_shields -= lost
	if(target && !QDELETED(target))
		shield_cooldowns[target] = world.time + shield_retarget_cooldown

/mob/living/carbon/human/huragok/proc/update_shield_targets()
	// Prune stale active shields
	for(var/datum/huragok_shield/S in active_shields)
		if(QDELETED(S) || QDELETED(S.shielded) || S.shielded.stat == DEAD)
			active_shields -= S

	// Regen HP for all existing shields (scan loop fires every 2s, so delta = 2)
	if(self_shield && !QDELETED(self_shield))
		self_shield.try_regen(2)
	for(var/datum/huragok_shield/S in active_shields)
		if(!QDELETED(S))
			S.try_regen(2)

	// Recreate self-shield only once 5s have passed since the last unshielded hit
	if(!self_shield || QDELETED(self_shield))
		if(world.time - self_last_hit_time >= 5 SECONDS)
			self_shield = new /datum/huragok_shield(src, src)

	if(length(active_shields) >= 3)
		return

	// Expire stale cooldowns
	for(var/mob/M in shield_cooldowns)
		if(world.time >= shield_cooldowns[M])
			shield_cooldowns.Remove(M)

	// Build set of already-shielded allies to avoid doubles
	var/list/already_shielded = list()
	for(var/datum/huragok_shield/S in active_shields)
		if(!QDELETED(S.shielded))
			already_shielded += S.shielded

	// Fill remaining slots with the nearest available allies.
	// Direct faction check — no brain needed, avoids timing issues with appraise_inventory.
	for(var/mob/living/carbon/human/nearby in range(8, src))
		if(length(active_shields) >= 3)
			break
		if(nearby == src || nearby.stat == DEAD)
			continue
		if(!is_covenant_ally(nearby))
			continue
		if(nearby in already_shielded)
			continue
		if(shield_cooldowns[nearby])
			continue
		// Prevent two Huragoks from shielding the same target
		if(nearby.filter_data && nearby.filter_data["huragok_shield"])
			continue
		already_shielded += nearby
		active_shields += new /datum/huragok_shield(src, nearby)

/// Returns TRUE if the target mob belongs to a Covenant-aligned faction.
/mob/living/carbon/human/huragok/proc/is_covenant_ally(mob/living/carbon/human/M)
	if(M.faction == faction)
		return TRUE
	return M.faction in list(
		FACTION_SANGHEILI,
		FACTION_KIGYAR,
		FACTION_UNGGOY,
		FACTION_SPECOPS_SANGHEILI,
		FACTION_SPECOPS_KIGYAR,
		FACTION_SPECOPS_UNGGOY,
		FACTION_COVENANT,
	)

// ── AI brain ──────────────────────────────────────────────────────────────

/datum/human_ai_brain/huragok
	combat_decay_time_min = 5 SECONDS
	combat_decay_time_max = 10 SECONDS
	cover_without_gun = FALSE
	/// Tracks when the last flee vocalization played to prevent spam
	var/flee_sound_time = 0

/datum/human_ai_brain/huragok/New(mob/living/carbon/human/tied_human)
	. = ..()
	action_whitelist = list(
		/datum/ai_action/huragok_approach_allies,
		/datum/ai_action/huragok_flee_enemies,
		/datum/ai_action/flee_grenade_carrier,
		/datum/ai_action/resist_burning,
	)

// ── AI action: approach ally cluster ─────────────────────────────────────

/datum/ai_action/huragok_approach_allies
	name = "Huragok Approach Allies"
	action_flags = ACTION_USING_LEGS

	var/ideal_range = 3

/datum/ai_action/huragok_approach_allies/get_weight(datum/human_ai_brain/brain)
	var/mob/living/carbon/human/tied_human = brain.tied_human
	// Yield to flee if any enemy is in close range
	for(var/mob/living/nearby in range(6, tied_human))
		if(nearby == tied_human || nearby.stat == DEAD)
			continue
		if(!brain.faction_check(nearby))
			return 0
	for(var/mob/living/carbon/human/ally in range(10, tied_human))
		if(ally == tied_human || ally.stat == DEAD)
			continue
		if(!brain.faction_check(ally))
			continue
		if(get_dist(tied_human, ally) > ideal_range)
			return 5
	return 0

/datum/ai_action/huragok_approach_allies/trigger_action()
	. = ..()
	var/mob/living/carbon/human/tied_human = brain.tied_human

	// Search for nearest ally each trigger tick — do NOT rely on singleton vars
	var/mob/nearest = null
	var/best_dist = INFINITY
	for(var/mob/living/carbon/human/ally in range(10, tied_human))
		if(ally == tied_human || ally.stat == DEAD)
			continue
		if(!brain.faction_check(ally))
			continue
		var/d = get_dist(tied_human, ally)
		if(d < best_dist)
			best_dist = d
			nearest = ally

	if(!nearest || best_dist <= ideal_range)
		return ONGOING_ACTION_COMPLETED

	if(brain.move_to_next_turf(get_turf(nearest)))
		return ONGOING_ACTION_UNFINISHED
	return ONGOING_ACTION_COMPLETED

// ── AI action: flee from enemies ──────────────────────────────────────────

/datum/ai_action/huragok_flee_enemies
	name = "Huragok Flee Enemies"
	action_flags = ACTION_USING_LEGS

/// Vocalize when the flee action starts, gated by an 8-second cooldown.
/// Added() fires every time a new instance is created, which happens each time
/// the action completes and then re-qualifies — without a cooldown it spams.
/datum/ai_action/huragok_flee_enemies/Added()
	if(!brain || QDELETED(brain.tied_human))
		return
	var/datum/human_ai_brain/huragok/hur_brain = brain
	if(!istype(hur_brain))
		return
	if(world.time - hur_brain.flee_sound_time < 8 SECONDS)
		return
	hur_brain.flee_sound_time = world.time
	playsound(brain.tied_human, pick(
		'modular_pve_halo/sound/covenant/huragok/eng_flee1.wav',
		'modular_pve_halo/sound/covenant/huragok/eng_flee2.wav',
		'modular_pve_halo/sound/covenant/huragok/eng_flee3.wav',
	), 60, TRUE, 10)

/datum/ai_action/huragok_flee_enemies/get_weight(datum/human_ai_brain/brain)
	var/mob/living/carbon/human/tied_human = brain.tied_human
	for(var/mob/living/nearby in range(8, tied_human))
		if(nearby == tied_human || nearby.stat == DEAD)
			continue
		if(!brain.faction_check(nearby))
			return 15
	return 0

/datum/ai_action/huragok_flee_enemies/get_conflicts(datum/human_ai_brain/brain)
	. = ..()
	. += /datum/ai_action/huragok_approach_allies

/datum/ai_action/huragok_flee_enemies/trigger_action()
	. = ..()
	var/mob/living/carbon/human/tied_human = brain.tied_human

	// Search for nearest enemy each trigger tick
	var/mob/living/nearest_enemy = null
	var/best_dist = INFINITY
	for(var/mob/living/nearby in range(8, tied_human))
		if(nearby == tied_human || nearby.stat == DEAD)
			continue
		if(brain.faction_check(nearby))
			continue
		var/d = get_dist(tied_human, nearby)
		if(d < best_dist)
			best_dist = d
			nearest_enemy = nearby

	if(!nearest_enemy || best_dist >= 8)
		return ONGOING_ACTION_COMPLETED

	var/relative_dir = Get_Compass_Dir(nearest_enemy, tied_human)
	for(var/direction in list(relative_dir, turn(relative_dir, 45), turn(relative_dir, -45), turn(relative_dir, 90), turn(relative_dir, -90)))
		var/turf/destination = get_step(tied_human, direction)
		if(!destination || destination.density)
			continue
		if(brain.move_to_next_turf(destination))
			return ONGOING_ACTION_UNFINISHED

	return ONGOING_ACTION_COMPLETED

