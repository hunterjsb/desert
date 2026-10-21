extends MenuProbe
## An automatic-arrival recovery and camp-building walk, with collision on.

var out: String
var run_seed_now: int

func run() -> void:
	# Isolate physical surface recovery, not the interactive ship preparation.
	Tuning.current().surveyor_preflight["enabled"] = false
	get_window().unfocusable = true
	AudioServer.set_bus_mute(0, true)
	out = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out)
	var seeds := [1234, 42, 9876]
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="):
			seeds = [int(arg.trim_prefix("--seed="))]
	for run_seed: int in seeds:
		run_seed_now = run_seed
		Tuning.current().run_seed = run_seed
		Tuning.current().salvage = false
		if main == null:
			await open_main()
		Tuning.current().run_seed = run_seed
		await main.new_game(false, false, Kit.standard())
		world = main.world()
		await started()
		print("ARRIVAL_LIGHT ",run_seed," time=",world.time," shown=",world.weather.day.sun_shown(world.time)," eye=",world.weather.eye.exposure()," local=",world.weather.day.time_of_day(world.time,world.moon.longitude))
		await _shot("landed")
		if OS.get_cmdline_user_args().has("--lighting"):
			for sample in 4:
				print("LIGHT ",run_seed," tick=",sample," day=",world.weather.day.time_of_day(world.time, world.moon.longitude)," exposure=",world.weather.eye.exposure()," seen=",world.weather.eye.seen," sun=",world.get_node("Sun").light_energy)
				await _shot("light_%d" % sample)
				await physics_frames(60)
			await main._quit_to_menu()
			continue

		if is_zero_approx(world.weather.day.sun_shown(world.time)):
			press(&"headlamp")
			await physics_frames(45)
			check(world.player.headlamp.on and world.player.headlamp.visible, "the bound free suit lamp lights eclipse recovery")
			await _shot("headlamp")
		print("SEED ",run_seed," roles ",world.arrival_state.placements)
		for role: StringName in [&"camp_cell", &"shield", &"panel"]:
			var gear: Node3D = world.arrival_nodes[role]
			print("GEAR ",role," at ",gear.global_position - world.player.global_position)
		var deck := world.arrival_nodes.get(&"roof_a", world.arrival_nodes[&"floor_a"]) as Chassis
		var okay := await _mount(&"camp_cell", deck, Vector3(-0.28, Chassis.THICK * 0.5, -0.28))
		okay = await _mount(&"shield", deck, Vector3(0.24, Chassis.THICK * 0.5, -0.22)) and okay
		var shield := world.arrival_nodes[&"shield"] as ShieldGenerator
		if okay:
			await _approach(shield.global_position, 1.2)
			_aim(shield.global_position)
			await physics_frames(8)
			press(&"interact")
			await physics_frames(90)
			check(shield.running() and world.power.pool_wh(shield) > 0.0, "ordinary recovered pieces make a powered shield")
		await _shot("powered")
		await _shot("worked")
		check(main.save_run(), "recovered camp can be saved")
		var recovery: Array = world.arrival_state.equipment.filter(func(e: Dictionary) -> bool: return e.recovered).map(func(e: Dictionary) -> StringName: return e.uid)
		print("RECOVERED ",run_seed," ",recovery)
		await main.resume()
		world = main.world()
		check(world.arrival_state.phase == &"recovery", "save returns to physical recovery")
		for role: StringName in recovery:
			check(world.arrival_state.equipment.filter(func(e: Dictionary) -> bool: return e.uid == role)[0].recovered, "recovery remains recorded")
		if okay:
			var resumed_shield := world.arrival_nodes[&"shield"] as ShieldGenerator
			check(resumed_shield.running() and world.power.pool_wh(resumed_shield) > 0.0, "recovered powered shelter resumes intact")
		await _shot("resumed")
		check(world.player.collision_layer != 0 and world.player.is_physics_processing(), "player collision and motion stay live")
		await main._quit_to_menu()


