extends DeckProbe
## Resolved landed survivors with normal physics, without a replacement kit grant.
func run() -> void:
	await load_lines()
	var at := Vector2(world.player_world_x() + 6, world.player_world_z())
	var state := SurveyorManifest.resolve(1234, world.start)
	state.landing_world = at
	state.heading = 0.25
	state.exit_world = at + Vector2(-3.2, 0).rotated(-state.heading)
	var made := SurveyorRecovery.materialize(world, state)
	check(state.get("materialized", false), "resolved survivors physically materialize")
	await simulate(1.0)
	check(made.values().all(func(n: Node) -> bool: return is_instance_valid(n)), "all surviving roles remain after physical settling")
	var deck := made.get(&"floor_a") as Chassis
	if deck == null:
		return
	var middle := deck.global_position + Vector3(0.5, 0.45, 0)
	look(middle + Vector3(-4.2, 2.8, 4.2), middle)
	world.player.camera.fov = 65.0
	Dev.hide_overlays()
	await physics_frames(8)
	await RenderingServer.frame_post_draw
	var path := OS.get_cmdline_user_args()[-1]
	get_viewport().get_texture().get_image().save_png(path)
	print("RECOVERY PHYSICAL roles=", made.size(), " placements=", state.placements)
