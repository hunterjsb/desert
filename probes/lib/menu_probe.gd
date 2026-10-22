class_name MenuProbe
extends WorldProbe
## For probes of the menus: the game as it runs, opened on the main menu or
## straight into a run, driven by its actions as a player would press them.
## Its saves and profile are the real ones, kept in the probe's own folder.

const MAIN := preload("res://game/main.tscn")

var main: Main


## The game on a fixed seed, without finds: on its main menu, or in a run.
func open_main(on_menu := true) -> Main:
	Tuning.current().run_seed = 1234
	Tuning.current().salvage = false
	main = MAIN.instantiate()
	main.opens_on_menu = on_menu
	add_child(main)
	world = main.world()
	if world != null:
		await settle(true)
		await started()
	return main


## Waits for the run's starting moment, its kit down; a Surveyor first takes
## the real opening. What follows runs at the start of a tick.
func started() -> void:
	await get_tree().physics_frame
	if world.arrival != null and world.arrival.active():
		await drop_in()
	for i in 600:
		if world.has_meta(&"kit"):
			return
		await get_tree().physics_frame
	check(false, "the run's kit is down within 600 ticks")


## The Surveyor opening as a player takes it: the shown pulse set at the
## station, the pod boarded and launched, the fall flown to the ground.
func drop_in() -> void:
	var prep := await cabin()
	if prep == null:
		return
	await set_pulse(prep)
	await launch_pod(prep)
	await fly_to(&"recovery")


## The ready cabin, within ten simulated seconds.
func cabin() -> SurveyorPreflight:
	for i in 600:
		if world.arrival != null and is_instance_valid(world.arrival.preflight):
			return world.arrival.preflight
		await get_tree().physics_frame
	check(false, "the Surveyor cabin is ready")
	return null


## Stands somewhere and looks at something, as if walked there.
func stand(at: Vector3, toward: Vector3) -> void:
	world.teleport(world.player, Transform3D(Basis.IDENTITY, at))
	world.player.velocity = Vector3.ZERO
	world.player.camera.look_at(toward)


func set_pulse(prep: SurveyorPreflight) -> void:
	var screen := prep.ship.computer_at.global_position
	stand(Vector3(screen.x, prep.ship.global_position.y + 0.02, screen.z + 0.9), screen)
	await physics_frames(2)
	press(&"interact")
	var focus := ceili(world.tuning.arrival_computer_focus_s * Engine.physics_ticks_per_second) + 2
	await physics_frames(focus)
	prep.computer.ui.commit()
	press(&"ui_cancel")
	await physics_frames(focus)
	check(world.arrival_state.preflight.plan_confirmed and not prep.computer_open(), "the station sets the shown pulse and lets go")


func launch_pod(prep: SurveyorPreflight) -> void:
	stand(prep.ship.pod_entry_at.global_position + Vector3(0, 0, 0.6), prep.ship.pod_entry_at.global_position + Vector3.UP * 0.5)
	await physics_frames(2)
	press(&"interact")
	await physics_frames(1)
	press(&"interact")
	await physics_frames(1)
	check(world.arrival_state.phase == &"ejection", "the boarded pod launches: %s" % ", ".join(prep.readiness()) if is_instance_valid(prep) else "")


## The fall flown at four times real speed until `phase`, bounded in simulated seconds.
func fly_to(phase: StringName, most_s := 60.0) -> void:
	var rate := Engine.physics_ticks_per_second
	Engine.time_scale = 4.0
	Engine.physics_ticks_per_second = rate * 4
	Engine.max_physics_steps_per_frame = 32
	var wanted := SurveyorArrival.PHASES.find(phase)
	for i in roundi(most_s * rate):
		if SurveyorArrival.PHASES.find(world.arrival_state.get("phase", &"")) >= wanted:
			break
		await get_tree().physics_frame
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = rate
	Engine.max_physics_steps_per_frame = 8
	check(SurveyorArrival.PHASES.find(world.arrival_state.get("phase", &"")) >= wanted, "the fall reaches %s within %.0f s" % [phase, most_s])


## Every start open, as the dev console's unlockall leaves them.
func open_every_start() -> void:
	var profile := get_node(^"/root/Profile")
	for kit in Kit.origins():
		if not kit.is_open_to(profile):
			for each in kit.unlocks():
				profile.unlock(each)


## The game's saves, in the probe's own folder.
func saves() -> Node:
	return get_node(^"/root/Saves")


## The first key or button bound to an action, pressed and let go.
func press(action: StringName) -> void:
	var event: InputEvent = InputMap.action_get_events(action)[0].duplicate()
	event.pressed = true
	get_viewport().push_input(event)
	event = event.duplicate()
	event.pressed = false
	get_viewport().push_input(event)


## Each character typed, as its key pressed and let go.
func type(text: String) -> void:
	for c in text:
		var key := InputEventKey.new()
		key.keycode = KEY_SPACE if c == " " else OS.find_keycode_from_string(c.to_upper())
		key.physical_keycode = key.keycode
		key.unicode = c.unicode_at(0)
		key.pressed = true
		get_viewport().push_input(key)
		key = key.duplicate()
		key.pressed = false
		get_viewport().push_input(key)


## The pointer pressed at one place on the screen, moved to another and let go.
func drag(from: Vector2, to: Vector2) -> void:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.button_mask = MOUSE_BUTTON_MASK_LEFT
	press.pressed = true
	press.position = from
	press.global_position = from
	get_viewport().push_input(press)
	var move := InputEventMouseMotion.new()
	move.button_mask = MOUSE_BUTTON_MASK_LEFT
	move.position = to
	move.global_position = to
	move.relative = to - from
	get_viewport().push_input(move)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.position = to
	release.global_position = to
	get_viewport().push_input(release)


## Waits for the screen to come back from black into a run, or onto the menu.
func faded_in(max_frames := 1800) -> void:
	for i in max_frames:
		await get_tree().process_frame
		if not main.ui._fading and main.ui._fade.modulate.a == 0.0:
			world = main.world()
			return
	check(false, "the screen came back within %d frames" % max_frames)
