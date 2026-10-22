extends MenuProbe
## Real projected dragging persists a pending pulse; covering the glass cannot edit it.
var station: PhysicalLaunchStation

func run() -> void:
	Tuning.current().run_seed = 1234
	Tuning.current().salvage = false
	main = MAIN.instantiate()
	main.opens_on_menu = false
	add_child(main)
	world = main.world()
	var prep := await cabin()
	check(is_instance_valid(prep), "the preparation room opens")
	if not is_instance_valid(prep): return
	var screen := prep.ship.computer_at.global_position
	world.teleport(world.player, Transform3D(Basis.IDENTITY, Vector3(screen.x, prep.ship.global_position.y + 0.02, screen.z + 0.9)))
	world.player.velocity = Vector3.ZERO
	world.player.camera.look_at(screen)
	await physics_frames(20)
	var feel_was_processing := world.player.feel.is_processing()
	press(&"interact")
	await physics_frames(36)
	station = prep.computer
	check(station.focused and not world.player.feel.is_processing(), "the station owns its focused camera")
	await button(station.ui._confirm.get_global_rect().get_center(), true)
	await button(station.ui._confirm.get_global_rect().get_center(), false)
	check(world.arrival_state.preflight.plan_confirmed, "a projected button click confirms the initial pulse")
	var before: Vector2 = world.arrival_state.landing_plan.departure_trajectory.pulse
	var handle := station.ui._chart.position + station.ui._project(station.ui._frame.pulse_handle)
	check(station.ui._chart.get_rect().has_point(handle), "the actual pulse handle is reachable on the chart")
	var moved := handle + Vector2(28, -18)
	await button(handle, true)
	await motion(moved, true)
	await button(moved, false)
	var pending: Vector2 = world.arrival_state.landing_plan.departure_trajectory.pulse
	check(pending.distance_to(before) > 0.0001 and not world.arrival_state.preflight.plan_confirmed,
		"a real glass drag changes the saved pulse and requires confirmation again")
	check(main.save_run(), "the pending pulse saves through the ordinary run path")
	var saved: Dictionary = main.saves().held().arrival
	check(saved.landing_plan.departure_trajectory.pulse == pending and not saved.preflight.plan_confirmed,
		"the disk snapshot keeps the actual dragged pulse unconfirmed")
	# Cover during a new drag; releasing under the console must cancel that drag.
	await button(handle, true)
	press(&"console")
	await get_tree().process_frame
	await get_tree().process_frame
	check(main.ui.dev_console.visible and station.focused and not station.ui._focused,
		"the console covers the physical display without leaving its focus")
	var covered: Vector2 = world.arrival_state.landing_plan.departure_trajectory.pulse
	await motion(handle + Vector2(-75, 40), true)
	await button(handle + Vector2(-75, 40), false)
	check(world.arrival_state.landing_plan.departure_trajectory.pulse == covered,
		"mouse input on the covered glass cannot edit the plan")
	press(&"console")
	await get_tree().process_frame
	await get_tree().process_frame
	check(not main.ui.dev_console.visible and station.focused and station.ui._focused
		and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE and not world.player.feel.is_processing(),
		"uncovering returns the visible pointer and focused camera ownership")
	await motion(handle + Vector2(65, 25), false)
	check(world.arrival_state.landing_plan.departure_trajectory.pulse == covered,
		"a drag released under the console does not resume on pointer movement")
	press(&"ui_cancel")
	await physics_frames(36)
	check(not prep.computer_open() and world.player.is_physics_processing()
		and world.player.feel.is_processing() == feel_was_processing,
		"stepping back returns movement and the original camera processing")

func pointer(pixel: Vector2) -> Vector2:
	var uv := pixel / Vector2(station.PIXELS)
	var extent := station._ship.computer_screen_size()
	var glass := station._display.to_global(Vector3((uv.x - 0.5) * extent.x, (0.5 - uv.y) * extent.y, 0))
	return world.player.camera.unproject_position(glass)

func button(pixel: Vector2, down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = pointer(pixel)
	event.pressed = down
	Input.parse_input_event(event)
	await get_tree().process_frame

func motion(pixel: Vector2, down: bool) -> void:
	var event := InputEventMouseMotion.new()
	event.position = pointer(pixel)
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	Input.parse_input_event(event)
	await get_tree().process_frame
