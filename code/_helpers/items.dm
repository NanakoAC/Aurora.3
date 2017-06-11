//Prevents robots dropping their modules.
/proc/dropsafety(var/atom/movable/A)
	if (istype(A.loc, /mob/living/silicon))
		return 0

	else if (istype(A.loc, /obj/item/rig_module))
		return 0
	return 1



//Returns a list of all movable atoms (objects and mobs) which are adjacent to BOTH of the input atoms.
//Inputs can be turfs. But turfs wont be returned
/proc/shared_adjacent_movable_atoms(var/atom/A1, var/atom/A2)
	var/list/turfs = shared_adjacent_turfs(A1, A2)
	var/list/things = list()
	for (var/t in turfs)
		var/turf/T = t
		for (var/a in T)
			things += a

	return things


//Returns a list of all movable atoms (objects and mobs) which are adjacent to BOTH of the input atoms.
//Inputs can be turfs. But turfs wont be returned
/proc/shared_adjacent_items(var/atom/A1, var/atom/A2)
	var/list/turfs = shared_adjacent_turfs(A1, A2)
	var/list/things = list()
	for (var/t in turfs)
		var/turf/T = t
		for (var/obj/item/a in T)
			things += a

	return things