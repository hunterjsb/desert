extends ColorRect
## Look-test: the whole of Tu unrolled, its clouds as the sky draws them,
## longitude across from the meridian fixed to Tu and latitude up, at a world
## time, at a pixel to each of its rows:
##   godot --path . res://look/tu/unrolled.tscn -- --capture <file.png> [time]


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var at := args.find("--capture")
	if at == -1:
		return
	get_window().unfocusable = true
	Dev.hide_overlays()
	var unrolled := material as ShaderMaterial
	unrolled.set_shader_parameter("time", float(args[at + 2]) if args.size() > at + 2 else 0.0)
	unrolled.set_shader_parameter("rows", size.y)
	for i in 4:
		await get_tree().process_frame
	var image := get_viewport().get_texture().get_image().get_region(Rect2i(Vector2i.ZERO, Vector2i(size)))
	image.save_png(args[at + 1] if args.size() > at + 1 else "user://unrolled.png")
	get_tree().quit()
