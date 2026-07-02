/obj/structure/machinery/computer/umbilical_control
	name = "umbilical control console"
	desc = "Manages the deployable umbilical passage for inter-ship boarding."
	icon = 'icons/obj/structures/machinery/computer.dmi'
	icon_state = "map"
	/// Must match the link_id on the umbilical_hatch objects this console owns.
	/// Different consoles on different ships use the same link_id to find each other.
	var/link_id = "umbilical_1"
	/// The active pocket-dimension tube, if extended
	var/datum/umbilical_tube/active_tube
	/// All external hatches linked locally, kept for retract cleanup
	var/list/active_hatches_local = list()
	/// All external hatches linked on the remote ship, kept for retract cleanup
	var/list/active_hatches_remote = list()
	/// The remote ship token locked while the umbilical is up
	var/obj/effect/overmap/ship/tethered_ship

/obj/structure/machinery/computer/umbilical_control/Initialize(mapload)
	. = ..()
	if(!mapload)
		_register_with_record()
	else
		addtimer(CALLBACK(src, PROC_REF(_register_with_record)), 1)

/obj/structure/machinery/computer/umbilical_control/proc/_register_with_record()
	var/datum/ship_record/R = get_ship_record(z)
	if(R)
		R.register_umbilical(src)

/obj/structure/machinery/computer/umbilical_control/Destroy()
	_retract()
	return ..()

// ---- Internal helpers -------------------------------------------------------

/obj/structure/machinery/computer/umbilical_control/proc/get_local_ship()
	return GLOB.map_sectors["[z]"]

/obj/structure/machinery/computer/umbilical_control/proc/get_adjacent_ship()
	var/obj/effect/overmap/ship/local = get_local_ship()
	if(!local)
		return null
	for(var/check_dir in list(NORTH, SOUTH, EAST, WEST))
		var/turf/adj = get_step(local, check_dir)
		if(!adj || adj.z != GLOB.overmap_z)
			continue
		for(var/obj/effect/overmap/ship/S in adj)
			return S

// External hatches on this console's own z-level with a matching link_id.
/obj/structure/machinery/computer/umbilical_control/proc/get_local_hatches()
	var/list/result = list()
	for(var/obj/structure/umbilical_hatch/H in world)
		if(istype(H, /obj/structure/umbilical_hatch/internal))
			continue
		if(_hatch_matches(H, z))
			result += H
	return result

// External hatches on the adjacent ship's z-level with a matching link_id.
/obj/structure/machinery/computer/umbilical_control/proc/get_remote_hatches()
	var/obj/effect/overmap/ship/adj = get_adjacent_ship()
	if(!adj)
		return list()
	var/remote_z = adj.ship_z
	var/list/result = list()
	for(var/obj/structure/umbilical_hatch/H in world)
		if(istype(H, /obj/structure/umbilical_hatch/internal))
			continue
		if(_hatch_matches(H, remote_z))
			result += H
	return result

// A hatch matches if it's on the right z-level and its link_id equals ours
// OR is empty (legacy hatches with no link_id set are treated as universal).
/obj/structure/machinery/computer/umbilical_control/proc/_hatch_matches(obj/structure/umbilical_hatch/H, target_z)
	if(H.z != target_z)
		return FALSE
	return H.link_id == link_id || H.link_id == ""

// ---- Extend / Retract -------------------------------------------------------

// Broadcasts a message to all non-observer mobs on a given z-level.
/obj/structure/machinery/computer/umbilical_control/proc/_broadcast_z(zl, msg)
	for(var/mob/M in world)
		if(M.z == zl && !isobserver(M))
			to_chat(M, msg)

// Plays a sound at every non-observer mob on a given z-level (bypasses range).
/obj/structure/machinery/computer/umbilical_control/proc/_sound_z(zl, sound_file, vol)
	for(var/mob/M in world)
		if(M.z == zl && !isobserver(M) && M.client)
			M.client << sound(sound_file, volume = vol)

// Shakes the camera for every non-observer mob on a given z-level.
/obj/structure/machinery/computer/umbilical_control/proc/_shake_z(zl, steps, strength)
	for(var/mob/M in world)
		if(M.z == zl && !isobserver(M))
			shake_camera(M, steps, strength)

