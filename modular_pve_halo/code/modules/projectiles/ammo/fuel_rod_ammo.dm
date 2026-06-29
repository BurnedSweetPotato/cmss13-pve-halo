// Green plasma burst spawned on fuel rod impact.
// Reuses the sebb explosion sprite (which respects RESET_COLOR / color tinting) and
// adds a spread of green-tinted sparks for a plasma-style detonation — no separate DMI needed.

/obj/effect/overlay/temp/fuel_rod_explosion
	icon = 'icons/effects/sebb.dmi'
	icon_state = "sebb_explode"
	layer = ABOVE_LIGHTING_PLANE
	pixel_x = -175
	pixel_y = -175
	appearance_flags = RESET_COLOR
	color = "#22FF55"
	effect_duration = 5

// Green-tinted spark particle for the fuel rod detonation.
/obj/effect/particle_effect/sparks/fuel_rod
	color = "#44FF77"

// Fuel rod projectile ammo.
// Uses heavy_plasma_magenta (a symmetric glowing orb from halo_projectiles.dmi) so the
// sprite looks the same from all fire directions — no tumbling.
/datum/ammo/rocket/fuel_rod
	name = "fuel rod"
	icon = 'icons/halo/obj/items/weapons/halo_projectiles.dmi'
	icon_state = "heavy_plasma_magenta"
	damage = 200
	shell_speed = AMMO_SPEED_TIER_1
	accuracy = HIT_ACCURACY_TIER_3
	accurate_range = 9
	max_range = 13
	damage_falloff = 0
	flags_ammo_behavior = AMMO_EXPLOSIVE|AMMO_ROCKET|AMMO_STRIKES_SURFACE
	ammo_glowing = TRUE
	bullet_light_color = "#44FF44"

// Tint the projectile atom bright green after generation.
// RESET_COLOR makes the atom respect its color var for rendering.
/datum/ammo/rocket/fuel_rod/on_bullet_generation(obj/projectile/P, mob/generator)
	..()
	P.appearance_flags |= RESET_COLOR
	P.color = "#22FF44"

// Minimum arming distance is 3 tiles. Below that the rod bounces instead of detonating.
#define FUEL_ROD_ARM_DIST 4

/datum/ammo/rocket/fuel_rod/proc/is_armed(obj/projectile/projectile)
	return projectile.distance_travelled >= FUEL_ROD_ARM_DIST

// Spawn a new fuel rod projectile bouncing away in a reflected direction.
// Uses the opposite of the incoming direction, rotated 90–135° randomly, so it
// skips back past the shooter and continues travelling.
/datum/ammo/rocket/fuel_rod/proc/ricochet(turf/impact_turf, obj/projectile/projectile)
	playsound(impact_turf, 'sound/weapons/halo/fuel_rod/unload.ogg', 50, TRUE, 8)

	// Reflect off the surface: reverse incoming dir, then skew by ±45°.
	var/incoming_dir = get_dir(get_turf(projectile.firer), impact_turf)
	var/bounce_dir = turn(REVERSE_DIR(incoming_dir), pick(-45, 0, 45))

	var/turf/target_turf = get_ranged_target_turf(impact_turf, bounce_dir, 15)
	if(!target_turf)
		return

	var/obj/projectile/P = new /obj/projectile(impact_turf, projectile.weapon_cause_data)
	P.generate_bullet(GLOB.ammo_list[/datum/ammo/rocket/fuel_rod], 0, NO_FLAGS)
	// Mark the bounce so it doesn't ricochet again (distance_travelled starts at 0 on the new projectile,
	// so we set a flag via a distance offset by pre-counting FUEL_ROD_ARM_DIST ticks).
	P.distance_travelled = FUEL_ROD_ARM_DIST
	P.fire_at(target_turf, projectile.firer, projectile.shot_from, 15, AMMO_SPEED_TIER_1)

/datum/ammo/rocket/fuel_rod/proc/detonate(turf/impact_turf, obj/projectile/projectile)
	new /obj/effect/overlay/temp/fuel_rod_explosion(impact_turf)
	var/datum/effect_system/spark_spread/sparks = new()
	sparks.set_up(6, FALSE, impact_turf)
	for(var/obj/effect/particle_effect/sparks/S in impact_turf)
		S.color = "#44FF77"
	sparks.start()
	playsound(impact_turf, pick(
		'sound/weapons/halo/fuel_rod/explode1.wav',
		'sound/weapons/halo/fuel_rod/explode2.wav',
		'sound/weapons/halo/fuel_rod/explode3.wav'), 75, TRUE, 12)
	cell_explosion(impact_turf, 175, 35, EXPLOSION_FALLOFF_SHAPE_EXPONENTIAL, null, projectile.weapon_cause_data)
	smoke.set_up(1, impact_turf)
	smoke.start()

/datum/ammo/rocket/fuel_rod/on_hit_mob(mob/mob, obj/projectile/projectile)
	if(!is_armed(projectile))
		ricochet(get_turf(mob), projectile)
		return
	var/turf/T = get_turf(mob)
	if(iscarbon(mob))
		mob.ex_act(400, null, projectile.weapon_cause_data, 75)
	detonate(T, projectile)

/datum/ammo/rocket/fuel_rod/on_hit_obj(obj/object, obj/projectile/projectile)
	if(!is_armed(projectile))
		ricochet(get_turf(object), projectile)
		return
	detonate(get_turf(object), projectile)

/datum/ammo/rocket/fuel_rod/on_hit_turf(turf/turf, obj/projectile/projectile)
	if(!is_armed(projectile))
		ricochet(turf, projectile)
		return
	detonate(turf, projectile)

/datum/ammo/rocket/fuel_rod/do_at_max_range(obj/projectile/projectile)
	detonate(get_turf(projectile), projectile)

#undef FUEL_ROD_ARM_DIST
