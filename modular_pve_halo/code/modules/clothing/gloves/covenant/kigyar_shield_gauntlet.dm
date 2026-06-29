// ====================== KIG-YAR DIRECTIONAL ENERGY SHIELD ====================== //
//
// Extends ruuhtian minor/major/ultra gloves with directional energy shield mechanics.
// Implemented to match the predator wristblade pattern:
//   - Shield item lives inside the gloves object when not deployed.
//   - Deploy: moved into hand via put_in_*_hand.
//   - Retract: moved BACK into gloves via drop_inv_item_to_loc (clears hand slot properly).
//   - Q-drop blocked by NODROP; Z (attack_self) or the HUD button retracts.
//   - Death: same retract path, silently.
//
// Blocking is PASSIVE — the gauntlet blocks regardless of whether the physical
// shield item is currently held.
//
// Shield HP:
//   Minor: 2250 HP, 5 s delay, 60/s regen — blue flash
//   Major: 3750 HP, 4 s delay, 75/s regen — orange flash
//   Ultra: 6000 HP, 3 s delay, 105/s regen — white flash

// ─────────────────────────────────────────────────────────────────────────────
//  Particles — per-rank shield hit sparks (stay within ~1 tile of mob)
// ─────────────────────────────────────────────────────────────────────────────

/particles/kigyar_shield_hit
	icon = 'icons/halo/effects/plasma.dmi'
	icon_state = list("shape_1" = 1, "shape_2" = 1, "shape_3" = 1, "shape_4" = 1)
	width = 64
	height = 64
	count = 6
	spawning = 6
	gradient = list("#FFFFFF", "#88ccffff", "#3355aaff")
	color_change = generator(GEN_NUM, 0.02, 0.01)
	lifespan = 8
	fade = generator(GEN_NUM, 30, 40)
	grow = -0.06
	velocity = generator(GEN_CIRCLE, 6, 4, NORMAL_RAND)
	scale = generator(GEN_NUM, 0.18, 0.26)
	friction = generator(GEN_NUM, 0.7, 0.15)

/particles/kigyar_shield_hit/major
	gradient = list("#FFFFFF", "#FF8800ff", "#992200ff")

/particles/kigyar_shield_hit/ultra
	gradient = list("#FFFFFF", "#ddeeffff", "#99aaccff")

// ─────────────────────────────────────────────────────────────────────────────
//  Temp visuals wrapping the per-rank particles
// ─────────────────────────────────────────────────────────────────────────────

/obj/effect/temp_visual/kigyar_shield_hit
	icon = null
	duration = 12
	layer = ABOVE_MOB_LAYER
	indestructible = TRUE
	light_on = FALSE  // light managed directly on shield_item to prevent stacking
	var/particles_type = /particles/kigyar_shield_hit

/obj/effect/temp_visual/kigyar_shield_hit/Initialize(mapload)
	. = ..()
	particles = new particles_type
	addtimer(VARSET_CALLBACK(particles, count, 0), 2)

/obj/effect/temp_visual/kigyar_shield_hit/major
	particles_type = /particles/kigyar_shield_hit/major

/obj/effect/temp_visual/kigyar_shield_hit/ultra
	particles_type = /particles/kigyar_shield_hit/ultra

// ─────────────────────────────────────────────────────────────────────────────
//  1. Physical shield item
// ─────────────────────────────────────────────────────────────────────────────

/obj/item/kigyar_energy_shield
	name = "energy shield"
	desc = "A shimmering directional energy shield projected from a Kig-Yar gauntlet. Activate in-hand to retract it."
	icon = 'icons/halo/obj/items/weapons/covenant/shield/shield_gauntlet.dmi'
	icon_state = "shield"
	item_state = "shield"
	w_class = SIZE_TINY
	flags_item = NODROP  // can't be Q-dropped; retract via Z or HUD button
	item_icons = list(
		WEAR_L_HAND = 'icons/halo/obj/items/weapons/covenant/shield/shield_gauntlet_lefthand.dmi',
		WEAR_R_HAND = 'icons/halo/obj/items/weapons/covenant/shield/shield_gauntlet_righthand.dmi',
	)
	var/obj/item/clothing/gloves/marine/ruuhtian/gauntlet

