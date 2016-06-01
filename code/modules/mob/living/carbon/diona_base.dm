//This function is for code that is shared by diona nymphs and gestalt


/mob/living/carbon/proc/diona_handle_light(var/dionatype = 1)//Carbon is the highest common denominator between gestalts and nymphs. They will share light code
	//Dionatype 0 = Nymph
	//Dionatype 1 = Worker Gestalt
		//This variable is just future proofing incase we want them to behave differently
	var/light_amount = 5 //how much light there is in the place, affects receiving nutrition and healing
	if(isturf(loc)) //else, there's considered to be no light
		var/turf/T = loc
		var/atom/movable/lighting_overlay/L = locate(/atom/movable/lighting_overlay) in T
		if(L)
			light_amount = min(10,L.lum_r + L.lum_g + L.lum_b)  //hardcapped to 10 so it's not abused by having a ton of flashlights
			light_amount = max(light_amount,0)//Make sure light amount is >=0

	light_amount -= 5//Light values > 5 will increase energy, <5 will decrease it
	energy += light_amount

	if(energy > 500)
		energy = 500
	if(energy > 0) //if there's enough energy stored then diona heal
		adjustBruteLoss(-1)
		adjustFireLoss(-1)
		adjustToxLoss(-1)
		adjustOxyLoss(-1)
	else	//If light is <=0 then it hurts instead
		var/severity = energy - (energy*2)//Get a positive value which is the severity of the damage
		adjustOxyLoss(severity*0.2)
		adjustHalLoss(severity*0.8)//Damage is 20% suffocation, 80% halloss

		//This damage must be adjusted so that diona survive 180 seconds in total darkness