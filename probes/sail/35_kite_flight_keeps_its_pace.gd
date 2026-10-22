extends SailProbe
## The same anchored wing and line fly alike at different physics rates.


func run() -> void:
	await load_sailing()
	blow(downwind * 9.0)
	var places: Array[Vector3] = []
	for rate in [30, 60, 120]:
		Engine.physics_ticks_per_second = rate
		var camp := Catalog.device(&"chassis") as Chassis
		world.content.add_child(camp)
		camp.global_position = open + Vector3.UP * 0.5
		fit_part(camp, &"hook")
		camp.freeze = true
		var kite := Catalog.device(&"salvage_kite") as SalvageKite
		world.content.add_child(kite)
		kite.global_position = open + Vector3.UP * 2.0
		kite.phase = 0.0
		var line := Line.between(world, kite.bridle(), camp.free_tie(kite.global_position), 1.0)
		line.full = world.tuning.traction_line_m
		line.rope.full = line.full
		world.time = 0.0
		kite.use(world.player, kite.global_position)
		await physics_frames(rate * 30)
		places.append(kite.global_position - camp.global_position)
		print("%d Hz kite: %s" % [rate, str(places.back())])
		world.ropes.untie(line.rope)
		for end in line.ends:
			if is_instance_valid(end):
				end.queue_free()
		line.queue_free()
		kite.queue_free()
		camp.queue_free()
		await physics_frames(1)
	Engine.physics_ticks_per_second = 60
	metric("largest rate deviation", maxf(places[0].distance_to(places[1]), places[2].distance_to(places[1])), "m", 3.0)
	for at in places:
		check(at.distance_to(places[1]) < 3.0, "flight agrees within 3 m across physics rates")
