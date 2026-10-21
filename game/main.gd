class_name Main
extends Node
## The game as it runs: the main menu over a live desert, then a run, and back
## to the menu on Save & quit. Saves and the profile are reached only through
## their nodes, and a missing one means there are none: no Resume, and Save &
## quit only quits. A Normal run also saves itself as you play and when you
## quit, and a death in it offers the last save back; quick save and quick
## load are its own. A dev scenario (`-- --scenario=<key>`, or the console's
## scenario) skips the menu, and its run is never saved. `-- --smoke` is an
## exported build's check instead (Smoke).

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
## The prop in the menu's foreground, or null in a run.
var showpiece: Showpiece
## The run in play is a dev scenario's: the save on disk, the player's own,
## is never written over or deleted by it.
var _scenario := false
## Seconds of play since the run in play was last saved.
var _played := 0.0

@onready var ui: UIRoot = $UI


func _ready() -> void:
	ui.main = self
	if Smoke.asked():
		Smoke.run(self)
		return
	var asked := _scenario_asked()
	_scenario = asked != ""
	if opens_on_menu and not _scenario:
		_show_view()
		ui.show_main_menu()
		return
	var first := _make(RUN)
	(first.get_node("World") as World).arrival_enabled = not _scenario
	_begin(first)
	if _scenario:
		# The world finishes setting up first.
		await get_tree().process_frame
		start_scenario(Scenarios.by_key(asked))


## The scenario the command line asks for, or "".
static func _scenario_asked() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--scenario="):
			return arg.trim_prefix("--scenario=")
	return ""


## Drops the run in play into a dev scenario. From then on it's a dev
## scenario's run: never saved, no deed counts in it, and a death in it begins
## a new run without touching the save on disk, which is the player's own.
func start_scenario(scenario: Dictionary) -> void:
	if world().arrival != null:
		world().arrival.cancel()
	world().arrival_enabled = false
	world().arrival_state.clear()
	world().arrival_nodes.clear()
	_scenario = true
	world().counts_deeds = false
	run.get_node("Runs").offer = Callable()
	Scenarios.apply(world(), scenario)


## A Normal run saves at once, saying so; Ironman and a dev scenario's run never.
func quick_save() -> void:
	if _scenario:
		ui.note("A dev run is never saved")
	elif ironman():
		ui.note("Ironman has no quick save")
	elif saves() != null:
		ui.note("Saved" if save_run() else "Couldn't save")


## The last save back, through the fade, as the death screen's Load last save.
func quick_load() -> void:
	if _scenario:
		ui.note("A dev run is never saved")
	elif ironman():
		ui.note("Ironman has no quick load")
	elif not has_save():
		ui.note("No save to load")
	else:
		resume()


## Heard only with nothing open: the UI root keeps a menu's keys to itself.
func _unhandled_input(event: InputEvent) -> void:
	if not in_run():
		return
	if event.is_action_pressed(&"quick_save"):
		quick_save()
	elif event.is_action_pressed(&"quick_load"):
		quick_load()


## The run's world now: a death brings a new one.
func world() -> World:
	return run.get_node_or_null("World") if run != null else null


func in_run() -> bool:
	return run != null


func saves() -> Node:
	return null if _scenario else get_node_or_null("/root/Saves")


## The run in play is Ironman's: it never saves as you go, and death ends it.
func ironman() -> bool:
	return run != null and run.get_node("Runs").ironman


func profile() -> Node:
	return get_node_or_null("/root/Profile")


func has_save() -> bool:
	var store := saves()
	return store != null and store.has_run()


## Why a saved run on disk can't be resumed, or "".
func save_refused() -> String:
	var store := saves()
	return "" if store == null or store.has_run() else str(store.get(&"refused"))


## A fresh run on a fresh seed, as the origin and in the mode chosen for it;
## the saved one, if any, is gone. With no origin given it's the run in
## play's, as after a death, when the seed is new whatever the tuning says,
## as for the new run an Ironman death begins.
func new_game(ironman := false, after_death := false, kit: Kit = null) -> void:
	if kit == null and world() != null:
		kit = world().kit
	var store := saves()
	if store != null and store.has_run():
		store.delete()
	var next := _make(RUN)
	var runs := next.get_node("Runs")
	runs.ironman = ironman
	var made := next.get_node("World") as World
	made.kit = kit
	made.arrival_enabled = Kit.of(made).id == &"surveyor"
	if after_death:
		made.run_seed = runs.new_seed()
	await _into(next, false)


