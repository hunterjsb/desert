extends SalvageProbe
## Salvage & ruins probe 3: every ruin floor meets the sand. By the ground's
## one function, for every ruin within 3 km of the start on two seeds: inside,
## the sand lies just under the floor; outside, it drifts up the walls so no
## wall shows its foot, and lies level with the floor at each door so you walk
## in without a step; round it the ground is never too steep to walk up. In
## the world, at the nearest: the collision is the function, the floor is
## solid where it should be, and the ruin's boxes are part of its chunk's
## ground, there exactly while the sand is solid.

const SEEDS := [1234, 7]
const RADIUS := 3000.0
## Points along each outer face, m apart, and how far out a door's level runs.
const ALONG := 0.5
const DOOR_RUN := 2.0
const LEVEL := 0.05
## A drift stands at least this high on a wall away from its doors.
const DRIFTED := 0.3


func run() -> void:
	var tuning := Tuning.current()
	tuning.salvage = true
	var steepest := 0.0
	var ruins := 0
	var faults := 0
	for run_seed: int in SEEDS:
		var shape := TerrainShape.new(run_seed, tuning)
		for ruin in shape.ruins.around(0.0, 0.0, RADIUS):
			ruins += 1
			var found := _footprint(shape, ruin)
			steepest = maxf(steepest, found.steepest)
			if not found.faults.is_empty():
				faults += 1
				printerr("seed %d ruin at %s turn %d: %s" % [run_seed, ruin.center, ruin.turn, ", ".join(found.faults)])
	var slip := tuning.slip_angle
	print("%d ruins; the steepest ground round any is %.1f°" % [ruins, steepest])
	check(ruins >= 20, "ruins stand near the start (%d)" % ruins)
	check(faults == 0, "every ruin's floor meets the sand, its drifts hide its walls' feet and its doors are level (%d don't)"
		% faults)
	check(steepest < slip, "the ground round every ruin can be walked (steepest %.1f° against %.0f°)" % [steepest, slip])
	await _in_the_world()


## What's wrong with a ruin's footprint, and the steepest ground round it.
func _footprint(shape: TerrainShape, ruin: Ruin) -> Dictionary:
	var faults := PackedStringArray()
	var half := Vector2(Ruin.HALF)
	var inner := half - Vector2.ONE * Ruin.WALL
	# Inside: every lattice point under the floor lies just under it.
	var worst := 0.0
	for v in range(-inner.y, inner.y + 1):
		for u in range(-inner.x, inner.x + 1):
			var at := ruin.to_world(Vector2(u, v))
			worst = maxf(worst, absf(shape.height_at(at.x, at.y) - (ruin.floor_y - Ruin.SAND_UNDER)))
	if worst > 1e-4:
		faults.append("sand off the floor by %.4f m" % worst)
	# Round the outside of the walls: never down to their foot, drifted up them away from doors.
	var lowest := INF
	var bare := INF
	for side in 4:
		var length := half.x if side < 2 else half.y
		var t := -length
		while t <= length:
			var p := Vector2(t, half.y + 0.05) if side == 0 else (Vector2(t, -half.y - 0.05) if side == 1
				else (Vector2(half.x + 0.05, t) if side == 2 else Vector2(-half.x - 0.05, t)))
			var at := ruin.to_world(p)
			var sand := shape.height_at(at.x, at.y)
			lowest = minf(lowest, sand - (ruin.floor_y - Ruin.FOOT))
			if Ruin.DOORS.all(func(d: Array) -> bool: return p.distance_to(d[0]) > Ruin.DOOR_WIDTH + Ruin.DOOR_SIDE + 0.5):
				bare = minf(bare, sand - ruin.floor_y)
			t += ALONG
	if lowest < 0.2:
		faults.append("a wall's foot shows (%.2f m of sand over it)" % lowest)
	if bare < DRIFTED:
		faults.append("a wall stands bare of drift (%.2f m)" % bare)
	# At each door, the sand across it and out from it is level with the floor.
	for door: Array in Ruin.DOORS:
		var out: Vector2 = door[1]
		var across := Vector2(out.y, -out.x)
		var step := 0.0
		for k in 9:
			for o in [-0.5, 0.0, 0.5]:
				var p: Vector2 = door[0] - out * Ruin.WALL + out * (k * (Ruin.WALL + DOOR_RUN) / 8.0) + across * o
				var at := ruin.to_world(p)
				step = maxf(step, absf(shape.height_at(at.x, at.y) - ruin.floor_y))
		if step > LEVEL:
			faults.append("a door's step is %.3f m" % step)
	# Round it: the steepest ground at 1 m, as the collision has it.
	var steepest := 0.0
	var reach := Vector2(Ruin.half_on(ruin.turn)) + Vector2.ONE * Ruin.APRON
	for j in range(-reach.y, reach.y + 1):
		for i in range(-reach.x, reach.x + 1):
			var x := ruin.center.x + i
			var z := ruin.center.y + j
			if absf(ruin.plan(i, j).x) <= half.x and absf(ruin.plan(i, j).y) <= half.y:
				continue
			var grade := Vector2(shape.height_at(x + 0.5, z) - shape.height_at(x - 0.5, z),
				shape.height_at(x, z + 0.5) - shape.height_at(x, z - 0.5))
			steepest = maxf(steepest, rad_to_deg(atan(grade.length())))
	return {"faults": faults, "steepest": steepest}


