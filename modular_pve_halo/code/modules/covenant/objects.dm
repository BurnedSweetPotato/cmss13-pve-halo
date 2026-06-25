// ============================================================
// Covenant Ship Objects
// Ported from HaloSpaceStation13-alpha.
// ============================================================

// ---- Lights ------------------------------------------------

/obj/structure/machinery/light/covenant
	name = "covenant light fixture"
	icon = 'modular_pve_halo/icons/covenant/structures/light.dmi'
	icon_state = "covie_light1"
	base_state = "covie_light"
	light_color = "#9966FF" // purple-tinted covenant glow


// ---- Airlocks ----------------------------------------------

// Standard single-tile covenant airlock (32px).
// DMI states: closed, open, locked, opening, closing, deny,
//             o_door_opening, o_door_closing, panel_open, welded
/obj/structure/machinery/door/airlock/covenant
	name = "airlock"
	icon = 'modular_pve_halo/icons/covenant/airlocks/door32.dmi'
	icon_state = "closed"

/obj/structure/machinery/door/airlock/covenant/update_icon()
	if(overlays)
		overlays.Cut()
	if(density)
		if(locked && lights)
			icon_state = "locked"
		else
			icon_state = "closed"
		if(panel_open || welded)
			overlays = list()
			if(panel_open)
				overlays += image(icon, "panel_open")
			if(welded)
				overlays += image(icon, "welded")
	else
		icon_state = "open"

/obj/structure/machinery/door/airlock/covenant/do_animate(animation)
	switch(animation)
		if("opening")
			if(overlays)
				overlays.Cut()
			if(panel_open)
				flick("o_door_opening", src)
			else
				flick("opening", src)
		if("closing")
			if(overlays)
				overlays.Cut()
			if(panel_open)
				flick("o_door_closing", src)
			else
				flick("closing", src)
		if("deny")
			flick("deny", src)
		if("spark")
			flick("door_spark", src)

/obj/structure/machinery/door/airlock/covenant/open(forced = FALSE)
	playsound(loc, 'modular_pve_halo/sound/covenant/airlocks/covenantdoor64open.ogg', 25, 1)
	return ..()

/obj/structure/machinery/door/airlock/covenant/close(forced = FALSE)
	playsound(loc, 'modular_pve_halo/sound/covenant/airlocks/covenantdoor64close.ogg', 25, 1)
	return ..()

// Two-tile covenant airlock (64px).
// DMI states: closed, open, locked, opening, closing
/obj/structure/machinery/door/airlock/multi_tile/covenant
	name = "airlock"
	icon = 'modular_pve_halo/icons/covenant/airlocks/door64.dmi'
	icon_state = "closed"
	width = 2
	damage_cap = 1200
	opacity = TRUE

// LateInitialize runs after the DMM applies the placed dir, so handle_multidoor()
// calculates bound_width/bound_height against the correct facing direction.
/obj/structure/machinery/door/airlock/multi_tile/covenant/Initialize(mapload)
	. = ..()
	return INITIALIZE_HINT_LATELOAD

/obj/structure/machinery/door/airlock/multi_tile/covenant/LateInitialize()
	. = ..()
	handle_multidoor()

/obj/structure/machinery/door/airlock/multi_tile/covenant/update_icon()
	if(overlays)
		overlays.Cut()
	if(density)
		icon_state = locked ? "locked" : "closed"
	else
		icon_state = "open"

/obj/structure/machinery/door/airlock/multi_tile/covenant/do_animate(animation)
	switch(animation)
		if("opening")
			flick("opening", src)
		if("closing")
			flick("closing", src)

/obj/structure/machinery/door/airlock/multi_tile/covenant/open(forced = FALSE)
	playsound(loc, 'modular_pve_halo/sound/covenant/airlocks/covenantdoor64open.ogg', 25, 1)
	return ..()

/obj/structure/machinery/door/airlock/multi_tile/covenant/close(forced = FALSE)
	playsound(loc, 'modular_pve_halo/sound/covenant/airlocks/covenantdoor64close.ogg', 25, 1)
	return ..()

