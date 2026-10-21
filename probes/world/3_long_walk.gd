extends WorldProbe
## Exclusive on noisy runners
## World & terrain probe 3: 20 km, half straight and half wandering, dropping boxes
## every kilometre. Nothing ends up below the ground, chunks stay bounded, and
## memory stays flat as the boxes are left behind and forgotten. Memory is
## compared back at the same settled ground, after warming up, so the extra
## chunks and collision kept behind a turn don't count as a leak.

const STEP := 32.0


func run() -> void:
	await load_world()
	var tuning := Tuning.current()
	var most_chunks := (2 * tuning.view_radius + 3) ** 2
	var x := world.player_world_x()
	var z := world.player_world_z()
	var anchor := Vector2(x, z)
	var heading := 0.0
	var walked := 0.0
	var next_drop := 1000.0
	var baseline_objects := 0
	var baseline_memory := 0.0
	var biggest_world := 0
	var most_boxes := 0
	var lowest := INF
	while walked < 20000.0:
		if walked >= 10000.0 and fmod(walked, 512.0) < STEP:
			heading = randf() * TAU
		x += cos(heading) * STEP
		z += sin(heading) * STEP
		walked += STEP
		teleport(x, z)
		await settle(true)
		await physics_frames(2)
		lowest = minf(lowest, clearance(world.player))
		biggest_world = maxi(biggest_world, world.terrain.chunks().size())
		var boxes := world.content.get_children().filter(func(n: Node) -> bool: return n is RigidBody3D)
		most_boxes = maxi(most_boxes, boxes.size())
		if walked >= next_drop:
			next_drop += 1000.0
			var dropped: Array[RigidBody3D] = []
			for i in 3:
				dropped.append(drop_box(x + randf_range(-20, 20), z + randf_range(-20, 20)))
			await physics_frames(90)
			for box in dropped:
				check(clearance(box) > 0.1, "box dropped at %.0f m rests on the sand" % walked)
		if baseline_objects == 0 and walked >= 2000.0:
			await _back_at(anchor)
			baseline_objects = int(Performance.get_monitor(Performance.OBJECT_COUNT))
			baseline_memory = Performance.get_monitor(Performance.MEMORY_STATIC)
			teleport(x, z)
			await settle(true)
	await _back_at(anchor)
	var objects := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var memory := Performance.get_monitor(Performance.MEMORY_STATIC)
	print("chunks <= %d, boxes <= %d, objects %d -> %d, memory %.1f -> %.1f MB, lowest player clearance %.3f m"
		% [biggest_world, most_boxes, baseline_objects, objects, baseline_memory / 1048576.0,
			memory / 1048576.0, lowest])
	check(lowest > -0.05, "the player never ended up below the sand (lowest %.3f m)" % lowest)
	check(biggest_world <= most_chunks, "loaded chunks stay bounded (%d)" % biggest_world)
	check(most_boxes <= 12, "left-behind boxes are forgotten (most at once %d)" % most_boxes)
	check(objects < baseline_objects * 1.1, "object count stays flat (%d -> %d)" % [baseline_objects, objects])
	check(memory < baseline_memory + 64.0 * 1048576.0, "memory stays flat")


func _back_at(anchor: Vector2) -> void:
	teleport(anchor.x, anchor.y)
	await settle()
	await physics_frames(2)
