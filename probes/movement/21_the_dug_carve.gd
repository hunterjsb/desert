extends MovementProbe
## Movement probe 21: the dug carve. From speed, a hard turn standing skids:
## the board swings out ahead of your way. The same turn with move back held
## digs the edge in and grips, your way following the board round, and comes
## out slower: it trades speed for grip. Dug, the board's low edge comes down
## to the sand, and never into it.

## Come round this far, radians, the turn is done.
const ROUND := PI * 0.45


func run() -> void:
	await load_moving()
	set_rate(60, 4)
	var flat := flat_place(world.player_world_x(), world.player_world_z(), 200.0, 40.0)
	var flat_turn := await _turn(flat, ["move_left"])
	var dug := await _turn(flat, ["move_left", "move_back"])
	for each: Dictionary in [flat_turn, dug]:
		print("%s from %.1f m/s: round in %.2f s at %.1f m/s, sliding %.0f° at most, its lowest edge %.3f m off the sand"
			% ["dug" if each == dug else "flat", each.from, each.took, each.out, rad_to_deg(each.slid), each.lowest])
	check(flat_turn.slid > deg_to_rad(30.0), "standing, a hard turn skids (%.0f°)" % rad_to_deg(flat_turn.slid))
	check(dug.slid < flat_turn.slid * 0.5, "dug in, it grips (%.0f° against %.0f°)"
		% [rad_to_deg(dug.slid), rad_to_deg(flat_turn.slid)])
	check(dug.took < flat_turn.took and dug.out < flat_turn.out, "coming round sooner and slower (%.2f s at %.1f m/s)"
		% [dug.took, dug.out])
	check(dug.lowest < 0.03 and dug.lowest > -0.005 and flat_turn.lowest > 0.04,
		"its low edge down to the sand dug and never into it (%.3f m, %.3f m standing)" % [dug.lowest, flat_turn.lowest])
	set_rate(60)


## Up to speed along +x, then a hard turn left on `keys`: {from, took, out,
## slid, lowest}. `slid` is the furthest the board pointed off your way;
## `lowest`, the nearest a corner of its underside came to the sand.
func _turn(flat: Dictionary, keys: Array) -> Dictionary:
	player.step_off()
	for node in world.content.get_children():
		if node is Hoverboard:
			node.free()
	await place(flat.x - 60.0, flat.z, Vector2(1.0, 0.0))
	await ride_here()
	hold(["move_forward"])
	await ride_for(6.0)
	var start := Vector2(player.velocity.x, player.velocity.z)
	var size: Vector3 = Catalog.DEVICES[&"board"].size
	var seen := {"from": start.length(), "took": INF, "out": 0.0, "slid": 0.0, "t": 0.0, "lowest": INF}
	hold(keys)
	await ride_for(3.0, func() -> void:
		var v := Vector2(player.velocity.x, player.velocity.z)
		var ride := player.ride
		seen.t += 1.0 / ticks_per_second()
		if seen.took == INF:
			seen.slid = maxf(seen.slid, absf(v.angle_to(ride.ahead)))
			if absf(start.angle_to(v)) >= ROUND:
				seen.took = seen.t
				seen.out = v.length()
		var pose := ride.board_pose(false)
		for corner: Vector3 in [Vector3(1, -1, 1), Vector3(-1, -1, 1), Vector3(1, -1, -1), Vector3(-1, -1, -1)]:
			var at := pose * (corner * size * 0.5)
			seen.lowest = minf(seen.lowest, at.y - world.height_under(at)))
	hold([])
	return seen