// Three-tile covenant airlock (96px).
/obj/structure/machinery/door/airlock/multi_tile/covenant/three
	name = "airlock"
	icon = 'modular_pve_halo/icons/covenant/airlocks/door96.dmi'
	icon_state = "closed"
	width = 3
	damage_cap = 1500

/obj/structure/machinery/door/airlock/multi_tile/covenant/three/update_icon()
	if(overlays)
		overlays.Cut()
	if(density)
		icon_state = locked ? "locked" : "closed"
	else
		icon_state = "open"

/obj/structure/machinery/door/airlock/multi_tile/covenant/three/do_animate(animation)
	switch(animation)
		if("opening")
			flick("opening", src)
		if("closing")
			flick("closing", src)

/obj/structure/machinery/door/airlock/multi_tile/covenant/three/open(forced = FALSE)
	playsound(loc, 'modular_pve_halo/sound/covenant/airlocks/covenantdoor96open.ogg', 25, 1)
	return ..()

// Four-tile vehicle airlock (128px). No locked state in DMI.
/obj/structure/machinery/door/airlock/multi_tile/covenant/four
	name = "vehicle airlock"
	icon = 'modular_pve_halo/icons/covenant/airlocks/door128.dmi'
	icon_state = "closed"
	width = 4
	damage_cap = 2000

/obj/structure/machinery/door/airlock/multi_tile/covenant/four/update_icon()
	if(overlays)
		overlays.Cut()
	icon_state = density ? "closed" : "open"

/obj/structure/machinery/door/airlock/multi_tile/covenant/four/do_animate(animation)
	switch(animation)
		if("opening")
			flick("opening", src)
		if("closing")
			flick("closing", src)

/obj/structure/machinery/door/airlock/multi_tile/covenant/four/open(forced = FALSE)
	playsound(loc, 'modular_pve_halo/sound/covenant/airlocks/covenantdoor128open.ogg', 25, 1)
	return ..()

/obj/structure/machinery/door/airlock/multi_tile/covenant/four/close(forced = FALSE)
	playsound(loc, 'modular_pve_halo/sound/covenant/airlocks/covenantdoor128close.ogg', 25, 1)
	return ..()

// ---- Computers / Consoles ----------------------------------

// Decorative covenant computer terminal (no interactivity).
/obj/structure/machinery/computer/covenant
	name = "covenant terminal"
	desc = "A sleek alien terminal. The interface is incomprehensible to humans."
	icon = 'modular_pve_halo/icons/covenant/structures/consoles.dmi'
	icon_state = "covie_console"

// Decorative covenant navigation terminal.
/obj/structure/machinery/computer/covenant/nav
	name = "covenant navigation terminal"
	desc = "A holographic navigation interface."
	icon_state = "covie_nav"

// ---- Storage -----------------------------------------------

// Short crate (roughly chest-height).
/obj/structure/closet/crate/covenant
	name = "covenant storage crate"
	desc = "A sleek, humming storage crate."
	icon = 'modular_pve_halo/icons/covenant/structures/crate_short.dmi'
	icon_state = "Covie Crate Closed"
	icon_opened = "Covie Crate Open"
	open_sound = 'modular_pve_halo/sound/covenant/objects/covenant_crate_open.ogg'
	close_sound = 'modular_pve_halo/sound/covenant/objects/covenant_crate_close.ogg'

// Tall crate / locker.
/obj/structure/closet/covenant
	name = "covenant storage unit"
	desc = "A tall alien storage unit."
	icon = 'modular_pve_halo/icons/covenant/structures/crate_tall.dmi'
	icon_state = "closed"
	icon_opened = "open"
	open_sound = 'modular_pve_halo/sound/covenant/objects/covenant_crate_open.ogg'
	close_sound = 'modular_pve_halo/sound/covenant/objects/covenant_crate_close.ogg'

// Weapon rack variant.
/obj/structure/closet/covenant/weapon_rack
	name = "covenant weapon rack"
	desc = "A rack for storing plasma weapons."
	icon_state = "weapon_rack"
	icon_opened = "weapon_rack"

