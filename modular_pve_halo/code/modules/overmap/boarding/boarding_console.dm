// Boarding Console -- targets enemy ships, selects pods, launches

/obj/structure/machinery/computer/boarding_console
	name = "boarding control console"
	desc = "Identifies hostile vessels and coordinates the launch of boarding pods."
	icon = 'icons/obj/structures/machinery/computer.dmi'
	icon_state = "retro2b"

	/// ship_z of the currently targeted vessel, 0 = none
	var/target_z = 0
	/// Selected pod
	var/obj/vehicle/multitile/boarding_pod/selected_pod
	/// Delay before pod launches. 0 / 15 SECONDS / 30 SECONDS / 60 SECONDS
	var/launch_delay = 30 SECONDS
	/// TRUE while a countdown is running -- blocks double-launch
	var/launch_pending = FALSE

// ---- Right-click verb (works even without a TGUI rebuild) ---

/obj/structure/machinery/computer/boarding_console/verb/verb_set_delay()
	set name = "Set Launch Delay"
	set category = "Object"
	set src in oview(1)
	var/choice = tgui_input_list(usr, "Select launch delay:", "Launch Delay", list("Immediate (0s)", "15 seconds", "30 seconds (default)", "60 seconds"))
	switch(choice)
		if("Immediate (0s)")
			launch_delay = 0
		if("15 seconds")
			launch_delay = 15 SECONDS
		if("30 seconds (default)")
			launch_delay = 30 SECONDS
		if("60 seconds")
			launch_delay = 60 SECONDS
	if(choice)
		to_chat(usr, SPAN_NOTICE("Launch delay set to [launch_delay / 10] seconds."))

// ---- TGUI ---------------------------------------------------

/obj/structure/machinery/computer/boarding_console/attack_hand(mob/user)
	if(..())
		return
	tgui_interact(user)

/obj/structure/machinery/computer/boarding_console/tgui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "BoardingConsole", src.name)
		ui.open()

/obj/structure/machinery/computer/boarding_console/ui_state(mob/user)
	return GLOB.not_incapacitated_and_adjacent_state

/obj/structure/machinery/computer/boarding_console/ui_data(mob/user)
	var/list/data = list()

	// Scan live overmap tokens directly -- reliable regardless of init order
	var/list/targets = list()
	for(var/obj/effect/overmap/ship/OS in world)
		if(OS.z != GLOB.overmap_z)
			continue
		if(OS.ship_z == z)
			continue
		targets += list(list("name" = OS.name, "z" = OS.ship_z))
	data["targets"] = targets
	data["target_z"] = target_z

	var/list/pods = list()
	for(var/obj/vehicle/multitile/boarding_pod/P in world)
		if(P.z != z)
			continue
		pods += list(list(
			"ref"       = REF(P),
			"name"      = P.name,
			"status"    = P.get_pod_status(),
			"occupants" = P.get_occupant_count(),
			"capacity"  = P.passengers_slots
		))
	data["pods"] = pods
	data["selected_pod"] = selected_pod ? REF(selected_pod) : null

	data["launch_delay"] = launch_delay / 10
	data["launch_pending"] = launch_pending

	return data

/obj/structure/machinery/computer/boarding_console/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("select_target")
			var/new_z = text2num(params["z"])
			target_z = (new_z && new_z != z) ? new_z : 0
			return TRUE

		if("select_pod")
			var/obj/vehicle/multitile/boarding_pod/P = locate(params["ref"])
			if(!istype(P) || P.z != z || P.launched)
				return FALSE
			selected_pod = P
			return TRUE

		if("set_delay")
			if(launch_pending)
				return FALSE
			var/secs = text2num(params["delay"])
			switch(secs)
				if(0)
					launch_delay = 0
				if(15)
					launch_delay = 15 SECONDS
				if(30)
					launch_delay = 30 SECONDS
				if(60)
					launch_delay = 60 SECONDS
			return TRUE

		if("launch")
			if(launch_pending)
				return FALSE
			return _validate_and_start(ui.user)

// ---- Validation + async launch ------------------------------

