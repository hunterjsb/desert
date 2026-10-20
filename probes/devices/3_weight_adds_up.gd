extends DeviceProbe
## Devices & mods probe 3: a chassis's weight is its own plus what's stuck
## and fitted on it, through any order of sticking, fitting and taking off,
## and the physics agrees: a known push moves it as that weight says.
## Floating at rest, its tray draws for that weight, a part more or less.


func run() -> void:
	await load_world()
	var deck := spawn_device(&"chassis", 4.0, 2.0, false)
	var spares: Array[Part] = []
	for id: StringName in [&"hover_tray", &"battery", &"big_battery", &"hook", &"hook", &"solar_panel", &"lamp"]:
		var part := Catalog.part(id)
		world.content.add_child(part)
		part.global_position = deck.global_position + Vector3(0, 3, 2)
		spares.append(part)
	await physics_frames(5)
	var wrong := 0
	var pushed_wrong := 0
	for step in 40:
		var loose := spares.filter(func(p: Part) -> bool: return p.is_inside_tree())
		var on := deck.parts()
		if not loose.is_empty() and (randf() < 0.6 or on.is_empty()):
			var part: Part = loose.pick_random()
			var ring := deck.sockets().filter(func(s: Socket) -> bool: return s.kind == part.kind and s.is_open())
			if not ring.is_empty():
				deck.fit(part, ring.pick_random())
			else:
				stick_on(deck as Chassis, part)
		elif not on.is_empty():
			var taken := deck.take((on.pick_random() as Part).socket)
			taken.global_position = deck.global_position + Vector3(0, 3, 2)
		var expected := deck.frame_mass
		for part in deck.parts():
			expected += part.mass
		if absf(deck.mass - expected) > 1e-4:
			wrong += 1
		# The engine's own weight: a known sideways impulse, up in still air
		# where no friction takes a share.
		deck.global_position.y = world.height_under(deck.global_position) + 10.0
		deck.linear_velocity = Vector3.ZERO
		deck.sleeping = false
		await physics_frames(2)
		var before := deck.linear_velocity
		deck.apply_central_impulse(Vector3(expected * 0.5, 0, 0))
		await get_tree().physics_frame
		var gained := deck.linear_velocity.x - before.x
		if absf(gained - 0.5) > 0.02:
			pushed_wrong += 1
			printerr("step %d: pushed %.3f m/s, weight says 0.5" % [step, gained])
		deck.linear_velocity = Vector3.ZERO
	check(wrong == 0, "weight is always frame plus parts (%d wrong)" % wrong)
	check(pushed_wrong == 0, "the physics moves it as that weight says (%d wrong)" % pushed_wrong)

	for part in deck.parts():
		deck.take(part.socket).free()
	fit_part(deck, &"hover_tray")
	fit_part(deck, &"big_battery")
	for extra: StringName in [&"", &"solar_panel", &"big_battery"]:
		if extra != &"":
			fit_part(deck, extra)
		deck.global_position.y = world.height_under(deck.global_position) + deck.rest_height()
		await physics_frames(180)
		var draw := deck.demand_w()
		check(absf(draw - deck.mass * Tuning.current().hover_watts_per_kg) < draw * 0.01,
			"floating at rest, its tray draws %.1f W for its %.1f kg" % [draw, deck.mass])
