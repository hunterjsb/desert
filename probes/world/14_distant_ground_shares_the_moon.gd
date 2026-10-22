extends WorldProbe
## Distant ground must share one observer frame through movement and origin shifts.

func run() -> void:
	await load_world()
	world.player.set_physics_process(false)
	var horizons: Horizons
	for child in world.terrain.get_children():
		if child is Horizons:
			horizons = child
	check(horizons != null, "distant hills exist")
	if horizons == null:
		return
	await get_tree().process_frame
	_check_frame(horizons)
	var radius := SurfaceProjection.radius(world.tuning)
	var eye := world.player.camera.global_position
	var anchor := Vector2(eye.x, eye.z)
	var point := Vector3(eye.x + 15000.0, 600.0, eye.z - 4000.0)
	var drawn := SurfaceProjection.project(point, anchor, radius)
	check(drawn.y < point.y - 30.0, "distant summit lowers on the large moon")
	check(SurfaceProjection.unproject(drawn, anchor, radius).distance_to(point) < 0.001, "weather sampling recovers undeformed ground")
	var normal := SurfaceProjection.normal(Vector3.UP, Vector2(point.x, point.z), anchor, radius)
	var along := SurfaceProjection.project(point + Vector3.RIGHT, anchor, radius) - drawn
	check(absf(normal.dot(along.normalized())) < 0.001, "projected normal follows the surface")
	var old_height := world.height_at(world.player_world_x(), world.player_world_z())
	var off := Vector3(3.0 * world.tuning.chunk_size, 0.0, -2.0 * world.tuning.chunk_size)
	world.shift_origin(Vector2i(3, -2))
	await get_tree().process_frame
	await get_tree().process_frame
	_check_frame(horizons)
	var shifted := SurfaceProjection.project(point - off, anchor - Vector2(off.x, off.z), radius)
	check((shifted + off).distance_to(drawn) < 0.002, "origin shifts preserve the drawn surface")
	check(is_equal_approx(old_height, world.height_at(world.player_world_x(), world.player_world_z())), "rendering leaves physical ground unchanged")
	var arrays := FarRing.apron(world.shape, Vector2i.ZERO, world.tuning)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var least := INF
	var most := 0.0
	for vertex in vertices:
		var distance := Vector2(vertex.x, vertex.z).length()
		least = minf(least, distance)
		most = maxf(most, distance)
	check(least < world.tuning.far_radius and most >= SurfaceProjection.horizon_distance(2.0, radius), "continuous apron overlaps far ground and reaches the eye-level horizon")
	check(vertices.size() < 3000 and most <= world.tuning.horizon_range.y + 0.1, "apron stays inside the existing distant budget (%d vertices)" % vertices.size())
	check(world.terrain._far.extra_cull_margin > 1.0 and world.terrain._apron.extra_cull_margin > 200.0, "native bounds contain lowered distant vertices")

func _check_frame(horizons: Horizons) -> void:
	var eye := world.player.camera.global_position
	var wanted := Vector3(eye.x, eye.z, SurfaceProjection.radius(world.tuning))
	for material: ShaderMaterial in [world.terrain.sand_material, world.terrain._apron_material, horizons._sand,
			horizons._summit, world.terrain.skyline._box_look, world.terrain.skyline._glint_look, world.terrain.skyline._dust_look]:
		var actual: Vector3 = material.get_shader_parameter("surface_frame")
		check(actual.distance_to(wanted) < 0.001, "selected distant material follows the actual main observer")
