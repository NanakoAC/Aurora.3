//This function is for code that is shared by diona nymphs and gestalt
/mob/living/carbon/var/stored_energy
/mob/living/carbon/var/max_energy = 90


/mob/living/carbon/proc/diona_handle_light(var/datum/dionastats/DS)//Carbon is the highest common denominator between gestalts and nymphs. They will share light code
	//if light_organ is non null, then we're working with a gestalt. otherwise nymph
	var/light_amount = 1.5 //how much light there is in the place, affects receiving nutrition and healing
	var/light_factor = 1//used for  if a gestalt's response node is damaged. it will feed more slowly
	if (DS.light_organ)
		if (DS.light_organ.is_broken())
			light_factor = 0.55
		else if (DS.light_organ.is_bruised())
			light_factor = 0.8

	if(isturf(loc)) //else, there's considered to be no light
		var/turf/T = loc
		var/atom/movable/lighting_overlay/L = locate(/atom/movable/lighting_overlay) in T
		if(L)
			light_amount = min(4.5,L.lum_r + L.lum_g + L.lum_b)  //hardcapped to 4.5 so it's not abused by having a ton of flashlights
			light_amount = max(light_amount*light_factor,0)//Make sure light amount is >=0 and apply light factor

	light_amount -= 1.5//Light values > 1.5 will increase energy, <1.5 will decrease it
	DS.stored_energy += light_amount

	if(DS.stored_energy > DS.max_energy)
		DS.stored_energy = DS.max_energy

	if(DS.stored_energy > 0) //if there's enough energy stored then diona heal
		diona_handle_regeneration(DS)
	else	//If light is <=0 then it hurts instead

		//var/severity = DS.stored_energy - (DS.stored_energy*2)
		var/severity = !light_amount//Get a positive value which is the severity of the damage
		world << "[src] taking damage from darkness [severity]"
		adjustBruteLoss(severity*DS.trauma_factor)
		adjustHalLoss(severity*DS.pain_factor)
		stored_energy = 0//We reset the energy back to zero after calculating the damage. dont want it to go negative


/mob/living/carbon/proc/diona_handle_regeneration(var/datum/dionastats/DS)
	if (health >= 100 || DS.stored_energy < 1)//we need energy to heal
		return

	if (bruteloss > 0 && DS.stored_energy > 1)
		adjustBruteLoss(-1)
		DS.stored_energy -= 1

	if (fireloss > 0 && DS.stored_energy > 1)
		adjustFireLoss(-1)
		DS.stored_energy -= 1

	if (toxloss > 0 && DS.stored_energy > 1)
		adjustToxLoss(-1)
		DS.stored_energy -= 1

//Dionastats is an instanced object that diona will each create and hold a reference to.
//It's used to store information which are relevant to both types of diona, to save on adding variables to carbon
//Most of these values are calculated from information configured at authortime in either diona_nymph.dm or diona_gestalt.dm
/datum/dionastats
	var/max_energy//how much energy the diona can store. will determine how long its energy lasts in darkness
	var/stored_energy//how much is currently stored
	var/trauma_factor//Multiplied with severity to determine how much damage the diona takes in darkness
	var/pain_factor//Multiplied with severity to determine how much pain the diona takes in darkness

	var/obj/item/organ/diona/node/light_organ = null//The organ this gestalt uses to recieve light. This is left null for nymphs






/*
var/obj/item/organ/diona/node/light_organ = locate() in internal_organs
		if(light_organ && !light_organ.is_broken())
			var/light_amount = 0 //how much light there is in the place, affects receiving nutrition and healing
			if(isturf(loc)) //else, there's considered to be no light
				var/turf/T = loc
				var/atom/movable/lighting_overlay/L = locate(/atom/movable/lighting_overlay) in T
				if(L)
					light_amount = min(10,L.lum_r + L.lum_g + L.lum_b) - 2 //hardcapped so it's not abused by having a ton of flashlights
				else
					light_amount =  1
			nutrition += light_amount
			traumatic_shock -= light_amount

			if(species.flags & IS_PLANT)
				if(nutrition > 450)
					nutrition = 450
				if(light_amount >= 3) //if there's enough light, heal
					adjustBruteLoss(-(round(light_amount/2)))
					adjustFireLoss(-(round(light_amount/2)))
					adjustToxLoss(-(light_amount))
					adjustOxyLoss(-(light_amount))
					//TODO: heal wounds, heal broken limbs.

		if(species.light_dam)
			var/light_amount = 0
			if(isturf(loc))
				var/turf/T = loc
				var/atom/movable/lighting_overlay/L = locate(/atom/movable/lighting_overlay) in T
				if(L)
					light_amount = L.lum_r + L.lum_g + L.lum_b //hardcapped so it's not abused by having a ton of flashlights
				else
					light_amount =  10
			if(light_amount > species.light_dam) //if there's enough light, start dying
				take_overall_damage(1,1)
			else //heal in the dark
				heal_overall_damage(1,1)

				if(species.flags & IS_PLANT && (!light_organ || light_organ.is_broken()))
			if(nutrition < 200)
				take_overall_damage(2,0)
				traumatic_shock++
				*/