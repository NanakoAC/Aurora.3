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
		var/severity = light_amount*-1//Get a positive value which is the severity of the damage
		adjustBruteLoss(severity*DS.trauma_factor)
		adjustHalLoss(severity*DS.pain_factor, 1)
		DS.stored_energy = 0//We reset the energy back to zero after calculating the damage. dont want it to go negative

	diona_handle_lightmessages(DS)



/mob/living/carbon/proc/diona_handle_lightmessages(var/datum/dionastats/DS)
	//This function handles the RP messages that inform the diona player about their light/withering state
	//Lightstates:
	//1: Full. Go down from this state below 80%
	//2. average: Go up a state at 100%, go down a state at 50%
	//3. Subsisting: Go down from this state at 0.% light, go up from it at 40%
	//4: Pain: Go up to this state when light is negative and damage < 40. Go down from when damage >60
	//5: Critical:Go up to this state when damage < 100 and not paralysed. Go down from it when halloss hits 100 and you're paralysed
	//6: Dying: You've collapsed from pain and are dying. theres nothing below this but death
	DS.EP = DS.stored_energy / DS.max_energy

	if (DS.LMS == 1)//If we're full
		if (DS.EP <= 0.8)//But at <=80% energy
			DS.LMS = 2
			src << "<span class='warning'>The darkness makes you uncomfortable</span>"

	else if (DS.LMS == 2)
		if (DS.EP >= 0.99)
			DS.LMS = 1
			src << "You bask in the light"
		else if (DS.EP <= 0.4)
			DS.LMS = 3
			src << "<span class='warning'>You feel lethargic as your energy drains away. Find some light soon!</span>"

	else if (DS.LMS == 3)
		if (DS.EP >= 0.5)
			DS.LMS = 2
			src << "You feel a little more energised as you return to the light. Stay awhile"
		else if (DS.EP <= 0.0)
			DS.LMS = 4
			src << "<span class='danger'> You feel sensory distress as your tendrils start to wither in the darkness. You will die soon without light</span>"
	//From here down, we immediately return to state 3 if we get any light
	else
		if (DS.EP > 0.0)//If there's any light at all, we can be saved
			src << "Light! At long last. Treasure it, savour it, hold onto it"
			DS.LMS = 3
		else
			var/HP = diona_get_health(DS) / DS.max_health//HP  = health-percentage
			if (DS.LMS == 4)
				if (HP < 0.6)
					src << "<span class='danger'> The darkness burns. Your nymphs decay and wilt You are in mortal danger</span>"
					DS.LMS = 5

			else if (DS.LMS == 5)
				if (paralysis > 0)
					src << "<span class='danger'> Your body has reached critical integrity, it can no longer move. The end comes soon</span>"
					DS.LMS = 6
			else if (DS.LMS == 6)
				return




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

	if (halloss > 0 && DS.stored_energy > 1)
		adjustHalLoss(adjustHalLoss(-3, 1))
		DS.stored_energy -= 1

/mob/living/carbon/proc/diona_get_health(var/datum/dionastats/DS)
	if (DS.dionatype == 0)
		return health
	else
		return health+(maxHealth*0.5)



//Dionastats is an instanced object that diona will each create and hold a reference to.
//It's used to store information which are relevant to both types of diona, to save on adding variables to carbon
//Most of these values are calculated from information configured at authortime in either diona_nymph.dm or diona_gestalt.dm
/datum/dionastats
	var/max_energy//how much energy the diona can store. will determine how long its energy lasts in darkness
	var/stored_energy//how much is currently stored
	var/EP//Energy percentage.
	var/trauma_factor//Multiplied with severity to determine how much damage the diona takes in darkness
	var/pain_factor//Multiplied with severity to determine how much pain the diona takes in darkness
	var/max_health = 100

	var/obj/item/organ/diona/node/light_organ = null//The organ this gestalt uses to recieve light. This is left null for nymphs
	var/LMS = 1//Lightmessage state. Switching between states gives the user a message
	var/dionatype//0 = nymph, 1 = worker gestalt





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