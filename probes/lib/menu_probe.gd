class_name MenuProbe
extends WorldProbe
## For probes of the menus: the game as it runs, opened on the main menu or
## straight into a run, driven by its actions as a player would press them.
## Saves, where a probe wants them, are a stand-in, never the real ones.

const MAIN := preload("res://game/main.tscn")

var main: Main


## A stand-in for the saves: one run, kept in memory, every call recorded.
class FakeSaves:
	extends Node
	const SEED := 4321
	var has := false
	var saved: World
	var restored: World
	var deleted := 0
	## Whether the sand round you had settled when the run was put back.
	var settled_then := false

	func has_run() -> bool:
		return has

	func save(world: World) -> bool:
		saved = world
		has = true
		return true

	func run_seed() -> int:
		return SEED

	func restore(world: World) -> bool:
		restored = world
		settled_then = world.terrain.is_settled_around(world.player_world_x(), world.player_world_z())
		return true

	func delete() -> void:
		deleted += 1
		has = false


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


## Beside the game's autoloads, where the real one will be.
func fake_saves(has: bool) -> FakeSaves:
	var saves := FakeSaves.new()
	saves.name = "Saves"
	saves.has = has
	get_tree().root.add_child.call_deferred(saves)
	await get_tree().process_frame
	return saves


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
