extends Node
## Look-test: the Console on seed 1234, as the "console" scenario stands it on
## its deck with a storm due: the Console from a step off, its screen with one
## instrument, with the full set and its storm map, and the map again with the
## front near and the smart shield switched on. At the fixed exposure:
##   godot --path . --disable-vsync res://look/console/console.tscn -- --capture <dir>
## look/console/shoot.sh builds the sheet. A small window that never takes
## focus, nothing but this script moving anything, and silence.

const SEED := 1234
## How far the eye stands off, m, and the lens, °, for the whole Console and
## for its screen.
const WHOLE := Vector2(1.5, 50.0)
const SCREEN := Vector2(0.85, 42.0)
## The front this near, m, for the last shot, and the clock's pace meanwhile.
const NEAR := 1200.0
const WARP := 20.0

@onready var world: World = $World


func _enter_tree() -> void:
	var tuning := Tuning.current()
	tuning.run_seed = SEED
	tuning.eye_adapts = false
	tuning.salvage = false


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var at := args.find("--capture")
	if at == -1:
		return
	_capture(args[at + 1] if args.size() > at + 1 else "user://console")


func _capture(out_dir: String) -> void:
	var window := get_window()
	window.unfocusable = true
	window.size = Vector2i(960, 540)
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	window.content_scale_size = Vector2i(1920, 1080)
	AudioServer.set_bus_mute(0, true)
	var player := world.player
	player.set_process_unhandled_input(false)
	player.hands.set_process_unhandled_input(false)
	player.hands.set_process(false)
	world.set_process_unhandled_input(false)
	Dev.hide_overlays()
	DirAccess.make_dir_recursive_absolute(out_dir)
	await _ground()
	var scenario := Scenarios.by_key("console")
	var place := Scenarios.find(world, scenario)
	Scenarios.stand(world, scenario, place)
	await _ground()
	var dropped := Scenarios.console(world)
	var made: Console = dropped[1]
	player.set_physics_process(false)
	player.flying = true
	await _ticks(120)
	await _shot(out_dir, "console", made, WHOLE, -0.65)
	# One instrument: the anemometer alone.
	var spare: Array[Part] = []
	for socket in made.sockets():
		if socket.part != null and (socket.kind == &"computer_top" or socket.kind == &"computer_mod"
				and socket.part.stats.get("anemometer", 0) == 0):
			spare.append(made.take(socket))
	var radio := made.mounted()[0]
	var top := made.seat_of(radio)
	made.dismount(top)
	radio.get_parent().remove_child(radio)
	await _ticks(90)
	await _shot(out_dir, "one", made, SCREEN, 0.0)
	for part in spare:
		for socket in made.sockets():
			if socket.kind == part.kind and socket.is_open():
				made.fit(part, socket)
				break
	made.mount(radio, top)
	await _ticks(150)
	await _shot(out_dir, "full", made, SCREEN, 0.0)
	world.time_warp = WARP
	for i in 60 * 120:
		var front: Dictionary = made.pooled_readings().get("front", {})
		if front.get("d", INF) <= NEAR or front.get("inside", false):
			break
		await get_tree().physics_frame
	world.time_warp = 1.0
	await _ticks(90)
	await _shot(out_dir, "map", made, SCREEN, 0.0)
	await _shot(out_dir, "deck", made, Vector2(4.5, 55.0), 0.9)
	get_tree().quit()


## Shoots the Console from in front of its screen, `off` m off and at `lens`
## °, swung `swing` rad round to one side.
func _shot(out_dir: String, name: String, made: Console, off: Vector2, swing: float) -> void:
	var player := world.player
	var normal := (made.global_basis * Vector3.FORWARD).normalized()
	var target := made.global_position if swing != 0.0 else made.global_transform * Vector3(0.0, 0.0, -0.43)
	var eye := target + normal.rotated(Vector3.UP, swing) * off.x + Vector3.UP * (off.x * 0.35 if swing != 0.0 else 0.03)
	var to := target - eye
	player.rotation = Vector3(0.0, atan2(-to.x, -to.z), 0.0)
	player.global_position = eye - player.camera.position
	player.camera.rotation = Vector3(atan2(to.y, Vector2(to.x, to.z).length()), 0.0, 0.0)
	player.feel.set_process(false)
	player.camera.fov = off.y
	await _ticks(20)
	for layer: CanvasLayer in world.find_children("*", "CanvasLayer", true, false):
		layer.visible = false
	await get_tree().process_frame
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(out_dir.path_join(name + ".png"))
	print("console: %s" % name)
	print(made.screen_text())


func _ground() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	while not world.terrain.is_idle():
		await get_tree().process_frame


func _ticks(count: int) -> void:
	for i in count:
		await get_tree().physics_frame
