extends Node
## Look-test: a signal flare lit in your hands, on seed 1234, by day and at
## dusk: its light, sparks and smoke, a few seconds on.
##   godot --path . --disable-vsync res://look/flare/flare.tscn -- --capture <dir>

const SEED := 1234

@onready var world: World = $World


func _enter_tree() -> void:
	var tuning := Tuning.current()
	tuning.run_seed = SEED
	tuning.eye_adapts = false
	tuning.salvage = false
	tuning.storm_threshold = 2.0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var at := args.find("--capture")
	if at == -1:
		return
	_capture(args[at + 1] if args.size() > at + 1 else "user://flare")


func _capture(out_dir: String) -> void:
	var window := get_window()
	window.unfocusable = true
	window.size = Vector2i(960, 540)
	AudioServer.set_bus_mute(0, true)
	var player := world.player
	player.set_process_unhandled_input(false)
	player.hands.set_process_unhandled_input(false)
	Dev.hide_overlays()
	DirAccess.make_dir_recursive_absolute(out_dir)
	await _ground()
	var flare := Catalog.part(&"flare") as Flare
	world.content.add_child(flare)
	flare.global_position = player.global_position + Vector3.UP
	player.hands.hold(flare)
	for i in 30:
		await get_tree().physics_frame
	print("flare: lighting")
	var lit := player.hands.interact()
	print("flare: interact %s, lit %s" % [lit, flare.lit])
	for k in 3:
		for i in 60:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png(out_dir.path_join("lit_%d.png" % k))
		print("flare: shot %d, burnt %.1f s" % [k, flare.burnt])
	get_tree().quit()


func _ground() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	while not world.terrain.is_idle():
		await get_tree().process_frame
