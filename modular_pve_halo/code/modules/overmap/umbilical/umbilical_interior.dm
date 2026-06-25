// Area type for the pocket-dimension umbilical corridor.
/area/interior/umbilical
	name = "Umbilical Corridor"
	icon_state = "interior"
	ceiling = CEILING_METAL
	requires_power = 0
	unlimited_power = 1
	base_lighting_alpha = 255

// Map template — file lives at maps/interiors/umbilical.dmm
// Does NOT inherit from /datum/map_template/interior to avoid the interior
// subsystem auto-loading this template into the ship map at world start.
/datum/map_template/umbilical_tube
	name = "Umbilical Tube"
	mappath = "maps/interiors/umbilical.dmm"

// Visual object placed on the tile(s) outside a ship's airlock when the umbilical
// is extended. Purely cosmetic.
/obj/structure/umbilical_tube_visual
	name = "umbilical tube"
	desc = "A pressurized passage connecting two vessels."
	icon = 'modular_pve_halo/icons/umbilical_full.dmi'
	icon_state = "umbi_extended"
	anchored = TRUE
	density = FALSE

// Manages the pocket-dimension umbilical tube for one console connection.
/datum/umbilical_tube
	var/ready = FALSE
	var/datum/turf_reservation/reservation
	/// Spawn turf for mobs entering from the local ship
	var/turf/entrance_a
	/// Spawn turf for mobs entering from the remote ship
	var/turf/entrance_b
	/// External hatch on the local ship — set by the console before create()
	var/obj/structure/umbilical_hatch/hatch_a
	/// External hatch on the remote ship — set by the console before create()
	var/obj/structure/umbilical_hatch/hatch_b
	/// All internal hatches found during create(), used for sprite updates
	var/list/internal_hatches = list()
	/// Visual tube objects spawned outside each hatch, cleaned up on Release()
	var/list/tube_visuals = list()

/datum/umbilical_tube/proc/create()
	var/datum/map_template/umbilical_tube/T = new()

	reservation = SSmapping.request_turf_block_reservation(T.width + 2, T.height + 2)
	if(!reservation)
		return FALSE

	var/turf/BL = reservation.bottom_left_turfs[1]
	T.load(locate(BL.x + 1, BL.y + 1, BL.z), centered = FALSE)

	// Scan the loaded area for entrance landmarks and internal exit hatches.
	var/turf/TL = locate(BL.x + T.width + 1, BL.y + T.height + 1, BL.z)
	for(var/turf/tile in block(BL, TL))
		var/obj/effect/landmark/interior/spawn/entrance/E = locate() in tile
		if(E)
			switch(E.tag)
				if("side_a")
					entrance_a = tile
				if("side_b")
					entrance_b = tile

		var/obj/structure/umbilical_hatch/internal/H = locate() in tile
		if(H)
			H.linked_tube = src
			internal_hatches += H

	if(!entrance_a || !entrance_b || !hatch_a || !hatch_b)
		Release()
		return FALSE

	// Assign each internal hatch its exit target based on which entrance it is
	// closest to. Hatch near entrance_a exits to hatch_a (local ship), and
	// hatch near entrance_b exits to hatch_b (remote ship).
	for(var/obj/structure/umbilical_hatch/internal/H in internal_hatches)
		var/dist_a = get_dist(get_turf(H), entrance_a)
		var/dist_b = get_dist(get_turf(H), entrance_b)
		H.exit_hatch = (dist_a <= dist_b) ? hatch_a : hatch_b

	_spawn_visuals()

	ready = TRUE
	return TRUE

// Spawns one tube visual object per side, one step outside the primary hatch.
/datum/umbilical_tube/proc/_spawn_visuals()
	for(var/obj/structure/umbilical_hatch/H in list(hatch_a, hatch_b))
		var/turf/outside = get_step(get_turf(H), H.enter_dir)
		if(outside)
			tube_visuals += new /obj/structure/umbilical_tube_visual(outside)

// Updates internal hatch sprites when the tube extends or retracts.
/datum/umbilical_tube/proc/set_extended(extended)
	for(var/obj/structure/umbilical_hatch/internal/H in internal_hatches)
		H.set_extended(extended)

/datum/umbilical_tube/proc/Release()
	for(var/obj/structure/umbilical_tube_visual/V in tube_visuals)
		qdel(V)
	tube_visuals.Cut()

	for(var/obj/structure/umbilical_hatch/internal/H in internal_hatches)
		H.exit_hatch = null
	internal_hatches.Cut()

	if(reservation)
		reservation.Release()
		reservation = null

	ready = FALSE
	entrance_a = null
	entrance_b = null

// Called by an external hatch when a mob walks into it.
// Spawns them at the pocket-dimension entrance opposite their ship.
/datum/umbilical_tube/proc/enter_from(mob/M, obj/structure/umbilical_hatch/from_hatch)
	if(!ready || (M in GLOB.umbilical_in_transit))
		return
	var/turf/dest = (from_hatch == hatch_a) ? entrance_a : entrance_b
	GLOB.umbilical_in_transit += M
	M.forceMove(dest)
	addtimer(CALLBACK(src, PROC_REF(_clear_transit), M), 3)

// Called by an internal hatch when a mob walks into it.
// Teleports them onto the external hatch of their destination ship.
/datum/umbilical_tube/proc/exit_to_hatch(mob/M, obj/structure/umbilical_hatch/target)
	if(!ready || (M in GLOB.umbilical_in_transit))
		return
	if(!target)
		to_chat(M, SPAN_WARNING("The umbilical connection has been severed!"))
		return
	GLOB.umbilical_in_transit += M
	M.forceMove(get_turf(target))
	addtimer(CALLBACK(src, PROC_REF(_clear_transit), M), 3)

/datum/umbilical_tube/proc/_clear_transit(mob/M)
	GLOB.umbilical_in_transit -= M
