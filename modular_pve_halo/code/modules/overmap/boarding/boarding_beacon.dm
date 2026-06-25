// Boarding Pod Beacon -- placed by GMs to define exact landing zones.
// Pods prefer these turfs over random selection when any exist on the target z.

/obj/effect/boarding_pod_beacon
	name = "boarding beacon"
	desc = "A tactical landing marker. Boarding pods will target this location."
	icon = 'icons/obj/structures/machinery/computer.dmi'
	icon_state = "aiming"
	layer = ABOVE_MOB_LAYER
	anchored = TRUE
	// Invisible to regular players; admins see it via their eye
	invisibility = INVISIBILITY_MAXIMUM
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/// Returns a list of open turfs that have a boarding beacon on the given z-level.
/// Called by boarding_pod._pick_landing_turf() so the type reference stays in this file.
/proc/get_boarding_beacon_turfs(target_z)
	var/list/result = list()
	for(var/obj/effect/boarding_pod_beacon/B in world)
		if(B.z != target_z)
			continue
		var/turf/T = get_turf(B)
		if(T && !T.density)
			result += T
	return result

// ---- GM verb: Place Boarding Beacon -------------------------

/client/proc/place_boarding_beacon()
	set name = "Place Boarding Beacon"
	set category = "Game Master.Extras"

	if(!check_rights(R_ADMIN))
		return

	if(!length(GLOB.ship_registry))
		tgui_alert(mob, "No ships registered yet.", "Boarding Beacon")
		return

	// Build ship list
	var/list/ship_names = list()
	var/list/ship_map = list() // name -> ship_z
	for(var/key in GLOB.ship_registry)
		var/datum/ship_record/R = GLOB.ship_registry[key]
		ship_names += R.name
		ship_map[R.name] = R.ship_z

	var/chosen = tgui_input_list(mob, "Select the target ship to place a beacon on.\nYou will be given a placer item to click the exact tile.", "Place Boarding Beacon", ship_names)
	if(!chosen)
		return

	var/target_z = ship_map[chosen]

	// Check for existing beacons
	var/existing = 0
	for(var/obj/effect/boarding_pod_beacon/B in world)
		if(B.z == target_z)
			existing++

	if(existing > 0)
		var/overwrite = tgui_alert(mob, "There are already [existing] beacon(s) on [chosen]. Add another?", "Boarding Beacon", list("Add", "Clear all and add", "Cancel"))
		if(overwrite == "Cancel" || !overwrite)
			return
		if(overwrite == "Clear all and add")
			for(var/obj/effect/boarding_pod_beacon/B in world)
				if(B.z == target_z)
					qdel(B)

	// Give the admin a placer item
	var/obj/item/boarding_beacon_placer/placer = new(mob.loc)
	placer.target_z = target_z
	placer.ship_name = chosen
	mob.put_in_hands(placer)
	to_chat(mob, SPAN_NOTICE("Click any tile on [chosen] to place a boarding beacon there. The placer will disappear after use."))
	message_admins("[key_name(mob)] is placing a boarding beacon on [chosen] (z=[target_z]).")

// ---- Placer item --------------------------------------------

/obj/item/boarding_beacon_placer
	name = "beacon placer"
	desc = "Click a tile to place a boarding beacon there."
	var/target_z = 0
	var/ship_name = ""

/obj/item/boarding_beacon_placer/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(!istype(user) || !check_rights_for(user.client, R_ADMIN))
		return

	var/turf/T = get_turf(target)
	if(!T)
		to_chat(user, SPAN_WARNING("Invalid tile."))
		return

	if(T.z != target_z)
		to_chat(user, SPAN_WARNING("That tile is not on [ship_name] (z=[target_z]). Click a tile on the correct ship."))
		return

	new /obj/effect/boarding_pod_beacon(T)
	to_chat(user, SPAN_NOTICE("Boarding beacon placed at ([T.x],[T.y],[T.z]) on [ship_name]."))
	message_admins("[key_name(user)] placed a boarding beacon at ([T.x],[T.y],[T.z]) on [ship_name].")
	qdel(src)
