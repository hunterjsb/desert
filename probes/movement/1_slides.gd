extends MovementProbe
## Movement probe 1: momentum is the reward. Sprint down the steepest real
## slope near spawn and crouch: you slide, and the slope keeps adding speed
## past anything your legs can do. Sprint on the flat and crouch: you slide
## on what you brought, slower every second, and stop in about the distance
## the sand's friction says.


func run() -> void:
	await load_moving()
	set_rate(60, 4)
	var x := world.player_world_x()
	var z := world.player_world_z()
	var t := world.tuning

	var hill := slope_between(x, z, 120.0, 8.0, 20.0, 12.0)
	check(not hill.is_empty(), "a slope of 8° or more, 12 m long, near spawn")
	if hill.is_empty():
		return
	var down: Vector2 = hill.downhill
	await place(hill.x - down.x * 3.0, hill.z - down.y * 3.0, down)
	hold(["move_forward", "sprint"])
	await simulate(0.6)
	var ran := flat_speed()
	hold(["move_forward", "sprint", "crouch"])
	var speeds: Array[float] = []
	var seen := {"slid": true}
	await simulate(2.0, func() -> void:
		speeds.append(flat_speed())
		seen.slid = seen.slid and player.mode == "slide")
	print("downhill %.1f°: sprinting %.2f m/s, sliding %.2f m/s after 1 s and %.2f after 2 s" % [hill.degrees, ran,
		speeds[59], speeds[-1]])
	check(seen.slid, "crouching at a sprint slides you, all the way down")
	check(speeds[-1] > t.sprint_speed + 1.0, "the slope adds speed past a sprint (%.2f m/s)" % speeds[-1])
	check(speeds[-1] > speeds[59] + 0.3, "and keeps adding it (%.2f then %.2f m/s)" % [speeds[59], speeds[-1]])

	var flat := flat_place(x, z, 150.0, 6.0)
	check(flat.degrees < 1.5, "a flat place near spawn (%.1f°)" % flat.degrees)
	var across := Vector2(1.0, 0.0)
	await place(flat.x - 3.0, flat.z, across)
	hold(["move_forward", "sprint"])
	await simulate(0.6)
	var start := where()
	var v0 := flat_speed()
	# Keys off but the crouch, or the slide's end would be a crouched walk on.
	hold(["crouch"])
	var run := {"slowing": true, "last": INF, "stopped": INF, "t": 0.0}
	await simulate(5.0, func() -> void:
		run.t += 1.0 / ticks_per_second()
		var v := flat_speed()
		run.slowing = run.slowing and v <= run.last + 0.01
		run.last = v
		if v < 0.05 and run.stopped == INF:
			run.stopped = run.t)
	var travelled := Vector2(where().x - start.x, where().z - start.z).length()
	# From the sprint plus the push into it, against the sand's friction alone; drag shortens it.
	var friction_says := pow(v0 + t.slide_kick, 2.0) / (2.0 * t.slide_friction * world.gravity)
	print("flat: slid from %.2f m/s, %.2f m in %.2f s; friction alone says %.2f m" % [v0, travelled,
		run.stopped, friction_says])
	check(run.slowing, "on the flat every tick is slower than the last")
	check(run.stopped < 4.0, "and it stops (%.2f s)" % run.stopped)
	check(travelled > friction_says * 0.6 and travelled < friction_says * 1.05,
		"about as far as the sand's friction allows (%.2f of %.2f m)" % [travelled, friction_says])
	check(player.mode != "slide" and player.crouched, "left crouched, no longer sliding (%s)" % player.mode)
	set_rate(60)
