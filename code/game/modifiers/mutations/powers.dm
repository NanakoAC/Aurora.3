//Gigantism, the new hulk.
//Doubles your mob size, sprite volume, and strength
/datum/modifier/mutation/giant
	id = "gigantism"
	var/added_strength = 0
	var/added_sizemod = 0
	var/added_mobsize = 0

/datum/modifier/mutation/giant/activate(var/feedback = 1)
	..()
	var/mob/living/L = target

	if (feedback)
		L << span("notice", "You feel a tremendous surge of power. Is the world getting smaller...?")

	added_strength = L.base_strength
	L.strength += added_strength

	added_sizemod = 0.25
	L.size_multiplier += added_sizemod

	var/newmobsize = sqrt((L.mob_size*L.mob_size)*2)
	added_mobsize = newmobsize - L.mob_size
	L.mob_size += added_mobsize

	L.update_scale(feedback)

/datum/modifier/mutation/giant/deactivate(var/feedback = 1)
	..()
	var/mob/living/L = target

	if (feedback)
		L << span("notice", "You feel smaller and weaker..")


	L.strength -= added_strength
	added_strength = 0

	L.size_multiplier -= added_sizemod
	added_sizemod = 0

	L.mob_size -= added_mobsize
	added_mobsize = 0

	L.update_scale(feedback)



//Dwarfism, the opposite of hulk.
//Halves your size, volume and strength
/datum/modifier/mutation/dwarf
	id = "dwarfism"
	var/added_strength = 0
	var/added_sizemod = 0
	var/added_mobsize = 0

/datum/modifier/mutation/dwarf/activate(var/feedback = 1)
	..()
	var/mob/living/L = target

	if (feedback)
		L << span("notice", "Is the world getting larger...?")

	added_strength = L.base_strength*-0.5

	L.strength += added_strength

	added_sizemod = -0.25
	L.size_multiplier += added_sizemod

	var/newmobsize = sqrt((L.mob_size*L.mob_size)*0.5)
	added_mobsize = newmobsize - L.mob_size
	L.mob_size += added_mobsize

	L.update_scale(feedback)

/datum/modifier/mutation/dwarf/deactivate(var/feedback = 1)
	..()
	var/mob/living/L = target

	if (feedback)
		L << span("notice", "You feel smaller and weaker..")


	L.strength -= added_strength
	added_strength = 0

	L.size_multiplier -= added_sizemod
	added_sizemod = 0

	L.mob_size -= added_mobsize
	added_mobsize = 0

	L.update_scale(feedback)