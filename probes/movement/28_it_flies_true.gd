extends MovementProbe
## Movement probe 28: it flies true. Flat out over the flat, popped from a
## crouch, the board's nose follows its path: up as it rises, down as it
## falls, and coming down it turns to the sand it meets, landing along it.
## Turned off its way in the air with nothing steering it, it comes round.

## Flying higher than this over its ride height, m, it's clear of the sand.
const CLEAR := 1.3
## Turned this far off its way at the top of its flight, radians.
const TURNED := deg_to_rad(30.0)


func run() -> void:
	await load_moving()
	set_rate(60, 4)
	var flat := flat_place(world.player_world_x(), world.player_world_z(), 200.0, 40.0)
	var true_flight := await _pop(flat, 0.0)
	var turned := await _pop(flat, TURNED)
	print("popped from %.1f m/s, %.2f m up: nose up %.1f° at most rising, down %.1f° falling; %.1f° off its path on average clear of the sand; %.1f° off the sand it landed on"
		% [true_flight.from, true_flight.high, rad_to_deg(true_flight.up), rad_to_deg(true_flight.down),
		rad_to_deg(true_flight.off), rad_to_deg(true_flight.landed)])
	print("turned %.0f° off its way at the top: %.1f° off it as it landed" % [rad_to_deg(TURNED), rad_to_deg(turned.slip)])
	check(true_flight.up > deg_to_rad(6.0) and true_flight.down < deg_to_rad(-6.0),
		"its nose rises with its path and falls with it (%.1f°, %.1f°)" % [rad_to_deg(true_flight.up), rad_to_deg(true_flight.down)])
	check(true_flight.off < deg_to_rad(6.0), "following it close (%.1f° off)" % rad_to_deg(true_flight.off))
	check(true_flight.landed < deg_to_rad(4.0), "and it lands along the sand (%.1f° off)" % rad_to_deg(true_flight.landed))
	check(turned.slip < TURNED * 0.5, "turned in the air, it comes round to its way (%.1f°)" % rad_to_deg(turned.slip))
	set_rate(60)


## Up to speed along +x, then a crouch and a pop off the flat, its nose turned
## `turn` off its way at the top: {from, high, up, down, off, landed, slip}.
## `off` is how far its pitch lay from its path's, on average while clear of
## the sand; `landed`, its pitch from the sand's along it as it landed;
## `slip`, how far it pointed off its way then.
func _pop(flat: Dictionary, turn: float) -> Dictionary:
	player.step_off()
	for node in world.content.get_children():
		if node is Hoverboard:
			node.free()
	await place(flat.x - 60.0, flat.z, Vector2(1.0, 0.0))
	await ride_here()
	hold(["move_forward"])
	await ride_for(5.0)
	hold(["move_forward", "crouch"])
	await ride_for(0.6)
	var ride := player.ride
	var seen := {"from": flat_speed(), "high": 0.0, "up": 0.0, "down": 0.0, "off": 0.0, "n": 0, "landed": INF,
		"slip": INF, "turned": false, "flown": false}
	hold(["jump"] if turn > 0.0 else ["move_forward", "jump"])
	await ride_for(4.0, func() -> void:
		if ride.gap > Ride.AIR_FROM:
			seen.flown = true
			hold([] if turn > 0.0 else ["move_forward"])
		seen.high = maxf(seen.high, ride.gap)
		if ride.gap > CLEAR:
			var along := ride.velocity.dot(ride.ahead)
			var path := atan2(ride.vy, along)
			seen.off += absf(ride.pitch - path)
			seen.n += 1
			if ride.vy > 0.0:
				seen.up = maxf(seen.up, ride.pitch)
			else:
				seen.down = minf(seen.down, ride.pitch)
				if not seen.turned and turn > 0.0:
					ride.ahead = ride.ahead.rotated(turn)
					seen.turned = true
		if seen.flown and ride.touched > 0.0 and seen.landed == INF:
			var at := where()
			var nose := world.height_at(at.x + ride.ahead.x * 0.65, at.z + ride.ahead.y * 0.65)
			var tail := world.height_at(at.x - ride.ahead.x * 0.65, at.z - ride.ahead.y * 0.65)
			seen.landed = absf(ride.pitch - atan((nose - tail) / 1.3))
			var a := absf(ride.velocity.angle_to(ride.ahead))
			seen.slip = minf(a, PI - a))
	seen.off /= maxi(seen.n, 1)
	hold([])
	return seen
