// ====================== FUEL ROD CANNON MAGAZINE ====================== \\

/obj/item/ammo_magazine/fuel_rod
	name = "Type-33 LAAW magazine"
	desc = "A fuel rod magazine for the Type-33 Light Anti-Armor Weapon. Holds up to 5 fuel rods."
	icon = 'icons/halo/obj/items/weapons/guns_by_faction/covenant/fuel_rod_cannon.dmi'
	icon_state = "fuel_rod_mag"
	caliber = "fuel_rod"
	w_class = SIZE_MEDIUM
	max_rounds = 5
	default_ammo = /datum/ammo/rocket/fuel_rod
	gun_type = /obj/item/weapon/gun/fuel_rod_cannon

// Map remaining rounds (0-5) to the matching numbered sprite.
/obj/item/ammo_magazine/fuel_rod/update_icon(round_diff = 0)
	..()
	icon_state = "fuel_rod_mag-[clamp(current_rounds, 0, 5)]"

// ====================== FUEL ROD CANNON ====================== \\

// Inherits directly from the base gun — not a SPNKR subtype — so standard magazine
// load/unload procs work without any cover-mechanic interference.
/obj/item/weapon/gun/fuel_rod_cannon
	name = "\improper Type-33 Light Anti-Armor Weapon"
	desc = "A shoulder-fired fuel rod launcher carried by Unggoy heavy infantry. Fires explosive fuel rod projectiles that produce a distinctive green plasma detonation on impact. Requires a brief moment to plant your feet before firing — you cannot fire on the move."
	icon = 'icons/halo/obj/items/weapons/guns_by_faction/covenant/fuel_rod_cannon.dmi'
	icon_state = "fuel_rod"
	// item_state matches the 'fuelrod' state in items_lefthand/righthand_halo_heavy.dmi.
	// wield() below fixes it to 'fuelrod-wielded' (HaloSS13 naming convention).
	item_state = "fuelrod"
	w_class = SIZE_LARGE
	flags_equip_slot = SLOT_BACK
	current_mag = /obj/item/ammo_magazine/fuel_rod
	fire_sound = 'sound/weapons/halo/fuel_rod/gun_fuelrod_1.ogg'
	reload_sound = null // random sound chosen in replace_magazine override below
	unload_sound = 'sound/weapons/halo/fuel_rod/unload.ogg'
	flags_gun_features = GUN_WIELDED_FIRING_ONLY|GUN_UNUSUAL_DESIGN
	mouse_pointer = 'icons/halo/effects/mouse_pointer/fuel_rod.dmi'
	item_icons = list(
		WEAR_BACK = 'icons/halo/mob/humans/onmob/clothing/back/guns_by_type/heavy_weapons_32.dmi',
		WEAR_J_STORE = 'icons/halo/mob/humans/onmob/clothing/suit_storage/suit_storage_by_faction/suit_slot_cov.dmi',
		WEAR_L_HAND = 'icons/halo/mob/humans/onmob/items_lefthand_halo_heavy.dmi',
		WEAR_R_HAND = 'icons/halo/mob/humans/onmob/items_righthand_halo_heavy.dmi'
	)

	var/planted = FALSE
	COOLDOWN_DECLARE(plant_cooldown)

/obj/item/weapon/gun/fuel_rod_cannon/set_gun_config_values()
	..()
	set_fire_delay(FIRE_DELAY_TIER_8)
	accuracy_mult = BASE_ACCURACY_MULT - HIT_ACCURACY_MULT_TIER_4
	scatter = SCATTER_AMOUNT_TIER_10
	damage_mult = BASE_BULLET_DAMAGE_MULT
	recoil = RECOIL_AMOUNT_TIER_2

/obj/item/weapon/gun/fuel_rod_cannon/update_icon()
	icon_state = current_mag ? "fuel_rod_loaded" : "fuel_rod"

// The parent wield() appends "_w" giving "fuelrod_w", but the DMI uses "fuelrod-wielded".
// Fix the state after the parent runs.
/obj/item/weapon/gun/fuel_rod_cannon/wield(mob/living/user)
	. = ..()
	if(flags_item & WIELDED)
		item_state = "fuelrod-wielded"

/obj/item/weapon/gun/fuel_rod_cannon/unwield(mob/living/user)
	. = ..()
	item_state = "fuelrod"

// Integrated targeting reticle — non-removable, hidden (no visual on the gun sprite).
/obj/item/attachable/scope/mini/fuel_rod
	name = "Type-33 targeting reticle"
	desc = "An integrated optical targeting system built into the Type-33 LAAW."
	size_mod = 0

