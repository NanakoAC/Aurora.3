/*
Attributes are vars used to numerically define the scale of a mob's capabilities. They are intended to
provide a simple, centralised point of abstraction, that effects, equipment, spells, chemicals etc can alter.

Attributes, such as strength, are hooked into a vast number of points in the code, so that specialised things
do not need to do this, for example replacing specific checks for the hulk mutation or power gloves, in grabbing code

Because attributes are hooked into so many places, this file is intended to provide documentation of where and how.
Whenever an attribute, or a check for it is added, that should be referenced here, including enough information
to locate it. Codefile name, partial path, and maybe procname containing the code.
Don't bother with line numbers, those will change when unrelated things get modified

*/

/*
In this initial draft, strength is the only attribute.
*/

/*
Strength is a measure of a mob's ability to exert physical force on its surroundings. It is factored into melee damage,
dragging/pulling objects, picking up items, hauling heavy things around, wearing heavy equipment, etc
*/

//Defined at mob level for safety and ease of checks.
//Nonliving mobs have no corporeal presence and/or dont really exist, so their strength is 0
/mob/var/strength = 0
/mob/living/strength = 5 //A fairly safe baseline value for animals, but should be overridden anyway
/mob/living/carbon/human/strength = 10 //This should be set from set_species anyway, just defining it for safety

/mob/var/base_strength = 5
/mob/living/carbon/human/base_strength = 10


//Helper procs for keeping attributes accurate.
//Attribute changes should only be done by modifiers and equipment
/mob/proc/update_attributes()
	return

/mob/living/update_attributes()

	var/list/modbuffer = list()

	//We do a two-stage refresh of modifiers. First turn them all off
	for (var/v in modifiers)
		var/datum/modifier/M = modifiers[v]
		if (M.active)
			M.deactivate()
			modbuffer += M //Keep a buffer of the ones we disabled so we can re-enable only them

	//Then sync the attributes to their base values
	strength = base_strength

	//Then re-enable only the ones we turned off previously
	for (var/datum/modifier/M in modbuffer)
		M.activate()

	//Now we add any bonuses from equipment. Rigs, force gloves, etc
	for (var/obj/item/I in get_worn_items())
		if (isnum(I.attribute_mods["strength"]))
			strength += I.attribute_mods["strength"]

/*
Strength Interactions

Generic/variable
	Each point of strength either side of 10 modifies:
		melee damage with weapons by 10%, stacking additively. code/_onclick/item_attack.dm
		unarmed melee damage by 10%, stacking additively. human/human_attackhand.dm
		thrown weapon damage by 10%, stacking additively. code/game/atoms_movable.dm, throw_at proc
	Each point of strength grants +10% damage when trying to break energy nets. weapons/weaponry.dm, /obj/effect/energy_net/attack_hand
	Strength affects the difficulty of dragging heavy objects and pulling people. mob_movement.dm, search for burdenmult

Specific:
10:
	Can damage normal windows without a weapon. structures/window.dm
	Can damage metal grilles with unarmed attacks. objects/structures/grille.dm
11:
	Can damage reinforced glass or non reinforced phoron windows without a weapon. structures/window.dm

12:
	Can damage reinforced phoron windows without a weapon, or completely smash normal ones. structures/window.dm

13:
	Can break handcuffs: carbon/resist.dm

14:
	Can send stun+launch slimes with an unarmed strike. carbon/metroid/metroid.dm,

15:
	Can completely smash reinforced or phoron windows in one hit, without a weapon structures/window.dm
	Can destroy alien resin walls in one hit (these aren't really used) alien/resin.dm
	Can damage exosuits with unarmed attacks code/game/mecha/mecha.dm, attack_hand proc **Needs work
16:
	Can completely smash reinforced phoron windows in one hit, without a weapon structures/window.dm

17:
	Unarmed attacks always break metal foam in a single hit (there is no minimum, this is more of a maximum. Nothing above this helps)
		effects/chem/foam.dm, /obj/structure/foamedmetal/attack_hand
	Unarmed attacks stun xenomorphs and do extra damage 	carbon/alien/alien_attacks.dm

18:
	Can destroy breakable structures: /code/game/objects/structures.dm
	Can destroy operating tables: machinery/OpTable.dm (operating tables probably don't need an override that duplicates base functions?)
	Can tear apart girders with bare hands. structures/girders.dm
20:
	Can tear apart walls with bare hands. /turfs/simulated/wall_attacks.dm
*/




//Planned future attributes, currently unimplemented
/*
Agility: A representation of coarse motor skills, athletics, acrobatics, and flexibility. Would affect movement
speeds, climbing over stuff, escaping from bondage, attack speeds, sprint costs and evasion in combat.

Dexterity: A representation of fine motor skills, precision, and hand-eye coordination. Would affect accuracy,
reloading, tool use, surgery success, wire hacking, etc

Endurance: A measure of your ability to endure pain and punishment. Would affect max health, stamina, pain resistance,
health regen, diseases, chemical metabolism, etc


*/