/obj/item/device/helmet_visor/night_vision/halo
	name = "HALO NVG Module"
	desc = "If you're seeing this, you probably shouldn't be."
	icon = 'icons/obj/items/clothing/helmet_visors.dmi'

	hud_type = list(MOB_HUD_FACTION_UNSC, MOB_HUD_VISR)
	lighting_alpha = 170 // originally 190
	toggle_on_sound = 'sound/handling/visr_on.ogg'
	toggle_off_sound = 'sound/handling/visr_off.ogg'
	helmet_overlay = null
	icon_state = "visr_chip"
	action_icon_string = "visr_on"
	power_use = 0
	visor_glows = FALSE

/obj/item/device/helmet_visor/night_vision/halo/unsc
	name = "VISR v22.5606C.01"
	desc = "The integrated VISR system features light enhancement systems, raising the brightness of the surrounding area on the user's heads-up display during low-light operations. This vision-enhancement mode also links with the user's neural interface to provide Friend or Foe designation by searching for IFF transponders on friendly or enemy personnel"
	hud_type = list() // outlines replace faction triangle HUD
	var/list/outlined_mobs = list()
	var/mob/living/carbon/human/visr_wearer
	var/obj/item/clothing/head/helmet/marine/visr_helmet

#define VISR_LOWLIGHT_USAGE(delta_time) (power_cell.use(power_use * (delta_time ? delta_time : 1)))

/obj/item/device/helmet_visor/night_vision/halo/activate_visor(obj/item/clothing/head/helmet/marine/attached_helmet, mob/living/carbon/human/user)
	RegisterSignal(user, COMSIG_HUMAN_POST_UPDATE_SIGHT, PROC_REF(on_update_sight))

	user.add_client_color_matrix("visr_low_light", 99, color_matrix_multiply(color_matrix_saturation(1.25), color_matrix_from_string("#cab999"))) // saturation originally 0.8, hexcode originally "#cbae77"
	user.overlay_fullscreen("visr_low_light_blur", /atom/movable/screen/fullscreen/brute/nvg/visr, 3)
	user.update_sight()

	for(var/type in hud_type)
		var/datum/mob_hud/current_mob_hud = GLOB.huds[type]
		current_mob_hud.add_hud_to(user, attached_helmet)

	if(visor_glows)
		on_light = new(attached_helmet)
		on_light.set_light_on(TRUE)
	START_PROCESSING(SSobj, src)
	RegisterSignal(user, COMSIG_MOB_CHANGE_VIEW, PROC_REF(change_view))

/obj/item/device/helmet_visor/night_vision/halo/deactivate_visor(obj/item/clothing/head/helmet/marine/attached_helmet, mob/living/carbon/human/user)
	user.remove_client_color_matrix("visr_low_light", 1 SECONDS)
	user.clear_fullscreen("visr_low_light_blur", 0.5 SECONDS)

	for(var/type in hud_type)
		var/datum/mob_hud/current_mob_hud = GLOB.huds[type]
		current_mob_hud.remove_hud_from(user, attached_helmet)

	if(visor_glows)
		qdel(on_light)
	UnregisterSignal(user, COMSIG_HUMAN_POST_UPDATE_SIGHT)
	UnregisterSignal(user, COMSIG_MOB_CHANGE_VIEW)

	user.update_sight()
	STOP_PROCESSING(SSobj, src)

/obj/item/device/helmet_visor/night_vision/halo/process(delta_time)
	if(VISR_LOWLIGHT_USAGE(delta_time))
		return

	if(!istype(loc, /obj/item/clothing/head/helmet/marine))
		return PROCESS_KILL

	if(!istype(loc?.loc, /mob/living/carbon/human))
		return PROCESS_KILL

	var/obj/item/clothing/head/helmet/marine/attached_helmet = loc
	var/mob/living/carbon/human/user = loc.loc
	to_chat(user, SPAN_NOTICE("[src] deactivates as the battery goes out."))
	deactivate_visor(attached_helmet, user)
	return PROCESS_KILL

