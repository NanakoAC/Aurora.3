/*
A mutation is a bodily modifier designed to represent some medium-large scale, semi-permanant effect on a
mob. Mutations are often, but not necessarily, linked with genetics. They can also be applied by magic,
drugs, and artifacts.

There are two subclasses of mutations:
	Disabilities:
		These represent a loss in baseline functionality. Eg blindness, deafness, poor coordination. A
		disability makes someone less capable than a normal human. In genetics disabilities are very easy
		to apply, requiring only that any of several enzymes be out of a tolerance range.

	Powers:
		Powers generally represent positive things, a gain in functionality. Like super strength, or not
		needing to breathe. Powers are generally positive and provide the subject with some advantage.

		This is not a requirement, and there can be be mutations that add to the user in a bad way, like
		cancerous tumors or malformed limbs.

		The only requirement is that powers are harder to do in genetics, requiring the inverse of disabilities
		That is, they require all of several enzymes to be IN a tolerance range. This means that gaining powers
		through random gene modding is unlikely.

An important feature of mutations is that they behave consistently, there is no room for variation.
No vars can be passed which will scale a mutation. It works the way it works regardless of how its applied.
Hulk will always double your strength, blind will always completely remove sight, etc.

However you are free to code mutations to adapt to the target mob. Hulk doubles the strength so the stronger
the mob was to start with, the better the result
*/


//Sourcetypes is a bitfield which tracks several possible origins of a mutation.
//This is primarily for data storage, usage of these bitfields is only partially enforced or technically implemented.
//Most of them are just here as a standard - a reserved slot for different common sources so they wont conflict
//Whenever a mutation has no remaining sources, it is removed from the mob
//These will be listed below, using blindness as an example to explain their intended usase
#define SOURCE_GENETIC	1
//Your genetic code has been altered, by genetics, changelings, or certain chemicals, causing you to be
//unable to see. This requires gene modding to fix
//This should only be used by the genetics system

#define SOURCE_CHEMICAL 2
//Some poison has rendered you temporarily blind. This will generally be removed when it wears off
//This should be used by drugs, medicines, alcohol, etc

#define SOURCE_STRUCTURAL 4
//Someone has stabbed your eyes, or you dont have any eyes. This will require surgery and/or imidazoline
//Structural blindness of permanant duration should be added if someone's eyes are cut out

#define SOURCE_EQUIPMENT 8
//You're wearing a blindfold. Take it off.

#define SOURCE_MAGICAL	16
//Blind spell, or blinding talisman. Get away from the caster and wait for it to wear off.

#define SOURCE_TECH	32
//Security flashed you. wait for it to wear off

#define SOURCE_CHRONIC 64
/*You are blind for some reason that modern medicine cannot fix.
This sourcetype is generally useful for disabilities that are chosen in character creation and permanantly
active. EG, someone born blind/deaf/crippled.

Generally no normally-accessible thing should be able to cure chronic mutations. Only really rare mechanics
like alien artifacts.
*/

/datum/modifier/mutation
	var/id = "mutation"
	//ID is a unique identifier for this class.  Eg Blindness, hulk, deafness, etc
	//It is mainly used as a dictionary key

	var/sourcetypes

	var/base_check_interval	=	120
	//Most mutations are fairly low intensity and dont need to recheck often


	var/list/durations = list()
	//Durations holds the remaining time on this mutation from each source.
	//Only one duration per source type is held.
	//All durations on a mutation will count down every tick. When a duration hits 0 that source is removed

/datum/modifier/mutation/handle_registration(var/override = 0)
	var/mob/living/L = target //Get it into the subject's mutations list before activation
	L.mutations[id] = src
	..()



/datum/modifier/mutation/custom_validity()


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
/mob/living/proc/add_mutation(var/mut_type, var/sourcetypes, var/duration)
	if (!mut_type || !sourcetypes)
		world << "Attempted to create mutation with nonexistent type or source: -[mut_type]-/-[sourcetypes]-"
		return //Invalid data passed, fail


	var/datum/modifier/mutation/mut
	if (mutations[mut_type])
		mut = mutations[mut_type]
		//The mob already has a mutation of this type, we grab a reference to it to work with

	else
		//The mob doesnt have this mutation, we must instantiate a new copy.
		//TODO: Add code to copy a mutation from a master list
		var/newtype //Fetch from master list on this line
		mut = new newtype(src, MODIFIER_CUSTOM, _check_interval = base_check_interval, override = MODIFIER_OVERRIDE_REPLACE)

	if (!mut)
		world << "Attempted to create mutation with invalid type: -[mut_type]-/-[sourcetypes]-"
		return //We failed to get it from the list, must have passed a nonexistent type.


	//Now that we have the reference to the mutation we're working with
	if (!mut.sources)
		//If the sources var of the mutation is zero, then this mutation was just created
		mut.sources = sourcetypes'
		mut.handle_registration() //Handle registration calls Activate to actually start the mutation
	else
		//If sources is already nonzero, then this mutation was pre-existing
		if ((sources & sourcetypes))
			//Mutation from this source already exists. Lets handle duration updating
			if (isnum(durations["[sourcetypes]"]))
				//A duration already exists
				if (!duration)
					//We're passing an indefinite duration. The old limited one is no longer relevant
					durations.Remove("[sourcetypes]")
				else
					//Set the duration to the maximum of the two
					durations["[sourcetypes]"] = max(durations["[sourcetypes]"], duration)

			//If there is no pre-existing duration, then we do nothing. Regardless of whether or not
			//A duration was passed with this mutation. We wont overwrite a permanant effect with a temporary one
