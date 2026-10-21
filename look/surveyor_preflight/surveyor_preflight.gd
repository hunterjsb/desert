extends MenuProbe
## Actual Main: ship, real computer, physical pod, then its selected flight and recovery.
var out: String
func run() -> void:
	Tuning.current().run_seed = 1234
	Tuning.current().salvage = false
	Tuning.current().surveyor_preflight["enabled"] = true
	out = OS.get_cmdline_user_args()[-1]
	DirAccess.make_dir_recursive_absolute(out)
	main = MAIN.instantiate()
	main.opens_on_menu = false
	add_child(main)
	world = main.world()
	Dev.hide_overlays()
	var until := Time.get_ticks_msec() + 90000
	while (world.arrival == null or not is_instance_valid(world.arrival.preflight)) and Time.get_ticks_msec() < until:
		await get_tree().physics_frame
	check(world.arrival != null and is_instance_valid(world.arrival.preflight), "interactive preparation opens")
	if world.arrival == null or not is_instance_valid(world.arrival.preflight):
		return
	var prep := world.arrival.preflight
	await shoot("ship")
	stand(prep.ship.computer_at.global_position + Vector3(0, -1.03, 0.9), prep.ship.computer_at.global_position)
	await physics_frames(2)
	press(&"interact")
	check(is_instance_valid(prep.computer), "real launch computer opens")
	if not is_instance_valid(prep.computer):
		return
	var view := prep.computer as LaunchComputer
	var id: StringName = world.arrival_state.landing_plan.candidates[-1].id
	view._buttons[id].pressed.emit()
	await shoot("computer")
	press(&"ui_cancel")
	await get_tree().process_frame
	stand(prep.ship.pod_entry_at.global_position + Vector3(0, 0, 0.6), prep.ship.pod_entry_at.global_position + Vector3.UP * 0.5)
	await shoot("pod")
	press(&"interact")
	await shoot("seated")
	press(&"interact")
	check(not world.arrival.preparing(), "the selected physical pod launches")
	var captured := {}
	until = Time.get_ticks_msec() + 90000
	while Time.get_ticks_msec() < until:
		await get_tree().physics_frame
		var state := world.arrival_state
		var phase: StringName = state.get("phase", &"")
		if captured.has(phase) or (phase != &"recovery" and float(state.get("progress", 0.0)) < 0.5):
			continue
		await shoot(String(phase))
		captured[phase] = true
		if phase == &"recovery":
			break
	check(world.arrival_state.get("phase", &"") == &"recovery", "the actual prepared flight reaches recovery")
	check(world.arrival_state.get("materialized", false) and world.player.suit.carried.is_empty(), "only physically loaded gear lands")
	print("Prepared flight: roles=%d rescued=%d phase=%s" % [world.arrival_nodes.size(), world.rescued, world.arrival_state.get("phase", &"")])

func stand(at: Vector3, toward: Vector3) -> void:
	world.teleport(world.player, Transform3D(Basis.IDENTITY, at))
	world.player.velocity = Vector3.ZERO
	world.player.camera.look_at(toward)

func shoot(name: String) -> void:
	for frame in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join(name + ".png"))
