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
	return main


## Waits for the run's starting moment, its kit down; what follows runs at
## the start of a tick, whenever the ground finished building.
func started() -> void:
	await get_tree().physics_frame
	while not world.has_meta(&"kit"):
		await get_tree().physics_frame


## Every start open, as the dev console's unlockall leaves them.
func open_every_start() -> void:
	var profile := get_node(^"/root/Profile")
	for kit in Kit.origins():
		if not kit.is_open_to(profile):
			profile.unlock(kit.unlock)


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


## Waits for the screen to come back from black into a run, or onto the menu.
func faded_in(max_frames := 1800) -> void:
	for i in max_frames:
		await get_tree().process_frame
		if not main.ui._fading and main.ui._fade.modulate.a == 0.0:
			world = main.world()
			return
	check(false, "the screen came back within %d frames" % max_frames)
