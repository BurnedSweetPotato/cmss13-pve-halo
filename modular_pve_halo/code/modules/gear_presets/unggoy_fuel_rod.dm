// Unggoy Heavy (Fuel Rod Cannon) — gear preset and support proc.

// Allow fuel rod magazines to be stored in any Covenant belt.
/obj/item/storage/belt/marine/covenant
	can_hold = list(
		/obj/item/attachable/bayonet,
		/obj/item/device/flashlight/flare,
		/obj/item/ammo_magazine/rifle,
		/obj/item/ammo_magazine/smg,
		/obj/item/ammo_magazine/pistol,
		/obj/item/ammo_magazine/revolver,
		/obj/item/ammo_magazine/sniper,
		/obj/item/ammo_magazine/handful,
		/obj/item/explosive/grenade,
		/obj/item/explosive/mine,
		/obj/item/reagent_container/food/snacks,
		/obj/item/ammo_magazine/needler_crystal,
		/obj/item/ammo_magazine/carbine,
		/obj/item/ammo_magazine/fuel_rod,
	)
	bypass_w_limit = list(
		/obj/item/ammo_magazine/rifle,
		/obj/item/ammo_magazine/smg,
		/obj/item/ammo_magazine/needler_crystal,
		/obj/item/ammo_magazine/carbine,
		/obj/item/ammo_magazine/fuel_rod,
	)

/datum/equipment_preset/proc/add_fuel_rod_package(mob/living/carbon/human/new_human)
	if(!istype(new_human))
		return
	// Gun in suit storage slot, belt packed with spare magazines.
	new_human.equip_to_slot_or_del(new /obj/item/weapon/gun/fuel_rod_cannon(new_human), WEAR_J_STORE)
	new_human.equip_to_slot_or_del(new /obj/item/ammo_magazine/fuel_rod(new_human), WEAR_IN_BELT)
	new_human.equip_to_slot_or_del(new /obj/item/ammo_magazine/fuel_rod(new_human), WEAR_IN_BELT)
	new_human.equip_to_slot_or_del(new /obj/item/ammo_magazine/fuel_rod(new_human), WEAR_IN_BELT)
	new_human.equip_to_slot_or_del(new /obj/item/ammo_magazine/fuel_rod(new_human), WEAR_IN_BELT)

/datum/equipment_preset/covenant/unggoy/heavy/fuel_rod_cannon
	name = "Unggoy Heavy (Fuel Rod Cannon)"

/datum/equipment_preset/covenant/unggoy/heavy/fuel_rod_cannon/load_gear(mob/living/carbon/human/new_human)
	add_grunt_basics(new_human)
	add_grunt_heavy(new_human)
	add_fuel_rod_package(new_human)
