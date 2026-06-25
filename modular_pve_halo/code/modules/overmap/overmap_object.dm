// Base overmap token — visible object that lives on the overmap z-level.
/obj/effect/overmap
	name = "unknown"
	icon = 'modular_pve_halo/icons/Heavycorvette.dmi'
	icon_state = "ship"
	anchored = TRUE
	/// Z-level of the actual map (ship/sector) this token represents
	var/ship_z = 0

// Placed on a ship map in the DMM. SSovermap moves it to the overmap z-level on init.
/obj/effect/overmap/ship
	name = "UNSC Ship"
	icon = 'modular_pve_halo/icons/Heavycorvette.dmi'
	icon_state = "ship"
	/// Cached reference to the helm computer that is currently viewing this token
	var/obj/structure/machinery/computer/helm/linked_helm
	/// Set to TRUE while an umbilical is extended from this ship; blocks overmap movement
	var/umbilical_locked = FALSE

/obj/effect/overmap/ship/covenant
	name = "Covenant Ship"
	icon = 'modular_pve_halo/icons/covshuttle2.dmi'
	icon_state = "ship"

// Placed directly on the overmap z-level (or spawned by SSovermap).
// Represents a planet, station, or other navigational landmark.
/obj/effect/overmap/sector
	name = "Unknown World"
	desc = "A distant object on the system map."
	icon_state = "shuttle_disp" // placeholder — swap with a planet icon
	/// Human-readable blurb shown in the helm UI when the ship is on this tile
	var/sector_desc = "A point of interest."
	/// If TRUE, ships can enter/leave this sector
	var/landable = TRUE
