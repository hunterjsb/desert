extends SailProbe
## Time limit: 600 s
## Sailing probe 7: nothing flings. Four minutes back and forth across the
## wind on open sand in a 10 m/s wind gusting a third either way, turning at
## each end, over chunk seams and through origin shifts: never faster than a
## reach carries it, no jolt from one tick to the next, no wild spin,
## upright on its runners and never in the sand. The same twenty-second
## reach at 30, 60 and 120 ticks a second goes as fast, as far and leans the
## same. And what it costs a tick.


func run() -> void:
	await load_sailing()
	rig(open, heading())
	blow(downwind * 10.0, 0.33)
	hoist(60.0)
	course = heading()
	tending = deg_to_rad(12.0)
	# Lambdas copy what they're given: what they change lives in here.
	var seen := {"fastest": 0.0, "jolt": 0.0, "spin": 0.0, "leaned": 0.0, "seams": 0, "shifts": 0, "sunk": -INF,
		"was": deck.linear_velocity, "numbers": true,
		"chunk": world.terrain.chunk_at(world.world_x(deck.global_position.x), world.world_z(deck.global_position.z))}
	world.origin_shifted.connect(func(_by: Vector2i) -> void: seen.shifts += 1)
	var watch := func() -> void:
		var v := deck.linear_velocity
		seen.numbers = seen.numbers and is_finite(v.length()) and is_finite(deck.global_position.length())
		seen.fastest = maxf(seen.fastest, v.length())
		seen.jolt = maxf(seen.jolt, (v - seen.was).length())
		seen.was = v
		seen.spin = maxf(seen.spin, deck.angular_velocity.length())
		seen.leaned = maxf(seen.leaned, roll())
		seen.sunk = maxf(seen.sunk, sunk())
		var now := world.terrain.chunk_at(world.world_x(deck.global_position.x), world.world_z(deck.global_position.z))
		if now != seen.chunk:
			seen.seams += 1
			seen.chunk = now
	speed_up(4)
	for leg in 12:
		course = heading() * (1.0 if leg % 2 == 0 else -1.0)
		await sail_for(20.0, watch)
		if leg % 4 == 1:
			# The world's origin moves on under the camp mid-run.
			world.shift_origin(Vector2i(1 if leg == 1 else -1, 0))
	print("4 min gusting: at most %.2f m/s, the most a tick changed it %.3f m/s, spin at most %.2f rad/s, leaning at most %.1f°, in the sand at most %.3f m, %d seams, %d shifts" % [
		seen.fastest, seen.jolt, seen.spin, seen.leaned, seen.sunk, seen.seams, seen.shifts])
	print("a tick costs the runners %.0f µs and the sail %.0f µs" % [deck.glider.cost_us, mast.cost_us])
	check(seen.numbers, "every number stays a number")
	check(seen.fastest < 9.0 and seen.jolt < 0.3 and seen.spin < 1.5, "nothing flung, no jolt, no wild spin")
	check(seen.leaned < 30.0 and deck.glider.touching >= 8, "never over, and on its runners (%.1f° at most)" % seen.leaned)
	check(seen.sunk < 0.05, "never in the sand (%.3f m)" % seen.sunk)
	check(seen.seams >= 4 and seen.shifts >= 2, "across chunk seams and origin shifts")
	deck.free()
	speed_up(1)
	# The sheet left as it's set, so only the ticks differ.
	tending = 0.0
	var reach := {}
	for ticks: int in [30, 60, 120]:
		follow(open)
		await settle(true)
		rig(open, heading())
		blow(downwind * 10.0)
		hoist(60.0)
		course = heading()
		var start := deck.global_position
		Engine.physics_ticks_per_second = ticks * 2
		Engine.time_scale = 2.0
		for i in 20 * ticks:
			await get_tree().physics_frame
			follow(deck.global_position + Vector3(0.0, 0.0, 8.0))
			_steer()
		Engine.physics_ticks_per_second = 60
		Engine.time_scale = 1.0
		var went := Vector2(deck.global_position.x - start.x, deck.global_position.z - start.z).length()
		reach[ticks] = [way().dot(heading()), roll(), went]
		print("%d ticks a second: %.3f m/s after %.2f m, leaning %.2f°" % [ticks, reach[ticks][0], went, reach[ticks][1]])
		deck.free()
	for ticks: int in [30, 120]:
		check(absf(reach[ticks][0] - reach[60][0]) < 0.03 * reach[60][0] and absf(reach[ticks][2] - reach[60][2]) < 0.03 * reach[60][2]
			and absf(reach[ticks][1] - reach[60][1]) < 0.5, "at %d ticks a second it sails as at 60" % ticks)
