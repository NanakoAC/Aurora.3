var/global/datum/controller/process/modifier/modifier_controller
var/global/mutations_list

/datum/controller/process/modifier
	var/last_tick = 0
	var/next_tick = 0
	var/deltatime //The time that has passed since our last tick

/datum/controller/process/modifier/setup()
	name = "modifiers"
	schedule_interval = 1
	start_delay = 8
	modifier_controller = src

	//Populate the global mutations list
	var/paths = typesof(/datum/modifier/mutation)
	mutations_list = list()
	world << "Setting up global mutations list"
	for(var/path in paths)
		var/datum/modifier/mutation/D = new path(-1)
		if(!D.id)
			continue
		world << "GlobalMuts: [D.id], [D]"
		mutations_list[D.id] = D


/datum/controller/process/modifier/started()
	..()
	if(!processing_modifiers)
		processing_modifiers = list()

/datum/controller/process/modifier/doWork()
	if (world.time >= next_tick)
		next_tick = INFINITY
		for(last_object in processing_modifiers)
			var/datum/modifier/O = last_object
			if(isnull(O.gcDestroyed))
				if (world.time >= O.next_tick)
					O.process()
					if (O && isnull(O.gcDestroyed))
						next_tick = min(next_tick, O.next_tick, O.next_check)
			else
				catchBadType(O)
				processing_objects -= O

		last_tick = world.time

/datum/controller/process/modifier/statProcess()
	..()
	stat(null, "[processing_modifiers.len] modifiers")
