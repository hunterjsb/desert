extends MovementProbe
## Movement probe 18: the drift. Flat out, a hard turn standing skids round:
## the board's grip lets go and the slide bleeds speed. The same turn with a
## crouch drifts: the board slides out further, on purpose, and comes round
## keeping more of its speed. Standing up ends the drift.

## Come round this far, radians, the turn is done.
const ROUND := PI * 0.45


func run() -> void:
	await load_moving()
	set_rate(60, 4)
	var flat := flat_place(world.player_world_x(), world.player_world_z(), 200.0, 40.0)
	var skid := await _turn(flat, false)
	var drift := await _turn(flat, true)
	print("a hard turn from %.1f m/s: skidding, round in %.2f s at %.1f m/s, sliding %.0f° at most"
		% [skid.from, skid.took, skid.out, rad_to_deg(skid.slid)])
	print("drifting, round in %.2f s at %.1f m/s, sliding %.0f° at most; stood up, %.0f° a second after"
		% [drift.took, drift.out, rad_to_deg(drift.slid), rad_to_deg(drift.after)])
	check(skid.took < 5.0 and drift.took < 5.0, "both come round (%.1f s, %.1f s)" % [skid.took, drift.took])
	check(drift.slid > skid.slid + deg_to_rad(10.0),
		"the drift slides further out (%.0f° against %.0f°)" % [rad_to_deg(drift.slid), rad_to_deg(skid.slid)])
	check(drift.out > skid.out + 2.0, "and keeps more speed (%.1f m/s against %.1f)" % [drift.out, skid.out])
	check(drift.after < deg_to_rad(10.0), "standing up, the board grips again (%.0f° off your way)"
		% rad_to_deg(drift.after))
	set_rate(60)


## Up to speed along +x, then a hard turn left with the move keys, crouched
## or not: {from, took, out, slid, after}. `slid` is the furthest the board
## pointed off your way; `after`, how far a second after standing up.
func _turn(flat: Dictionary, crouch: bool) -> Dictionary:
	player.step_off()
	for node in world.content.get_children():
		if node is Hoverboard:
			node.free()
	await place(flat.x - 60.0, flat.z, Vector2(1.0, 0.0))
	await ride_here()
	hold(["move_forward"])
	await ride_for(6.0)
	var start := Vector2(player.velocity.x, player.velocity.z)
	var seen := {"from": start.length(), "took": INF, "out": 0.0, "slid": 0.0, "t": 0.0, "after": 0.0}
	hold(["move_left", "crouch"] if crouch else ["move_left"])
	await ride_for(5.0, func() -> void:
		var v := Vector2(player.velocity.x, player.velocity.z)
		var ride := player.ride
		seen.t += 1.0 / ticks_per_second()
		seen.slid = maxf(seen.slid, absf(v.angle_to(ride.ahead)))
		if seen.took == INF and absf(start.angle_to(v)) >= ROUND:
			seen.took = seen.t
			seen.out = v.length())
	hold(["move_left"])
	await ride_for(1.0)
	seen.after = absf(Vector2(player.velocity.x, player.velocity.z).angle_to(player.ride.ahead))
	hold([])
	return seen