// ---- Vendors -----------------------------------------------

// Empty covenant vendor — add product lists to subtypes as needed.
/obj/structure/machinery/cm_vending/covenant
	name = "covenant supply unit"
	desc = "An alien dispensary unit. The controls require familiarity with Covenant interfaces."
	icon = 'modular_pve_halo/icons/covenant/structures/covendor.dmi'
	icon_state = "covendor"
	req_access = null

// Wall locker.
/obj/structure/closet/crate/covenant/wall_locker
	name = "covenant emergency locker"
	desc = "A wall-mounted covenant emergency storage unit."
	icon = 'modular_pve_halo/icons/covenant/structures/Wallocker.dmi'
	icon_state = "emerg_02"
	icon_opened = "emerg_02"

/obj/structure/closet/crate/covenant/wall_locker/tools
	name = "covenant tool locker"
	icon_state = "emerg"
	icon_opened = "emerg"

// ---- Machinery Props (decorative, no gameplay logic) -------

// 128x128 generator. Offset so the sprite centres on the placed tile.
/obj/structure/prop/covenant/pinch_fusion
	name = "Covenant Pinch Fusion Generator"
	desc = "An incredibly advanced generator capable of producing both energy and energised plasma."
	icon = 'modular_pve_halo/icons/covenant/structures/pinch_fusion.dmi'
	icon_state = ""
	density = TRUE
	anchored = TRUE
	layer = ABOVE_MOB_LAYER

// 64x64 slipspace drive (Covenant faction variant).
/obj/structure/prop/covenant/slipspace_drive
	name = "Slipspace Traversal Drive"
	desc = "A self-contained device allowing for traversal of slipspace, providing methods of quick travel across large distances without sacrificing accuracy."
	icon = 'modular_pve_halo/icons/covenant/structures/slipspace_drive.dmi'
	icon_state = "slipspace"
	bound_width = 64
	bound_height = 64
	pixel_x = -16
	pixel_y = -16
	density = TRUE
	anchored = TRUE
	layer = ABOVE_MOB_LAYER

// Repulsor engine -- single-tile, directional sprite.
/obj/structure/prop/covenant/repulsor_engine
	name = "Repulsor Engine"
	desc = "A sophisticated gravitic drive that allows great speed and manoeuvrability."
	icon = 'modular_pve_halo/icons/covenant/structures/repulsor_engine.dmi'
	icon_state = "off"
	density = TRUE
	anchored = TRUE
	layer = ABOVE_MOB_LAYER

// ---- Banshee Prop ------------------------------------------

/obj/structure/prop/covenant/banshee
	name = "Type-26 \"Banshee\" Ground Support Aircraft"
	desc = "A versatile single-pilot ground assault aircraft. The controls have been disabled for maintenance."
	icon = 'modular_pve_halo/icons/covenant/vehicles/banshee.dmi'
	icon_state = "banshee"
	bound_x = 96
	bound_y = 96
	pixel_x = -32
	pixel_y = -32
	density = TRUE
	anchored = TRUE
	layer = ABOVE_MOB_LAYER
	var/max_banshee_health = 200
	var/banshee_health = 200

/obj/structure/prop/covenant/banshee/Initialize(mapload)
	. = ..()
	banshee_health = max_banshee_health

/obj/structure/prop/covenant/banshee/ex_act(severity, explosion_direction, datum/cause_data/cause_data)
	switch(severity)
		if(EXPLOSION_THRESHOLD_LOW)
			banshee_health -= 50
		if(EXPLOSION_THRESHOLD_MEDIUM)
			banshee_health -= 100
		if(EXPLOSION_THRESHOLD_HIGH)
			banshee_health -= 200
	if(banshee_health <= 0)
		_destroy()

/obj/structure/prop/covenant/banshee/proc/_destroy()
	var/turf/T = get_turf(src)
	visible_message(SPAN_WARNING("The Banshee erupts in a fireball!"))
	explosion(T, -1, 1, 3, 4, 1, 0, 0, create_cause_data("Banshee destroyed", src))
	robogibs(T)
	qdel(src)

