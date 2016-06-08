//This file contains variables and helper functions for mobs that can eat other mobs

//There are two ways to eat a mob:
	//Swallowing whole can only be done if the mob is sufficiently small
		//It will place the mob inside you, and slowly digest it,
			//Digesting deals genetic damage to the victim,
			//drains blood from it,
				//and adds protein to your stomach, based on the amounts.
			//Mob will be deleted from your contents when fully digested.
				//Mob is fully digested when it has taken genetic damage equal to its max health. This continues past death if necessary

	//Devouring eats the mob piece by piece. Taking a bite periodically
		//Each bite deals genetic damage, and drains blood.
			//Adds protein to your stomach based on quantities.
		//Mob is fully digested when it has taken genetic damage equal to its max health.  This continues past death if necessary
		//Devouring is interrupted if you or the mob move away from each other, or if the eater gets disabled.


/mob/living/var/swallowed_mob = 0
//This is set true if there are any mobs in this mob's contents. they will be slowly digested.
//just used as a boolean to minimise extra processing

///mob/living/proc/attempt_devour(/mob/victim)
	//This function will attempt to eat the victim,
	//either by swallowing them if they're small enough, or starting to devour them otherwise
	//This function is the main gateway to devouring, and will have all the safety checks


///mob/living/proc/swallow(/mob/victim)
	//This function will move the victim inside the eater's contents.. There they will be digested over time

///mob/living/proc/devour(/mob/victim)
	//This function will start consuming the victim by taking bites out of them.
	//Victim or attacker moving will interrupt it