extends WorldProbe
## World & terrain probe 1: at 1,000 random points in collision range, a downward
## ray hits within 1 cm of height_at.


func run() -> void:
	await load_world()
	await get_tree().physics_frame
	var space := world.get_world_3d().direct_space_state
	var tuning := Tuning.current()
	var reach := float(tuning.near_radius * tuning.chunk_size)
	var center := (Vector2(world.terrain.chunk_at(world.player_world_x(), world.player_world_z())) \
		+ Vector2(0.5, 0.5)) * tuning.chunk_size
	var misses := 0
	var worst := 0.0
	for i in 1000:
		var x := center.x + randf_range(-reach, reach)
		var z := center.y + randf_range(-reach, reach)
		var h := world.height_at(x, z)
		var from := Vector3(world.engine_x(x), h + 20.0, world.engine_z(z))
		var query := PhysicsRayQueryParameters3D.create(from, from - Vector3(0, 40, 0))
		query.exclude = [world.player.get_rid()]
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			misses += 1
		else:
			worst = maxf(worst, absf(hit.position.y - h))
	check(misses == 0, "every ray hits the ground (%d missed)" % misses)
	check(worst < 0.01, "collision within 1 cm of height_at (worst %.4f m)" % worst)
	print("worst ray error %.5f m" % worst)