/obj/structure/machinery/computer/boarding_console/proc/_validate_and_start(mob/user)
	if(!target_z)
		to_chat(user, SPAN_WARNING("No target vessel selected."))
		return FALSE

	if(!selected_pod || !istype(selected_pod))
		to_chat(user, SPAN_WARNING("No boarding pod selected."))
		return FALSE

	if(selected_pod.z != z)
		to_chat(user, SPAN_WARNING("Selected pod is no longer on this vessel."))
		selected_pod = null
		return FALSE

	if(selected_pod.launched)
		to_chat(user, SPAN_WARNING("That pod has already been deployed."))
		selected_pod = null
		return FALSE

	if(!selected_pod.interior || !selected_pod.interior.ready)
		to_chat(user, SPAN_WARNING("Pod interior is not ready."))
		return FALSE

	var/found = FALSE
	for(var/obj/effect/overmap/ship/OS in world)
		if(OS.z == GLOB.overmap_z && OS.ship_z == target_z)
			found = TRUE
			break
	if(!found)
		to_chat(user, SPAN_WARNING("Target vessel is no longer on sensors."))
		target_z = 0
		return FALSE

	var/obj/vehicle/multitile/boarding_pod/pod = selected_pod
	var/tz = target_z
	selected_pod = null
	launch_pending = TRUE

	pod.start_alarm()

	var/delay_secs = launch_delay / 10
	var/local_z = z
	for(var/mob/M in world)
		if(M.z == local_z && !isobserver(M))
			if(delay_secs > 0)
				to_chat(M, SPAN_LARGE(SPAN_BOLDANNOUNCE("BOARDING ACTION: Pod launch in [delay_secs] seconds! Stand clear.")))
			else
				to_chat(M, SPAN_LARGE(SPAN_BOLDANNOUNCE("BOARDING ACTION: Pod launching immediately!")))
			if(M.client)
				M.client << sound('sound/effects/generalquartersalarm.ogg', volume = 70)

	to_chat(user, SPAN_NOTICE("Launch sequence started. You may leave the console."))

	INVOKE_ASYNC(src, PROC_REF(_run_countdown), pod, tz, launch_delay)
	return TRUE

// ---- Helper -------------------------------------------------

/obj/structure/machinery/computer/boarding_console/proc/_broadcast(zl, msg)
	for(var/mob/M in world)
		if(M.z == zl && !isobserver(M))
			to_chat(M, msg)

// ---- Async countdown ----------------------------------------

/obj/structure/machinery/computer/boarding_console/proc/_run_countdown(obj/vehicle/multitile/boarding_pod/pod, target_z_snap, delay_ticks)
	set waitfor = FALSE

	if(delay_ticks > 0)
		if(delay_ticks > 30 SECONDS)
			sleep(delay_ticks - 30 SECONDS)
			if(!QDELETED(src) && !QDELETED(pod) && !pod.launched)
				_broadcast(z, SPAN_BOLDANNOUNCE("Pod launch in 30 seconds."))
			sleep(20 SECONDS)
			if(!QDELETED(src) && !QDELETED(pod) && !pod.launched)
				_broadcast(z, SPAN_BOLDANNOUNCE("Pod launch in 10 seconds."))
			sleep(10 SECONDS)
		else if(delay_ticks == 30 SECONDS)
			sleep(20 SECONDS)
			if(!QDELETED(src) && !QDELETED(pod) && !pod.launched)
				_broadcast(z, SPAN_BOLDANNOUNCE("Pod launch in 10 seconds."))
			sleep(10 SECONDS)
		else
			sleep(delay_ticks)

	launch_pending = FALSE

	if(QDELETED(src) || QDELETED(pod) || pod.launched)
		return

	var/found = FALSE
	for(var/obj/effect/overmap/ship/OS in world)
		if(OS.z == GLOB.overmap_z && OS.ship_z == target_z_snap)
			found = TRUE
			break
	if(!found)
		_broadcast(z, SPAN_WARNING("Boarding action aborted -- target vessel lost from sensors."))
		pod.stop_alarm()
		return

	if(!pod.launch(target_z_snap))
		_broadcast(z, SPAN_WARNING("Pod launch failed -- no valid landing zone on target vessel."))
