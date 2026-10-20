extends LineProbe
## Rope & tethering probe 8: origin shifts are invisible. A camp staked out in
## a steady storm wind (two floating planters, each on two lines to
## stakes upwind, and a slack spare lying on the sand between two stakes), with
## you holding a third device's line in your hand and a fourth's at your waist,
## crosses an origin shift. No line's pull jumps, every drawn end is still on
## its ring in the frames after, and nothing, drawn rope included, moves in the
## world.

## A line's pull may change this much across the shift tick, N, on top of a
## hundredth of it.
const STEADY := 1.0
const ON_RING := 0.01
const KEPT := 0.01


## Runs after every other node's _process in a frame.
class LastInFrame extends Node:
	var each: Callable

	func _ready() -> void:
		process_priority = 1000

	func _process(_delta: float) -> void:
		each.call()


func run() -> void:
	await load_lines()
	speed_up(2)
	# Downwind is +z; the camp's stakes are upwind of it.
	var camp: Array[Device] = [floating(&"planter", spot(-4.0, -3.0)), floating(&"planter", spot(3.0, -3.0))]
	for piece in camp:
		for side in [-1.5, 1.5]:
			var stake := driven_stake(piece.global_position + Vector3(side, 0.0, -6.0))
			Line.between(world, piece.free_tie(stake.global_position), stake.free_tie(piece.global_position), 0.2)
	var spare_a := driven_stake(spot(-1.0, -12.0))
	var spare_b := driven_stake(spot(3.0, -12.0))
	Line.between(world, spare_a.free_tie(spare_b.global_position), spare_b.free_tie(spare_a.global_position), 2.0)
	var towed: Array[Device] = [floating(&"planter", spot(-1.0, 4.0)), floating(&"planter", spot(1.0, 4.0))]
	for i in 2:
		var spare := Catalog.stake()
		world.content.add_child(spare)
		spare.global_transform = Transform3D(Basis(Vector3.BACK, PI / 2.0), spot(i * 1.2 - 0.6, 1.0) + Vector3.UP * 0.04)
		Line.between(world, towed[i].free_tie(spare.global_position), spare.free_tie(towed[i].global_position), 0.0)
		look(spot(i * 1.2 - 0.6, 0.0) + Vector3.UP * 1.65, spare.global_position)
		await simulate(0.1)
		check(hands.grab(), "you take up a towed line's stake")
		await simulate(0.5)
		if i == 0:
			# Looking up, not at the sand where use would drive it: use ties it on.
			look(eye(), eye() + Vector3(0.0, 1.0, -1.0))
			check(hands.interact() and world.player.waist.holds(spare), "and tie it at your waist")
			await simulate(0.2)
	blow(Vector2(0.0, wind.storm_speed()))
	await simulate(20.0)

	var bodies: Array[Node3D] = []
	bodies.append_array(camp)
	bodies.append_array(towed)
	var where := bodies.map(_world_position)
	var drawn := _drawn()
	var lines := ropes.ropes.duplicate()
	var before := lines.map(func(r: Rope) -> float: return r.tension)
	var worst := {"ring": 0.0, "frames": 0}
	var watch := LastInFrame.new()
	watch.each = func() -> void:
		worst.frames += 1
		for rope in ropes.ropes:
			var points := rope.strand.points
			worst.ring = maxf(worst.ring, maxf(points[0].distance_to(rope.a.global_position),
				points[points.size() - 1].distance_to(rope.b.global_position)))
	world.shift_origin(Vector2i(3, -2))
	# Where everything is in the world the moment after, before anything moves on.
	var moved := 0.0
	var now := bodies.map(_world_position)
	for i in bodies.size():
		moved = maxf(moved, (now[i] - where[i]).length())
	var rope_moved := 0.0
	var drawn_now := _drawn()
	for i in drawn.size():
		rope_moved = maxf(rope_moved, drawn_now[i].distance_to(drawn[i]))
	add_child(watch)
	await get_tree().physics_frame
	# A line gone across the shift is the biggest jump of all.
	var after := lines.map(func(r: Rope) -> float: return r.tension if ropes.ropes.has(r) else INF)
	await simulate(1.0)
	watch.queue_free()
	var jump := 0.0
	var allowed := true
	for i in before.size():
		var change: float = absf(after[i] - before[i])
		jump = maxf(jump, change)
		allowed = allowed and change < STEADY + 0.01 * before[i]
	print("%d lines pulling %s N; across the shift the most any changed %.3f N; drawn ends at most %.4f m off over %d frames; bodies moved %.4f m in the world"
		% [before.size(), before.map(func(t: float) -> int: return roundi(t)), jump, worst.ring, worst.frames, moved])
	print("drawn rope moved at most %.4f m in the world across the shift" % rope_moved)
	check(before.size() == 7 and before.filter(func(t: float) -> bool: return t > 50.0).size() == 6,
		"six lines loaded, and the spare slack")
	check(allowed, "no line's pull jumps across the shift (%.3f N)" % jump)
	check(worst.ring < ON_RING, "every drawn end stays on its ring (%.4f m)" % worst.ring)
	check(moved < KEPT, "nothing moves in the world (%.4f m)" % moved)
	check(rope_moved < KEPT, "nor does any drawn rope (%.4f m)" % rope_moved)


func _world_position(body: Node3D) -> Vector3:
	return Vector3(world.world_x(body.global_position.x), body.global_position.y,
		world.world_z(body.global_position.z))


## Every drawn point of every line, in world coordinates.
func _drawn() -> PackedVector3Array:
	var all := PackedVector3Array()
	for strand in ropes.strands:
		for p in strand.points:
			all.append(_world_position_of(p))
	return all


func _world_position_of(p: Vector3) -> Vector3:
	return Vector3(world.world_x(p.x), p.y, world.world_z(p.z))
