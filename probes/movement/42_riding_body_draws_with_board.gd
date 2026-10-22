extends MovementProbe
## Runs alone
## Real riding at 60 physics Hz and 15 rendered frames/s: the visible suit
## shares the actual board's rendered origin, and near-camera torso surfaces
## remain available to other cameras and shadows without entering your view.

var _watch := false
var _rows: Array[Dictionary] = []

func run() -> void:
	await load_moving()
	var flat := flat_place(world.player_world_x(), world.player_world_z(), 100.0, 30.0)
	await place(flat.x, flat.z, Vector2(0, -1))
	var board := await ride_here(&"big_battery")
	Engine.physics_ticks_per_second = 60
	Engine.max_fps = 15
	process_priority = 100
	player.camera.rotation_degrees.x = -58.0
	var body := player.body
	for name: String in ["collar", "head"]:
		var mesh := body.get_node(NodePath(name)) as MeshInstance3D
		check(mesh.layers & player.camera.cull_mask == 0 and mesh.layers & 1 == 0
			and mesh.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
			"the %s stays out of your view but retains external rendering and shadows" % name)
	for name: String in ["hips", "trunk", "hand_r", "hand_l", "foot_r", "foot_l"]:
		var mesh := body.get_node(NodePath(name)) as MeshInstance3D
		check(mesh.layers & player.camera.cull_mask != 0, "the %s remains visible" % name)
	hold(["move_forward"])
	await simulate(3.0)
	_watch = true
	for i in 30:
		await get_tree().process_frame
	_watch = false
	hold([])
	var worst := 0.0
	var fastest := 0.0
	for row in _rows:
		worst = maxf(worst, row.error)
		fastest = maxf(fastest, row.speed)
	print("BODY_RIDE ", JSON.stringify({"frames":_rows.size(), "max_speed":fastest, "max_origin_error_m":worst,
		"physics_hz":Engine.physics_ticks_per_second,"render_cap":Engine.max_fps}))
	check(_rows.size() >= 20 and fastest > 8.0 and player.board == board,
		"the fixture observes actual sustained riding at speed")
	check(worst < 0.0001, "every rendered suit frame shares the actual board origin (%.6f m)" % worst)
	Engine.max_fps = 0

func _process(_delta: float) -> void:
	if not _watch or player == null or player.ride == null:
		return
	# Sample after ordinary camera, body and board callbacks, never their future projections.
	var origin := player.board.global_position + Vector3.UP * float(Catalog.DEVICES[&"board"].size.y) * 0.5
	_rows.append({"error":player.body.global_position.distance_to(origin), "speed":player.ride.velocity.length(),
		"fraction":Engine.get_physics_interpolation_fraction(), "physics":Engine.get_physics_frames(),
		"render":Engine.get_process_frames(), "body":player.body.global_position,
		"camera":player.camera.global_position,"board":player.board.global_position})
