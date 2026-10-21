extends WorldProbe
## The actual ArrivalView keeps one seated shell and hands the matching eye to ground rendering.
func run() -> void:
	await load_world()
	world.time_warp = 0.0
	world.player.set_physics_process(false)
	world.player.feel.set_process(false)
	var rig := PodShell.build(world.content, Transform3D(Basis.IDENTITY, world.player.global_position + Vector3(0, 1, -4)))
	rig.deck.freeze = true
	world.arrival_nodes = rig.named.duplicate()
	var view := ArrivalView.new()
	add_child(view)
	view.setup(world)
	var shell := view._interior
	var original_nodes := world.content.get_child_count()
	var screen := Rect2(Vector2.ZERO, Vector2.ONE)
	for phase in [&"orbit", &"ejection", &"descent", &"entry"]:
		view.present({"phase": phase, "elapsed": 0.5, "progress": 0.5})
		var window: Vector4 = view._effects._look.get_shader_parameter(&"aperture")
		var rect := Rect2(Vector2(window.x, window.y), Vector2(window.z, window.w))
		check(view._interior == shell and shell.transform.is_equal_approx(view._seat_eye.affine_inverse())
			and view._screen.visible and rect.size.x > 0.1 and rect.size.y > 0.1
			and screen.encloses(rect), "each flight phase looks through the same real seated shell window")
	world.player.restore_ground_pose(&"prone")
	world.player.global_transform = rig.deck.global_transform * PodShell.seat_pose()
	world.player.camera.position = Vector3(0, world.tuning.surveyor_preflight.seat_eye_m, 0)
	world.player.camera.rotation = Vector3(0.1, 0, 0)
	var base := world.player.camera.transform
	var hit := {"phase": &"landing", "elapsed": world.tuning.surveyor_arrival.impact_jolt_s * 0.25, "progress": 0.1}
	view.present(hit)
	var first := world.player.camera.transform
	view.present(hit)
	check(not view._screen.visible and first.is_equal_approx(world.player.camera.transform)
		and first.origin.distance_to(base.origin) > 0.0
		and first.origin.distance_to(base.origin) <= world.tuning.surveyor_arrival.impact_offset_m + 0.000001,
		"ground rendering uses one bounded nonaccumulating recoil on the seated eye")
	view.present({"phase": &"landing", "elapsed": 2.0, "progress": 1.0})
	check(world.player.camera.transform.is_equal_approx(base) and world.content.get_child_count() == original_nodes,
		"the settled eye returns to its original seat without spawning bodies")
	view.present(hit)
	view.dispose()
	check(world.player.camera.transform.is_equal_approx(base), "disposal restores the exact unmodified ground camera")
