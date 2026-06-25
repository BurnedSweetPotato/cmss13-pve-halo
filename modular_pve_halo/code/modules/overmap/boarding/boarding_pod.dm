// ============================================================
// Boarding Pod — vehicle with interior, launched by console
// ============================================================

/area/interior/vehicle/boarding_pod
	name = "boarding pod interior"
	icon_state = "van"

/datum/map_template/interior/boarding_pod
	name = "Boarding Pod"
	interior_id = "boarding_pod"

// Interior hatch — spawned from the entrance landmark in the DMM.
/obj/structure/interior_exit/vehicle/boarding_pod
	name = "pod hatch"
	desc = "A reinforced hatch. Click to exit the pod."
	icon = 'icons/obj/vehicles/interiors/apc.dmi'
	icon_state = "exit_door"

// ---- The vehicle itself -------------------------------------

/obj/vehicle/multitile/boarding_pod
	name = "boarding pod"
	desc = "A single-use armored insertion pod. Board it and await launch orders."

	icon = 'modular_pve_halo/icons/vehicles/boarding_pod.dmi'
	icon_state = "boarding"

	bound_width = 32
	bound_height = 32
	bound_x = 0
	bound_y = 0

	interior_map = /datum/map_template/interior/boarding_pod

	// Mob must stand directly south of the pod (offset 0,-1) to enter.
	entrances = list(
		"hatch" = list(0, -1)
	)

	passengers_slots = 6
	xenos_slots = 0

	health = 500

	door_locked = FALSE
	entrance_speed = 1 SECONDS

	move_delay = VEHICLE_SPEED_STATIC
	vehicle_flags = VEHICLE_CLASS_WEAK

	hardpoints_allowed = list()

	light_range = 2
	vehicle_light_range = 3

	misc_multipliers = list(
		"move"     = 1,
		"accuracy" = 1,
		"cooldown" = 1,
	)

	/// TRUE once launched — prevents re-launch and re-boarding
	var/launched = FALSE
	/// TRUE while in transit — hatch is sealed
	var/in_transit = FALSE
	/// Landing turf set during launch(); used by _arrive() via addtimer
	var/turf/destination = null

// ---- Entry (override: any adjacent tile works) ---------------

/obj/vehicle/multitile/boarding_pod/attack_hand(mob/user)
	if(launched && !in_transit)
		to_chat(user, SPAN_WARNING("This pod has already deployed."))
		return
	if(in_transit)
		to_chat(user, SPAN_WARNING("The hatch is sealed for transit."))
		return
	if(!interior || !interior.ready)
		to_chat(user, SPAN_WARNING("Pod systems are not ready yet."))
		return
	if(get_dist(src, user) > 1)
		. = ..()
		return
	playsound(src, 'modular_pve_halo/sound/pod/pod_door_open.ogg', 60, FALSE)
	to_chat(user, SPAN_NOTICE("You start climbing into the boarding pod..."))
	if(!do_after(user, entrance_speed, INTERRUPT_NO_NEEDHAND, BUSY_ICON_GENERIC))
		return
	if(launched || in_transit)
		to_chat(user, SPAN_WARNING("The hatch sealed before you could enter."))
		return
	interior.enter(user, "hatch")

// ---- Status helpers -----------------------------------------

/obj/vehicle/multitile/boarding_pod/proc/get_pod_status()
	if(in_transit)
		return "In Transit"
	if(launched)
		return "Deployed"
	if(!interior || !interior.ready)
		return "Initializing"
	return "Ready"

/obj/vehicle/multitile/boarding_pod/proc/get_occupant_count()
	if(!interior || !interior.ready)
		return 0
	return interior.passengers_taken_slots

// ---- Pre-launch alarm (called by console during countdown) --

/obj/vehicle/multitile/boarding_pod/proc/start_alarm()
	_loop_interior('sound/machines/warning-buzzer.ogg', SOUND_CHANNEL_NOTIFY, 70)
	_msg_interior(SPAN_BOLDANNOUNCE("WARNING: Launch sequence initiated. Brace for departure."))

/obj/vehicle/multitile/boarding_pod/proc/stop_alarm()
	_stop_interior_loop(SOUND_CHANNEL_NOTIFY)

// ---- Launch (called by console after countdown) -------------

