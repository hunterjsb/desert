extends "res://probes/camp/10_a_loaded_home_stays_live.gd"
## The loaded camp, returned to after a real remote physics interval.


func run() -> void:
	await super.run()
	Dev.hide_overlays()
	var output := OS.get_cmdline_user_args()[-1]
	DirAccess.make_dir_recursive_absolute(output)
	look(camp.global_position + Vector3(-3.0, 3.8, 6.5), camp.global_position + Vector3(1.2, 0.0, 0.8))
	await physics_frames(12)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(output.path_join("medium-return.png"))
	look(camp.global_position + Vector3(4.5, 1.4, -2.5), camp.global_position + Vector3(1.5, 0.0, 1.0))
	await physics_frames(12)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(output.path_join("medium-supports.png"))
