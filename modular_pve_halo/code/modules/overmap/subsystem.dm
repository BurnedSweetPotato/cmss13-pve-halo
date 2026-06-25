SUBSYSTEM_DEF(overmap)
	name = "Overmap"
	init_order = SS_INIT_MAPPING - 0.5 // run right after SSmapping
	flags = SS_NO_FIRE

/datum/controller/subsystem/overmap/Initialize(timeofday)
	// Create a dedicated z-level for the overmap grid
	var/datum/space_level/S = SSmapping.add_new_zlevel("Overmap", list(ZTRAIT_OVERMAP = TRUE))
	GLOB.overmap_z = S.z_value

	// Find every overmap ship marker placed on a ship map and move it onto the overmap level.
	// Space out multiple ships so they don't stack.
	var/spawn_x = 15
	var/spawn_y = 15
	for(var/obj/effect/overmap/ship/OS in world)
		if(OS.z == GLOB.overmap_z)
			continue
		OS.ship_z = OS.z
		GLOB.map_sectors["[OS.ship_z]"] = OS
		register_ship_token(OS)
		var/turf/start = locate(spawn_x, spawn_y, GLOB.overmap_z)
		if(start)
			OS.forceMove(start)
		spawn_x = min(spawn_x + 5, world.maxx - 2)

	// Spawn some placeholder sectors so there is something to navigate toward.
	// Replace these with real sector objects once proper sprites/lore exist.
	_spawn_sector("Reach", "A glassy, war-scarred human colony world.", 25, 20)
	_spawn_sector("Installation 04", "A Forerunner ringworld of immense scale.", 8, 28)

	return SS_INIT_SUCCESS

/datum/controller/subsystem/overmap/proc/_spawn_sector(name, desc, x, y)
	var/turf/T = locate(x, y, GLOB.overmap_z)
	if(!T)
		return
	var/obj/effect/overmap/sector/S = new(T)
	S.name = name
	S.sector_desc = desc
