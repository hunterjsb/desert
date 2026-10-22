extends MenuProbe
## The physical station exposes real optional packing without moving anything.
var station: PhysicalLaunchStation

func run() -> void:
	var tuning := Tuning.current()
	tuning.run_seed = 1234
	tuning.salvage = false
	tuning.surveyor_preflight.enabled = true
	main = MAIN.instantiate()
	main.opens_on_menu = false
	add_child(main)
	world = main.world()
	var deadline := Time.get_ticks_msec() + 60000
	while (world.arrival == null or not is_instance_valid(world.arrival.preflight)) and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	var prep := world.arrival.preflight
	check(is_instance_valid(prep), "the real preparation and physical screen become ready")
	if not is_instance_valid(prep):
		return
	await physics_frames(5)
	var named := SurveyorRecovery.named(world)
	var beacon := named[&"beacon"] as Device
	var report := PreflightCargo.packing_report(world, prep.ship)
	check(not _row(report, &"beacon").aboard and _row(report, &"water").aboard,
		"the actual optional rack beacon is omitted while preloaded water is aboard")
	world.player.hands.hold(beacon)
	await physics_frames(4)
	report = PreflightCargo.packing_report(world, prep.ship)
	check(not _row(report, &"beacon").aboard and world.player.hands.held == beacon,
		"carrying the original beacon does not pack it")
	world.player.hands.stow()
	Stick.put(prep.ship.pod.deck, prep.ship.pod_parts[&"floor_b"], Chassis.TOP, Vector2(0.34, -0.04), 0.0, beacon)
	await physics_frames(4)
	report = PreflightCargo.packing_report(world, prep.ship)
	check(_row(report, &"beacon").aboard and PreflightCargo.loaded(world, prep.ship).has(&"beacon"),
		"a legally mounted original beacon appears aboard through the real loading rules")
	world.teleport(world.player, Transform3D(Basis.IDENTITY, Vector3(prep.ship.computer_at.global_position.x,
		prep.ship.global_position.y + 0.02, prep.ship.computer_at.global_position.z + 0.9)))
	world.player.velocity = Vector3.ZERO
	world.player.camera.look_at(prep.ship.computer_at.global_position)
	await physics_frames(2)
	press(&"interact")
	await get_tree().create_timer(0.6).timeout
	station = prep.computer
	check(station.focused, "the existing physical glass takes focus")
	if not station.focused:
		return
	var ui := station.ui
	var plan: Dictionary = world.arrival_state.landing_plan.duplicate(true)
	var confirmed := bool(world.arrival_state.preflight.plan_confirmed)
	await click(ui._cargo_toggle.get_global_rect().get_center())
	ui.refresh()
	await get_tree().process_frame
	check(ui._show_cargo and ui._cargo_page.visible and ui._chart.visible
		and ui._cargo_page.text.text.contains(_row(report, &"beacon").label + "\n" + _row(report, &"beacon").reason),
		"projected mouse input reveals the cargo report while the real globe remains visible")
	var water := named[&"water"] as Supply
	var amount := water.amount
	water.amount = 0.0
	ui.refresh()
	check(ui._cargo_page.text.text.contains("Refill water") and ui._instruction.text.contains("Launch blocked"),
		"depleted required stores remain actionable while cargo is open")
	water.amount = amount
	ui.refresh()
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed = true
	wheel.position = pointer(ui._cargo_page.get_global_rect().get_center())
	Input.parse_input_event(wheel)
	wheel = wheel.duplicate()
	wheel.pressed = false
	Input.parse_input_event(wheel)
	await get_tree().process_frame
	check(ui._cargo_page.scroll > 0.0 and ui._cargo_page.bar.visible,
		"ordinary wheel input scrolls the long manifest through the themed page bar")
	var offset := ui._cargo_page.scroll
	ui.refresh()
	check(is_equal_approx(ui._cargo_page.scroll, offset) and world.arrival_state.landing_plan == plan
		and bool(world.arrival_state.preflight.plan_confirmed) == confirmed and named[&"beacon"] == beacon,
		"live report refresh preserves reading position, course and original equipment")
	await click(ui._cargo_toggle.get_global_rect().get_center())
	check(not ui._show_cargo and ui._result.visible and ui._readiness.visible,
		"the same focused display returns to the ordinary landing forecast")
	press(&"ui_cancel")
	await get_tree().create_timer(0.6).timeout
	check(not station.focused and station._display.visible and world.player.is_physics_processing(),
		"stepping back leaves the physical screen lit and restores walking")

func _row(report: Array[Dictionary], uid: StringName) -> Dictionary:
	for item: Dictionary in report:
		if item.uid == uid:
			return item
	return {}

func pointer(pixel: Vector2) -> Vector2:
	var uv := pixel / Vector2(station.PIXELS)
	var extent := station._ship.computer_screen_size()
	var glass := station._display.to_global(Vector3((uv.x - 0.5) * extent.x, (0.5 - uv.y) * extent.y, 0))
	return world.player.camera.unproject_position(glass)

func click(pixel: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = pointer(pixel)
	Input.parse_input_event(motion)
	await get_tree().process_frame
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = pointer(pixel)
		event.pressed = down
		Input.parse_input_event(event)
		await get_tree().process_frame
