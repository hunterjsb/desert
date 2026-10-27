extends WeatherProbe
## Real fitted station, unpowered glass and rebuilt kit in the same camp light.
func run() -> void:
	await load_weather()
	world.time_warp = 0.0
	world.tuning.eye_adapts = false
	world.player.set_physics_process(false)
	world.player.feel.set_process(false)
	world.player.vitals.god = true
	Dev.hide_overlays()
	for layer in world.find_children("*", "CanvasLayer", true, false): layer.visible = false
	world.player.camera.fov = 60
	var out := OS.get_cmdline_user_args()[-1]
	DirAccess.make_dir_recursive_absolute(out)
	var base := world.player.global_position + Vector3(0, 0, -6)
	var rig := Rig.build(null, [[&"piece", Vector2i(1, 0)],
		[&"stick", Vector2i.ZERO, &"top", Vector2(0, -0.12), 180.0,
		[&"console", [&"screen", &"radar", &"anemometer", &"barometer", &"hygrometer", &"particle_sensor", &"ground_radar"]], &"console"],
		[&"stick", Vector2i(1, 0), &"top", Vector2(-0.25, 0.1), 0.0, &"shield", &"shield"],
		[&"stick", Vector2i(1, 0), &"top", Vector2(0.3, 0.25), 0.0, &"big_battery"]])
	_place(rig.deck, base)
	(rig.named.shield as ShieldGenerator).stand(true)
	var second := Rig.make([&"console", [&"screen", &"anemometer", &"radar"]]) as Console
	Catalog.found_in(second, Eras.SECOND, &"watchtower", 1234)
	_place(second, base + Vector3(2.4, 0, 0), PI + 0.25)
	var condenser := Catalog.device(&"condenser")
	Catalog.found_in(condenser, Eras.SECOND, &"watchtower", 1234)
	_place(condenser, base + Vector3(3.4, 0, -0.5), PI)
	var planter := Rig.make([&"planter", [&"harvester", &"solar_panel"]])
	_place(planter, base + Vector3(-1.3, 0, -1.5))
	await physics_frames(60)
	var station := (rig.named.console as Console).global_position
	var glass := second.global_position
	var centre := base + Vector3(1.3, 0.8, 0)
	var storm := OS.get_cmdline_user_args().has("--storm")
	var shots := [["station5_morning", 0.4, station + Vector3(2.5, 1, 4).normalized() * 5, station],
		["station5_dusk", 0.715, station + Vector3(2.5, 1, 4).normalized() * 5, station],
		["live_screen", 0.4, station + Vector3(0.3, 0.1, 1.6), station],
		["glass_front", 0.4, glass + Vector3(0, 0.1, 1.8), glass],
		["glass_oblique", 0.4, glass + Vector3(-1.5, 0.4, 0.8), glass],
		["second_rebuilds", 0.4, base + Vector3(4, 1.3, -1.8), base + Vector3(2.9, 0.6, 0)],
		["camp20", 0.4, centre + Vector3(12, 4, 15).normalized() * 20, centre]]
	if storm:
		var t := find_time(func(t: float) -> bool: return field.storm_at(world.world_x(base.x), world.world_z(base.z), t) >= 1.0 and world.weather.day.time_of_day(t, world.moon.longitude) > 0.35 and world.weather.day.time_of_day(t, world.moon.longitude) < 0.55)
		world.time = t
		shots = [["station5_storm", -1, station + Vector3(2.5, 1, 4).normalized() * 5, station], ["bubble", -1, base + Vector3(0.6, 1.7, 2), centre]]
	var rid := get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid, true)
	for shot: Array in shots:
		if shot[1] >= 0: world.time = world.tuning.day_minutes * 60 * fposmod(shot[1] - world.tuning.start_time_of_day, 1.0)
		world.power.live(world.tuning.power_tick, world.time)
		look(shot[2], shot[3])
		await physics_frames(35)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(out.path_join(shot[0] + ".png"))
		print("STATION CONTEXT ", shot[0], " powered=", (rig.named.console as Console).powered, " glass_powered=", second.powered, " glass_running=", second.running(), " gpu_ms=", RenderingServer.viewport_get_measured_render_time_gpu(rid))
	for body in [rig.deck, second, condenser, planter]: body.queue_free()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw

func _place(body: RigidBody3D, at: Vector3, yaw := 0.0) -> void:
	world.content.add_child(body)
	body.freeze = true
	var box := Finds.bounds(body)
	body.global_position = Vector3(at.x, world.height_under(at) - box.position.y + 0.02, at.z)
	body.rotation.y = yaw

func look(eye: Vector3, target: Vector3) -> void:
	var player := world.player
	var to := target - eye
	player.rotation = Vector3(0, atan2(-to.x, -to.z), 0)
	player.global_position = eye - player.camera.position
	player.camera.rotation = Vector3(atan2(to.y, Vector2(to.x, to.z).length()), 0, 0)
