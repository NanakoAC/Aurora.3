/*
A mutation is a subclass of modifier with extended functionality and some specifics:

1. Mutations are for mobs only, this assumption is implicit
2. Mutations have procs which fire every time the mob it's on takes certain actions.
	Such as speaking, walking, interacting with things, etc.
	The action is intercepted before it happens, and with a certain return var they can cause the action to be discarded
3. Mutations track several sources that applied them, and one source can be added or removed without disabling the mutation.
4. Because of the multiple source issue, mutations generally don't accept certain input parameters for strength/scaling, and have a flat effect. This can be overridden


*/



/datum/modifier/mutation
	var/id = ""
	//ID is a unique identifier for this class.  Eg Blindness, hulk, deafness, etc
	//It is mainly used as a dictionary key
	//ID should be empty for any base/parent classes that aren't intended to exist as used mutations.
	//This will prevent them being in the all_mutations list

	var/sourcetypes
	//Source types, used in mutation modifiers
	//Sourcetypes is a bitfield which tracks several possible origins of a mutation.
	//This is primarily for data storage, usage of these bitfields is only partially enforced or technically implemented.
	//Most of them are just here as a standard - a reserved slot for different common sources so they wont conflict
	//Whenever a mutation has no remaining sources, it is removed from the mob
	//Defines for sourcetype flags are found in __defines/modifiers.dm


	//Most mutations are fairly low intensity and dont need to recheck often


	var/list/durations = list()
	//Durations holds the remaining time on this mutation from each source.
	//Only one duration per source type is held.
	//All durations on a mutation will count down every tick. When a duration hits 0 that source is removed

	var/intercept_flags = 65535
	//Intercept flags. These determine what actions a mutation wants to intercept.
	//Defines for intercept flags are found in __defines/modifiers.dm
	//If we ever need to intercept more than 16 different types of actions, the bitfield should be used for the most common/performance intensive ones

	var/blocks_speech = 0
	//No function within the mutation, this is just a signal to quickly check for mute effects
	//Set it to 1 on any mutations that probably prevent speaking, so it can be used in certain cases to check whether the mob can speak

	check_interval = 6000
	tick_interval = 6000
	//Most mutations don't need to tick regularly
	//These times should be overridden for any mutation that wants to tick, or for any that has special conditions to check

/datum/modifier/mutation/New(var/atom/_target, var/_modifier_type, var/_source = null, var/_source_data = 0, var/_strength = 0, var/_duration = 0, var/_check_interval = 0)

	if (_target == -1)
		return null
		//For spawning dummy mutations to hold in a global list
	world << "Mutation created [id]"
	..()


/datum/modifier/mutation/process(var/deltatime)
	deltatime = world.time - last_tick
	world << "Mutation processing, delta [deltatime]"
	var/forcecheck = 0 //If true we will force a validity recheck this tick
	var/mindelta = tick_interval //The amount of time that we are going to wait until the next tick
	if (durations)
		for (var/v in durations)
			world << "Ticking down duration before [durations[v]]"
			durations[v] -= deltatime
			world << "Ticking down duration after [durations[v]]"
			if (durations[v] <= 0)
				forcecheck = 1
			mindelta = min(mindelta, durations[v]) //If a duration has less time remaining than our tick interval, next tick will be sooner

	if (!active && !forcecheck && !durations.len)
		last_tick = world.time
		return 0

	next_tick = last_tick + mindelta
	last_tick = world.time

	if (forcecheck || world.time > next_check)
		last_check = world.time
		.=check_validity()
	else
		return 1

/datum/modifier/mutation/Destroy()
	..()
	if (isliving(target))
		var/mob/living/L = target
		L.mutations -= id

/datum/modifier/mutation/handle_registration(var/override = 0)
	var/mob/living/L = target //Get it into the subject's mutations list before activation
	L.mutations[id] = src
	..()


/datum/modifier/mutation/check_validity()
	next_check = last_check + check_interval
	for (var/v in durations)
		if (durations[v] <= 0)
			sourcetypes &= ~(text2num(v))
			durations -= v

	if (sourcetypes)
		return 1
	world << "Validity check failing [sourcetypes]"
	return validity_fail("No sources remaining.")


