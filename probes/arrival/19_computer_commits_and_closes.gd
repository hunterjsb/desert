extends Probe
## Confirming the displayed default commits an independent saved course.
func run() -> void:
	var plan := {"version": LandingPlan.VERSION, "seed": 1234, "anchor": {"world": Vector2.ZERO},
		"candidates": [{"id": &"fallback", "point": Vector3.RIGHT, "landing_world": Vector2.ZERO,
		"safe": true, "footprint": {"rise_m": 0.2}, "signals": []}],
		"selected_id": &"fallback", "heading": 0.0, "profile": &"standard"}
	var changes: Array[Dictionary] = []
	var view := LaunchComputer.new()
	view.setup(null, plan, func(next: Dictionary) -> void: changes.append(next))
	view.size = Vector2(1152, 680)
	add_child(view)
	await get_tree().process_frame
	view.set_focused(true)
	view._confirm.pressed.emit()
	check(changes.size() == 1 and changes[0].selected_id == &"fallback", "the visible default can be explicitly committed without changing it")
	changes[0].heading = 1.0
	check(plan.heading == 0.0 and view._plan.heading == 0.0, "a callback cannot mutate either displayed or caller data")
	view.set_focused(false)
	check(view._confirm.disabled and view.visible, "leaving focus keeps the physical display lit without accepting input")
	view.dispose()