## The saved run's world built on its seed and origin, in its mode, then put
## back as it was: from the main menu, and after a death in Normal.
func resume() -> void:
	var next := _make(RUN)
	(next.get_node("World") as World).run_seed = saves().run_seed()
	(next.get_node("World") as World).kit = Kit.named(saves().kit())
	(next.get_node("World") as World).arrival_enabled = not saves().held().get("arrival", {}).is_empty()
	next.get_node("World").set_meta(&"resumed", true)
	next.get_node("Runs").ironman = saves().ironman()
	await _into(next, true)


## Saves the run in play as it stands; says whether it landed.
func save_run() -> bool:
	var store := saves()
	if store == null or not store.save(world(), ironman()):
		return false
	_played = 0.0
	return true


## Safe at any moment, mid-storm included. A save that fails keeps you in the run.
func save_and_quit() -> void:
	if saves() != null and not save_run():
		ui.open(ui.confirm("Couldn't save the run", "Back", "Quit anyway", _quit_to_menu))
		return
	await _quit_to_menu()


func reset_profile() -> void:
	var store := profile()
	if store != null:
		store.reset()
	if showpiece != null:
		showpiece.home = last_kit()


## The kit of the origin you last came as, the Surveyor's before any.
func last_kit() -> Kit:
	var store := profile()
	var kit := Kit.named(store.last_origin()) if store != null else null
	return kit if kit != null else Kit.standard()


func quit() -> void:
	get_tree().quit()


## A Normal run saves itself every few minutes of play. Here, ahead of the
## run's own nodes, the save falls between two ticks.
func _physics_process(delta: float) -> void:
	if not _saves_itself():
		return
	_played += delta
	if _played >= world().tuning.autosave_minutes * 60.0:
		_played = 0.0
		saves().save_in_background(world(), ironman())


## Closing the game saves a Normal run as Save & quit would.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and _saves_itself():
		save_run()


## Never while you're dead, nor while the run is changing over or being put back.
func _saves_itself() -> bool:
	var at := world()
	var store := saves()
	return at != null and store != null and not ironman() and not at.player.vitals.dead \
		and not store.restoring and not ui.is_fading()


func _quit_to_menu() -> void:
	await ui.fade(true)
	ui.close_all()
	_end_run()
	_show_view()
	ui.show_main_menu()
	await ui.fade(false)


## Fades to black, swaps the menu's world (or a dead run) for the next run,
## and fades back in once the sand round you is solid. A resumed run is put
## back first, on settled ground, everything of yours back before the screen
## is; a refused one goes back to the menu saying why.
func _into(next: Node, resuming: bool) -> void:
	await ui.fade(true)
	ui.close_all()
	if view != null:
		_drop_view()
	if run != null:
		_end_run()
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
	if profile() != null:
		profile().remember_origin(Kit.of(world()).id)
	Controls.free_mouse(false)
	await ui.fade(false)
	while run == next and world() != null and world().arrival != null and world().arrival.active():
		await get_tree().physics_frame


func _settled() -> void:
	var at := world()
	while at != null and not at.terrain.is_settled_around(at.player_world_x(), at.player_world_z()):
		await get_tree().physics_frame
		at = world()


## Ahead of the UI in the tree, so the menus hear input before the game does.
func _begin(next: Node) -> void:
	Dev.clear()
	if not _scenario:
		next.get_node("Runs").offer = ui.show_death
	(next.get_node("World") as World).counts_deeds = not _scenario
	add_child(next)
	move_child(next, 0)
	run = next
	_played = 0.0


func _end_run() -> void:
	remove_child(run)
	run.queue_free()
	run = null
	_scenario = false


## The real world from a fixed camera: no one stands there, nothing of yours
## is in it but the prop, and only the weather moves, at its own pace,
## without a sound: a storm at the menu is only to look at, while the menu's
## own words and its music are heard.
func _show_view() -> void:
	Dev.clear()
	AudioServer.set_bus_mute(AudioServer.get_bus_index(Sounds.WORLD), true)
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
	# Beside the world's content, never in it: saves, power and wear never see it.
	showpiece = Showpiece.new()
	showpiece.ui = ui
	showpiece.camera = eye.camera
	showpiece.home = last_kit()
	view.add_child(showpiece)
	var music := MenuMusic.new()
	music.ui = ui
	view.add_child(music)


static func _make(path: String) -> Node:
	return (load(path) as PackedScene).instantiate()


func _drop_view() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index(Sounds.WORLD), false)
	remove_child(view)
	view.queue_free()
	view = null
	showpiece = null
