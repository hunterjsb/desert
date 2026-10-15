extends MovementProbe
## Movement probe 7: nothing goes through the sand, you included. On dunes
## raised until slip faces appear, slide flat out down the steepest, jumping
## mid-slide and landing crouched into the next, at 1 g and at 0.45 g, and
## off crests at speed. Every tick your feet stay on the sand, never in it,
## and nothing had to be rescued from below it.

const RUNS := 6


func run() -> void:
	Tuning.current().dune_amplitude = 18.0
	await load_moving()
	set_rate(60, 4)
	var x := world.player_world_x()
	var z := world.player_world_z()
	var seen := {"fastest": 0.0, "landing": 0.0}
	player.landed.connect(func(speed: float) -> void: seen.landing = maxf(seen.landing, speed))
	for i in RUNS:
		var g := Player.ONE_G if i % 2 == 0 else World.LOW_GRAVITY
		world.set_gravity(g)
		var face := slope_between(x + i * 40.0, z, 60.0, 25.0, 40.0, 6.0)
		if face.is_empty():
			continue
		var down: Vector2 = face.downhill
		await place(face.x - down.x * 2.0, face.z - down.y * 2.0, down)
		player.stamina = world.tuning.stamina_max
		hold(["move_forward", "sprint", "crouch"])
		await simulate(1.5, func() -> void: seen.fastest = maxf(seen.fastest, flat_speed()))
		hold(["move_forward", "sprint", "crouch", "jump"])
		await simulate(0.1)
		hold(["move_forward", "sprint", "crouch"])
		await simulate(2.0, func() -> void: seen.fastest = maxf(seen.fastest, flat_speed()))
		hold(["move_forward", "sprint", "jump"])
		await simulate(1.5)
	world.set_gravity(Player.ONE_G)
	print("%d runs: fastest %.1f m/s, hardest landing %.1f m/s, deepest %.3f m below the sand, %d rescued"
		% [RUNS, seen.fastest, seen.landing, -deepest, world.rescued])
	check(seen.fastest > 6.0, "the slides got fast (%.1f m/s)" % seen.fastest)
	check(seen.landing > 3.0, "and the landings hard (%.1f m/s)" % seen.landing)
	set_rate(60)
