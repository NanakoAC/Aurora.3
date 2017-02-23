/datum/controller/process/modifier/setup()
	name = "modifiers"
	schedule_interval = 10
	start_delay = 8
	var/last_tick = 0

/datum/controller/process/modifier/started()
	..()
	if(!processing_modifiers)
		processing_modifiers = list()

/datum/controller/process/modifier/doWork()
	var/diff = last_tick - world.time
	for(last_object in processing_modifiers)
		var/datum/modifier/O = last_object
		if(isnull(O.gcDestroyed))
			if (!isnull(O.duration))
				O.duration -= diff

			if (world.time >= O.next_tick)
				O.process(diff)
		else
			catchBadType(O)
			processing_objects -= O

	last_tick = world.time

/datum/controller/process/modifier/statProcess()
	..()
	stat(null, "[processing_modifiers.len] modifiers")
