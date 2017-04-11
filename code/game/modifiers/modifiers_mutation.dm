/*
A mutation is a subclass of modifier with extended functionality and some specifics:

1. Mutations are for mobs only, this assumption is implicit
2. Mutations have procs which fire every time the mob it's on takes certain actions.
	Such as speaking, walking, interacting with things, etc.
	The action is intercepted before it happens, and with a certain return var they can cause the action to be discarded
3. Mutations track several sources that applied them, and one source can be added or removed without disabling the mutation.
4. Because of the multiple source issue, mutations generally don't accept certain input parameters for strength/scaling, and have a flat effect. This can be overridden


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

#define SOURCE_MENTAL	128
//Its all in your head

#define SOURCE_GENERIC	65535	//Unknown or unspecified source. This is the default. It is strongly advised to use a limited duration if using generic

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

	var/intercept_flags = 65535


//Intercept flags. These determine what actions this mutation wants to intercept.
#define INTERCEPT_SPEECH	0x1	//Whenever the mob says something
#define INTERCEPT_STEP  	0x2 //Whenever the mob moves under its own power
#define	INTERCEPT_HAND     	0x4 //Whenever the mob uses attack_hand, or attack_generic on an object
#define INTERCEPT_LIFE      0x8 //When the mob's life ticks.
#define INTERCEPT_DEATH		0x10
//#define SLOT_EARS       0x10
//#define SLOT_MASK       0x20
//#define SLOT_HEAD       0x40
//#define SLOT_FEET       0x80
//#define SLOT_ID         0x100
//#define SLOT_BELT       0x200
//#define SLOT_BACK       0x400
//#define SLOT_POCKET     0x800
//#define SLOT_DENYPOCKET 0x1000
//#define SLOT_TWOEARS    0x2000
//#define SLOT_TIE        0x4000
//#define SLOT_HOLSTER	0x8000

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


/datum/modifier/proc/adjust_duration(var/change = 0, var/set_duration = 0)
	for (var/v in durations)
		if (set_duration)
			durations[v] = change
		else
			durations[v] += change



//Here are the mutation interception procs.
//Each of these is called when a mob with this mutation does a certain common action


//Speech: For modifying how the mob talks. Add stutter, capitalise things, add shouting verbs, etc.
//Return a list in the form of text, language, verb to override these params.
//Set the text to null or "" in order to drop the speech command
//Return nothing to let the speech continue unmodified
/datum/modifier/mutation/proc/on_say(var/text, var/datum/language/language, var/speechverb="says")
	return null