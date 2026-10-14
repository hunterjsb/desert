extends DeviceProbe
## Devices & mods probe 6: loose things stacked on a floating device sit still
## under plain physics for ten minutes of still air, with no jitter, no creep
## and no explosions; then a gust knocks them off cleanly.

const MINUTES := 10.0
## A gale outside any shield, m/s.
const GUST := 30.0


func run() -> void:
	await load_world()
	var crate := spawn_device(&"crate_frame", 4.0, 1.5)
	await fast_forward(5.0)
	var stack: Array[RigidBody3D] = []
	for i in 3:
		var box := drop_box(world.world_x(crate.global_position.x), world.world_z(crate.global_position.z), 0.0)
		# On the solar panel, whose face is 0.29 m above the crate's middle.
		box.global_position = crate.global_transform * Vector3(0.0, 0.29 + BOX_SIZE * 0.5 + 0.01 + i * (BOX_SIZE + 0.02), 0.0)
		# Light enough that the tray floats the crate and its load at its set height.
		box.mass = 2.0
		stack.append(box)
	await fast_forward(10.0)
	var settled := stack.map(func(b: RigidBody3D) -> Transform3D: return relative(crate, b))
	var fastest := 0.0
	var invalid := false
	for minute in MINUTES:
		await fast_forward(60.0)
		for box in stack:
			fastest = maxf(fastest, (box.linear_velocity - crate.linear_velocity).length())
			invalid = invalid or not box.global_position.is_finite()
	var crept := 0.0
	for i in stack.size():
		crept = maxf(crept, relative(crate, stack[i]).origin.distance_to(settled[i].origin))
	print("after %d min: crept %.4f m, fastest %.4f m/s, crate %.3f m over the sand" % [MINUTES, crept, fastest, clearance(crate)])
	check(not invalid, "nothing went to invalid numbers")
	check(crept < 0.02, "the stack didn't creep (%.4f m)" % crept)
	check(fastest < 0.01, "and didn't jitter (fastest %.4f m/s)" % fastest)
	check(absf(clearance(crate) - Tuning.current().hover_height) < 0.05, "the crate kept floating")

	# The gust: a gale from the west, felt through the weather like any wind.
	var tuning := Tuning.current()
	tuning.prevailing_speed = GUST
	world.weather.field = WeatherField.new(world.run_seed, tuning)
	var wildest := 0.0
	for i in 600:
		await get_tree().physics_frame
		for box in stack:
			wildest = maxf(wildest, box.linear_velocity.length())
	var off := stack.filter(func(b: RigidBody3D) -> bool:
		var at := relative(crate, b).origin
		return absf(at.x) > 0.45 or absf(at.z) > 0.45 or at.y < 0.0)
	print("gust: %d of %d knocked off, wildest %.1f m/s" % [off.size(), stack.size(), wildest])
	check(off.size() == stack.size(), "a gust knocks the whole stack off (%d of %d)" % [off.size(), stack.size()])
	check(wildest < GUST * 1.5, "cleanly, never faster than the wind could throw them (%.1f m/s)" % wildest)