/obj/item/weapon/gun/fuel_rod_cannon/handle_starting_attachment()
	..()
	var/obj/item/attachable/scope/mini/fuel_rod/scope = new(src)
	scope.hidden = TRUE
	scope.flags_attach_features &= ~ATTACH_REMOVABLE
	scope.Attach(src)
	update_attachables()

// GUN_UNUSUAL_DESIGN blocks both unload() and reload() — override both.
// Each gets the same 1.5 s busy-icon delay and plays a random sound from the shared pool.

/obj/item/weapon/gun/fuel_rod_cannon/unload(mob/user, reload_override = 0, drop_override = 0, loc_override = 0)
	if(user && !reload_override)
		if(!do_after(user, 15, show_busy_icon = BUSY_ICON_GENERIC))
			return
		playsound(user, pick(
			'sound/weapons/halo/fuel_rod/reload1.wav',
			'sound/weapons/halo/fuel_rod/reload2.wav',
			'sound/weapons/halo/fuel_rod/reload3.wav'), 40, TRUE, 5)
	return ..(user, TRUE, drop_override, loc_override)

// reload() bails on GUN_UNUSUAL_DESIGN before reaching replace_magazine, so replicate its
// logic here minus that flag check, adding the same delay + random sound.
/obj/item/weapon/gun/fuel_rod_cannon/reload(mob/user, obj/item/ammo_magazine/magazine)
	if(!magazine || !istype(magazine))
		to_chat(user, SPAN_WARNING("That's not a magazine!"))
		return
	if(magazine.flags_magazine & AMMUNITION_HANDFUL)
		to_chat(user, SPAN_WARNING("[src] needs an actual magazine."))
		return
	if(magazine.current_rounds <= 0)
		to_chat(user, SPAN_WARNING("[magazine] is empty!"))
		return
	if(!istype(src, magazine.gun_type) && !((magazine.type) in src.accepted_ammo))
		to_chat(user, SPAN_WARNING("That magazine doesn't fit in there!"))
		return
	if(current_mag)
		to_chat(user, SPAN_WARNING("It's still got something loaded."))
		return
	if(!user)
		current_mag = magazine
		magazine.forceMove(src)
		replace_ammo(null, magazine)
		if(!in_chamber)
			load_into_chamber()
		update_icon()
		return TRUE
	if(!do_after(user, 15, INTERRUPT_ALL, BUSY_ICON_FRIENDLY))
		to_chat(user, SPAN_WARNING("Your reload was interrupted!"))
		return
	playsound(user, pick(
		'sound/weapons/halo/fuel_rod/reload1.wav',
		'sound/weapons/halo/fuel_rod/reload2.wav',
		'sound/weapons/halo/fuel_rod/reload3.wav'), 40, TRUE, 5)
	replace_magazine(user, magazine)
	SEND_SIGNAL(user, COMSIG_MOB_RELOADED_GUN, src)
	update_icon()
	return TRUE

// Intercept normal fire to enforce the plant-feet delay.
// When planted is TRUE we let the parent proc handle the actual shot.
/obj/item/weapon/gun/fuel_rod_cannon/Fire(atom/target, mob/living/user, params, reflex, dual_wield)
	if(planted)
		return ..()

	if(!COOLDOWN_FINISHED(src, plant_cooldown))
		to_chat(user, SPAN_WARNING("You need a moment before firing again."))
		return

	INVOKE_ASYNC(src, PROC_REF(plant_and_fire), target, user, params)

/obj/item/weapon/gun/fuel_rod_cannon/proc/plant_and_fire(atom/target, mob/living/user, params)
	if(!COOLDOWN_FINISHED(src, plant_cooldown))
		return

	COOLDOWN_START(src, plant_cooldown, 0.7 SECONDS)

	if(user.client)
		user.client.next_movement = world.time + 5

	user.visible_message(
		SPAN_WARNING("[user] plants [user.p_their()] feet, raising the [src]!"),
		SPAN_WARNING("You plant your feet and raise the [src]...")
	)

	if(!do_after(user, 5, show_busy_icon = BUSY_ICON_HOSTILE))
		to_chat(user, SPAN_WARNING("You stumble and abort the shot!"))
		return

	if(QDELETED(src) || QDELETED(user) || !target || QDELETED(target))
		return

	planted = TRUE
	Fire(target, user, params, FALSE, FALSE)
	planted = FALSE
