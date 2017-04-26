//This file contains mutations which primarily exist for modifying a mob's speech

//TODO Future:
//Port voice changers to a mutation
//Port ninja hardsuit scrambling to a mutation
//Add Mute, tourettes, shouting



//Stuttering, used from a wide variety of spells, electric shocks and injuries
/mob/proc/stutter(var/duration, var/source)
	if (istype(src, /mob/living))
		//Defined at mob level for simplicity, but must be mob/living to actually work
		add_mutation("stuttering", source, duration*10)

/datum/modifier/mutation/stutter
	intercept_flags = INTERCEPT_SPEECH
	id = "stuttering"

/datum/modifier/mutation/stutter/on_say(var/message, var/datum/language/language, var/speechverb="says")
	if (language && (!(language.flags & (NO_STUTTER | NONVERBAL | SIGNLANG | HIVEMIND))))
		.= list(stutter(message), language, pick("stammers","stutters"))


/proc/stutter(n)
	var/te = html_decode(n)
	var/t = ""//placed before the message. Not really sure what it's for.
	n = length(n)//length of the entire word
	var/p = null
	p = 1//1 is the start of any word
	while(p <= n)//while P, which starts at 1 is less or equal to N which is the length.
		var/n_letter = copytext(te, p, p + 1)//copies text from a certain distance. In this case, only one letter at a time.
		if (prob(80) && (ckey(n_letter) in list("b","c","d","f","g","h","j","k","l","m","n","p","q","r","s","t","v","w","x","y","z")))
			if (prob(10))
				n_letter = text("[n_letter]-[n_letter]-[n_letter]-[n_letter]")//replaces the current letter with this instead.
			else
				if (prob(20))
					n_letter = text("[n_letter]-[n_letter]-[n_letter]")
				else
					if (prob(5))
						n_letter = null
					else
						n_letter = text("[n_letter]-[n_letter]")
		t = text("[t][n_letter]")//since the above is ran through for each letter, the text just adds up back to the original word.
		p++//for each letter p is increased to find where the next letter will be.
	return sanitize(t)







//Slurring, mostly used from drunkenness and certain drugs
/mob/proc/slur(var/duration, var/source)
	if (istype(src, /mob/living))
		//Defined at mob level for simplicity, but must be mob/living to actually work
		add_mutation("slurring", source, duration*10)

/datum/modifier/mutation/slur
	intercept_flags = INTERCEPT_SPEECH
	id = "slurring"

/datum/modifier/mutation/slur/on_say(var/message, var/datum/language/language, var/speechverb="says")
	if (language && (!(language.flags & (NO_STUTTER | NONVERBAL | SIGNLANG | HIVEMIND))))
		.= list(slur(message), language, verb = pick("slobbers","slurs"))

/proc/slur(phrase)
	phrase = html_decode(phrase)
	var/leng=lentext(phrase)
	var/counter=lentext(phrase)
	var/newphrase=""
	var/newletter=""
	while(counter>=1)
		newletter=copytext(phrase,(leng-counter)+1,(leng-counter)+2)
		if(rand(1,3)==3)
			if(lowertext(newletter)=="o")	newletter="u"
			if(lowertext(newletter)=="s")	newletter="ch"
			if(lowertext(newletter)=="a")	newletter="ah"
			if(lowertext(newletter)=="c")	newletter="k"
		switch(rand(1,15))
			if(1,3,5,8)	newletter="[lowertext(newletter)]"
			if(2,4,6,15)	newletter="[uppertext(newletter)]"
			if(7)	newletter+="'"
			//if(9,10)	newletter="<b>[newletter]</b>"
			//if(11,12)	newletter="<big>[newletter]</big>"
			//if(13)	newletter="<small>[newletter]</small>"
		newphrase+="[newletter]";counter-=1
	return newphrase



//Muteness. Drops all speech commands for languages with verbal components, and displays a fail message only to the speaker
/datum/modifier/mutation/mute
	intercept_flags = INTERCEPT_SPEECH
	id = "mute"
	var/fail_msg = "You are unable to speak."
	//Override this for custom fail messages
	blocks_speech = 1

/datum/modifier/mutation/mute/on_say(var/message, var/datum/language/language, var/speechverb="says")
	if (language && ((language.flags & (SIGNLANG | HIVEMIND))))
		return null //Signlanguage and hive mind don't use your voice, so we won't alter them at all
	else if (language && ((language.flags & (NONVERBAL))))
		.= list(stars(message, 75), language, speechverb)
		//If language is partially nonverbal, stars out 75% of text.
		//This is the inverse of the 25% that is lost without visual context, indicating how much is gesticular
	else
		//Entirely verbal language. Fails completely
		.= list("", language, speechverb)
		target << span("warning", fail_msg)


//Easy helper proc
/mob/proc/mute(var/duration, var/source)
	if (istype(src, /mob/living))
		//Defined at mob level for simplicity, but must be mob/living to actually work
		add_mutation("mute", source, duration*10)

/mob/proc/is_muted()
	if (istype(src, /mob/living))
		for (var/v in mutations)
			var/datum/modifier/mutation/V = v
			if (V.blocks_speech)
				return 1
	return 0