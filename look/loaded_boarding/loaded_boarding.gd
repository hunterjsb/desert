extends "res://probes/movement/40_loaded_deck_boarding.gd"
## The actual loaded craft after input-driven boarding and ordinary power loss.

var camera: Camera3D

func _capture(name: String) -> void:
	var output := OS.get_cmdline_user_args()[-1]
	DirAccess.make_dir_recursive_absolute(output)
	Dev.hide_overlays()
	if camera == null:
		camera = Camera3D.new()
		add_child(camera)
		camera.current = true
	camera.global_position = deck.global_transform * Vector3(-4, 4, 8)
	camera.look_at(deck.global_transform * Vector3(2, 0.5, 2))
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(output.path_join(name))
