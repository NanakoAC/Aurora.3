
//Created because humans have these
/mob/living/carbon/alien/diona/var/datum/reagents/vessel
/mob/living/carbon/alien/diona/var/list/internal_organs_by_name = list() // so internal organs have less ickiness too

//Diona time variables, these differ slightly between a gestalt and a nymph. All values are times in seconds
/mob/living/carbon/alien/diona
	var/energy_duration = 144//The time in seconds that this diona can exist in total darkness before its energy runs out
	var/dark_consciousness = 144//How long this diona can stay on its feet and keep moving in darkness after energy is gone.
	var/dark_survival = 216//How long this diona can survive in darkness after energy is gone, before it dies
	var/datum/dionastats/DS


/mob/living/carbon/alien/diona
	name = "diona nymph"
	voice_name = "diona nymph"
	adult_form = /mob/living/carbon/human
	speak_emote = list("chirrups")
	icon_state = "nymph"
	language = "Rootspeak"
	death_msg = "expires with a pitiful chirrup..."
	universal_understand = 0
	universal_speak = 0      // Dionaea do not need to speak to people other than other dionaea.
	holder_type = /obj/item/weapon/holder/diona

/mob/living/carbon/alien/diona/New()

	..()
	//species = all_species[]
	verbs += /mob/living/carbon/alien/diona/proc/merge
	set_species("Diona")
	setup_dionastats()

/mob/living/carbon/alien/diona/start_pulling(var/atom/movable/AM)
	//TODO: Collapse these checks into one proc (see pai and drone)
	if(istype(AM,/obj/item))
		var/obj/item/O = AM
		if(O.w_class > 2)
			src << "<span class='warning'>You are too small to pull that.</span>"
			return
		else
			..()
	else
		src << "<span class='warning'>You are too small to pull that.</span>"
		return

/mob/living/carbon/alien/diona/put_in_hands(var/obj/item/W) // No hands.
	W.loc = get_turf(src)
	return 1



//Functions duplicated from humans, albeit slightly modified
/mob/living/carbon/alien/diona/proc/set_species(var/new_species)
	world << "Calling setspecies for [src]"
	if(!dna)
		if(!new_species)
			new_species = "Human"
	else
		if(!new_species)
			new_species = dna.species
		else
			dna.species = new_species

	// No more invisible screaming wheelchairs because of set_species() typos.
	if(!all_species[new_species])
		new_species = "Human"

	if(species)

		if(species.name && species.name == new_species)
			return
		if(species.language)
			remove_language(species.language)
		if(species.default_language)
			remove_language(species.default_language)
		// Clear out their species abilities.
		species.remove_inherent_verbs(src)
		holder_type = null

	species = all_species[new_species]
	world << "Species Set for [src]"
	if(species.language)
		add_language(species.language)
		world << "language set for [src]"

	if(species.default_language)
		world << "Dlanguage set for [src]"
		add_language(species.default_language)

	if(species.holder_type)
		world << "holder type set for [src]"
		holder_type = species.holder_type

	icon_state = lowertext(species.name)

	species.handle_post_spawn(src)

	maxHealth = species.total_health


	spawn(0)
		regenerate_icons()
		make_blood()

	// Rebuild the HUD. If they aren't logged in then login() should reinstantiate it for them.
	if(client && client.screen)
		client.screen.len = null
		if(hud_used)
			qdel(hud_used)
		hud_used = new /datum/hud(src)


	if(species)
		return 1
	else
		return 0

/mob/living/carbon/alien/diona/proc/make_blood()

	if(vessel)
		return

	vessel = new/datum/reagents(600)
	vessel.my_atom = src

	if(species && species.flags & NO_BLOOD) //We want the var for safety but we can do without the actual blood.
		return

	vessel.add_reagent("blood",560)
	spawn(1)
		fixblood()

/mob/living/carbon/alien/diona/proc/fixblood()
	for(var/datum/reagent/blood/B in vessel.reagent_list)
		if(B.id == "blood")
			B.data = list(	"donor"=src,"viruses"=null,"species"=species.name,"blood_DNA"=dna.unique_enzymes,"blood_colour"= species.blood_color,"blood_type"=dna.b_type,	\
							"resistances"=null,"trace_chem"=null, "virus2" = null, "antibodies" = list())
			B.color = B.data["blood_colour"]


/mob/living/carbon/alien/diona/proc/setup_dionastats()
	var/MLS = (1.5 / 2.1)//Maximum energy lost per second, in total darkness
	DS = new/datum/dionastats()
	DS.max_energy = energy_duration * MLS
	DS.stored_energy = (DS.max_energy / 2)
	DS.max_health = maxHealth
	DS.pain_factor = (50 / dark_consciousness) / MLS
	DS.trauma_factor = (DS.max_health / dark_survival) / MLS
	DS.dionatype = 0//Nymph

//Overriding this function from /mob/living/carbon/alien/life.dm
/mob/living/carbon/alien/diona/handle_regular_status_updates()

	if(status_flags & GODMODE)	return 0

	if(stat == DEAD)
		blinded = 1
		silent = 0
	else
		updatehealth()
		handle_stunned()
		handle_weakened()
		if(health <= 0)
			death()
			blinded = 1
			silent = 0
			return 1

		if (halloss > 50)
			paralysis = 8


		if(paralysis && paralysis > 0)
			handle_paralysed()
			blinded = 1
			stat = UNCONSCIOUS

		if(sleeping)
			if (mind)
				if(mind.active && client != null)
					sleeping = max(sleeping-1, 0)
			blinded = 1
			stat = UNCONSCIOUS
		else if(resting)

		else
			stat = CONSCIOUS

		// Eyes and blindness.
		if(!has_eyes())
			eye_blind =  1
			blinded =    1
			eye_blurry = 1
		else if(eye_blind)
			eye_blind =  max(eye_blind-1,0)
			blinded =    1
		else if(eye_blurry)
			eye_blurry = max(eye_blurry-1, 0)

		//Ears
		if(sdisabilities & DEAF)	//disabled-deaf, doesn't get better on its own
			ear_deaf = max(ear_deaf, 1)
		else if(ear_deaf)			//deafness, heals slowly over time
			ear_deaf = max(ear_deaf-1, 0)
			ear_damage = max(ear_damage-0.05, 0)

		update_icons()

	return 1