## At the nearest ruin, in the world: its chunk's collision is the function,
## its floor is solid, and its boxes come and go with the sand's collision.
func _in_the_world() -> void:
	await load_salvage()
	var ruin := ruins_near()[0]
	var at := ruin.to_world(Ruin.APPROACH)
	await go(at.x, at.y)
	var coord := world.terrain.chunk_at(ruin.center.x, ruin.center.y)
	var chunk: TerrainChunk = world.terrain.chunks().filter(func(c: TerrainChunk) -> bool: return c.coord == coord)[0]
	check(chunk.ruin() == ruin, "the ruin stands in its chunk")
	# Function equals collision, over the ruin's whole chunk.
	var off := 0.0
	for j in chunk.side + 1:
		for i in chunk.side + 1:
			var x := coord.x * chunk.side + i
			var z := coord.y * chunk.side + j
			off = maxf(off, absf(chunk.heights[j * (chunk.side + 1) + i] - world.shape.height_at(x, z)))
	# Its samples are kept in 32 bits.
	check(off < 1e-4, "the chunk's samples are the ground's one function, ruin and all (%.6f m)" % off)
	# The floor is solid in every room, at the floor's top.
	var space := world.get_world_3d().direct_space_state
	var floor_off := 0.0
	for room: Rect2 in Ruin.ROOMS:
		for k in 5:
			var p := room.position + room.size * Vector2(0.15 + 0.175 * k, 0.85 - 0.175 * k)
			var top := on_floor(ruin, p)
			var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(top + Vector3.UP * 0.5, top - Vector3.UP))
			floor_off = maxf(floor_off, INF if hit.is_empty() else absf(hit.position.y - ruin.floor_y))
	check(floor_off < 0.001, "every room's floor is solid at its top (%.4f m)" % floor_off)
	var boxes := _ruin_boxes(chunk)
	check(boxes == Ruin.boxes().size(), "its boxes are in its chunk's collision (%d)" % boxes)
	# Away until its sand isn't solid: its boxes go with it.
	var middle := Vector2(ruin.center)
	await go(middle.x + 5.0 * world.tuning.chunk_size, middle.y)
	check(not chunk.has_collision() and _ruin_boxes(chunk) == 0, "its boxes go when its sand stops being solid")
	await go(at.x, at.y)
	check(_ruin_boxes(chunk) == Ruin.boxes().size(), "and come back with it")


func _ruin_boxes(chunk: TerrainChunk) -> int:
	for child in chunk.get_children():
		if child is StaticBody3D:
			return child.get_children().filter(func(c: Node) -> bool: return (c as CollisionShape3D).shape is BoxShape3D).size()
	return 0
