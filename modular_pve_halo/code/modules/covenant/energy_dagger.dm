// Sangheili Energy Dagger
//
// Stored inside the gauntlets. A button on the gauntlets deploys it into a free
// hand; pressing the button again (or the dagger being dropped) retracts it.

// ────────────────────────────────────────────────────────────
// Dagger item
// ────────────────────────────────────────────────────────────

/obj/item/weapon/energy_dagger
	name = "energy dagger"
	desc = "A compact energy blade integrated into Sangheili combat gauntlets. Extremely sharp and capable of bypassing most conventional armor."
	icon = 'icons/halo/obj/items/weapons/melee_by_faction/covenant/covenant_weapons.dmi'
	icon_state = "en_dag_deploy"
	item_state = "en_dag_deploy"
	w_class = SIZE_SMALL
	force = MELEE_FORCE_TIER_6  // 30
	throwforce = MELEE_FORCE_TIER_2  // 10
	sharp = IS_SHARP_ITEM_BIG
	edge = 1
	attack_verb = list("slashed", "stabbed", "cut", "impaled")
	hitsound = 'modular_pve_halo/sound/covenant/weapons/energy_dagger_hit.ogg'

	item_icons = list(
		WEAR_L_HAND = 'icons/halo/mob/humans/inhand/energy_dagger_inhand.dmi',
		WEAR_R_HAND = 'icons/halo/mob/humans/inhand/energy_dagger_inhand.dmi'
	)
	item_state_slots = list(
		WEAR_L_HAND = "en_dag_l_hand",
		WEAR_R_HAND = "en_dag_r_hand"
	)

	/// Reference back to the gauntlets that own this dagger
	var/obj/item/clothing/gloves/marine/sangheili/owner_gauntlets

/obj/item/weapon/energy_dagger/dropped(mob/user)
	. = ..()
	// Auto-retract: put it back into the gauntlets when dropped
	if(owner_gauntlets && !QDELETED(owner_gauntlets))
		owner_gauntlets.retract_dagger(user)

// ────────────────────────────────────────────────────────────
// Deploy action (appears as a button when gloves are worn)
// ────────────────────────────────────────────────────────────

/datum/action/item_action/deploy_energy_dagger
	name = "Deploy Energy Dagger"
	action_icon_state = "en_dag_handle"

/datum/action/item_action/deploy_energy_dagger/action_activate()
	. = ..()
	var/obj/item/clothing/gloves/marine/sangheili/gauntlets = target
	if(!istype(gauntlets))
		return
	gauntlets.toggle_dagger(owner)

// ────────────────────────────────────────────────────────────
// Gauntlet modifications
// ────────────────────────────────────────────────────────────

/obj/item/clothing/gloves/marine/sangheili
	actions_types = list(/datum/action/item_action/deploy_energy_dagger)

	/// The dagger stored inside the gauntlets
	var/obj/item/weapon/energy_dagger/stored_dagger

/obj/item/clothing/gloves/marine/sangheili/item_action_slot_check(mob/user, slot)
	return slot == WEAR_HANDS

/obj/item/clothing/gloves/marine/sangheili/Initialize()
	. = ..()
	stored_dagger = new /obj/item/weapon/energy_dagger(src)
	stored_dagger.owner_gauntlets = src

/obj/item/clothing/gloves/marine/sangheili/Destroy()
	QDEL_NULL(stored_dagger)
	return ..()

/obj/item/clothing/gloves/marine/sangheili/proc/toggle_dagger(mob/living/carbon/human/user)
	if(!stored_dagger || QDELETED(stored_dagger))
		return

	// Dagger is out in a hand — retract it
	if(stored_dagger.loc == user)
		retract_dagger(user)
		return

	// Dagger is stored — deploy it
	if(!user.put_in_active_hand(stored_dagger))
		if(!user.put_in_any_hand_if_possible(stored_dagger, disable_warning = TRUE))
			to_chat(user, SPAN_WARNING("You need a free hand to deploy your energy dagger."))
			return
	playsound(user, 'modular_pve_halo/sound/covenant/weapons/energy_dagger_deploy.ogg', 60, TRUE)

/obj/item/clothing/gloves/marine/sangheili/proc/retract_dagger(mob/living/carbon/human/user)
	if(!stored_dagger || QDELETED(stored_dagger))
		return
	// Pull the dagger out of the user's hand and back into the gauntlets
	if(ishuman(user) && stored_dagger.loc == user)
		user.drop_held_item(stored_dagger)
	stored_dagger.forceMove(src)
	playsound(user || src.loc, 'modular_pve_halo/sound/covenant/weapons/energy_dagger_retract.ogg', 50, TRUE)
