extends MenuProbe
## The real screen takes projected mouse clicks and returns the camera after focus.
func run() -> void:
	Tuning.current().run_seed = 1234
	Tuning.current().salvage = false
	Tuning.current().surveyor_preflight["enabled"] = true
	main = MAIN.instantiate()
	main.opens_on_menu = false
	add_child(main)
	world = main.world()
	var until := Time.get_ticks_msec() + 60000
	while (world.arrival == null or not is_instance_valid(world.arrival.preflight)) and Time.get_ticks_msec() < until:
		await get_tree().physics_frame
	var prep := world.arrival.preflight
	check(is_instance_valid(prep), "the preparation room opens")
	if not is_instance_valid(prep): return
	var screen := prep.ship.computer_at.global_position
	world.teleport(world.player, Transform3D(Basis.IDENTITY, Vector3(screen.x, prep.ship.global_position.y + 0.02, screen.z + 0.9)))
	world.player.velocity = Vector3.ZERO
	world.player.camera.look_at(screen)
	await physics_frames(2)
	var before := world.player.camera.global_transform
	press(&"interact")
	check(prep.computer_open(), "use focuses the persistent physical display")
	await get_tree().process_frame
	check(world.player.camera.global_position.distance_to(before.origin) < 0.25, "camera focus begins with continuous travel")
	await get_tree().create_timer(0.6).timeout
	var station := prep.computer
	var rect := station.ui._confirm.get_global_rect()
	var uv := rect.get_center() / Vector2(station.PIXELS)
	var extent := prep.ship.computer_screen_size()
	var on_glass := station._display.to_global(Vector3((uv.x - 0.5) * extent.x, (0.5 - uv.y) * extent.y, 0))
	var mouse_at := world.player.camera.unproject_position(on_glass)
	for down in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.position = mouse_at
		click.pressed = down
		Input.parse_input_event(click)
		await get_tree().process_frame
	check(world.arrival_state.preflight.plan_confirmed, "a real projected mouse click confirms the displayed course")
	press(&"ui_cancel")
	await get_tree().create_timer(0.6).timeout
	check(not prep.computer_open() and world.player.is_physics_processing(), "leaving focus restores movement")
	check(world.player.camera.global_position.distance_to(before.origin) < 0.01, "the camera returns to the same viewpoint")
	check(is_instance_valid(station) and station.ui.visible, "the station stays visible after stepping back")
