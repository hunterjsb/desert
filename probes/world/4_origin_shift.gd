extends WorldProbe
## World & terrain probe 4: a resting stack and a jointed pair come through an
## origin shift without moving in the world or relative to each other, and the
## world shifts on its own when the player strays.


func run() -> void:
	await load_world()
	var px := world.player_world_x()
	var pz := world.player_world_z()
	var stack: Array[RigidBody3D] = []
	for i in 3:
		stack.append(drop_box(px + 4.0, pz, 0.4 + i * (BOX_SIZE + 0.05)))
	var a := drop_box(px - 4.0, pz)
	var b := drop_box(px - 4.0 + BOX_SIZE + 0.1, pz)
	await get_tree().physics_frame
	var joint := PinJoint3D.new()
	world.content.add_child(joint)
	joint.global_position = (a.global_position + b.global_position) * 0.5
	joint.node_a = a.get_path()
	joint.node_b = b.get_path()
	await physics_frames(240)

	var bodies: Array[RigidBody3D] = stack.duplicate()
	bodies.append_array([a, b])
	var before := bodies.map(_world_position)
	await get_tree().physics_frame
	world.shift_origin(Vector2i(3, -2))
	await physics_frames(60)
	var after := bodies.map(_world_position)
	var worst := 0.0
	for i in bodies.size():
		worst = maxf(worst, (after[i] - before[i]).length())
	check(worst < 0.01, "bodies keep their world position through a shift (worst %.4f m)" % worst)
	var pair_before: float = (before[3] - before[4]).length()
	var pair_after: float = (after[3] - after[4]).length()
	check(absf(pair_after - pair_before) < 0.01, "the jointed pair keeps its spacing")
	check(stack.all(func(box: RigidBody3D) -> bool: return box.linear_velocity.length() < 0.05),
		"the stack is still at rest")

	var origin := world.origin_chunk
	var stray := float((Tuning.current().origin_shift_chunks + 1) * Tuning.current().chunk_size)
	var x := world.world_x(stray + 10.0)
	var z := world.player_world_z()
	teleport(x, z)
	await physics_frames(3)
	check(world.origin_chunk != origin, "straying shifts the origin on its own")
	check(absf(world.player.global_position.x) < stray, "the player is back near the engine origin")
	check(absf(world.player_world_x() - x) < 0.01, "the player kept its world position")


## Near spawn, so a Vector3 holds world positions to well under a millimetre.
func _world_position(body: Node3D) -> Vector3:
	return Vector3(world.world_x(body.global_position.x), body.global_position.y,
		world.world_z(body.global_position.z))