/obj/item/kigyar_energy_shield/Initialize(mapload, obj/item/clothing/gloves/marine/ruuhtian/creator)
	. = ..()
	gauntlet = creator

/obj/item/kigyar_energy_shield/Destroy()
	gauntlet = null
	return ..()

// Z (activate in-hand) retracts the shield, matching wristblade behaviour.
/obj/item/kigyar_energy_shield/attack_self(mob/living/carbon/human/user)
	. = ..()
	if(gauntlet && istype(user))
		gauntlet.retract_shield(user)

// Force-dropped by unusual code path — clean up state.
/obj/item/kigyar_energy_shield/dropped(mob/user)
	. = ..()
	if(gauntlet)
		gauntlet.on_shield_item_dropped()

// Minor uses the shield_old state (blue sprite).
/obj/item/kigyar_energy_shield/minor
	icon_state = "shield_old"
	item_state = "shield_old"

// Major uses the base "shield" sprite but tinted orange.
/obj/item/kigyar_energy_shield/major
	color = "#FF8800"

// Ultra uses the shield_major sprite (visually distinct).
/obj/item/kigyar_energy_shield/ultra
	icon_state = "shield_major"
	item_state = "shield_major"

// ─────────────────────────────────────────────────────────────────────────────
//  2. HUD action button
// ─────────────────────────────────────────────────────────────────────────────

/datum/action/item_action/kigyar_shield_toggle
	name = "Toggle Energy Shield"

/datum/action/item_action/kigyar_shield_toggle/update_button_icon()
	button.overlays.Cut()
	button.overlays += mutable_appearance(
		'icons/halo/obj/items/weapons/covenant/shield/shield_gauntlet.dmi',
		"gauntlet_active",
		plane = ABOVE_HUD_PLANE,
	)

/datum/action/item_action/kigyar_shield_toggle/action_activate()
	. = ..()
	var/obj/item/clothing/gloves/marine/ruuhtian/G = target
	if(!istype(G) || !ishuman(owner))
		return
	G.toggle_shield(owner)

// ─────────────────────────────────────────────────────────────────────────────
//  3. Gloves — vars
// ─────────────────────────────────────────────────────────────────────────────

/obj/item/clothing/gloves/marine/ruuhtian
	var/shield_max     = 0
	var/shield_current = 0
	var/shield_broken  = FALSE
	var/regen_delay    = 5 SECONDS
	var/regen_rate     = 20
	var/shield_color   = "#44AAFF"
	// Base RGB of the shield sprite at full health — used for damage hue interpolation.
	var/shield_base_r  = 68
	var/shield_base_g  = 170
	var/shield_base_b  = 255
	// world.time tick at which the hit glow on shield_item should be cleared.
	var/shield_light_expires = 0
	var/obj/item/kigyar_energy_shield/shield_item    = null
	var/obj/item/weapon/gun/stabilized_gun            = null
	var/datum/action/item_action/kigyar_shield_toggle/shield_action = null

	COOLDOWN_DECLARE(shield_regen_cd)

// ─────────────────────────────────────────────────────────────────────────────
//  4. Equip / unequip
// ─────────────────────────────────────────────────────────────────────────────

/obj/item/clothing/gloves/marine/ruuhtian/equipped(mob/user, slot)
	. = ..()
	if(slot != WEAR_HANDS || !shield_max)
		return

	shield_current = shield_max
	shield_broken  = FALSE

	shield_action = new /datum/action/item_action/kigyar_shield_toggle(src)
	shield_action.give_to(user)

	RegisterSignal(user, COMSIG_HUMAN_PRE_BULLET_ACT, PROC_REF(on_bullet_hit))
	RegisterSignal(user, COMSIG_MOB_DEATH, PROC_REF(on_wearer_death))

	START_PROCESSING(SSobj, src)

	// AI mobs: auto-deploy 10 ticks after equip (gun will be in the other hand by then).
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		if(H.get_ai_brain())
			addtimer(CALLBACK(src, PROC_REF(ai_auto_deploy), H), 10)

