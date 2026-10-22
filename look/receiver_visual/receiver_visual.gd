extends Node3D
## Inspect a receiver wrapper on the real renderer, with fresh and worn finishes.
## scripts/unseen.sh --path . --resolution 960x720 res://look/receiver_visual/receiver_visual.tscn -- <output-dir> [visual-scene]


func _ready() -> void:
	get_window().unfocusable = true
	AudioServer.set_bus_mute(0, true)
	Dev.hide_overlays()
	var args := OS.get_cmdline_user_args()
	var out := args[0] if not args.is_empty() else "user://receiver-visual"
	DirAccess.make_dir_recursive_absolute(out)
	var scene: PackedScene = load(args[1]) if args.size() > 1 else SurveyReceiver.DEFAULT_VISUAL
	var receiver := Catalog.device(&"survey_receiver") as SurveyReceiver
	receiver.freeze = true
	receiver.process_mode = Node.PROCESS_MODE_DISABLED
	receiver.visual_scene = scene
	add_child(receiver)
	var visual := receiver.visual
	if visual == null or receiver.visual_scene != scene:
		push_error("Choose a receiver visual scene with its required references")
		get_tree().quit(1)
		return
	visual.present(0.7, -0.4, 0.2)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.12, 0.15, 0.18)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.8, 0.85, 1.0)
	env.ambient_light_energy = 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var surround := WorldEnvironment.new()
	surround.environment = env
	add_child(surround)
	var sun := DirectionalLight3D.new()
	add_child(sun)
	sun.rotation_degrees = Vector3(-40, -35, 0)
	var camera := Camera3D.new()
	camera.near = 0.01
	camera.fov = 32.0
	add_child(camera)
	camera.make_current()
	for shot: Array in [["fresh", 0.0, Vector3(0.6, 0.3, 1.6)],
			["worn", 0.8, Vector3(0.6, 0.3, 1.6)], ["rear", 0.35, Vector3(-0.8, 0.3, -1.5)]]:
		visual.appearance(shot[1], 0.0, 1.0)
		camera.look_at_from_position(shot[2], Vector3.ZERO)
		for i in 5:
			await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(out.path_join(shot[0] + ".png"))
	print("Receiver appearance captures: ", out)
	get_tree().quit()