func _aim(at: Vector3) -> void:
	var player := world.player
	var delta := at - player.camera.global_position
	player.rotation.y = atan2(-delta.x, -delta.z)
	player.camera.rotation.x = atan2(delta.y, Vector2(delta.x, delta.z).length())


func _approach(at: Vector3, reach: float) -> bool:
	var player := world.player
	var initial := Vector2(at.x - player.global_position.x, at.z - player.global_position.z).length()
	var last := initial
	var stagnant := 0
	for frame in 480:
		var gap := Vector2(at.x - player.global_position.x, at.z - player.global_position.z).length()
		if gap <= reach:
			Input.action_release(&"move_forward")
			await physics_frames(12)
			return true
		_aim(Vector3(at.x, player.camera.global_position.y, at.z))
		Input.action_press(&"move_forward")
		await get_tree().physics_frame
		if frame % 30 == 0:
			stagnant = stagnant + 1 if last - gap < 0.05 else 0
			last = gap
			if stagnant >= 4:
				break
	Input.action_release(&"move_forward")
	print("BLOCKED walk from ",initial," remaining ",last," at ",player.global_position)
	return false


func _take(role: StringName) -> bool:
	var body: RigidBody3D = world.arrival_nodes[role]
	var landing: Vector2 = world.arrival_state.landing_world
	var local := Basis(Vector3.UP, -float(world.arrival_state.heading)) * (body.global_position - Vector3(world.engine_x(landing.x), body.global_position.y, world.engine_z(landing.y)))
	if local.z > 0.7:
		var origin := Vector3(world.engine_x(landing.x), 0.0, world.engine_z(landing.y))
		var facing := Basis(Vector3.UP, world.arrival_state.heading)
		await _approach(origin + facing * Vector3(-2.8, 0.0, local.z + 1.8), 0.4)
		await _approach(origin + facing * Vector3(local.x, 0.0, local.z + 1.4), 0.4)
	await _approach(body.global_position, 0.85)
	var visible := false
	for offset: Vector3 in [Vector3.ZERO, Vector3(1.3, 0, 0), Vector3(0, 0, 1.3), Vector3(-1.3, 0, 0)]:
		if offset != Vector3.ZERO:
			await _approach(body.global_position + Basis(Vector3.UP, world.arrival_state.heading) * offset, 0.35)
		for frame in 15:
			await get_tree().physics_frame
			_aim(body.global_position)
		world.player.hands._look()
		var target: Node = world.player.hands.look_part if body is Part else world.player.hands.look_device
		if target == body:
			visible = true
			break
	if not visible:
		print("OCCLUDED ",role," at ",body.global_position," eye=",world.player.camera.global_position)
		check(false, "surviving gear is visible from its approach")
		return false
	press(&"hands_grab")
	await physics_frames(30)
	var hands := world.player.hands
	var got := hands.held == body or hands.grasp.body == body
	print("TAKE ",role," ",got," held=",hands.held," grasp=",hands.grasp.body," looked=",hands.look_device," / ",hands.look_part)
	check(got, "normal take reaches surviving " + String(role))
	return got


func _mount(role: StringName, deck: Chassis, at: Vector3) -> bool:
	if not await _take(role):
		await _shot(String(role) + "_blocked")
		return false
	var body: RigidBody3D = world.arrival_nodes[role]
	await _approach(deck.global_position, 1.3)
	_aim(deck.to_global(at))
	await physics_frames(40)
	print("PLACE ",role," socket=",world.player.hands.socket," stick=",world.player.hands.sticking," stand=",world.player.hands.stand)
	press(&"hands_grab")
	await physics_frames(35)
	var mounted: bool = body.host() == deck if body is Device else (body as Part).socket != null
	print("MOUNT ",role," ",mounted)
	check(mounted, "normal placement seats recovered " + String(role))
	return mounted


func _shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join("%d_%s.png" % [run_seed_now, label]))
