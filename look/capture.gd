extends Node
## Look-test helper: builds the world on a fixed seed, waits for the far ring,
## aims the camera and saves a screenshot. Needs a window, not --headless:
##   godot --path . res://look/capture.tscn -- out.png [yaw] [pitch] [lift_m] [run_seconds] [--f3]

const WORLD_SCENE := preload("res://game/world/world.tscn")


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out := args[0] if args.size() > 0 else "user://capture.png"
	var yaw := float(args[1]) if args.size() > 1 else 0.0
	var pitch := float(args[2]) if args.size() > 2 else -5.0
	var lift := float(args[3]) if args.size() > 3 else 0.0
	var time := float(args[4]) if args.size() > 4 else 0.0
	# Screenshots are silent: the storm roar shouldn't play through his speakers.
	AudioServer.set_bus_mute(0, true)
	Tuning.current().run_seed = 1234
	var world: World = WORLD_SCENE.instantiate()
	add_child(world)
	for i in 1800:
		await get_tree().process_frame
		if world.terrain.is_idle():
			break
	world.time = time
	world.player.flying = true
	world.player.global_position.y += lift
	world.player.rotation_degrees.y = yaw
	world.player.camera.rotation_degrees.x = pitch
	if args.has("--f3"):
		var press := InputEventAction.new()
		press.action = "toggle_dev_overlay"
		press.pressed = true
		Input.parse_input_event(press)
	# Physics ticks, not frames: the weather and its wall update on the tick.
	for i in 60:
		await get_tree().physics_frame
	get_viewport().get_texture().get_image().save_png(out)
	get_tree().quit()
