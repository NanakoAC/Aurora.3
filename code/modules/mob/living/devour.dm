//This file contains variables and helper functions for mobs that can eat other mobs

//There are two ways to eat a mob:
	//Swallowing whole can only be done if the mob is sufficiently small
		//It will place the mob inside you, and slowly digest it,
			//Digesting deals genetic damage to the victim,
			//drains blood from it,
				//and adds protein to your stomach, based on the quantitys.
			//Mob will be deleted from your contents when fully digested.
				//Mob is fully digested when it has taken genetic damage equal to its max health. This continues past death if necessary

	//Devouring eats the mob piece by piece. Taking a bite periodically
		//Each bite deals genetic damage, and drains blood.
			//Adds protein to your stomach based on quantities.
		//Mob is fully digested when it has taken genetic damage equal to its max health.  This continues past death if necessary
		//Devouring is interrupted if you or the mob move away from each other, or if the eater gets disabled.

#define PPM	9//Protein per meat, used for calculating the quantity of protein in an animal


//Blacklists of mobs that can be excluded from eating by flags in the bitfield
var/list/humanoid_mobs_specific = list( /mob/living/carbon/human,
	/mob/living/carbon/human/bst,
	/mob/living/carbon/human/skrell,
	/mob/living/carbon/human/unathi,
	/mob/living/carbon/human/diona,
	/mob/living/carbon/human/tajaran,
	/mob/living/carbon/human/vox,
	/mob/living/carbon/human/machine,
	/mob/living/carbon/human/bug

	)

var/list/humanoid_mobs_inclusive = list(
	/mob/living/simple_animal/hostile/pirate,
	/mob/living/simple_animal/hostile/russian,
	/mob/living/simple_animal/hostile/syndicate
	)

var/list/synthetic_mobs_specific = list(
	/mob/living/carbon/human/machine,
	/mob/living/simple_animal/hostile/retaliate/malf_drone,
	/mob/living/simple_animal/hostile/viscerator,
	/mob/living/simple_animal/spiderbot
	)


var/list/synthetic_mobs_inclusive = list( /mob/living/silicon,
	/mob/living/simple_animal/hostile/hivebot,
	/mob/living/bot
	)

var/list/wierd_mobs_specific = list(/mob/living/simple_animal/adultslime)

var/list/wierd_mobs_inclusive = list( /mob/living/simple_animal/construct,
	/mob/living/simple_animal/shade,
	/mob/living/simple_animal/slime,
	/mob/living/simple_animal/hostile/faithless,
	/mob/living/carbon/slime
	)



//Flags for the eat_types variable, a bitfield of what can or can't be eaten
#define TYPE_ORGANIC	1//Almost any creature under /mob/living/carbon
#define	TYPE_SYNTHETIC	2//Everything under /mob/living/silicon, plus IPCs, viscerators
#define TYPE_HUMANOID	4//Humans, skrell, unathi, tajara, vaurca, diona, vox
#define TYPE_WIERD		8//Slimes, constructs, demons, and other creatures of a magical or bluespace nature.
/mob/living/var/swallowed_mob = 0
//This is set true if there are any mobs in this mob's contents. they will be slowly digested.
//just used as a boolean to minimise extra processing


/mob/living/proc/attempt_devour(var/mob/living/victim, var/eat_types, var/mouth_size = null)
	//This function will attempt to eat the victim,
	//either by swallowing them if they're small enough, or starting to devour them otherwise
		//If a mouth_size is passed in, it will be used instead of this mob's size, for determining whether the victim is small enough to swallow
	//This function is the main gateway to devouring, and will have all the safety checks
	if (victim == src)
		src << "You can't eat yourself!"
		return 0

	if (!src.Adjacent(victim))
		src << "That creature is too far away, move closer!"
		return 0

	if (!victim.mob_size || !src.mob_size)
		src << "Error, no mob size defined!"
		return 0

	if (!is_valid(victim, eat_types))
		src << "You can't eat that type of creature!"
		return 0

	if (!mouth_size)
		mouth_size = src.mob_size

	if (victim.mob_size <= mouth_size)
		swallow(victim, mouth_size)
	else
		devour_gradual(victim,mouth_size)



//This function checks against a list to see if the mob is in it.
//Any specified types are checked against exactly, using ==, not istype
//Any types ending in * will be tested with isType
/proc/mob_listed(var/mob/living/test, var/list/toCheck, var/specific = 0)
	for (var/i in toCheck)
		if (specific)
			if (test.type == i)
				return 1
		else
			if (istype(test, i))
				return 1
	return 0







