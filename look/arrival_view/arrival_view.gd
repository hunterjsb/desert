extends DeckProbe
## Real orbital SubViewport phases over an actual loaded landing scene.
func run() -> void:
	await load_lines()
	world.time_warp = 0.0
	world.time = world.tuning.day_minutes * 60.0 * 0.31
	world.set_physics_process(false)
	var at := world.player.global_position + Vector3(0, 0, -4)
	at.y = world.height_under(at) + Chassis.THICK * 0.5 + 0.06
	var rig := PodShell.build(world.content, Transform3D(Basis.IDENTITY, at))
	rig.deck.freeze = true
	var hatch := rig.deck.detach(rig.named[&"hatch"])
	var roof := rig.deck.detach(rig.named[&"roof_a"])
	for panel in [hatch, roof]:
		panel.freeze = true
	hatch.global_position = at + Vector3(-1.5, 0, 0.7)
	roof.global_position = at + Vector3(-0.5, 0, 1.6)
	look(at + Vector3(-2.6, 1.6, 2.8), at + Vector3(0.4, 0.4, 0))
	var view := ArrivalView.new()
	add_child(view)
	view.setup(world)
	Dev.hide_overlays()
	var state := {"landing_point": Sphere.point(world.moon.latitude, world.moon.longitude), "heading": world.player.global_rotation.y}
	view.present({"phase": &"entry", "progress": 0.5, "elapsed": 2.0})
	check(not view._voice.playing and view._voice.bus == Sounds.WORLD, "a resumed mid-phase view starts silently on the world bus")
	var out := OS.get_cmdline_user_args()[-1]
	DirAccess.make_dir_recursive_absolute(out)
	var previous: StringName = &"entry"
	var cues := 0
	for sample: Array in [[&"orbit", 0.5], [&"ejection", 0.5], [&"descent", 0.35], [&"descent", 0.9], [&"entry", 0.25], [&"entry", 0.9], [&"landing", 0.45], [&"recovery", 1.0]]:
		state.phase = sample[0]
		state.progress = sample[1]
		state.elapsed = sample[1] * 5.0
		view.present(state)
		if previous != state.phase and state.phase in [&"ejection", &"entry", &"landing"]:
			check(view._voice.playing, "an actual arrival phase transition starts its cue")
			cues += int(view._voice.playing)
		previous = state.phase
		await physics_frames(12)
		await RenderingServer.frame_post_draw
		var name := "%s_%02d.png" % [sample[0], roundi(sample[1] * 100.0)]
		get_viewport().get_texture().get_image().save_png(out.path_join(name))
		print("Captured actual ArrivalView ", name)
		if state.phase == &"landing":
			await physics_frames(40)
			check(not view._voice.playing, "the short touchdown cue finishes")
			view.present(state)
			check(not view._voice.playing, "presenting the same phase again does not replay its cue")
	check(cues == 3, "ejection, entry and touchdown each sounded once")
	view.dispose()
	await get_tree().process_frame
	check(not is_instance_valid(view), "the presentation disposes independently of its world")
