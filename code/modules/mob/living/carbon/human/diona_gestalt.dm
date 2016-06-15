//This file defines variables and functions specific to diona worker gestalts, not used by nymphs
/mob/living/carbon/human/diona
	var/datum/dionastats/DS

	//Diona time variables, these differ slightly between a gestalt and a nymph. All values are times in seconds
	var/energy_duration = 120//How long this diona can exist in total darkness before its energy runs out
	var/dark_consciousness = 120//How long this diona can stay on its feet and keep moving in darkness after energy is gone.
	var/dark_survival = 180//How long this diona can survive in darkness after energy is gone, before it dies
	composition_reagent = "nutriment"//Dionae are plants, so eating them doesn't give animal protein

/mob/living/carbon/human/diona/set_species(var/new_species, var/default_colour)
	.=..()
	setup_dionastats()


/mob/living/carbon/human/diona/handle_environment(datum/gas_mixture/environment)
	.=..()
	diona_handle_light(DS)

/mob/living/carbon/human/diona/verb/check_light()
	set category = "Abilities"
	set name = "Check light level"
	var/turf/T = src.loc
	var/atom/movable/lighting_overlay/L = locate(/atom/movable/lighting_overlay) in T
	if(L)
		var/light_amount = min(10,L.lum_r + L.lum_g + L.lum_b)
		usr << "The light level here is [light_amount]"

//1.5 is the maximum energy that can be lost per proc
//2.1 is the approximate delay between procs
/mob/living/carbon/human/diona/proc/setup_dionastats()
	var/MLS = (1.5 / 2.1)//Maximum (energy) lost per second, in total darkness
	DS = new/datum/dionastats()
	DS.max_energy = energy_duration * MLS
	DS.max_health = maxHealth*2
	DS.stored_energy = DS.max_energy
	DS.pain_factor = (100 / dark_consciousness) / MLS
	DS.trauma_factor = (DS.max_health / dark_survival) / MLS
	DS.dionatype = 1//Gestalt

	for (var/organ in internal_organs)
		if (istype(organ, /obj/item/organ/diona/node))
			DS.light_organ = organ