/mob/living/proc/swallow(var/mob/living/victim, var/mouth_size)
	//This function will move the victim inside the eater's contents.. There they will be digested over time

	var/swallow_time = max(3 + (victim.mob_size * victim.mob_size) - mouth_size, 3)
	src.visible_message("[src] starts swallowing [victim]","You start swallowing [victim], this will take approximately [swallow_time] seconds")
	var/turf/ourloc = src.loc
	var/turf/victimloc = victim.loc
	if (do_mob(src, victim, swallow_time*10))
		victim.loc = src
		stomach_contents.Add(victim)
	else if (victimloc != victim.loc)
		src << "[victim] moved away, you need to keep it still. Try grabbing, stunning or killing it first."
	else if (ourloc != src.loc)
		src << "You moved! Can't eat if you move away from the victim"
	else
		src << "Swallowing failed!"//reason unknown, maybe the eater got stunned?




/mob/living/proc/devour_gradual(var/mob/living/victim, var/mouth_size)
	//This function will start consuming the victim by taking bites out of them.
	//Victim or attacker moving will interrupt it
	//A bite will be taken every 4 seconds
	var/bite_delay = 4
	var/bite_size = mouth_size * 0.5
	var/num_bites_needed = (victim.mob_size*victim.mob_size)/bite_size//total bites needed to eat it from full health
	var/PEPB = 1/num_bites_needed//Percentage eaten per bite
	var/turf/ourloc = src.loc
	var/turf/victimloc = victim.loc
	var/messes = 0//number of bloodstains we've placed
	var/datum/reagents/vessel = get_vessel(victim)
	world << "Vessel fetched + [vessel]"
	if(!victim.composition_reagent_quantity)
		victim.calculate_composition()

	var/victim_maxhealth = victim.maxHealth//We cache this here incase we need to edit it, for example, for humans and anything else that doesn't die until negative health

	//Now, incase we're resuming an earlier feeding session on the same creature
	//We calculate the actual bites needed to fully eat it based on how eaten it already is
	if (victim.cloneloss)
		var/percentageDamaged = victim.cloneloss / victim_maxhealth
		var/percentageRemaining = 1 - percentageDamaged
		num_bites_needed = percentageRemaining / PEPB

	var/time_needed_seconds = num_bites_needed*bite_delay//in seconds for now
	var/time_needed_minutes
	var/time_needed_string
	if (time_needed_seconds > 60)
		time_needed_minutes = round((time_needed_seconds/60))
		time_needed_seconds = time_needed_seconds % 60
		time_needed_string = "[time_needed_minutes] minutes and [time_needed_seconds] seconds"
	else
		time_needed_string = "[time_needed_seconds] seconds"


	src.visible_message("[src] starts devouring [victim]","You start devouring [victim], this will take approximately [time_needed_string]. You and the victim must remain still to continue, but you can interrupt feeding anytime and leave with what you've already eaten.")

	var/i = 0
	for (i=0;i < num_bites_needed;i++)
		if(do_mob(src, victim, bite_delay*10))
			face_atom(victim)
			victim.adjustCloneLoss(victim_maxhealth*PEPB)
			victim.adjustHalLoss(victim_maxhealth*PEPB*5)//Being eaten hurts!
			src.ingested.add_reagent(victim.composition_reagent, victim.composition_reagent_quantity*PEPB)
			src.visible_message("[src] bites a chunk out of [victim]",bitemessage(victim))
			if (messes < victim.mob_size - 1)
				handle_devour_mess(src, victim, vessel)
			if (victim.cloneloss >= victim_maxhealth)
				src.visible_message("[src] finishes devouring [victim]","You finish devouring [victim]")
				if (victim.mob_size >= 3)
					handle_devour_mess(src, victim, vessel, 1)
				qdel(victim)
				break
		else
			if (victimloc != victim.loc)
				src << "[victim] moved away, you need to keep it still. Try grabbing, stunning or killing it first."
			else if (ourloc != src.loc)
				src << "You moved! Devouring cancelled"
			else
				src << "Devouring Cancelled"//reason unknown, maybe the eater got stunned?
			break



