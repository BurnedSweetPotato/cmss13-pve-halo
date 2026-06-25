// ============================================================
// Covenant Food Items, Food Nipple, Food Vendors, Food Crates
// Ported from HaloSpaceStation13-alpha.
// ============================================================

// ---- Food Items --------------------------------------------

/obj/item/reagent_container/food/snacks/covenant
	icon = 'modular_pve_halo/icons/covenant/items/covenant_food.dmi'
	/// How much nutriment reagent is added on Initialize.
	var/nutriment_amt = 3

/obj/item/reagent_container/food/snacks/covenant/Initialize(mapload)
	. = ..()
	reagents.add_reagent("nutriment", nutriment_amt)

// Irukan bar — the Covenant "ration" food, eaten by all species.
/obj/item/reagent_container/food/snacks/covenant/irukanbar
	name = "irukan bar"
	desc = "A hard bar of irukan. It doesn't look very appealing, but it's dense with nutrients."
	icon_state = "Irukan_bar"
	bitesize = 3
	nutriment_amt = 3
	center_of_mass = "x=16;y=12"

// Thornbeast steak — Jiralhanae preferred meal.
/obj/item/reagent_container/food/snacks/covenant/thornbeast
	name = "thornbeast steak"
	desc = "A cutlet of thornbeast steak. Looks appealing, but only lightly grilled."
	icon_state = "thornbeast_steak"
	bitesize = 4
	nutriment_amt = 5
	center_of_mass = "x=16;y=12"

// Thornbeast thorn — byproduct, also edible.
/obj/item/reagent_container/food/snacks/covenant/thornbeast/thorn
	name = "thornbeast thorn"
	desc = "A thorn of a thornbeast. It looks edible...sorta."
	icon_state = "thornbeast_thorn"
	bitesize = 2
	nutriment_amt = 8

// Colo steak — Sangheili preferred meal.
/obj/item/reagent_container/food/snacks/covenant/colo
	name = "colo steak"
	desc = "A nicely grilled steak of alien origin."
	icon_state = "Colo_steak"
	bitesize = 5
	nutriment_amt = 4
	center_of_mass = "x=16;y=12"

// Uoi steak — Kig-Yar preferred meal.
/obj/item/reagent_container/food/snacks/covenant/uoi
	name = "uoi steak"
	desc = "A purple steak dusted with an odd powder. Smells faintly acidic."
	icon_state = "Uoi_steak"
	bitesize = 6
	nutriment_amt = 3
	center_of_mass = "x=16;y=12"

// ---- Food Nipple -------------------------------------------
// A wall-mounted fluid dispenser used by Unggoy to drink methane-nutrient mix.
// Only Unggoy may use it; doing so restores their nutrition and plays a voiceline.

/obj/structure/food_nipple
	name = "Grunt food nipple"
	desc = "Boy I sure hope you worked up a big grunty thirst!"
	icon = 'modular_pve_halo/icons/covenant/structures/food_nipple.dmi'
	icon_state = "food nipple"
	density = TRUE
	anchored = TRUE

/obj/structure/food_nipple/attack_hand(mob/living/carbon/human/user)
	if(!ishuman(user))
		to_chat(user, SPAN_WARNING("You can't figure out how to use [src]."))
		return

	if(!isspeciesunggoy(user))
		to_chat(user, SPAN_WARNING("There's no way you are touching that."))
		return

	// Must be standing directly in front of the nipple.
	var/turf/forward = get_step(src, dir)
	if(get_turf(user) != forward)
		to_chat(user, SPAN_NOTICE("You must stand directly in front of [src] to drink from it."))
		return

	if(user.nutrition >= NUTRITION_NORMAL)
		to_chat(user, SPAN_NOTICE("You aren't thirsty right now."))
		return

	user.nutrition = min(user.nutrition + 150, NUTRITION_HIGH)
	user.visible_message(
		SPAN_NOTICE("[user] takes a long drink from [src], making satisfied gurgling noises."),
		SPAN_NOTICE("You gulp down the nutrient mix. Much better.")
	)
	playsound(src, 'modular_pve_halo/sound/covenant/food_nipple.ogg', 50, TRUE)

// ---- Food Vendors ------------------------------------------
// Decorative covenant vendors that dispense food items.
// Based on CM's cm_vending system.

/obj/structure/machinery/cm_vending/covenant/food
	name = "covenant food dispenser"
	desc = "A Covenant food dispenser stocked with rations for the lesser species."
	icon = 'modular_pve_halo/icons/covenant/structures/covendor.dmi'
	icon_state = "covendor"
	vendor_theme = VENDOR_THEME_COMPANY

