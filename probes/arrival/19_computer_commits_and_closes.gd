extends Probe
## Computer choices update saved data while closing restores its modal mouse state.
func run() -> void:
	get_window().size = Vector2i(1280, 720)
	var plan := {"version": LandingPlan.VERSION, "seed": 1234, "anchor": {"world": Vector2.ZERO},
		"candidates": [], "selected_id": &"fallback", "heading": 0.0, "profile": &"standard"}
	for id in [&"fallback", &"site_1"]:
		plan.candidates.append({"id": id, "point": Vector3.RIGHT, "landing_world": Vector2.ZERO,
			"latitude": 0.0, "longitude": 0.0, "safe": true, "footprint": {"rise_m": 0.2}, "signals": []})
	var changes: Array[Dictionary] = []
	var before := Input.mouse_mode
	var view := LaunchComputer.new()
	view.setup(null, plan, func(next: Dictionary) -> void: changes.append(next))
	add_child(view)
	for frame in 3:
		await get_tree().process_frame
	check((view._panel.position + view._panel.size).y <= get_viewport().get_visible_rect().size.y,
		"the initial modal keeps its controls inside the viewport")
	view._buttons[&"site_1"].pressed.emit()
	view._heading.value = 135.0
	view._profile.select(2)
	view._profile.item_selected.emit(2)
	check(not changes.is_empty() and changes[-1].selected_id == &"site_1"
		and is_equal_approx(changes[-1].heading, deg_to_rad(135.0)) and changes[-1].profile == &"steep",
		"the actual controls commit destination, heading and trajectory")
	check(plan.selected_id == &"fallback" and plan.heading == 0.0, "editing the view does not alias its caller's saved data")
	var closes := [0]
	view.closed.connect(func() -> void: closes[0] += 1)
	var event := InputEventAction.new()
	event.action = &"ui_cancel"
	event.pressed = true
	view._input(event)
	await get_tree().process_frame
	check(closes[0] == 1 and not is_instance_valid(view) and Input.mouse_mode == before,
		"cancel closes the modal and restores the previous mouse mode")
