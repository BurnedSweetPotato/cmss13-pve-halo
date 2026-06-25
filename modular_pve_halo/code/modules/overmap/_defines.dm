#define ZTRAIT_OVERMAP "Overmap"

// z-value of the overmap level, set by SSovermap during init
GLOBAL_VAR_INIT(overmap_z, 0)

// Maps "[ship_z]" -> /obj/effect/overmap/ship token on the overmap level
GLOBAL_LIST_EMPTY(map_sectors)

// Mobs currently mid-transit through an umbilical tube.
// Prevents Crossed() from retriggering immediately after a forceMove arrival.
GLOBAL_LIST_EMPTY(umbilical_in_transit)
