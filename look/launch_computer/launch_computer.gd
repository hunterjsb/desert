extends Probe
## The actual seeded corridor in the themed launch computer.
func run() -> void:
	var output := OS.get_cmdline_user_args()[-1]
	DirAccess.make_dir_recursive_absolute(output)
	var tuning := Tuning.current()
	var shape := TerrainShape.new(1234, tuning)
	var point := Starts.find(shape, &"artery", tuning)
	var ground := Starts.ground(shape, tuning, &"artery", point)
	var anchor := Sites.Anchor.new(ground.x, ground.y, point, 1.0, shape.history.radius)
	shape.landforms.follow(anchor)
	var plan := LandingPlan.build(shape, anchor)
	print("LANDING_CAPTURE_PLAN ", JSON.stringify(plan))
	var view := LaunchComputer.new()
	view.setup(null, plan, func(_next: Dictionary) -> void: pass)
	add_child(view)
	for frame in 3:
		await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(output.path_join("fallback.png"))
	if plan.candidates.size() > 1:
		view._buttons[plan.candidates[1].id].pressed.emit()
		view._heading.value = 135.0
		view._profile.select(2)
		view._profile.item_selected.emit(2)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(output.path_join("alternative.png"))
	view.dispose()