/obj/item/device/helmet_visor/night_vision/halo/can_toggle(mob/living/carbon/human/user)
	. = ..()
	if(!.)
		return

	if(user.client?.view > 13)
		to_chat(user, SPAN_WARNING("You cannot use [src] while using optics."))
		return FALSE

	if(!VISR_LOWLIGHT_USAGE(FALSE))
		to_chat(user, SPAN_NOTICE("Your [src] is out of power! You'll need to recharge it."))
		return FALSE

	return TRUE

/obj/item/device/helmet_visor/night_vision/halo/on_update_sight(mob/user)

	if(lighting_alpha < 255)
		user.see_in_dark = 7
	user.lighting_alpha = lighting_alpha
	user.sync_lighting_plane_alpha()

/obj/item/device/helmet_visor/night_vision/halo/change_view(mob/user, new_size)
	if(new_size <= 13) // cannot use binos with NVO
		return
	var/obj/item/clothing/head/helmet/marine/attached_helmet = loc
	if(!istype(attached_helmet))
		return
	deactivate_visor(attached_helmet, user)
	to_chat(user, SPAN_NOTICE("You deactivate [src] on [attached_helmet]."))
	playsound_client(user.client, toggle_off_sound, null, 75)
	attached_helmet.active_visor = null
	attached_helmet.update_icon()
	var/datum/action/item_action/cycle_helmet_huds/cycle_action = locate() in attached_helmet.actions
	if(cycle_action)
		cycle_action.set_default_overlay()

#undef VISR_LOWLIGHT_USAGE

/obj/item/device/helmet_visor/night_vision/halo/unsc/activate_visor(obj/item/clothing/head/helmet/marine/attached_helmet, mob/living/carbon/human/user)
	. = ..()
	visr_wearer = user
	visr_helmet = attached_helmet

/obj/item/device/helmet_visor/night_vision/halo/unsc/deactivate_visor(obj/item/clothing/head/helmet/marine/attached_helmet, mob/living/carbon/human/user)
	. = ..()
	_clear_visr_outlines()
	visr_wearer = null
	visr_helmet = null

/obj/item/device/helmet_visor/night_vision/halo/unsc/proc/_clear_visr_outlines()
	for(var/mob/M in outlined_mobs)
		if(!QDELETED(M))
			M.remove_filter("visr_outline")
	outlined_mobs.Cut()

/obj/item/device/helmet_visor/night_vision/halo/unsc/proc/_get_visr_color(mob/living/target)
	if(isxeno(target))
		return "#FF0000FF"
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		if(H.faction in FACTION_LIST_UNSC)
			return "#00FF00FF"
	if((target.faction == FACTION_INSURGENT || target.faction == FACTION_COVENANT) || (target.faction in FACTION_LIST_COVENANT))
		return "#FF0000FF"
	return "#FFFF00FF"

/obj/item/device/helmet_visor/night_vision/halo/unsc/process(delta_time)
	. = ..()
	if(. == PROCESS_KILL)
		_clear_visr_outlines()
		return PROCESS_KILL
	if(!visr_wearer || QDELETED(visr_wearer) || !visr_helmet || QDELETED(visr_helmet))
		_clear_visr_outlines()
		return PROCESS_KILL
	if(visr_wearer.head != visr_helmet)
		_clear_visr_outlines()
		return

	var/list/current_mobs = list()
	for(var/mob/living/M in range(7, visr_wearer))
		if(M == visr_wearer || M.stat == DEAD)
			continue
		current_mobs += M

	for(var/mob/M in outlined_mobs.Copy())
		if(!(M in current_mobs) || QDELETED(M))
			if(!QDELETED(M))
				M.remove_filter("visr_outline")
			outlined_mobs -= M

	var/obj/item/clothing/head/helmet/marine/odst/odst_helm = visr_helmet
	if(!odst_helm || odst_helm.iff_enabled)
		for(var/mob/living/M in current_mobs)
			M.add_filter("visr_outline", 2, list("type" = "outline", "color" = _get_visr_color(M), "size" = 1))
			outlined_mobs |= M