/obj/structure/machinery/cm_vending/covenant/food/general
	name = "Covenant Lesser Species Food Dispenser"
	desc = "A Covenant food dispenser stocked with irukan bars — suitable for all species."
	listed_products = list(
		list("Irukan Bar",        5, /obj/item/reagent_container/food/snacks/covenant/irukanbar,   VENDOR_ITEM_REGULAR)
	)

/obj/structure/machinery/cm_vending/covenant/food/sangheili
	name = "Covenant Sangheili Food Dispenser"
	desc = "A food dispenser carrying provisions favoured by Sangheili warriors."
	listed_products = list(
		list("Colo Steak",        5, /obj/item/reagent_container/food/snacks/covenant/colo,         VENDOR_ITEM_REGULAR),
		list("Irukan Bar",        5, /obj/item/reagent_container/food/snacks/covenant/irukanbar,    VENDOR_ITEM_REGULAR)
	)

/obj/structure/machinery/cm_vending/covenant/food/jiralhanae
	name = "Covenant Jiralhanae Food Dispenser"
	desc = "A food dispenser carrying provisions favoured by Jiralhanae brutes."
	listed_products = list(
		list("Thornbeast Steak",  5, /obj/item/reagent_container/food/snacks/covenant/thornbeast,  VENDOR_ITEM_REGULAR),
		list("Thornbeast Thorn",  5, /obj/item/reagent_container/food/snacks/covenant/thornbeast/thorn, VENDOR_ITEM_REGULAR),
		list("Irukan Bar",        5, /obj/item/reagent_container/food/snacks/covenant/irukanbar,   VENDOR_ITEM_REGULAR)
	)

/obj/structure/machinery/cm_vending/covenant/food/kigyar
	name = "Covenant Kig-Yar Food Dispenser"
	desc = "A food dispenser carrying provisions favoured by Kig-Yar."
	listed_products = list(
		list("Uoi Steak",         5, /obj/item/reagent_container/food/snacks/covenant/uoi,          VENDOR_ITEM_REGULAR),
		list("Irukan Bar",        5, /obj/item/reagent_container/food/snacks/covenant/irukanbar,    VENDOR_ITEM_REGULAR)
	)

// ---- Food Crates -------------------------------------------

/obj/structure/closet/crate/covenant/food
	name = "covenant foodstuffs crate"
	desc = "A Covenant supply crate stocked with food rations."

/obj/structure/closet/crate/covenant/food/Initialize(mapload)
	. = ..()
	new /obj/item/reagent_container/food/snacks/covenant/irukanbar(src)
	new /obj/item/reagent_container/food/snacks/covenant/irukanbar(src)
	new /obj/item/reagent_container/food/snacks/covenant/irukanbar(src)
	new /obj/item/reagent_container/food/snacks/covenant/irukanbar(src)
	new /obj/item/reagent_container/food/snacks/covenant/irukanbar(src)

/obj/structure/closet/crate/covenant/food/sangheili
	name = "Sangheili ration crate"
	desc = "Field rations intended for Sangheili warriors."

/obj/structure/closet/crate/covenant/food/sangheili/Initialize(mapload)
	. = ..()
	new /obj/item/reagent_container/food/snacks/covenant/colo(src)
	new /obj/item/reagent_container/food/snacks/covenant/colo(src)
	new /obj/item/reagent_container/food/snacks/covenant/colo(src)
	new /obj/item/reagent_container/food/snacks/covenant/irukanbar(src)
	new /obj/item/reagent_container/food/snacks/covenant/irukanbar(src)

/obj/structure/closet/crate/covenant/food/jiralhanae
	name = "Jiralhanae ration crate"
	desc = "Field rations intended for Jiralhanae brutes."

/obj/structure/closet/crate/covenant/food/jiralhanae/Initialize(mapload)
	. = ..()
	new /obj/item/reagent_container/food/snacks/covenant/thornbeast(src)
	new /obj/item/reagent_container/food/snacks/covenant/thornbeast(src)
	new /obj/item/reagent_container/food/snacks/covenant/thornbeast/thorn(src)
	new /obj/item/reagent_container/food/snacks/covenant/irukanbar(src)
	new /obj/item/reagent_container/food/snacks/covenant/irukanbar(src)

/obj/structure/closet/crate/covenant/food/kigyar
	name = "Kig-Yar ration crate"
	desc = "Field rations intended for Kig-Yar."

/obj/structure/closet/crate/covenant/food/kigyar/Initialize(mapload)
	. = ..()
	new /obj/item/reagent_container/food/snacks/covenant/uoi(src)
	new /obj/item/reagent_container/food/snacks/covenant/uoi(src)
	new /obj/item/reagent_container/food/snacks/covenant/uoi(src)
	new /obj/item/reagent_container/food/snacks/covenant/irukanbar(src)
	new /obj/item/reagent_container/food/snacks/covenant/irukanbar(src)
