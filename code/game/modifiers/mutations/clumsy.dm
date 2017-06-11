//Generic clumsiness mutation, and several variations of it. This base version is intended for longterm use
//It represents an inherent lack of coordination and a person who is fairly prone to mistakes
/datum/modifier/mutation/clumsy
	id = "clumsiness"
	var/intensity = 2
	intercept_flags = INTERCEPT_CLICK



//A more intense version of clumsiness that is applied for some time (~30 minutes) after being cloned
/datum/modifier/mutation/clumsy/cloned
	id = "disoriented clone"
	intensity = 4

//A fairly intense clumsiness that is applied when very drunk
/datum/modifier/mutation/clumsy/inebriated
	id = "inebriated"
	intensity = 3

//An acute clumsiness with a near certain failure rate. This is intended for very short periods in acute situations
//Eg, for a few seconds after taking a blow to the head
/datum/modifier/mutation/clumsy/dazed
	id = "dazed"
	intensity = 90


/obj/var/fumble_mult = 1 //The chance of fumbling an interaction with the object is equal to fumble_mult of the object * intensity of the clumsy mutation
//This mult only applies when the object in question is the weapon, not when it is the target



//The main onclick function. We'll do fumble checks on held items, and on objects that are their targets
/datum/modifier/mutation/clumsy/on_click(var/atom/A, var/adjacency, var/restrained, var/list/modifiers)
	var/mob/living/user = target //A confusing varname, but target refers to who (or what) this modifier is applied to
	var/obj/item/weapon = user.get_active_hand()
	var/context = get_context(user, A, weapon)

	if (!context)
		return null //Something went wrong, abort!

	var/newtarget = null
	if (weapon && prob(intensity*weapon.fumble_mult))
		newtarget = weapon.fumble_act(user, context, A, weapon)
	else if (!weapon && prob(intensity) && istype(A, /obj))
		var/obj/O = A
		newtarget = O.fumble_act(user, context, O, weapon)


	if (!newtarget)
		//Nothing happened. A return of null will make the click continue as normal
		return null
	else if (istype(newtarget, /atom))
		//An atom was passed back to be the new target. We'll override it by returning it
		return list(newtarget, adjacency, restrained, modifiers)
	else
		//A non reference value was passed back. Generally 1
		//This is the order to drop the click command. We will execute that by returning a list full of nulls
		//In this case only the information in the first element matters, but we've gotta have four to avoid runtime errors
		return list(null,null,null,null)





//Fumble act is a new *_act proc that is called when the user fucks up while interacting with this object.
//Override it to define object_specific behaviours for clumsiness
//If the context is attack, The object should check whether it is the weapon or the target, it may be called in either case.
	//In all other contexts it is fixed and checking is unnecessary.  Touch, switch = target, self, throw = weapon
//Fumble act should return 1 if it takes any action or displays any message, and return 0 if it does nothing at all
	//In the case of fumble act being called from clumsy code, returning a nonzero value will drop the command (eg a click) that lead here.
/obj/proc/fumble_act(var/mob/user, var/context, var/atom/target, var/obj/item/weapon)
	return 0