/obj/item/clothing/gloves/marine/ruuhtian/unequipped(mob/user, slot)
	. = ..()
	if(slot != WEAR_HANDS || !shield_max)
		return

	if(shield_item)
		retract_shield(user)

	if(shield_action)
		shield_action.remove_from(user)
		qdel(shield_action)
		shield_action = null

	UnregisterSignal(user, COMSIG_HUMAN_PRE_BULLET_ACT)
	UnregisterSignal(user, COMSIG_MOB_DEATH)
	STOP_PROCESSING(SSobj, src)

// ─────────────────────────────────────────────────────────────────────────────
//  5. AI auto-deploy
// ─────────────────────────────────────────────────────────────────────────────

/obj/item/clothing/gloves/marine/ruuhtian/proc/ai_auto_deploy(mob/living/carbon/human/user)
	if(!user || QDELETED(user) || user.stat == DEAD)
		return
	if(!shield_max || (shield_item && !QDELETED(shield_item)))
		return
	if(src.loc != user)
		return
	deploy_shield(user)

// ─────────────────────────────────────────────────────────────────────────────
//  6. Death handler
// ─────────────────────────────────────────────────────────────────────────────

/obj/item/clothing/gloves/marine/ruuhtian/proc/on_wearer_death(mob/living/carbon/human/H, gibbed)
	SIGNAL_HANDLER
	if(stabilized_gun)
		stabilized_gun.flags_gun_features &= ~GUN_ONE_HAND_WIELDED
		stabilized_gun = null
	if(shield_item && !QDELETED(shield_item))
		// Shield was still up when the jackal died — play the same pop effect as overload.
		if(!QDELETED(H))
			playsound(H, 'sound/weapons/halo/jackal_shield/shield_pop.wav', 65, TRUE, 6)
			new /obj/effect/temp_visual/plasma_explosion/shield_pop(get_turf(H))
			play_shield_death_voice(H)
		var/obj/item/kigyar_energy_shield/S = shield_item
		shield_item = null
		S.gauntlet = null
		if(!QDELETED(H))
			H.drop_inv_item_to_loc(S, src, FALSE, TRUE)
		qdel(S)

// ─────────────────────────────────────────────────────────────────────────────
//  7. Toggle, deploy, retract
// ─────────────────────────────────────────────────────────────────────────────

/obj/item/clothing/gloves/marine/ruuhtian/proc/toggle_shield(mob/living/carbon/human/user)
	if(shield_item && !QDELETED(shield_item))
		retract_shield(user)
	else
		deploy_shield(user)

/obj/item/clothing/gloves/marine/ruuhtian/proc/deploy_shield(mob/living/carbon/human/user)
	if(!user || (shield_item && !QDELETED(shield_item)))
		return

	if(user.l_hand && user.r_hand)
		if(user.client)
			to_chat(user, SPAN_WARNING("You need a free hand to deploy your energy shield!"))
		return

	var/shield_type = /obj/item/kigyar_energy_shield
	if(istype(src, /obj/item/clothing/gloves/marine/ruuhtian/ultra))
		shield_type = /obj/item/kigyar_energy_shield/ultra
	else if(istype(src, /obj/item/clothing/gloves/marine/ruuhtian/major))
		shield_type = /obj/item/kigyar_energy_shield/major
	else if(istype(src, /obj/item/clothing/gloves/marine/ruuhtian/minor))
		shield_type = /obj/item/kigyar_energy_shield/minor
	// Create inside the gloves (matching wristblade pattern — item lives in gloves when not held).
	shield_item = new shield_type(src, src)

	if(!user.put_in_inactive_hand(shield_item))
		if(!user.put_in_active_hand(shield_item))
			shield_item.gauntlet = null
			qdel(shield_item)
			shield_item = null
			return

	// Stabilise the gun in the other hand.
	var/obj/item/other = (user.l_hand == shield_item) ? user.r_hand : user.l_hand
	if(istype(other, /obj/item/weapon/gun))
		stabilized_gun = other
		stabilized_gun.flags_gun_features |= GUN_ONE_HAND_WIELDED

	update_shield_color()

	playsound(user, "shield_manual_up", 50, TRUE, 5)
	user.visible_message(
		SPAN_NOTICE("[user] activates their energy shield."),
		SPAN_NOTICE("You raise your energy shield."),
	)

