// Dynamic Ship Spawner
// Loads a ship DMM onto a fresh z-level at runtime, places an
// overmap token, and registers everything in GLOB.ship_registry
// and GLOB.map_sectors.

// ---- Registered ship templates -----------------------------
// Add one subtype per ship map file. The GM panel reads all
// subtypes of /datum/map_template/ship_def to build its list.

/datum/map_template/ship_def
	var/faction = "UNSC"
	var/overmap_type = /obj/effect/overmap/ship

/datum/map_template/ship_def/covenant_scout
	name = "Covenant Scout Ship"
	mappath = "maps/covenant_scout.dmm"
	faction = "Covenant"
	overmap_type = /obj/effect/overmap/ship/covenant

// ---- Core spawner proc -------------------------------------

// spawn_ship(template_type, display_name, overmap_x, overmap_y)
// Loads the ship DMM onto a new z-level, places an overmap token,
// and registers into ship_registry + map_sectors.
// Returns the new datum/ship_record, or null on failure.
/proc/spawn_ship(template_type, display_name, overmap_x = 0, overmap_y = 0)
	if(!ispath(template_type, /datum/map_template/ship_def))
		return null

	var/datum/map_template/ship_def/T = new template_type()

	var/datum/space_level/level = T.load_new_z()
	if(!level)
		log_game("SHIP SPAWNER: Failed to load [T.name] - load_new_z() returned null.")
		return null

	var/new_z = level.z_value

	// Auto-place on overmap if coordinates not specified
	if(!overmap_x || !overmap_y)
		var/placed = FALSE
		for(var/try_x = 5 to world.maxx - 2 step 5)
			for(var/try_y = 5 to world.maxy - 2 step 5)
				var/turf/candidate = locate(try_x, try_y, GLOB.overmap_z)
				if(candidate && !(locate(/obj/effect/overmap) in candidate))
					overmap_x = try_x
					overmap_y = try_y
					placed = TRUE
					break
			if(placed)
				break
		if(!placed)
			overmap_x = 5
			overmap_y = 5

	var/turf/overmap_turf = locate(overmap_x, overmap_y, GLOB.overmap_z)
	if(!overmap_turf)
		log_game("SHIP SPAWNER: No valid overmap turf at ([overmap_x],[overmap_y],[GLOB.overmap_z])")
		return null

	var/obj/effect/overmap/ship/token = new T.overmap_type(overmap_turf)
	token.name = display_name
	token.ship_z = new_z
	GLOB.map_sectors["[new_z]"] = token

	var/datum/ship_record/R = register_new_ship(
		display_name,
		T.faction,
		new_z,
		token,
		template_type
	)

	// Link consoles pre-placed in the DMM
	for(var/obj/structure/machinery/computer/helm/H in world)
		if(H.z == new_z)
			R.register_helm(H)
	for(var/obj/structure/machinery/computer/umbilical_control/U in world)
		if(U.z == new_z)
			R.register_umbilical(U)

	log_game("SHIP SPAWNER: Spawned [display_name] ([T.faction]) at z=[new_z], overmap ([overmap_x],[overmap_y]).")
	return R

// ---- Ship Spawner dialog -----------------------------------
// Shared proc called by the TGUI panel and the client verb.

/proc/open_ship_spawner_dialog(mob/user)
	var/list/template_paths = list()
	var/list/template_names = list()

	for(var/T in subtypesof(/datum/map_template/ship_def))
		var/datum/map_template/ship_def/proto = new T()
		var/label = "[proto.faction] - [proto.name]"
		template_names[label] = T
		template_paths += label
		qdel(proto)

	if(!length(template_paths))
		tgui_alert(user, "No ship templates are registered.", "Ship Spawner")
		return

	var/chosen_label = tgui_input_list(user, "Select a ship template to spawn:", "Ship Spawner", template_paths)
	if(!chosen_label)
		return

	var/chosen_type = template_names[chosen_label]

	var/ship_name = tgui_input_text(user, "Enter a name for this ship:", "Ship Name", chosen_label)
	if(!ship_name)
		return

	if(tgui_alert(user, "Spawn [ship_name]?", "Confirm Spawn", list("Spawn", "Cancel")) != "Spawn")
		return

	var/datum/ship_record/R = spawn_ship(chosen_type, ship_name)
	if(!R)
		tgui_alert(user, "Failed to spawn ship. Check the server log.", "Ship Spawner")
		return

	message_admins("[key_name(user)] spawned ship '[ship_name]' (z=[R.ship_z]) via Ship Spawner.")
	to_chat(user, SPAN_NOTICE("Ship '[ship_name]' spawned at z=[R.ship_z], overmap token placed."))

// Kept as a fallback verb in case the TGUI panel isn't open.
/client/proc/open_ship_spawner()
	set name = "Ship Spawner"
	set category = "Game Master.Extras"
	if(!check_rights(R_ADMIN))
		return
	open_ship_spawner_dialog(mob)

// ---- GM verb: Ship Registry --------------------------------

/client/proc/open_ship_registry_view()
	set name = "Ship Registry"
	set category = "Game Master.Extras"

	if(!check_rights(R_ADMIN))
		return

	if(!length(GLOB.ship_registry))
		tgui_alert(mob, "No ships are currently registered.", "Ship Registry")
		return

	var/list/lines = list()
	for(var/key in GLOB.ship_registry)
		var/datum/ship_record/R = GLOB.ship_registry[key]
		lines += ">> [R.name] ([R.faction]) z=[R.ship_z]"
		lines += "   Helm consoles:      [length(R.helm_consoles)]"
		lines += "   Umbilical consoles: [length(R.umbilical_consoles)]"
		lines += " "

	var/chosen = tgui_input_list(mob, "Registered ships (select >> line to jump):", "Ship Registry", lines)
	if(!chosen || !findtext(chosen, ">> "))
		return

	for(var/key in GLOB.ship_registry)
		var/datum/ship_record/R = GLOB.ship_registry[key]
		var/label = ">> [R.name] ([R.faction]) z=[R.ship_z]"
		if(chosen == label && R.overmap_token)
			var/turf/dest = get_turf(R.overmap_token)
			if(dest)
				src.jump_to_turf(dest)
			return
