/obj/structure/machinery/computer/helm
	name = "helm control console"
	desc = "A navigation console for piloting the ship on the system map."
	icon = 'icons/obj/structures/machinery/computer.dmi'
	icon_state = "shuttle_disp" // placeholder
	/// The overmap ship token linked to this console
	var/obj/effect/overmap/ship/linked

// ---- Linking ----------------------------------------------------------------

/obj/structure/machinery/computer/helm/proc/try_link()
	if(!linked)
		linked = GLOB.map_sectors["[z]"]
		if(linked)
			var/datum/ship_record/R = get_ship_record(z)
			if(R)
				R.register_helm(src)
	return linked

// ---- Interaction / view system ----------------------------------------------

// When the player clicks the console, move their eye to the overmap token
// so they see the live overmap z-level, then open the TGUI overlay.
/obj/structure/machinery/computer/helm/attack_hand(mob/user)
	if(..())
		return
	if(!try_link())
		to_chat(usr, SPAN_WARNING("No ship detected on this z-level."))
		return
	user.set_interaction(src)
	user.reset_view(linked)
	tgui_interact(user)

// Called by unset_interaction — restore the player's normal view.
/obj/structure/machinery/computer/helm/on_unset_interaction(mob/user)
	..()
	user.reset_view(null)

// BYOND calls check_eye() periodically while client.eye != client.mob.
// Return without action = still valid. Call unset_interaction() to end it.
/obj/structure/machinery/computer/helm/check_eye(mob/user)
	if(get_dist(user, src) > 1 || user.is_mob_incapacitated() || !user.client)
		user.unset_interaction()

// ---- TGUI ------------------------------------------------------------------

/obj/structure/machinery/computer/helm/tgui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "HelmConsole", src.name)
		ui.open()

// Close the TGUI when the player is no longer adjacent / incapacitated.
/obj/structure/machinery/computer/helm/ui_state(mob/user)
	return GLOB.not_incapacitated_and_adjacent_state

/obj/structure/machinery/computer/helm/ui_data(mob/user)
	. = list()
	if(!try_link())
		.["error"] = "No ship detected on this z-level."
		return

	// Collect any sector token on the same overmap tile as the ship
	var/obj/effect/overmap/sector/current_sector
	for(var/obj/effect/overmap/sector/S in get_turf(linked))
		current_sector = S
		break

	.["ship_name"] = linked.name
	.["x"] = linked.x
	.["y"] = linked.y
	.["max_x"] = world.maxx
	.["max_y"] = world.maxy
	.["sector_name"] = current_sector ? current_sector.name : "Deep Space"
	.["sector_desc"] = current_sector ? current_sector.sector_desc : "Nothing but void in every direction."
	.["landable"] = current_sector ? current_sector.landable : FALSE

/obj/structure/machinery/computer/helm/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	if(!try_link())
		return

	switch(action)
		if("move")
			if(linked.umbilical_locked)
				to_chat(usr, SPAN_WARNING("Cannot maneuver: umbilical is attached. Retract it first."))
				return
			var/dir = text2dir(params["dir"])
			if(!dir)
				return
			var/turf/dest = get_step(linked, dir)
			if(dest && dest.z == GLOB.overmap_z)
				linked.Move(dest, dir)
			. = TRUE

		if("disengage")
			var/mob/user = ui.user
			user.unset_interaction() // restores view via on_unset_interaction
			SStgui.close_uis(src)   // close_uis takes only the src_object
			. = TRUE

		if("land")
			// Stub for future landing/docking logic
			to_chat(usr, SPAN_NOTICE("Landing sequence not yet implemented."))
			. = TRUE

// When the TGUI window closes (player clicks X or walks away), restore view.
/obj/structure/machinery/computer/helm/ui_close(mob/user)
	..()
	user.unset_interaction()
