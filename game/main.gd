class_name Main
extends Node
## The game as it runs: the main menu over a live desert, then a run, and back
## to the menu on Save & quit. Saves and the profile are reached only through
## their nodes, and a missing one means there are none: no Resume, and Save &
## quit only quits. A dev scenario (`-- --scenario=<key>`) skips the menu.

## Loaded when wanted, not preloaded: the world's own scripts reach back here
## through the UI root, and a preload would go round in a circle.
const RUN := "res://game/run.tscn"
const WORLD := "res://game/world/world.tscn"
## The menu's camera stands this high on the highest sand within VIEW_SEARCH
## m of the spawn, facing upwind, where the weather comes from, a little down.
const VIEW_SEARCH := 60.0
const VIEW_HEIGHT := 1.65
const VIEW_PITCH := -2.0

## Opens on the main menu, as the game does; a probe that wants a run turns it off.
@export var opens_on_menu := true

## The run in play, or null at the menu.
var run: Node
## The menu's world, or null in a run.
var view: World

@onready var ui: UIRoot = $UI


func _ready() -> void:
	ui.main = self
	if opens_on_menu and not _scenario_asked():
		_show_view()
		ui.show_main_menu()
	else:
		_begin(_make(RUN))


static func _scenario_asked() -> bool:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--scenario="):
			return true
	return false


## The run's world now: a death brings a new one.
func world() -> World:
	return run.get_node_or_null("World") if run != null else null


func in_run() -> bool:
	return run != null


func saves() -> Node:
	return get_node_or_null("/root/Saves")


func profile() -> Node:
	return get_node_or_null("/root/Profile")


func has_save() -> bool:
	var store := saves()
	return store != null and store.has_run()


## Why a saved run on disk can't be resumed, or "".
func save_refused() -> String:
	var store := saves()
	return "" if store == null or store.has_run() else str(store.get(&"refused"))


## A fresh run on a fresh seed; the saved one, if any, is gone.
func new_game() -> void:
	var store := saves()
	if store != null and store.has_run():
		store.delete()
	await _into(_make(RUN), false)


## The saved run's world built on its seed, then put back as it was.
func resume() -> void:
	var next := _make(RUN)
	(next.get_node("World") as World).run_seed = saves().run_seed()
	await _into(next, true)


## Safe at any moment, mid-storm included. A save that fails keeps you in the run.
func save_and_quit() -> void:
	var store := saves()
	if store != null and not store.save(world()):
		ui.open(ui.confirm("Couldn't save the run", "Back", "Quit anyway", _quit_to_menu))
		return
	await _quit_to_menu()


func reset_profile() -> void:
	var store := profile()
	if store != null:
		store.reset()


func quit() -> void:
	get_tree().quit()


func _quit_to_menu() -> void:
	await ui.fade(true)
	ui.close_all()
	_end_run()
	_show_view()
	ui.show_main_menu()
	await ui.fade(false)


## Fades to black, swaps the menu's world for the run, and fades back in once
## the sand round you is solid. A resumed run is put back first, on settled
## ground, everything of yours back before the screen is; a refused one goes
## back to the menu saying why.
func _into(next: Node, resuming: bool) -> void:
	await ui.fade(true)
	ui.close_all()
	_drop_view()
	_begin(next)
	await _settled()
	if resuming:
		var store := saves()
		if not store.restore(world()):
			_end_run()
			_show_view()
			ui.show_main_menu("Couldn't resume: %s" % store.get(&"refused"))
			await ui.fade(false)
			return
		if store.get(&"restoring"):
			await store.restored
		await _settled()
	Dev.show_hint(true)
	Controls.free_mouse(false)
	await ui.fade(false)


func _settled() -> void:
	var at := world()
	while at != null and not at.terrain.is_settled_around(at.player_world_x(), at.player_world_z()):
		await get_tree().physics_frame
		at = world()


## Ahead of the UI in the tree, so the menus hear input before the game does.
func _begin(next: Node) -> void:
	Dev.clear()
	add_child(next)
	move_child(next, 0)
	run = next


func _end_run() -> void:
	remove_child(run)
	run.queue_free()
	run = null


## The real world from a fixed camera: no one stands there, nothing of yours
## is in it, and only the weather moves, at its own pace, without a sound: a
## storm at the menu is only to look at.
func _show_view() -> void:
	Dev.clear()
	AudioServer.set_bus_mute(0, true)
	view = _make(WORLD) as World
	view.name = "View"
	add_child(view)
	move_child(view, 0)
	var eye := view.player
	eye.process_mode = Node.PROCESS_MODE_DISABLED
	eye.collision_layer = 0
	eye.collision_mask = 0
	for layer: CanvasLayer in eye.find_children("*", "CanvasLayer", true, false):
		layer.visible = false
	var best := view.spawn
	var top := view.height_at(best.x, best.y)
	for ring in range(1, 7):
		for k in 16:
			var at := view.spawn + Vector2.from_angle(TAU * k / 16.0) * VIEW_SEARCH * ring / 6.0
			var h := view.height_at(at.x, at.y)
			if h > top:
				best = at
				top = h
	var upwind := -view.weather.field.prevailing_at(view.time).normalized()
	eye.global_position = Vector3(view.engine_x(best.x), top + VIEW_HEIGHT - eye.camera.position.y,
		view.engine_z(best.y))
	eye.rotation = Vector3(0.0, atan2(-upwind.x, -upwind.y), 0.0)
	eye.camera.rotation = Vector3(deg_to_rad(VIEW_PITCH), 0.0, 0.0)


static func _make(path: String) -> Node:
	return (load(path) as PackedScene).instantiate()


func _drop_view() -> void:
	AudioServer.set_bus_mute(0, false)
	remove_child(view)
	view.queue_free()
	view = null
