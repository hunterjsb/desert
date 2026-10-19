extends WorldProbe
## World & terrain probe 11: the sand holds what grip says. A crate resting on
## the sand, pushed sideways by a force rising slowly, starts to slide at the
## share of its weight World.grip says, as the sleep's drift and the wind's
## balance count on.

## The push rises by this share of the weight a second.
const RAMP := 0.05


func run() -> void:
	await load_world()
	var x := world.player_world_x() + 6.0
	var z := world.player_world_z()
	# One pushed each way, so the sand's slope cancels.
	var boxes: Array[RigidBody3D] = [drop_box(x, z, 0.3), drop_box(x + 1.0, z, 0.3)]
	for box in boxes:
		box.can_sleep = false
	await physics_frames(120)
	var from := boxes.map(func(box: RigidBody3D) -> Vector3: return box.global_position)
	var weight := BOX_MASS * world.gravity
	var at := [NAN, NAN]
	var share := 0.0
	while share < 1.0 and (is_nan(at[0]) or is_nan(at[1])):
		share += RAMP / Engine.physics_ticks_per_second
		for i in 2:
			var moved: Vector3 = boxes[i].global_position - from[i]
			if not is_nan(at[i]):
				continue
			if Vector2(moved.x, moved.z).length() > 0.01:
				at[i] = share
			else:
				boxes[i].apply_central_force(Vector3.RIGHT * (1.0 - 2.0 * i) * share * weight)
		await get_tree().physics_frame
	var held: float = (at[0] + at[1]) * 0.5
	var says := world.grip(boxes[0]) / weight
	check(absf(held - says) < says * 0.1,
		"a resting crate slides at the %.2f of its weight grip says (%.2f)" % [says, held])
