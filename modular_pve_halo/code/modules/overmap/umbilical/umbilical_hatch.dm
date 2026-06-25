// Placed on each ship hull in the map editor.
// Walk into it (facing enter_dir) to board the umbilical tube when extended.
/obj/structure/umbilical_hatch
	name = "umbilical airlock"
	desc = "A reinforced hatch for connecting to an external umbilical passage."
	icon = 'modular_pve_halo/icons/umbilical_full.dmi'
	icon_state = "umbi_contracted"
	anchored = TRUE
	density = FALSE
	/// Walk in this direction to enter — set in map editor to match the approach corridor.
	var/enter_dir = NORTH
	/// Must match the link_id on the umbilical_control console that owns this hatch.
	var/link_id = "umbilical_1"
	/// Set by the console when the umbilical is extended.
	var/datum/umbilical_tube/linked_tube

/obj/structure/umbilical_hatch/proc/set_extended(extended)
	icon_state = extended ? "umbi_extended" : "umbi_contracted"

/obj/structure/umbilical_hatch/Crossed(atom/movable/A)
	..()
	if(!ismob(A) || istype(A, /mob/dead/observer))
		return
	if(!linked_tube || !linked_tube.ready)
		return
	var/mob/M = A
	if(M in GLOB.umbilical_in_transit)
		return
	if(M.dir != enter_dir)
		return
	to_chat(M, SPAN_NOTICE("You step through the umbilical passage."))
	linked_tube.enter_from(M, src)

// Pre-placed inside the umbilical tube DMM at each end.
// exit_hatch is assigned by datum/umbilical_tube/create() based on which
// entrance this hatch is closest to — no manual side tag needed.
/obj/structure/umbilical_hatch/internal
	name = "umbilical exit hatch"
	desc = "The end of the umbilical passage. Walk through to return to the ship."
	/// Set by tube.create(). Teleports the mob to this external hatch on exit.
	var/obj/structure/umbilical_hatch/exit_hatch

// Does NOT call ..() so the parent entry logic never fires here.
/obj/structure/umbilical_hatch/internal/Crossed(atom/movable/A)
	if(!ismob(A) || istype(A, /mob/dead/observer))
		return
	if(!linked_tube || !linked_tube.ready)
		return
	var/mob/M = A
	if(M in GLOB.umbilical_in_transit)
		return
	linked_tube.exit_to_hatch(M, exit_hatch)
