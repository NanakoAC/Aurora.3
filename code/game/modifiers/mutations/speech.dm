/mob/living/proc/stutter(var/duration, var/source)
	add_mutation(/datum/modifier/mutation/stutter, source, duration)

/datum/modifier/mutation/stutter
	intercept_flags = INTERCEPT_SPEECH
	id = "stutter"

/datum/modifier/mutation/stutter/on_say(var/text, var/datum/language/language, var/speechverb="says")

	.= list(stutter(message), language, pick("stammers","stutters"))




/mob/living/proc/slur(var/duration, var/source)
	add_mutation(/datum/modifier/mutation/slur, source, duration)

/datum/modifier/mutation/slur
	intercept_flags = INTERCEPT_SPEECH
	id = "slur"

/datum/modifier/mutation/slur/on_say(var/text, var/datum/language/language, var/speechverb="says")

	.= list(slur(message), language, verb = pick("slobbers","slurs"))