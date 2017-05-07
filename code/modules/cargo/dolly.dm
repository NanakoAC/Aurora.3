/*
A dolly, also known as a hand truck, is a a tool used in warehouses, docks, and other industrial professions
It uses leverage and wheels to allow a single average person to move heavy loads which would normally
take 2-3 strong men

In game terms, a dolly applies a fairly low mobility factor to an object or mob, greatly
reducing the strength needed to drag it around.

Any non-anchored object or mob can be loaded onto it, and the dolly will use the load's w_class,
but it will keep its own mobility factor, allowing it to be pulled around and take the object with it.

//Todo in future: As part of metaresearch, add an unlockable advanced version of the dolly, taking the form of an antigrav lifter that hovers around, and has a lower mobility factor
*/

/obj/structure/dolly
	name = "dolly"
	desc = "A tool used to allow a single person to move heavy loads. Drag a heavy object onto it, and then pull it around."
	w_class = 5
	mobility_factor = 0.65
	density = 0
	icon = 'icons/obj/tools/dolly.dmi' //This really doesnt need its own dmi but i couldnt think of any existing one for it
	icon_state = "dolly"
	var/atom/movable/cargo = null

/obj/structure/dolly/MouseDrop_T(var/atom/movable/C, mob/user)
	load(C, user)

/obj/structure/dolly/MouseDrop(var/atom/movable/C, mob/user)
	load(C, user)

/obj/structure/dolly/proc/load(var/atom/movable/C, var/mob/living/user)

	if (!istype(C))
		return

	if (cargo)
		user << span("warning", "\The [src] already has [cargo] on it! One item at a time.")
		return

	if (!Adjacent(C) || !istype(C.loc, /turf))
		user << span("warning", "\The [src] is too far from \the [C], move it closer!")
		return

	if (!Adjacent(user))
		user << span("warning", "You can't load anything from there, get closer to \the [src]")
		return

	if (C.anchored)
		user << span("warning", "\The [C] won't budge!")
		return

	var/newmass = 0
	if (istype(C, /obj))
		var/obj/O = C
		newmass = O.w_class
	else if (istype(C, /mob/living))
		var/mob/living/M = C
		newmass = M.mob_size

	if (!newmass)
		user << span("warning", "That isn't suitable for loading onto a dolly.")
		return

	//Safety checks done, now we actually do the loading

	//Not sure why we'd ever not have a user, but better safe
	if (user)
		var/success = 0
		if (ismob(C))
			success = do_mob(user, C, 5*newmass, needhand = 1)
		else
			success = do_after(user, 5*newmass, needhand = 1)

		if (!success)
			user << span("warning", "You moved away, and cancelled loading [C] onto the [src]!.")
			return

	user << span("notice", "You load [C] onto the [src]!.")
	forceMove(get_turf(C)) //Move the dolly under the thing
	cargo = C
	w_class = max(newmass, w_class)
	density = 1 //Dolly is now dense, to avoid oddities
	processing_objects.Add(src) //Starts processing


/obj/structure/dolly/proc/unload(var/mob/living/user)

	if (user)
		if (!isliving(user) || user.strength < initial(w_class))
			//Block mice and ghosts
			return
		if (!cargo)
			user << span("warning", "There's nothing on the [src]!")
			return
		var/turf/CT  = get_turf(cargo)
		var/T = get_turf(src)


		if (T == CT)
			//Thing is still on the dolly, nothing has gone wrong, we're doing a manual unload
			//You've gotta be near the dolly to unload it
			if (!Adjacent(user))
				user << span("warning", "You can't unload \the [src] from there, get closer!")
				return 0

			//Check that we're in a clear tile first
			for (var/atom/movable/AM in T)
				if (AM.density)
					if (AM != src && AM != cargo)
						user << span("warning", "There's no room to unload [cargo] here! Find a clear floor space!")
						return 0

	//The above two checks are unnecessary if the cargo is no longer on the dolly.
	//That means something else has removed it, or it was deleted or something. We don't care to figure out how

		user << span("notice", "You unload \the [src], depositing \the [cargo]  onto the floor.")
	cargo = null
	density = 0
	w_class = initial(w_class)
	processing_objects.Remove(src)

/obj/structure/dolly/AltClick(var/mob/user)
	unload(user)

/obj/structure/dolly/verb/verbunload()
	set name = "Unload Cargo"

	unload(usr)

/obj/structure/dolly/process()
	if (!cargo || cargo.loc != loc)
		unload(null)

//Cargo comes with us when we move
/obj/structure/dolly/Move()
	if (!cargo)
		return ..()
	var/mc = 0
	if (cargo.loc != loc)
		unload(null)
	else
		mc = 1

	.=..()
	if (. && mc)
		cargo.forceMove(loc)