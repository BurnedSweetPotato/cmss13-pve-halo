// ====================== TYPE-52 DIRECTED ENERGY SUPPORT WEAPON ====================== //
//
// Player-manned covenant plasma turret. Subtype of m56d_hmg — drag the sprite onto
// yourself to man it, aim with the mouse, click to fire.
//
// No disassembly / pick-up — deploy it and it stays until destroyed.

// ── Weak plasma bolt (lower damage for the player-manned turret) ─────────────

/datum/ammo/energy/halo_plasma/plasma_rifle/weak
	name = "plasma bolt"
	damage = 15
	accurate_range = 10
	max_range = 18

// ── Plasma power cell (reloads the turret) ─────────────────────────────────

/obj/item/covenant_plasma_cell
	name = "Type-52 DESW plasma power cell"
	desc = "A high-capacity plasma energy cell for the Type-52 Directed Energy Support Weapon. Click it on the turret to slot in a fresh cell."
	icon = 'icons/halo/obj/structures/machinery/defenses/turret_items.dmi'
	icon_state = "plasmacellbox"
	w_class = SIZE_MEDIUM
	/// How many rounds this cell restores when used.
	var/rounds_restore = 200

// ── Carry / deploy item ─────────────────────────────────────────────────────

/obj/item/device/covenant_plasma_turret
	name = "\improper Type-52 Directed Energy Support Weapon (folded)"
	desc = "A compact covenant plasma weapon in its folded carry configuration.  Activate in-hand to deploy it at your feet facing your direction."
	icon = 'icons/halo/obj/structures/machinery/defenses/turret_items.dmi'
	icon_state = "plasmaturret_obj"
	item_state = "plaskit"
	w_class = SIZE_HUGE
	flags_equip_slot = SLOT_BACK
	item_icons = list(
		WEAR_L_HAND = 'icons/halo/mob/humans/onmob/deploy_kit_inhands_l.dmi',
		WEAR_R_HAND = 'icons/halo/mob/humans/onmob/deploy_kit_inhands_r.dmi',
	)
	/// Rounds remaining in the weapon (persist through pack/unpack).
	var/rounds = 200

/obj/item/device/covenant_plasma_turret/attack_self(mob/user)
	. = ..()
	if(!ishuman(user) && !HAS_TRAIT(user, TRAIT_OPPOSABLE_THUMBS))
		return
	if(SSinterior.in_interior(user))
		to_chat(user, SPAN_WARNING("It's too cramped in here to deploy [src]."))
		return

	var/turf/T = get_turf(user)
	if(istype(T, /turf/open))
		var/turf/open/floor = T
		if(!floor.allow_construction)
			to_chat(user, SPAN_WARNING("You can't set up [src] here — the surface is unsuitable."))
			return

	var/fail = FALSE
	for(var/obj/X in T.contents - src)
		if(X.density && !(X.flags_atom & ON_BORDER))
			fail = TRUE
			break
		if(istype(X, /obj/structure/machinery/defenses) || istype(X, /obj/structure/machinery/m56d_hmg))
			fail = TRUE
			break
		if(istype(X, /obj/structure/machinery/door) || istype(X, /obj/structure/window))
			fail = TRUE
			break
	if(fail)
		to_chat(user, SPAN_WARNING("You can't deploy [src] here — something is in the way."))
		return

	if(!do_after(user, 2 SECONDS, INTERRUPT_ALL|BEHAVIOR_IMMOBILE, BUSY_ICON_BUILD))
		return

	// Re-check after delay.
	fail = FALSE
	for(var/obj/X in T.contents - src)
		if(X.density && !(X.flags_atom & ON_BORDER))
			fail = TRUE
			break
		if(istype(X, /obj/structure/machinery/defenses) || istype(X, /obj/structure/machinery/m56d_hmg))
			fail = TRUE
			break
	if(fail)
		to_chat(user, SPAN_WARNING("Something moved into the way — can't deploy here."))
		return

	var/obj/structure/machinery/m56d_hmg/covenant_plasma_turret/turret = new(T)
	turret.setDir(user.dir)
	turret.rounds = rounds
	turret.update_icon()
	playsound(T, 'sound/items/m56dauto_setup.ogg', 60, TRUE)
	user.visible_message(
		SPAN_NOTICE("[user] deploys a [turret]."),
		SPAN_NOTICE("You deploy [turret]."),
	)
	qdel(src)

// ── Deployed turret structure ───────────────────────────────────────────────

