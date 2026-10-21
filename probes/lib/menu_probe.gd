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
	# These menu fixtures need a surface run; Arrival 16 covers interactive preparation.
	Tuning.current().surveyor_preflight["enabled"] = false
	main = MAIN.instantiate()
	main.opens_on_menu = on_menu
	add_child(main)
	world = main.world()
	if world != null:
		await settle(true)
		await started()
	return main


## Waits for the run's starting moment, its kit down; what follows runs at
## the start of a tick, whenever the ground finished building.
func started() -> void:
	await get_tree().physics_frame
	while not world.has_meta(&"kit") or (world.arrival != null and world.arrival.active()):
		await get_tree().physics_frame


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