//This is the main proc for adding a mutation. call mob.add_mutation whenever you wish to add one.
//Mutations and disabilities should no longer be directly added to the lists. always use this proc
/*
	Vars:
		mut type is the ID of the mutation we want to add. This is in the form of a string name.

		sourcetype is a value of the type of source this mutation is applied from. It is a bitfield although
		its generally not advised to toggle multiple bits at once unless you have a special application.
		Sourcetypes are described above

		duration is a var used to make a mutation temporary, it is quantified in deciseconds.
		If a mutation with a limited duration is added, while the same mutation with the same source type already
		exists, then the duration will be set to the higher of the two. In this case having no duration is
		regarded as infinitely high.

*/
/mob/proc/add_mutation(var/mut_type, var/_sourcetypes, var/duration)
	if (!isliving(src))
		return null

	if (!mut_type || !_sourcetypes)
		world << "Attempted to create mutation with nonexistent type or source: -[mut_type]-/-[_sourcetypes]-"
		return //Invalid data passed, fail


	var/datum/modifier/mutation/mut
	if (mutations[mut_type])
		mut = mutations[mut_type]
		world << "Mutation [mut_type] already exists. we have a reference to it [mut]"
		//The mob already has a mutation of this type, we grab a reference to it to work with

	else
		//The mob doesnt have this mutation, we must instantiate a new copy.
		mut = mutations_list[mut_type] //Fetch from global mutations list
		var/newtype = mut.type
		if (!newtype)
			world << "Failed to fetch mutation from global list: -[mut_type]-/-[_sourcetypes]-"
			for (var/v in mutations_list)
				world << "[v] [mutations_list[v]]"
			return //We failed to get it from the list, must have passed a nonexistent type.
		world << "newtype is [newtype] about to create one"
		mut = new newtype(src, MODIFIER_MUTATION)
		world << "Created [mut]"

	if (!mut || !istype(mut))
		world << "Failed to create mut, [mut]"
		world << "Attempted to create mutation with invalid type: -[mut_type]-/-[_sourcetypes]-"
		return //We failed to get it from the list, must have passed a nonexistent type.

	world << "Mutation creation successful [mut], [mut.id]"
	//Now that we have the reference to the mutation we're working with
	if (!mut.sourcetypes)
		//If the sources var of the mutation is zero, then this mutation was just created
		mut.sourcetypes = _sourcetypes
		if (duration)
			mut.durations["[_sourcetypes]"] = duration
			mut.next_tick = min(mut.next_tick, mut.last_tick + duration)
		mut.handle_registration() //Handle registration calls Activate to actually start the mutation
	else
		//If sources is already nonzero, then this mutation was pre-existing
		if ((mut.sourcetypes & _sourcetypes))
			//Mutation from this source already exists. Lets handle duration updating
			//Note that for handling durations, the assumption of a single type is made. Passing multiple sourcetypes in one bitfield isnt a good idea
			if (isnum(mut.durations["[_sourcetypes]"]))
				//A duration already exists
				if (!duration)
					//We're passing an indefinite duration. The old limited one is no longer relevant
					mut.durations.Remove("[_sourcetypes]")
				else
					//Set the duration to the maximum of the two
					mut.durations["[_sourcetypes]"] = max(mut.durations["[_sourcetypes]"], duration)
					mut.next_tick = min(mut.next_tick, mut.last_tick + duration)

	mut.update_controller()
			//If there is no pre-existing duration, then we do nothing. Regardless of whether or not
			//A duration was passed with this mutation. We wont overwrite a permanant effect with a temporary one




/datum/modifier/mutation/adjust_duration(var/change = 0, var/set_duration = 0)
	for (var/v in durations)
		if (set_duration)
			durations[v] = change
		else
			durations[v] += change
	update_controller()


//Here are the mutation interception procs.
//Each of these is called when a mob with this mutation does a certain common action


//Speech: For modifying how the mob talks. Add stutter, capitalise things, add shouting verbs, etc.
//Return a list in the form of message, language, verb to override these params.
//Return a valid list with the message set to null or "" in order to silently drop the command
//Return null to let the speech continue unmodified
/datum/modifier/mutation/proc/on_say(var/text, var/datum/language/language, var/speechverb="says")
	return null


//Life: Mostly useable for things that tick whenever the mob's life does
//Environment is passed in, this is the result of a return_air call, can be manipulated as desired
//If a specific value of -1 is returned, the life proc terminates immediately
//If any other true value is returned, it replaces the environment var in the life call
/datum/modifier/mutation/proc/on_life(var/datum/gas_mixture/environment)
	return null


/client/verb/teststutter()
	set category = "Debug"
	new /obj/structure/sink(mob.loc)
	new /obj/item/weapon/melee/baton/loaded(mob.loc)

/client/verb/addmut()
	set category = "Debug"
	set name = "Add Mutation"

	var/mut = input(mob,"Choose a mutation to add to yourself") in mutations_list
	var/dur = input(mob,"Type in a duration, in seconds. Blank or 0 will be permanant.") as num
	if (!dur || !isnum(dur))
		dur = 0
	mob.add_mutation(mut, SOURCE_CHRONIC, dur*10)