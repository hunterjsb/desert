extends DeviceProbe
## Devices & mods probe 3: a device's weight is its frame plus its parts,
## through any order of fitting and taking out, and the physics agrees: a known
## push moves it as that weight says. Floating at rest, its tray draws for
## that weight, a part more or less.


func run() -> void:
	await load_world()
	var crate := spawn_device(&"crate_frame", 4.0, 2.0, false)
	var spares: Array[Part] = []
	for id: StringName in [&"hover_tray", &"battery", &"big_battery", &"hook", &"hook", &"solar_panel", &"lamp"]:
		var part := Catalog.part(id)
		world.content.add_child(part)
		part.global_position = crate.global_position + Vector3(0, 3, 2)
		spares.append(part)
	await physics_frames(5)
	var wrong := 0
	var pushed_wrong := 0
	for step in 40:
		var free := crate.sockets().filter(func(s: Socket) -> bool: return s.part == null)
		var fitting := spares.filter(func(p: Part) -> bool: return p.is_inside_tree() \
			and free.any(func(s: Socket) -> bool: return s.kind == p.kind))
		if not fitting.is_empty() and (randf() < 0.6 or crate.parts().is_empty()):
			var part: Part = fitting.pick_random()
			var socket: Socket = free.filter(func(s: Socket) -> bool: return s.kind == part.kind).pick_random()
			crate.fit(part, socket)
		elif not crate.parts().is_empty():
			var full: Socket = crate.sockets().filter(func(s: Socket) -> bool: return s.part != null).pick_random()
			var taken := crate.take(full)
			taken.global_position = crate.global_position + Vector3(0, 3, 2)
		var expected := crate.frame_mass
		for part in crate.parts():
			expected += part.mass
		if absf(crate.mass - expected) > 1e-4:
			wrong += 1
		# The engine's own weight: a known sideways impulse, up in still air
		# where no friction takes a share.
		crate.global_position.y = world.height_under(crate.global_position) + 10.0
		crate.linear_velocity = Vector3.ZERO
		crate.sleeping = false
		await physics_frames(2)
		var before := crate.linear_velocity
		crate.apply_central_impulse(Vector3(expected * 0.5, 0, 0))
		await get_tree().physics_frame
		var gained := crate.linear_velocity.x - before.x
		if absf(gained - 0.5) > 0.02:
			pushed_wrong += 1
			printerr("step %d: pushed %.3f m/s, weight says 0.5" % [step, gained])
		crate.linear_velocity = Vector3.ZERO
	check(wrong == 0, "weight is always frame plus parts (%d wrong)" % wrong)
	check(pushed_wrong == 0, "the physics moves it as that weight says (%d wrong)" % pushed_wrong)

	for socket in crate.sockets():
		if socket.part != null:
			crate.take(socket).free()
	fit_part(crate, &"hover_tray")
	fit_part(crate, &"big_battery")
	for extra: StringName in [&"", &"solar_panel", &"big_battery"]:
		if extra != &"":
			fit_part(crate, extra)
		crate.global_position.y = world.height_under(crate.global_position) + crate.rest_height()
		await physics_frames(180)
		var draw := crate.demand_w()
		check(absf(draw - crate.mass * Tuning.current().hover_watts_per_kg) < draw * 0.01,
			"floating at rest, its tray draws %.1f W for its %.1f kg" % [draw, crate.mass])