// ---- Chairs / Seating --------------------------------------

// Anti-gravity stool. Simple seat, no overlay logic needed.
/obj/structure/bed/chair/covenant/stool
	name = "anti-grav stool"
	desc = "A hovering Covenant stool. Surprisingly comfortable despite the lack of a backrest."
	icon = 'modular_pve_halo/icons/covenant/structures/chair.dmi'
	icon_state = "coviestool"

// ---- Beds --------------------------------------------------

/obj/structure/bed/covenant
	name = "Sangheili bed"
	desc = "Not designed for human comfort."
	icon = 'modular_pve_halo/icons/covenant/structures/bed.dmi'
	icon_state = "cbed1"

/obj/structure/bed/covenant/hierarch
	name = "hierarch's bed"
	desc = "Advanced technology makes this bed extremely comfortable."
	icon_state = "hbed1"

// ---- Tables ------------------------------------------------

// Purple glass table. Uses CM's surface/table system (items can be placed on it).
// The purple tint is applied via the color var over the standard glass table icon.
/obj/structure/surface/table/covenant/glass
	name = "purple glass table"
	desc = "A sleek table fashioned from Covenant purple-tinted glass."
	color = "#915C91"

// ---- Windows (slivers) -------------------------------------

// Covenant nanolaminate window sliver — directional, no frame needed.
/obj/structure/window/reinforced/covenant
	name = "nanolaminate-coated window"
	desc = "An extremely sturdy window with a distinctive purple tint."
	icon = 'modular_pve_halo/icons/covenant/structures/window_covenant.dmi'
	icon_state = "window"

// ---- Props -------------------------------------------------

// Battlenet transmitter — decorative prop, no comms logic.
/obj/structure/prop/covenant/battlenet_transmitter
	name = "Battlenet transmitter"
	desc = "A Covenant communications device. This one appears to be an older model, now nonfunctional."
	icon = 'modular_pve_halo/icons/covenant/structures/comms.dmi'
	icon_state = "comms"
	density = TRUE
	anchored = TRUE
	layer = ABOVE_MOB_LAYER

// ---- Covenant Floodlights ----------------------------------

// Standing floodlight — toggleable, emits purple/blue light.
/obj/structure/machinery/floodlight/covenant
	name = "Covenant floodlight"
	desc = "A Covenant lighting array that bathes the area in an eerie violet glow."
	light_color = "#7B2FBE"
	light_power = 2
	on_light_range = 6

// Landing/pad light — always-on, indestructible, flush with the floor.
/obj/structure/machinery/floodlight/landing/covenant
	name = "Covenant landing light"
	desc = "A fixed Covenant light bolted into the deck plating. It pulses with a soft violet hue."
	light_color = "#7B2FBE"
	light_power = 2
	on_light_range = 6

/obj/structure/machinery/floodlight/landing/floor/covenant
	name = "Covenant floor light"
	desc = "A flush Covenant floor light. A faint violet glow emanates from its surface."
	light_color = "#7B2FBE"
	light_power = 1
	on_light_range = 4

// ---- Faction banner — marks an area as under Covenant control.
/obj/structure/prop/covenant/faction_banner
	name = "Covenant banner"
	desc = "A banner indicating this area is under control of the Covenant."
	icon = 'modular_pve_halo/icons/covenant/structures/faction_banner.dmi'
	icon_state = "Covenant"
	density = FALSE
	anchored = TRUE
	layer = ABOVE_MOB_LAYER

// ---- Flora -------------------------------------------------

// Unusual potted plant — emits a faint blue bioluminescent glow.
// The distinctive plant-09 sprite from the base game, lit to feel alien.
/obj/structure/flora/pottedplant/unusual
	name = "unusual potted plant"
	desc = "An alien-looking plant with bulbous, glowing blue ends. It was likely brought aboard by Covenant researchers."
	icon_state = "pottedplant_9"
	light_range = 1
	light_power = 0.5
	light_color = "#3399FF"