//A generic definition of fumble act for items. Individual things should extend or override this where applicable.
//This is intended to provide some interesting and universally-applicable base behaviours
//Most of these possible actions will only display text feedback to the user (and not to bystanders) explaining what happened
//I feel this has more RP potential, the user could try to pretend it was intended, or make up their own explanation about what just happened
//The logic for whether fumble_act is called, is done outwith this function, so when it is called, something should happen every single time.
//This base fumble definition is quite complex, moreso than any specific item needs to be. Because it will be used for hundreds of items.
//Particular items are likely to have only minimal interactions with a clumsy person, so just a single effect is fine for them
/obj/item/fumble_act(var/mob/user, var/context, var/atom/target, var/obj/item/weapon, var/returntarget = 0)
	if (!user || !target)
		return 0 //Someone has to do the fumbling

	//src MUST be either one, (or both) of weapon or target.
	if (src != target && src != weapon)
		return 0

	//Robustness measure, to make it easier to call outwith clumsy code
	if (!context)
		context = get_context(user, target, weapon)

		if (!context)
			return 0 //failed to get context, terminate


	//Now we actually do the content
	if (context == CONTEXT_TOUCH)
		if (prob(50))
			//Pick up a different item instead
			var/list/L = shared_adjacent_items(user, target)
			L -= target
			var/obj/item/I = pick(L)
			if (I && !I.anchored)
				user << span("danger", "You accidentally grab [I] instead!")
				return I

		if (prob(15) && user.Adjacent(target) && istype(target.loc, /turf) && (locate(/obj/structure/table) in target.loc))
			//A complex set of conditions, this basically fires when trying to pickup something off a table
			//Knock everything off the table and make a mess
			for (var/obj/item/I in target.loc)
				if (!I.anchored)
					I.tumble(rand(1,3))

			user << span("danger", "You overbalance and crash into the table, scattering all its contents across the area!")
			return 1

		//This is a fallback if above fails. Grab a different item instead of the intended one
		if (prob(35))
			//Also have a chance to activate it
			attack_self(user)

		user << span("danger", "You try to pick up [src] but it slips through your fingers and rolls across the floor!")
		tumble(2)
		return 1



	if (context == CONTEXT_SWITCH)
		if (prob(75) && canremove)
			user << span("danger", "Whoops! \the [src] slips out of your hand!")
			user.drop_from_inventory(src)
			tumble(2)
			return 1
		else
			user << span("danger", "Whoops!")
			attack_self(user)
			return 1

	if (context == CONTEXT_SELF)
		if (canremove)
			user << span("danger", "Whoops! \the [src] slips out of your hand!")
			user.drop_from_inventory(src)
			tumble(2)
			return 1

	if (context == CONTEXT_THROW)
		if (prob(50))
			attack_self(user) //do this just for the hell of it, but its not the main attraction here

		//When a throw fumbles, one of two things will happen

		if (prob(50))
			//1. The throw goes wildly off target
			user << span("danger", "\The [src] slips out of your hand too early, and goes wildly off course!")
			var/list/l = list()
			for (var/turf/t in range(5, get_turf(target))) //We get a list of turfs within five tiles of the intended target, and throw at that instead
				l += t
			var/turf/A = pick(l)
			return A
		else
			//2. The throw goes nowhere except to the floor
			user << span("danger", "\The [src] slips out of your hand too late, and slides across the floor!")
			user.drop_from_inventory(src)
			tumble(4)
			return 1

	if (context == CONTEXT_ATTACK)
		//Attack is the most complex one of all. A wide variety of possibilities
		if (weapon == src)
			var/adjacency = user.Adjacent(target)

			if (adjacency)
				if (prob(25))
					//Whack the target with the thing
					//This won't be noticeable in the case of weapons, but smacking someone in the face with a health analyser will be funny


					var/noforce = 0
					//Slight hack for items that have no force and normally arent meant for bludgeoning. We'll temporarily set their damage to 1
					if (!force)
						force = 1
						noforce = 1
					bludgeon(user, target)
					//Bludgeoning gives a feedback message so we don't need an extra one

					if (noforce)
						//Then set back to 0
						force = 0

					return 1

				else if (prob(50))
					//Use the item on a different target within reach, instead
					target = pick(shared_adjacent_movable_atoms(user, target))

					user << span("danger", "You accidentally use [src] on [target] instead!")
					return target

				else
					//Use the item on ourselves
					user << span("danger", "You accidentally use [src] on yourself instead!")
					return user

			//Some other options for nonadjacent targets
			if (prob(30) && canremove)
				//Throw the item at the target.  This will be fun.
				user << span("danger", "[src] slips out of your hand and goes flying")
				user.throw_item(target)
				return 1

			if (canremove && prob(30))
				//Drop the item on the floor
				user << span("danger", "\The [src] slips out of your grip!")
				user.drop_from_inventory(src)
				tumble(2)
				return 1
			else
				//Use the item on something random that's generally near the target
				target = pick(orange(4, target))

				//No feedback for this, as its fairly likely to do nothing. If it does do something, then it'll probably be obvious
				return target



//Helper proc to figure out interaction context
//A zero return value means context is invalid, or we couldnt figure it out.
/proc/get_context(var/mob/user, var/atom/target, var/atom/weapon)
	if (!user || !target)
		return 0

	if (istype(target, /obj/screen)) //We dont want to do anything with UI clicks
		return 0

	if (!weapon)
		if (target.loc == user)
			//The user is moving the item from one hand to another
			return CONTEXT_SWITCH
		else
			//The user is picking up or touching the object while its on a turf
			return CONTEXT_TOUCH

	else
		if (target == weapon)
			//The user is holding the item in one hand and interacting with it
			return CONTEXT_SELF
		else
			if (user.in_throw_mode)
				//The user is throwing the item
				return CONTEXT_THROW
			else
				//The user is using the item on another atom
				//OR the user is using an item on this object
				return CONTEXT_ATTACK

	return 0