//this function gradually digests things inside the mob's contents.
//It is called from life.dm. Any creatures that don't want to digest their contents simply don't call it
/mob/living/proc/handle_stomach()
	for(var/mob/living/M in stomach_contents)
		if(M.loc != src)//if something somehow escaped the stomach, then we remove it
			stomach_contents.Remove(M)
			continue

		if(!M.composition_reagent_quantity)
			M.calculate_composition()

		var/digestion_power = (((mob_size * mob_size)/10) / (M.mob_size * M.mob_size))
		var/digestion_time = digestion_power * 60//Number of seconds it will take to digest in total
		var/DPPP = 1 / (digestion_time / 2.1)//Digestion percentage per proc
		M.adjustCloneLoss(M.maxHealth*DPPP)
		//Digestion power is how much of the creature we can digest per minute. Calculated as a tenth of our mob size squared, divided by the victim's mob size squared
		//If the resulting value is >1, digestion will take under a minute.
		src.ingested.add_reagent(M.composition_reagent, M.composition_reagent_quantity*DPPP)
		if ((M.stat != DEAD) && (M.cloneloss > (M.maxHealth*0.5)))//If we've consumed half of the victim, then it dies
			M.death()
			M.stat = DEAD //Just in case the death function doesn't set it
			src << "Your stomach feels a little more relaxed as [M] finally stops fighting"

		if (M.cloneloss >= M.maxHealth)//If we've consumed all of it, then digestion is finished.
			stomach_contents.Remove(M)
			src << "Your stomach feels a little more empty as you finish digesting [M]"
			qdel(M)



//Helpers
/proc/bitemessage(var/mob/living/victim)
	return pick("You take a bite out of [victim]",
	"You rip a chunk off of [victim]",
	"You consume a piece of [victim]",
	"You feast upon your prey",
	"You chow down on [victim]",
	"You gobble [victim]'s flesh")

/proc/find_type(var/mob/living/test)
	//This function returns a bitfield indicating what type(s) the passed mob is.
	//Synthetic and wierd are exclusive from organic. We assume it's organic if it's not either of those
	var/mobtypes = 0

	if (mob_listed(test, synthetic_mobs_specific,1))
		mobtypes |= TYPE_SYNTHETIC
	else if (mob_listed(test, synthetic_mobs_inclusive,0))
		mobtypes |= TYPE_SYNTHETIC

	if (mob_listed(test, wierd_mobs_specific,1))
		mobtypes |= TYPE_WIERD
	else if (mob_listed(test, wierd_mobs_inclusive,0))
		mobtypes |= TYPE_WIERD

	if (!(mobtypes & TYPE_WIERD) && !(mobtypes & TYPE_SYNTHETIC))
		mobtypes |= TYPE_ORGANIC


	if (mob_listed(test, humanoid_mobs_specific,1))
		mobtypes |= TYPE_HUMANOID
	else if (mob_listed(test, humanoid_mobs_inclusive,0))
		mobtypes |= TYPE_HUMANOID

	return mobtypes

/proc/handle_devour_mess(var/mob/user, var/mob/victim, var/datum/reagents/vessel, var/finish = 0)
	//The maximum number of blood placements is equal to the mob size of the victim
	//We will use one blood placement on each of the following, in this order
		//Bloodying the victim's tile
		//Bloodying the attacker, if possible
		//Bloodying the attacker's tile
	//After that, we will allocate the remaining blood placements to random tiles around the victim and attacker, until either all are used or victim is dead
	var/datum/reagent/blood/B = vessel.reagent_list[/datum/reagent/blood]
	world << "handlemess + [vessel]"
	if (!turf_hasblood(get_turf(victim)))
		world << "Victimloc has no blood, adding it +[vessel]"
		devour_add_blood(victim, get_turf(victim), vessel)

	else if (!user.blood_DNA)
		world << "Attackerhands has no blood, adding it"
		//if this blood isn't already in the list, add it
		user.blood_DNA = list(B.data["blood_DNA"])
		user.blood_color = B.data["blood_color"]
		user.update_inv_gloves()	//handles bloody hands overlays and updating
		user.verbs += /mob/living/carbon/human/proc/bloody_doodle
		return 1 //we applied blood to the item

	else if (!turf_hasblood(get_turf(user)))
		world << "Attackerloc has no blood, adding it"
		devour_add_blood(victim, get_turf(user), vessel)

	if (finish)
		world << "Adding gibs"
		//var/obj/effect/decal/cleanable/blood/gibs/gib =
		new /obj/effect/decal/cleanable/blood/gibs(get_turf(victim))


