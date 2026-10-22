extends WorldProbe
## Head input turns the seated view, never the pod's saved trajectory.
func run() -> void:
	await load_world()
	world.player.set_physics_process(false)
	world.player.set_process_unhandled_input(false)
	var pod := PodShell.build(world.content, Transform3D(Basis.IDENTITY, world.player.global_position + Vector3(0, 1, -4)))
	pod.deck.freeze = true
	world.arrival_nodes = pod.named.duplicate()
	var state := {"phase": &"descent", "elapsed": 2.5, "progress": 0.4, "preflight": {"pulse": Vector2(0.4, 0.0)}}
	var course: Dictionary = state.preflight.duplicate(true)
	var view := ArrivalView.new()
	add_child(view)
	view.setup(world)
	view.present(state)
	var camera := view._orbit.camera.global_transform
	var shell := view._interior.global_transform
	Controls.mouse_free = false
	await _motion(Vector2(350, -120))
	view.present(state)
	check(view._orbit.camera.global_basis != camera.basis and state.head_look.length() > 0.1,
		"ordinary mouse input actually turns the falling view")
	check(view._interior.global_transform.is_equal_approx(shell) and state.preflight == course,
		"the pod stays put and looking does not steer the saved launch")
	var ui := UIRoot.new()
	add_child(ui)
	ui.open(Words.new("covered"))
	var angles := view.head_angles()
	await _motion(Vector2(-250, 80))
	check(view.head_angles() == angles, "a covering menu consumes head input")
	ui.close_top()
	Controls.mouse_free = false
	await _motion(Vector2(100000, -100000))
	var limit := view.head_angles()
	check(absf(limit.x) <= deg_to_rad(world.tuning.surveyor_arrival.head_yaw_deg)
		and absf(limit.y) <= deg_to_rad(world.tuning.surveyor_arrival.head_pitch_deg), "seated looking stays within its head limits")
	var restored: Dictionary = bytes_to_var(var_to_bytes(state))
	view.present(restored)
	check(view.head_angles() == limit, "the saved head direction restores without resetting forward")
	world.player.restore_ground_pose(&"prone")
	world.player.global_transform = pod.deck.global_transform * PodShell.seat_pose()
	world.player.camera.transform = Transform3D(Basis(Vector3.RIGHT, 0.1), Vector3(0, world.tuning.surveyor_preflight.seat_eye_m, 0))
	restored.phase = &"landing"
	restored.elapsed = 1.2
	restored.progress = 1.0
	view.present(restored)
	var facing := world.player.camera.global_basis
	view.dispose()
	check(world.player.camera.global_basis.is_equal_approx(facing) and is_zero_approx(world.player.camera.rotation.y),
		"recovery keeps the looked direction and transfers yaw to ordinary movement")
	Controls.mouse_free = true

func _motion(relative: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.relative = relative
	Input.parse_input_event(motion)
	await get_tree().process_frame
