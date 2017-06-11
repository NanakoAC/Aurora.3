//Modifier types
//These are needed globally and cannot be undefined

#define MODIFIER_EQUIPMENT	1
//The status effect remains valid as long as it is worn upon the affected mob.
//Worn here means it must be held in a valid equip slot, which does not include pockets, storage, or held in hands.
//The affected atom must be a mob

#define MODIFIER_ITEM	2
//The modifier remains valid as long as the item is in the target's contents,
//no matter how many layers deep, if it can be found by recursing up, it is valid
//This is essentially a more permissable version of equipment, and works when held, in backpacks, pockets, etc
//It can also be used on non-mob targets

#define MODIFIER_REAGENT	3
//The status effect remains valid as long as the dose of this chemical in a mob's reagents is above
//a specified dose value (specified in source data).
//The default of zero will keep it valid if the chemical is in them at all
//This checks for the reagent by type, in any of a mob's reagent holders - touching, blood, ingested
//Affected atom must be a mob

#define MODIFIER_AURA	4
//The modifier remains valid as long as the target's turf is within a range of the source's turf
//The range is defined in source data
//A range of zero is still valid if source and target are on the same turf. Sub-zero range is invalid
//Works on any affected atom

#define MODIFIER_TIMED	5
//The modifier remains valid as long as the duration has not expired.
//Note that a duration can be used on any time, this type is just one that does not
//check anything else but duration.
//Does not require or use a source atom
//Duration is mandatory for this type.
//Works on any atom


#define MODIFIER_CUSTOM	6
//The validity check will always return 1. The author is expected to override
//it with custom validity checking behaviour.
//Does not require or use a source atom
//Does not support duration

#define MODIFIER_MUTATION 7
//Completely overrides the check validity function as a new subsystem. there's no special behaviour in the base class


//Override Modes:
//An override parameter is passed in with New, which determines what to do if a modifier of
//the same type already exists on the target

#define MODIFIER_OVERRIDE_DENY	0
//The default. If a modifier of our type already exists, the new one is discarded. It will Qdel itself
//Without adding itself to any lists

#define MODIFIER_OVERRIDE_NEIGHBOR	1
//The new modifier ignores the existing one, and adds itself to the list alongside it
//This is not recommended but you may have a specific application
//Using the strength var and updating the effects is preferred if you want to stack multiples
//of the same type of modifier on one mob

#define MODIFIER_OVERRIDE_REPLACE 	2
//Probably the most common nondefault and most useful. If an old modifier of the same type exists,
//Then the old one is first stopped without suspending, and deleted.
//Then the new one will add itself as normal

#define MODIFIER_OVERRIDE_REFRESH 	3
//This mode will overwrite the variables of the old one with our new values
//It will also force it to remove and reapply its effects
//This is useful for applying a lingering modifier, by refreshing its duration

#define MODIFIER_OVERRIDE_STRENGTHEN	4
//Almost identical to refresh, but it will only apply if the new modifer has a higher strength value
//If the existing modifier's strength is higher than the new one, the new is discarded

#define MODIFIER_OVERRIDE_CUSTOM	5
//Calls a custom override function to be overwritten


//Source types, used in mutation modifiers
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



//Intercept flags. These determine what actions a mutation wants to intercept.
#define INTERCEPT_SPEECH	0x1	//Whenever the mob says something.
#define INTERCEPT_STEP  	0x2 //Whenever the mob moves under its own power
#define	INTERCEPT_HAND     	0x4 //Whenever the mob uses attack_hand, or attack_generic on an object
#define INTERCEPT_LIFE      0x8 //When the mob's life ticks.
#define INTERCEPT_DEATH		0x10 //When the mob dies
#define INTERCEPT_CLICK		0x20 //When the mob clicks on anything. only works on player-controlled mobs



//Interaction contexts. These are used for fumble_act. These flags are used to define what the user was attempting to do with the object
#define CONTEXT_TOUCH	0x1 //Using an empty hand on an object that's located in another atom that isnt yourself
#define CONTEXT_SWITCH	0x2 //Using an empty hand on an object located in yourself. Generally, switching between hands
#define CONTEXT_SELF	0x4	//Using the object on itself. Ie, attack_Self
#define CONTEXT_ATTACK	0x8 //Using the object on another atom, without throw mode
#define CONTEXT_THROW	0x10 //Using the object on another atom, in throw mode