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
	var old_height := world.height_at(world.player_world_x(), world.player_world_z())
	world.shift_origin(Vector2i(3, -2))
	await get_tree().process_frame
	await get_tree().process_frame
	_check_frame(horizons)
	check(is_equal_approx(old_height, world.height_at(world.player_world_x(), world.player_world_z())), "rendering leaves physical ground unchanged")
	var radius := SurfaceProjection.radius(world.tuning)
	var apron := _reach(FarRing.apron(world.shape, Vector2i.ZERO, world.tuning))
	var far := _reach(FarRing.make(world.shape, Vector2i.ZERO, world.tuning))
	check(apron.x < world.tuning.far_radius and apron.y >= SurfaceProjection.horizon_distance(2.0, radius),
		"the apron overlaps far ground and reaches the eye-level horizon, leaving no gap")
	# Lowered past their native boxes, distant meshes would be culled while in view;
	# the eye stands anywhere in the centre chunk the meshes are laid from.
	var eye := world.tuning.chunk_size * sqrt(2.0)
	check(world.terrain._apron.extra_cull_margin >= pow(apron.y + eye, 2.0) / (2.0 * radius)
		and world.terrain._far.extra_cull_margin >= pow(far.y + eye, 2.0) / (2.0 * radius),
		"distant meshes stay drawn wherever the large moon lowers them")


## Nearest and farthest horizontal reach of a distant mesh's vertices, m.
func _reach(arrays: Array) -> Vector2:
	var reach := Vector2(INF, 0.0)
	for vertex: Vector3 in arrays[Mesh.ARRAY_VERTEX]:
		var d := Vector2(vertex.x, vertex.z).length()
		reach = Vector2(minf(reach.x, d), maxf(reach.y, d))
	return reach

func _check_frame(horizons: Horizons) -> void:
	var eye := world.player.camera.global_position
	var wanted := Vector3(eye.x, eye.z, SurfaceProjection.radius(world.tuning))
	for material: ShaderMaterial in [world.terrain.sand_material, world.terrain._apron_material, horizons._sand,
			horizons._summit, world.terrain.skyline._box_look, world.terrain.skyline._glint_look, world.terrain.skyline._dust_look]:
		var actual: Vector3 = material.get_shader_parameter("surface_frame")
		check(actual.distance_to(wanted) < 0.001, "selected distant material follows the actual main observer")