/obj/vehicle/multitile/boarding_pod/proc/launch(target_z)
	if(launched || in_transit)
		return FALSE
	if(!interior || !interior.ready)
		return FALSE

	destination = _pick_landing_turf(target_z)
	if(!destination)
		return FALSE

	launched = TRUE
	in_transit = TRUE
	stop_alarm()

	// Seal hatch + interior messages
	_sound_interior('modular_pve_halo/sound/pod/pod_door_close.ogg', 70)
	_msg_interior(SPAN_BOLDANNOUNCE("Hatch sealed. BRACE FOR LAUNCH."))

	// Ship-wide launch announcement
	var/local_z = z
	for(var/mob/M in world)
		if(M.z == local_z && !isobserver(M))
			to_chat(M, SPAN_BOLDANNOUNCE("A boarding pod has launched!"))
	playsound(src, 'modular_pve_halo/sound/pod/escape_pod_launch.ogg', 80, FALSE)

	// Move pod exterior to overmap limbo
	var/turf/limbo = locate(1, 1, GLOB.overmap_z)
	if(limbo)
		forceMove(limbo)

	// Staggered launch sequence via addtimer (non-blocking, no CALLBACK args)
	addtimer(CALLBACK(src, PROC_REF(_seq_warmup)),  5)
	addtimer(CALLBACK(src, PROC_REF(_seq_thruster)), 20)
	addtimer(CALLBACK(src, PROC_REF(_seq_fly)),      35)

	var/transit_ticks = rand(300, 600)
	addtimer(CALLBACK(src, PROC_REF(_arrive)), 35 + transit_ticks)

	return TRUE

// ---- Timed launch sequence steps ----------------------------

/obj/vehicle/multitile/boarding_pod/proc/_seq_warmup()
	_sound_interior('modular_pve_halo/sound/pod/escape_pod_warmup.ogg', 75)
	_shake_interior(4, 2)

/obj/vehicle/multitile/boarding_pod/proc/_seq_thruster()
	_sound_interior('modular_pve_halo/sound/pod/pod_thruster.ogg', 80)
	_shake_interior(6, 3)

/obj/vehicle/multitile/boarding_pod/proc/_seq_fly()
	_msg_interior(SPAN_LARGE(SPAN_BOLDANNOUNCE("Pod away. Intercept trajectory locked.")))
	_loop_interior('sound/ambience/shuttle_fly_loop.ogg', SOUND_CHANNEL_AMBIENCE, 55)
	// Swap interior background to animated transit turfs
	_set_interior_bg(/turf/open/space/transit)

/obj/vehicle/multitile/boarding_pod/proc/_arrive()
	set waitfor = FALSE
	if(QDELETED(src))
		return

	_stop_interior_loop(SOUND_CHANNEL_AMBIENCE)
	_shake_interior(10, 5)
	_set_interior_bg(/turf/open/void/vehicle)

	var/land_sound = pick(
		'modular_pve_halo/sound/pod/pod_land_1.ogg',
		'modular_pve_halo/sound/pod/pod_land_2.ogg',
		'modular_pve_halo/sound/pod/pod_land_3.ogg',
		'modular_pve_halo/sound/pod/pod_land_4.ogg')
	_sound_interior(land_sound, 90)
	_msg_interior(SPAN_LARGE(SPAN_BOLDANNOUNCE("You lurch forward violently as the pod slams into the hull with a deafening crack, metal screaming as it tears through the plating. The pod has breached.")))

	// Blast + smoke at the impact site BEFORE pod arrives
	var/datum/cause_data/cause = create_cause_data("Boarding Pod Impact")
	new /obj/effect/particle_effect/explosion(destination)
	var/datum/effect_system/expl_particles/EP = new /datum/effect_system/expl_particles()
	EP.set_up(12, 0, destination)
	EP.start()
	cell_explosion(destination, 120, 30, EXPLOSION_FALLOFF_SHAPE_LINEAR, null, cause)

	var/datum/effect_system/smoke_spread/bad/smoke = new /datum/effect_system/smoke_spread/bad()
	smoke.set_up(3, 0, destination, null, 150, cause)
	smoke.start()

	sleep(5)

	if(QDELETED(src))
		return

	forceMove(destination)
	in_transit = FALSE

	addtimer(CALLBACK(src, PROC_REF(_open_hatch_after_impact)), 8)

	// Alert everyone on the target ship
	var/target_z = destination.z
	for(var/mob/M in world)
		if(M.z == target_z && !isobserver(M))
			shake_camera(M, 8, 4)
			to_chat(M, SPAN_LARGE(SPAN_BOLDANNOUNCE("WARNING: EXTERNAL INCURSION. A boarding pod has breached the hull.")))
	for(var/mob/M in world)
		if(M.z == target_z && !isobserver(M) && M.client)
			M.client << sound('modular_pve_halo/sound/ship_lurch2.ogg', volume = 70)