/obj/item/clothing/gloves/marine/ruuhtian/proc/update_shield_color()
	if(!shield_item || QDELETED(shield_item) || !shield_max)
		return
	var/ratio = clamp(shield_current / shield_max, 0, 1)
	var/r = round(shield_base_r + (255 - shield_base_r) * (1 - ratio))
	var/g = round(shield_base_g + (34  - shield_base_g) * (1 - ratio))
	var/b = round(shield_base_b + (34  - shield_base_b) * (1 - ratio))
	shield_item.color = rgb(r, g, b)
	// The mob's hand overlay is a snapshot image — must be regenerated after a color change.
	if(!ishuman(loc))
		return
	var/mob/living/carbon/human/H = loc
	if(H.l_hand == shield_item)
		H.update_inv_l_hand()
	else if(H.r_hand == shield_item)
		H.update_inv_r_hand()

/obj/item/clothing/gloves/marine/ruuhtian/proc/retract_shield(mob/living/carbon/human/user)
	if(stabilized_gun)
		stabilized_gun.flags_gun_features &= ~GUN_ONE_HAND_WIELDED
		stabilized_gun = null

	if(shield_item && !QDELETED(shield_item))
		var/obj/item/kigyar_energy_shield/S = shield_item
		shield_item = null
		S.gauntlet = null
		// Move back into the gloves — properly clears the mob's hand slot variable.
		if(user && !QDELETED(user))
			user.drop_inv_item_to_loc(S, src, FALSE, TRUE)
		qdel(S)

	if(user)
		playsound(user, "shield_manual_down", 50, TRUE, 5)
		user.visible_message(
			SPAN_NOTICE("[user] lowers their energy shield."),
			SPAN_NOTICE("You retract your energy shield."),
		)

/obj/item/clothing/gloves/marine/ruuhtian/proc/retract_shield_silent(mob/living/carbon/human/user)
	if(stabilized_gun)
		stabilized_gun.flags_gun_features &= ~GUN_ONE_HAND_WIELDED
		stabilized_gun = null
	if(shield_item && !QDELETED(shield_item))
		var/obj/item/kigyar_energy_shield/S = shield_item
		shield_item = null
		S.gauntlet = null
		if(user && !QDELETED(user))
			user.drop_inv_item_to_loc(S, src, FALSE, TRUE)
		qdel(S)

// Fallback for edge-case force-drops.
/obj/item/clothing/gloves/marine/ruuhtian/proc/on_shield_item_dropped()
	if(stabilized_gun)
		stabilized_gun.flags_gun_features &= ~GUN_ONE_HAND_WIELDED
		stabilized_gun = null
	shield_item = null

// ─────────────────────────────────────────────────────────────────────────────
//  8. Directional bullet blocking (passive)
// ─────────────────────────────────────────────────────────────────────────────

/obj/item/clothing/gloves/marine/ruuhtian/proc/on_bullet_hit(mob/living/carbon/human/H, obj/projectile/P)
	SIGNAL_HANDLER

	if(shield_broken || !shield_current)
		return

	// No protection when prone — can't hold the shield up.
	if(H.body_position == LYING_DOWN)
		return

	if(!P.starting)
		return

	var/mob_dir    = H.dir
	var/attack_dir = get_dir(get_turf(H), P.starting)
	if(!(attack_dir in list(mob_dir, turn(mob_dir, 45), turn(mob_dir, -45))))
		return

	absorb_hit(H, P.damage)
	return COMPONENT_CANCEL_BULLET_ACT

