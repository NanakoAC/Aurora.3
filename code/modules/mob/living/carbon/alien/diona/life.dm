//Dionaea regenerate health and nutrition in light.
/mob/living/carbon/alien/diona/handle_environment(datum/gas_mixture/environment)
	if (stat != DEAD)
		diona_handle_light(DS)

/mob/living/carbon/alien/diona/handle_chemicals_in_body()
	chem_effects.Cut()
	analgesic = 0

	if(touching) touching.metabolize()
	if(ingested) ingested.metabolize()
	if(bloodstr) bloodstr.metabolize()

	// nutrition decrease
	if (nutrition > 0 && stat != 2)
		nutrition = max (0, nutrition - HUNGER_FACTOR)

	if (nutrition > max_nutrition)
		nutrition = max_nutrition

	//handle_trace_chems() implement this later maybe

	updatehealth()

	return


///mob/living/carbon/alien/diona/Life()