/obj/structure/machinery/m56d_hmg/covenant_plasma_turret
	name = "\improper Type-52 Directed Energy Support Weapon"
	desc = "A covenant deployable plasma turret.  Drag its sprite onto yourself to man it. <B>Your hands must be empty.</B>"
	icon = 'icons/halo/obj/structures/machinery/defenses/covenant_turret.dmi'
	// icon_full / icon_empty unused — update_icon() handles everything directly.
	icon_full = "covturret"
	icon_empty = "covturret"
	icon_state = "stand"

	// Fires weak plasma bolts.
	ammo = /datum/ammo/energy/halo_plasma/plasma_rifle/weak
	rounds = 200
	rounds_max = 200

	gun_noise = 'sound/weapons/halo/gun_heavyplasma_1.ogg'
	// Overheat sound played on ammo-out; see handle_ammo_out override below.
	empty_alarm = 'sound/weapons/halo/plasrifle_overheat.ogg'

	// No IFF chip — this thing kills whatever you aim at.
	iff_allowed = FALSE

	// 0.3 s between shots (fire_delay is in ticks; 1 tick = 0.1 s).
	fire_delay = 3

	// Lock down disassembly — once placed it stays.
	locked = 1

	health = 350
	health_max = 350

	// Muzzle-flash offsets (tuned for the covturret sprite).
	north_x_offset = 0
	north_y_offset = 12
	east_x_offset = 8
	east_y_offset = 8
	south_x_offset = 0
	south_y_offset = 4
	west_x_offset = -8
	west_y_offset = 8

// Combine the stand (base) and covturret (gun) sprites as a base + overlay pair.
// Glow blue when manned and loaded.
/obj/structure/machinery/m56d_hmg/covenant_plasma_turret/update_icon()
	overlays.Cut()
	icon_state = "stand"
	overlays += image('icons/halo/obj/structures/machinery/defenses/covenant_turret.dmi', "covturret")
	if(rounds > 0 && operator)
		set_light(2, 3, COLOR_PLASMA_BLUE)
	else
		set_light(0)

// Play the plasma overheat sting when the turret runs dry.
/obj/structure/machinery/m56d_hmg/covenant_plasma_turret/handle_ammo_out(mob/user)
	visible_message(SPAN_WARNING("[icon2html(src, viewers(src))] [src]'s plasma cell is depleted — it vents superheated gas!"))
	playsound(loc, 'sound/weapons/halo/plasrifle_overheat.ogg', 75, TRUE, 6)
	update_icon()

// Override attackby: allow plasma power cells for reloading, block disassembly tools,
// pass everything else to parent (welder repair etc. can stay).
/obj/structure/machinery/m56d_hmg/covenant_plasma_turret/attackby(obj/item/O, mob/user)
	if(istype(O, /obj/item/covenant_plasma_cell))
		var/obj/item/covenant_plasma_cell/cell = O
		if(rounds >= rounds_max)
			to_chat(user, SPAN_WARNING("[src] already has a full energy cell."))
			return
		to_chat(user, SPAN_NOTICE("You begin slotting in the plasma cell..."))
		if(!do_after(user, 2 SECONDS, INTERRUPT_ALL, BUSY_ICON_FRIENDLY, src))
			to_chat(user, SPAN_WARNING("Reload interrupted!"))
			return
		var/new_rounds = min(rounds + cell.rounds_restore, rounds_max)
		var/loaded = new_rounds - rounds
		user.visible_message(
			SPAN_NOTICE("[user] slots a plasma cell into [src], restoring [loaded] rounds."),
			SPAN_NOTICE("You slot in the plasma cell, restoring [loaded] rounds."),
		)
		playsound(loc, 'sound/weapons/halo/cov_carbine_reload.ogg', 60, TRUE)
		rounds = new_rounds
		update_icon()
		user.temp_drop_inv_item(O)
		qdel(O)
		return

	// The base class handles wrench (locked = 1 blocks it) and screwdriver (locked = 1 blocks
	// disassembly) already.  Still give a flavour message for screwdrivers.
	if(HAS_TRAIT(O, TRAIT_TOOL_SCREWDRIVER))
		to_chat(user, SPAN_WARNING("The [src] is too heavy and complex to be field-stripped."))
		return

	return ..()

// When destroyed: plasma blast, no dropped item.
/obj/structure/machinery/m56d_hmg/covenant_plasma_turret/update_health(amount)
	health -= amount
	if(health <= 0)
		visible_message(SPAN_DANGER("[src] explodes in a burst of plasma and molten metal!"))
		playsound(loc, pick(
			'sound/weapons/halo/fuel_rod/explode1.wav',
			'sound/weapons/halo/fuel_rod/explode2.wav',
			'sound/weapons/halo/fuel_rod/explode3.wav'), 60, TRUE, 8)
		var/turf/T = get_turf(src)
		new /obj/effect/overlay/temp/fuel_rod_explosion(T)
		cell_explosion(T, 50, 15, EXPLOSION_FALLOFF_SHAPE_EXPONENTIAL)
		qdel(src)
		return
	if(health > health_max)
		health = health_max
	update_damage_state()
	update_icon()