/obj/structure/machinery/computer/umbilical_control/proc/_extend(mob/user)
	if(active_tube)
		if(user)
			to_chat(user, SPAN_WARNING("Umbilical is already extended."))
		return

	var/list/hatches_local = get_local_hatches()
	if(!hatches_local.len)
		if(user)
			to_chat(user, SPAN_WARNING("No local umbilical hatch found with link_id=\"[link_id]\"."))
		return

	var/obj/effect/overmap/ship/adj = get_adjacent_ship()
	if(!adj)
		if(user)
			to_chat(user, SPAN_WARNING("No adjacent ship detected on the overmap."))
		return

	var/list/hatches_remote = get_remote_hatches()
	if(!hatches_remote.len)
		if(user)
			to_chat(user, SPAN_WARNING("Adjacent ship has no umbilical hatch with link_id=\"[link_id]\"."))
		return

	// Docking countdown — ships must stay adjacent for 5 seconds.
	var/cached_adj_z = adj.ship_z
	_broadcast_z(z, SPAN_BOLDANNOUNCE("WARNING: Umbilical docking sequence initiated. All hands brace for contact."))
	_sound_z(z, 'modular_pve_halo/sound/ship_lurch2.ogg', 40)
	_shake_z(z, 3, 1)

	if(user && !do_after(user, 8 SECONDS, INTERRUPT_ALL, BUSY_ICON_BUILD))
		to_chat(user, SPAN_WARNING("Docking sequence aborted."))
		return

	// Verify the same ship is still adjacent.
	var/obj/effect/overmap/ship/adj_now = get_adjacent_ship()
	if(!adj_now || adj_now.ship_z != cached_adj_z)
		_broadcast_z(z, SPAN_WARNING("Target vessel moved during docking sequence. Umbilical aborted."))
		return

	var/datum/umbilical_tube/U = new()
	U.hatch_a = hatches_local[1]
	U.hatch_b = hatches_remote[1]

	if(!U.create())
		if(user)
			to_chat(user, SPAN_WARNING("Failed to load umbilical corridor."))
		qdel(U)
		return

	// Link and update sprites on every external hatch for this link_id.
	for(var/obj/structure/umbilical_hatch/H in hatches_local)
		H.linked_tube = U
		H.set_extended(TRUE)
	for(var/obj/structure/umbilical_hatch/H in hatches_remote)
		H.linked_tube = U
		H.set_extended(TRUE)

	U.set_extended(TRUE)

	var/obj/effect/overmap/ship/local_ship = get_local_ship()
	if(local_ship)
		local_ship.umbilical_locked = TRUE
	tethered_ship = adj_now
	if(tethered_ship)
		tethered_ship.umbilical_locked = TRUE

	active_hatches_local = hatches_local
	active_hatches_remote = hatches_remote
	active_tube = U

	// Hard dock thud + shake, then the pressure equalisation creak a moment later.
	_sound_z(z, 'modular_pve_halo/sound/ship_lurch.ogg', 65)
	_shake_z(z, 6, 3)
	_broadcast_z(z, SPAN_LARGE(SPAN_BOLDANNOUNCE("With a resonant clunk, the umbilical passage locks into place. The deck shudders as pressure equalizes between the vessels.")))
	addtimer(CALLBACK(src, PROC_REF(_lurch_sound)), 2 SECONDS)

/obj/structure/machinery/computer/umbilical_control/proc/_lurch_sound()
	_sound_z(z, 'modular_pve_halo/sound/ship_lurch2.ogg', 50)
	_shake_z(z, 3, 1)

/obj/structure/machinery/computer/umbilical_control/proc/_retract()
	if(!active_tube)
		return

	for(var/obj/structure/umbilical_hatch/H in active_hatches_local)
		H.linked_tube = null
		H.set_extended(FALSE)
	for(var/obj/structure/umbilical_hatch/H in active_hatches_remote)
		H.linked_tube = null
		H.set_extended(FALSE)
	active_hatches_local.Cut()
	active_hatches_remote.Cut()

	active_tube.set_extended(FALSE)

	var/obj/effect/overmap/ship/local_ship = get_local_ship()
	if(local_ship)
		local_ship.umbilical_locked = FALSE
	if(tethered_ship)
		tethered_ship.umbilical_locked = FALSE
		tethered_ship = null

	active_tube.Release()
	qdel(active_tube)
	active_tube = null

// ---- TGUI ------------------------------------------------------------------

/obj/structure/machinery/computer/umbilical_control/attack_hand(mob/user)
	if(..())
		return
	tgui_interact(user)

/obj/structure/machinery/computer/umbilical_control/tgui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "UmbilicalConsole", src.name)
		ui.open()

/obj/structure/machinery/computer/umbilical_control/ui_state(mob/user)
	return GLOB.not_incapacitated_and_adjacent_state

/obj/structure/machinery/computer/umbilical_control/ui_data(mob/user)
	. = list()
	var/obj/effect/overmap/ship/adj = get_adjacent_ship()
	.["extended"] = !!(active_tube && active_tube.ready)
	.["adjacent_ship"] = adj ? "[adj.name] (z=[adj.ship_z])" : "None"
	.["local_hatch"] = !!length(get_local_hatches())
	.["remote_hatch"] = !!length(get_remote_hatches())
	.["debug_local_z"] = z
	.["debug_link_id"] = link_id

/obj/structure/machinery/computer/umbilical_control/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	switch(action)
		if("extend")
			_extend(ui.user)
			. = TRUE
		if("retract")
			_retract()
			. = TRUE
