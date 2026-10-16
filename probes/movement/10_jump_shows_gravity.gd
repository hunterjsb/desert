extends MovementProbe
## Movement probe 10: a jump shows the moon's gravity. Legs push off the same
## anywhere, so at 1 g you rise the tuned height and at 0.45 g, F6's lean,
## 9.8/4.4 times as high and for as much longer. A second press in the air
## does nothing; a press just before you land jumps as you touch down; a
## press just after you leave the ground still counts.


func run() -> void:
	await load_moving()
	set_rate(60, 2)
	var t := world.tuning
	var flat := flat_place(world.player_world_x(), world.player_world_z(), 150.0, 3.0)

	for g: float in [Player.ONE_G, World.LOW_GRAVITY]:
		world.set_gravity(g)
		await place(flat.x, flat.z, Vector2(1.0, 0.0))
		var ground := player.global_position.y
		var flight := await _jump()
		var expected := t.jump_height * Player.ONE_G / g
		var air := 2.0 * sqrt(2.0 * Player.ONE_G * t.jump_height) / g
		print("%.2f g: rose %.3f m (gravity says %.3f) in %.2f s of air (%.2f)" % [g / Player.ONE_G, flight.top - ground,
			expected, flight.air, air])
		check(absf(flight.top - ground - expected) < 0.01, "at %.2f g you rise %.2f m (%.3f)" % [g / Player.ONE_G,
			expected, flight.top - ground])
		check(absf(flight.air - air) < 0.04, "and come down after %.2f s (%.2f)" % [air, flight.air])
		check(absf(flight.spent - t.jump_stamina) < 0.2, "a jump costs %.0f stamina (%.2f)" % [t.jump_stamina,
			flight.spent])

	world.set_gravity(Player.ONE_G)
	await place(flat.x, flat.z, Vector2(1.0, 0.0))
	var ground := player.global_position.y
	hold(["jump"])
	await simulate(0.15)
	hold([])
	await simulate(0.05)
	hold(["jump"])
	var seen := {"top": -INF, "again": false, "left": -1.0, "t": 0.0, "jumped": false}
	await simulate(0.5, func() -> void: seen.top = maxf(seen.top, player.global_position.y - ground))
	hold([])
	check(seen.top < t.jump_height + 0.01, "a press in the air doesn't jump again (rose %.3f m)" % seen.top)

	await place(flat.x, flat.z, Vector2(1.0, 0.0))
	var takeoff := sqrt(2.0 * Player.ONE_G * t.jump_height)
	var land_at := 2.0 * takeoff / Player.ONE_G
	hold(["jump"])
	await simulate(0.05)
	hold([])
	await simulate(land_at - 0.05 - t.jump_buffer_seconds * 0.5)
	hold(["jump"])
	await simulate(t.jump_buffer_seconds, func() -> void:
		seen.again = seen.again or (player.velocity.y > takeoff * 0.9 and player.mode == "air"))
	hold([])
	await simulate(1.0)
	check(seen.again, "a press just before landing jumps as you touch down")

	# Walk off a crate's edge, a metre up: the press comes just after your feet leave it.
	await place(flat.x, flat.z, Vector2(1.0, 0.0))
	var crate := drop_box(flat.x + 0.9, flat.z, 0.75)
	crate.freeze = true
	player.global_position = Vector3(world.engine_x(flat.x + 0.9), crate.global_position.y + 0.26,
		world.engine_z(flat.z))
	await simulate(0.3)
	hold(["move_forward"])
	await simulate(1.5, func() -> void:
		seen.t += 1.0 / ticks_per_second()
		if seen.left < 0.0 and not player.is_on_floor():
			seen.left = seen.t
		if seen.left > 0.0 and seen.t - seen.left >= t.coyote_seconds * 0.5:
			Input.action_press("jump")
		seen.jumped = seen.jumped or player.velocity.y > takeoff * 0.9)
	hold([])
	check(seen.left > 0.0 and seen.jumped, "a press just after you walk off an edge still jumps")
	crate.queue_free()
	set_rate(60)


## Jumps from rest and lands: the highest the feet got, the time in the air
## and the stamina the takeoff took.
func _jump() -> Dictionary:
	var flight := {"top": -INF, "air": 0.0, "spent": player.stamina}
	hold(["jump"])
	await simulate(1.0 / ticks_per_second())
	hold([])
	flight.spent += world.tuning.stamina_regen / ticks_per_second() - player.stamina
	flight.air = 1.0 / ticks_per_second()
	var landed := false
	await simulate(3.0, func() -> void:
		flight.top = maxf(flight.top, player.global_position.y)
		if not landed:
			landed = player.is_on_floor()
			if not landed:
				flight.air += 1.0 / ticks_per_second())
	return flight
