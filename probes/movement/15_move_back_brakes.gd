extends MovementProbe
## Movement probe 15: on the board, move back only brakes. From rest it never
## moves you; riding, it slows you to a stop and never on into reverse, even
## with your view turned off your way.


func run() -> void:
	await load_moving()
	set_rate(60, 4)
	var flat := flat_place(world.player_world_x(), world.player_world_z(), 150.0, 30.0)
	var across := Vector2(1.0, 0.0)
	await place(flat.x - 20.0, flat.z, across)
	await ride_here()
	hold(["move_back"])
	var seen := {"fastest": 0.0}
	await ride_for(3.0, func() -> void: seen.fastest = maxf(seen.fastest, flat_speed()))
	print("move back from rest on %.1f° sand: %.2f m/s at most" % [flat.degrees, seen.fastest])
	check(seen.fastest < 0.3, "from rest, move back never moves you (%.2f m/s)" % seen.fastest)

	for turned: float in [0.0, 0.6]:
		hold(["move_forward"])
		await ride_for(2.5)
		var way := Vector2(player.velocity.x, player.velocity.z)
		var going := way.length()
		face(way.normalized().rotated(turned))
		hold(["move_back"])
		var run := {"t": 0.0, "stopped": INF, "back": 0.0}
		await ride_for(4.0, func() -> void:
			run.t += 1.0 / ticks_per_second()
			var v := Vector2(player.velocity.x, player.velocity.z)
			run.back = minf(run.back, v.dot(way / going))
			if v.length() < 0.1 and run.stopped == INF:
				run.stopped = run.t)
		print("braking from %.1f m/s, view %.0f° off your way: stopped in %.2f s, %.2f m/s back at most"
			% [going, rad_to_deg(turned), run.stopped, -run.back])
		check(run.stopped < 3.0, "it slows you to a stop (%.2f s)" % run.stopped)
		check(run.back > -0.1, "and never reverses you (%.2f m/s back)" % -run.back)
	set_rate(60)
