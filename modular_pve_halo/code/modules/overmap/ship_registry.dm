// ============================================================
// Ship Registry
// Associates every active ship z-level with a datum that knows
// its overmap token, faction, and linked consoles.
// Helm computers and umbilical consoles call register_console()
// on Initialize so the registry is always up to date.
// ============================================================

// z-level (as string) -> datum/ship_record
GLOBAL_LIST_EMPTY(ship_registry)

/proc/get_ship_record(z_level)
	return GLOB.ship_registry["[z_level]"]

// ---- Ship record datum -------------------------------------

/datum/ship_record
	/// Display name of the ship
	var/name = "Unknown Vessel"
	/// "UNSC" or "Covenant"
	var/faction = "UNSC"
	/// Z-value of the ship's map level
	var/ship_z = 0
	/// The overmap token representing this ship on the overmap z-level
	var/obj/effect/overmap/ship/overmap_token
	/// Type path of the map_template used to generate this ship, if any
	var/map_template_type
	/// All helm computers found on this ship's z-level
	var/list/helm_consoles = list()
	/// All umbilical control consoles found on this ship's z-level
	var/list/umbilical_consoles = list()

/datum/ship_record/Destroy(force, ...)
	overmap_token = null
	helm_consoles = null
	umbilical_consoles = null
	return ..()

/// Register a helm computer with this ship record.
/datum/ship_record/proc/register_helm(obj/structure/machinery/computer/helm/H)
	helm_consoles |= H
	RegisterSignal(H, COMSIG_PARENT_QDELETING, PROC_REF(_on_helm_deleted))

/// Register an umbilical console with this ship record.
/datum/ship_record/proc/register_umbilical(obj/structure/machinery/computer/umbilical_control/U)
	umbilical_consoles |= U
	RegisterSignal(U, COMSIG_PARENT_QDELETING, PROC_REF(_on_umbilical_deleted))

/datum/ship_record/proc/_on_helm_deleted(datum/source)
	SIGNAL_HANDLER
	helm_consoles -= source

/datum/ship_record/proc/_on_umbilical_deleted(datum/source)
	SIGNAL_HANDLER
	umbilical_consoles -= source

// ---- Helpers for the overmap subsystem ---------------------

/// Create a ship_record from an existing overmap token (called by SSovermap).
/proc/register_ship_token(obj/effect/overmap/ship/token)
	var/datum/ship_record/R = new()
	R.name = token.name
	R.ship_z = token.ship_z
	R.overmap_token = token
	R.faction = istype(token, /obj/effect/overmap/ship/covenant) ? "Covenant" : "UNSC"
	GLOB.ship_registry["[token.ship_z]"] = R
	return R

/// Create a ship_record for a dynamically spawned ship (called by spawn_ship).
/proc/register_new_ship(name, faction, ship_z, obj/effect/overmap/ship/token, map_template_type)
	var/datum/ship_record/R = new()
	R.name = name
	R.faction = faction
	R.ship_z = ship_z
	R.overmap_token = token
	R.map_template_type = map_template_type
	GLOB.ship_registry["[ship_z]"] = R
	return R