/obj/item/clothing/gloves/marine/ruuhtian/proc/absorb_hit(mob/living/carbon/human/H, damage)
	playsound(H, pick(
		'sound/weapons/halo/jackal_shield/shield_hit1.wav',
		'sound/weapons/halo/jackal_shield/shield_hit3.wav',
		'sound/weapons/halo/jackal_shield/shield_hit10.wav',
		'sound/weapons/halo/jackal_shield/shield_hit11.wav',
	), 55, TRUE, 5)

	COOLDOWN_START(src, shield_regen_cd, regen_delay)
	shield_current = max(shield_current - damage, 0)
	update_shield_color()

	// Spawn rank-coloured particle burst and apply a single blueish-purple glow.
	if(shield_item && !QDELETED(shield_item))
		var/visual_type = /obj/effect/temp_visual/kigyar_shield_hit
		if(istype(src, /obj/item/clothing/gloves/marine/ruuhtian/ultra))
			visual_type = /obj/effect/temp_visual/kigyar_shield_hit/ultra
		else if(istype(src, /obj/item/clothing/gloves/marine/ruuhtian/major))
			visual_type = /obj/effect/temp_visual/kigyar_shield_hit/major
		new visual_type(get_turf(H))
		// One persistent light on the shield item — refreshes expire time each hit.
		shield_item.set_light(1, 2, "#5533BB")
		shield_light_expires = world.time + 5

	if(shield_current <= 0)
		shield_broken = TRUE
		playsound(H, 'sound/weapons/halo/jackal_shield/shield_pop.wav', 65, TRUE, 6)
		new /obj/effect/temp_visual/plasma_explosion/shield_pop(get_turf(H))
		play_shield_death_voice(H)
		H.visible_message(
			SPAN_WARNING("[H]'s energy shield collapses with a burst of light!"),
			SPAN_WARNING("Your energy shield has been overloaded!"),
		)
		retract_shield_silent(H)

/obj/item/clothing/gloves/marine/ruuhtian/proc/play_shield_death_voice(mob/living/carbon/human/H)
	playsound(H, pick(
		'sound/weapons/halo/jackal_shield/jackal_pain_1.wav',
		'sound/weapons/halo/jackal_shield/jackal_pain_2.wav',
		'sound/weapons/halo/jackal_shield/jackal_pain_3.wav',
	), 60, FALSE, 7)

// ─────────────────────────────────────────────────────────────────────────────
//  9. Regen
// ─────────────────────────────────────────────────────────────────────────────

/obj/item/clothing/gloves/marine/ruuhtian/process(delta_time)
	if(!ishuman(loc))
		STOP_PROCESSING(SSobj, src)
		return

	// Clear the hit glow once the expire tick passes.
	if(shield_light_expires && world.time >= shield_light_expires)
		shield_light_expires = 0
		if(shield_item && !QDELETED(shield_item))
			shield_item.set_light(0, 0)

	if(!shield_broken && shield_current >= shield_max)
		return

	if(!COOLDOWN_FINISHED(src, shield_regen_cd))
		return

	shield_current = min(shield_current + (regen_rate * delta_time), shield_max)
	update_shield_color()

	if(shield_broken && shield_current >= shield_max)
		shield_broken = FALSE
		var/mob/living/carbon/human/H = loc
		playsound(H, "shield_charge", 40, TRUE, 5)
		H.visible_message(
			SPAN_NOTICE("[H]'s energy shield shimmers back to life."),
			SPAN_NOTICE("Your energy shield has recharged."),
		)
		// AI mobs: re-deploy the physical shield now that it's fully recharged.
		if(H.get_ai_brain())
			deploy_shield(H)

// ─────────────────────────────────────────────────────────────────────────────
//  10. Per-rank stats
// ─────────────────────────────────────────────────────────────────────────────

/obj/item/clothing/gloves/marine/ruuhtian/minor
	shield_max     = 2500
	shield_current = 2500
	regen_delay    = 5 SECONDS
	regen_rate     = 60
	shield_color   = "#44AAFF"

/obj/item/clothing/gloves/marine/ruuhtian/major
	shield_max     = 3000
	shield_current = 3000
	regen_delay    = 4 SECONDS
	regen_rate     = 75
	shield_color   = "#FF8800"
	shield_base_r  = 255
	shield_base_g  = 136
	shield_base_b  = 0

/obj/item/clothing/gloves/marine/ruuhtian/ultra
	shield_max     = 3500
	shield_current = 3500
	regen_delay    = 3 SECONDS
	regen_rate     = 105
	shield_color   = "#FFFFFF"
	shield_base_r  = 255
	shield_base_g  = 255
	shield_base_b  = 255
