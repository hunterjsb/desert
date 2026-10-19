extends MovementProbe
## Movement probe 30: a skid gouges the sand. Flat out, a carve the hover
## holds leaves its faint line; turned hard enough to skid, the board leaves
## a gouge plainly deeper and wider, kept as any mark is.

## Turning your view this fast, rad/s, move forward held, as probe 25 does.
const GENTLE := 0.4
const HARD := 1.6
const TURNING := 2.5
## A mark this deep shows, of a footprint's.
const SHOWS := 0.1


func run() -> void:
	await load_moving()
	set_rate(60, 4)
	var flat := flat_place(world.player_world_x(), world.player_world_z(), 200.0, 40.0)
	var carve := await _mark(flat, GENTLE)
	var skid := await _mark(flat, HARD)
	for each: Array in [["a carve", carve], ["a skid", skid]]:
		print("%s: its mark %.2f of a footprint deep, %.2f m wide, over %d places"
			% [each[0], each[1].depth, each[1].width, each[1].places])
	check(skid.places > 10 and skid.depth > carve.depth * 2.0 and skid.width > carve.width * 2.0,
		"a skid gouges deeper and wider than a carve's line (%.2f against %.2f deep, %.2f against %.2f m wide)"
		% [skid.depth, carve.depth, skid.width, carve.width])
	set_rate(60)


## Up to speed along +x on a fresh board, then your view turning at `rate`
## with move forward held: the mark left where it went, across its way, at
## the middle of each tick it turned (skidding, if it skids): {depth, width,
## places}, the medians.
func _mark(flat: Dictionary, rate: float) -> Dictionary:
	player.step_off()
	for node in world.content.get_children():
		if node is Hoverboard:
			node.free()
	var tracks := world.terrain.tracks
	# Every mark before this one filled in.
	tracks.clock += Tracks.DEEPEST
	await place(flat.x - 60.0, flat.z, Vector2(1.0, 0.0))
	await ride_here()
	hold(["move_forward"])
	await ride_for(6.0)
	var ride := player.ride
	var path: Array[Vector4] = []
	var dt := 1.0 / ticks_per_second()
	await ride_for(TURNING, func() -> void:
		player.rotation.y -= rate * dt
		if rate == GENTLE or ride.skidding:
			var at := ride.board_pose(false).origin
			var way := ride.velocity.normalized()
			path.append(Vector4(world.world_x(at.x), world.world_z(at.z), way.x, way.y)))
	hold([])
	var depths: Array[float] = []
	var widths: Array[float] = []
	for k in range(path.size() / 4, path.size() * 3 / 4):
		var across := Vector2(-path[k].w, path[k].z)
		var deepest := 0.0
		var shown := 0
		for s in range(-40, 41):
			var at := Vector2(path[k].x, path[k].y) + across * s * 0.05
			var depth := tracks.depth_at(at.x, at.y)
			deepest = maxf(deepest, depth)
			shown += 1 if depth >= SHOWS else 0
		depths.append(deepest)
		widths.append(shown * 0.05)
	depths.sort()
	widths.sort()
	var middle := depths.size() / 2
	return {"depth": depths[middle] if middle < depths.size() else 0.0,
		"width": widths[middle] if middle < widths.size() else 0.0, "places": depths.size()}