/obj/vehicle/multitile/boarding_pod/proc/_open_hatch_after_impact()
	_sound_interior('modular_pve_halo/sound/pod/pod_door_open.ogg', 70)
	_msg_interior(SPAN_NOTICE("Hatch open. Move out."))

// ---- Landing turf picker ------------------------------------
// Block iteration on the exact target z. Filters space/void and
// /area/space so only ship interior floors are candidates.

/obj/vehicle/multitile/boarding_pod/proc/_pick_landing_turf(target_z)
	// Prefer GM-placed beacon markers on the target ship
	var/list/beacon_turfs = get_boarding_beacon_turfs(target_z)
	if(beacon_turfs.len)
		return pick(beacon_turfs)

	// Fall back: iterate all open floor tiles on the target z-level
	var/list/candidates = list()
	for(var/turf/open/T in block(locate(1, 1, target_z), locate(world.maxx, world.maxy, target_z)))
		if(istype(T, /turf/open/space) || istype(T, /turf/open/void))
			continue
		if(T.density)
			continue
		var/area/A = get_area(T)
		if(!A || istype(A, /area/space))
			continue
		var/blocked = FALSE
		for(var/obj/O in T)
			if(O.density)
				blocked = TRUE
				break
		if(!blocked)
			candidates += T
	if(!candidates.len)
		return null
	return pick(candidates)

// ---- Interior background swap -------------------------------

/obj/vehicle/multitile/boarding_pod/proc/_set_interior_bg(turf_type)
	if(!interior || !interior.ready || !interior.reservation)
		return
	var/turf/T1 = interior.reservation.bottom_left_turfs[1]
	var/turf/T2 = interior.reservation.top_right_turfs[1]
	for(var/turf/T in block(T1, T2))
		if(istype(T, /turf/open/void/vehicle) || istype(T, /turf/open/space/transit) || istype(T, /turf/open/space/basic))
			T.ChangeTurf(turf_type)

// ---- Interior helpers ---------------------------------------

/obj/vehicle/multitile/boarding_pod/proc/_msg_interior(msg)
	if(!interior || !interior.ready)
		return
	for(var/mob/M in interior.get_passengers())
		to_chat(M, msg)

/obj/vehicle/multitile/boarding_pod/proc/_sound_interior(sound_file, vol)
	if(!interior || !interior.ready)
		return
	for(var/mob/M in interior.get_passengers())
		if(M.client)
			M.client << sound(sound_file, volume = vol)

/obj/vehicle/multitile/boarding_pod/proc/_loop_interior(sound_file, channel, vol)
	if(!interior || !interior.ready)
		return
	for(var/mob/M in interior.get_passengers())
		if(M.client)
			var/sound/S = sound(sound_file, repeat = TRUE, wait = FALSE, channel = channel, volume = vol)
			M.client << S

/obj/vehicle/multitile/boarding_pod/proc/_stop_interior_loop(channel)
	if(!interior || !interior.ready)
		return
	for(var/mob/M in interior.get_passengers())
		if(M.client)
			M.client << sound(null, channel = channel)

/obj/vehicle/multitile/boarding_pod/proc/_shake_interior(steps, strength)
	if(!interior || !interior.ready)
		return
	for(var/mob/M in interior.get_passengers())
		shake_camera(M, steps, strength)

// ---- Spawner ------------------------------------------------

/obj/effect/vehicle_spawner/boarding_pod
	name = "Boarding Pod Spawner"
	icon = 'modular_pve_halo/icons/vehicles/boarding_pod.dmi'
	icon_state = "boarding"

/obj/effect/vehicle_spawner/boarding_pod/Initialize()
	. = ..()
	spawn_vehicle()
	qdel(src)

/obj/effect/vehicle_spawner/boarding_pod/spawn_vehicle()
	var/obj/vehicle/multitile/boarding_pod/P = new(loc)
	load_misc(P)
	handle_direction(P)
	P.update_icon()
