extends ArrivalSaveProbe
## Disk restore keeps the player's chosen head direction independently of the flight course.
func run() -> void:
	await prepare_arrival()
	var pod := PodShell.build(world.content, Transform3D(Basis.IDENTITY, world.player.global_position + Vector3(0, 2, -5)))
	pod.deck.freeze = true
	for role: StringName in pod.named:
		pod.named[role].set_meta(&"arrival_uid", role)
	world.arrival_nodes = pod.named.duplicate()
	world.arrival_state.phase = &"descent"
	world.arrival_state.materialized = true
	world.player.set_process_unhandled_input(false)
	var view := ArrivalView.new()
	add_child(view)
	view.setup(world)
	view.present(world.arrival_state)
	var destination: Vector3 = world.arrival_state.landing_point
	var manifest: Array = world.arrival_state.equipment.duplicate(true)
	Controls.mouse_free = false
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(-420, 180)
	Input.parse_input_event(motion)
	await get_tree().process_frame
	var angles := view.head_angles()
	check(angles.length() > 0.1 and saves.save(world), "the mouse-chosen flight view saves through the real disk store")
	view.dispose()
	check(await resume_arrival(), "the saved flight resumes")
	var restored := ArrivalView.new()
	add_child(restored)
	restored.setup(world)
	restored.present(world.arrival_state)
	check(restored.head_angles() == angles and world.arrival_state.landing_point == destination
		and world.arrival_state.equipment == manifest, "disk preserves the chosen view without changing course or cargo")
	restored.dispose()
	Controls.mouse_free = true
