extends WeatherProbe
## Wind & storms probe 25: the rumble is felt. 300 m off the rift's live vent
## a burst's deep build grows as it nears and the ground trembles at its
## onset, jostling a crate on the sand; 1.5 km off, less of both; 12 km off,
## none of either, and the crate lies as still as it did before.


func run() -> void:
	# In still air, so only the ground moves the crate.
	await load_world(1234, true)
	var vent := await beside_vent(300.0)
	var geology := world.shape.history.geology
	var rumbles := world.weather.rumbles
	var start := Vector2(world.player_world_x(), world.player_world_z())
	var out := Vector2(signf(start.x - world.shape.sites.anchor().place(vent.p).x), 0.0)
	var onset := 600.0
	var felt := []
	for metres: float in [300.0, 1500.0, 12000.0]:
		# Well clear of the burst before, so only its own build is heard.
		onset = geology.next_burst(vent, onset + 1.0)
		while onset - geology.last_burst(vent, onset - 1.0).x < 400.0:
			onset = geology.next_burst(vent, onset + 1.0)
		if metres > 300.0:
			teleport(start.x + out.x * (metres - 300.0), start.y)
			await settle(true)
		var by := Sphere.angle(Sphere.point(world.moon.latitude, world.moon.longitude), vent.p) * geology.radius
		var crate := drop_box(world.player_world_x() + 2.0, world.player_world_z() + 2.0, 0.3)
		world.time_warp = 1.0
		world.time = onset - 45.0
		await physics_frames(90)
		var still := await _fastest(crate)
		var heard := {}
		for since: float in [-25.0, -5.0, 1.0]:
			world.time = onset + since
			for i in 2:
				await get_tree().process_frame
			heard[since] = Vector2(rumbles.build, rumbles.tremble)
		var shaken := await _fastest(crate)
		crate.queue_free()
		print("%.0f m off: build %.2f at 25 s before, %.2f at 5 s; tremble %.2f 1 s after; the crate %.2f m/s, %.2f before" % [
			by, heard[-25.0].x, heard[-5.0].x, heard[1.0].y, shaken, still])
		felt.append({"build": heard[-5.0].x, "earlier": heard[-25.0].x, "tremble": heard[1.0].y, "jostled": shaken - still})
	for i in 2:
		check(felt[i].build > felt[i].earlier and felt[i].earlier > 0.0, "the build grows as the burst nears")
	check(felt[0].build > felt[1].build and felt[0].tremble > felt[1].tremble and felt[1].tremble > Rumbles.KICK_FROM,
		"nearer, it builds louder and trembles harder")
	check(felt[0].jostled > 0.05 and felt[2].jostled < 0.01, "near, the crate is jostled; far off it lies as it did")
	check(felt[2].build == 0.0 and felt[2].earlier == 0.0 and felt[2].tremble == 0.0, "12 km off, none of it")


## The fastest a body goes over the next second, m/s.
func _fastest(body: RigidBody3D) -> float:
	var most := 0.0
	for i in 60:
		await get_tree().physics_frame
		most = maxf(most, body.linear_velocity.length())
	return most