/proc/devour_add_blood(var/mob/living/M, var/turf/location, var/datum/reagents/vessel)
	for(var/datum/reagent/blood/source in vessel.reagent_list)
		var/obj/effect/decal/cleanable/blood/B = new /obj/effect/decal/cleanable/blood(location)

		// Update appearance.
		if(source.data["blood_colour"])
			B.basecolor = source.data["blood_colour"]
			B.update_icon()
			world << "Setting colour"

		// Update blood information.
		if(source.data["blood_DNA"])
			B.blood_DNA = list()
			world << "Setting DNA 1"
			if(source.data["blood_type"])
				B.blood_DNA[source.data["blood_DNA"]] = source.data["blood_type"]
				world << "Setting DNA 2a"
			else
				B.blood_DNA[source.data["blood_DNA"]] = "O+"
				world << "Setting DNA 2b"

		// Update virus information.
		if(source.data["virus2"])
			B.virus2 = virus_copylist(source.data["virus2"])
			world << "copying virus"

		B.fluorescent  = 0
		B.invisibility = 0
/*

/turf/simulated/add_blood(mob/living/carbon/human/M as mob)
	if (!..())
		return 0

	if(istype(M))
		for(var/obj/effect/decal/cleanable/blood/B in contents)
			if(!B.blood_DNA)
				B.blood_DNA = list()
			if(!B.blood_DNA[M.dna.unique_enzymes])
				B.blood_DNA[M.dna.unique_enzymes] = M.dna.b_type
				B.virus2 = virus_copylist(M.virus2)
			return 1 //we bloodied the floor
		blood_splatter(src,M.get_blood(M.vessel),1)
		return 1 //we bloodied the floor
	return 0
*/



/proc/get_vessel(var/mob/bleeder)
	if(istype(bleeder, /mob/living/carbon/human))
		var/mob/living/carbon/human/H = bleeder
		return H.vessel

	else
		//we make a new vessel for whatever creature we're devouring. this allows blood to come from creatures that can't normally bleed
		var/datum/reagents/vessel = new/datum/reagents(600)
		vessel.add_reagent("blood",560)
		for(var/datum/reagent/blood/B in vessel.reagent_list)
			if(B.id == "blood")
				B.data = list(	"donor"=bleeder,"viruses"=null,"species"=bleeder.name,"blood_DNA"=bleeder.name,"blood_colour"= "#a10808","blood_type"=null,	\
								"resistances"=null,"trace_chem"=null, "virus2" = null, "antibodies" = list())
				B.color = B.data["blood_colour"]
		return vessel


/proc/turf_hasblood(/var/turf/test)
	for (var/obj/effect/decal/cleanable/blood/b in test)
		return 1
	return 0

/proc/is_valid(var/mob/living/test, var/eat_types)
	var/mobtypes = find_type(test)//We find a bitfield of types for the victim

	//Then for each type the victim has, we test if we're allowed to eat that type.
	//eat_types must contain all types that the mob has. For example we need both humanoid and synthetic to eat an IPC
	if (mobtypes & TYPE_SYNTHETIC)
		if (!(eat_types & TYPE_SYNTHETIC))
			return 0
	if (mobtypes & TYPE_HUMANOID)
		if (!(eat_types & TYPE_HUMANOID))
			return 0
	if (mobtypes & TYPE_WIERD)
		if (!(eat_types & TYPE_WIERD))
			return 0
	if (mobtypes & TYPE_ORGANIC)
		if (!(eat_types & TYPE_ORGANIC))
			return 0

	//If we get here, none of the checks have failed, the mob must be valid!
	return 1

/mob/living/proc/calculate_composition()
	if (!composition_reagent)//if no reagent has been set, then we'll set one
		var/type = find_type(src)
		if (type & TYPE_SYNTHETIC)
			src.composition_reagent = "iron"
		else
			src.composition_reagent = "protein"

	//if the mob is a simple animal with a defined meat quantity
	if (istype(src, /mob/living/simple_animal))
		var/mob/living/simple_animal/SA = src
		if (SA.meat_amount)
			src.composition_reagent_quantity = SA.meat_amount*1.3*PPM

		//The quantity of protein is based on the meat_amount, but multiplied by 1.3

	var/size_reagent = (src.mob_size * src.mob_size) * 2//The quantity of protein is set to 2x mob size squared
	if (size_reagent > src.composition_reagent_quantity)//We take the larger of the two
		src.composition_reagent_quantity = size_reagent
	world << "[src] [src.composition_reagent] quantity is [src.composition_reagent_quantity]"

