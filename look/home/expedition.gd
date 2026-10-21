extends "res://probes/camp/9_live_resources_while_scouting.gd"
## The actual unfrozen shelter after far save, restore and return.
func run() -> void:
	await super.run()
	Dev.hide_overlays()
	var output := OS.get_cmdline_user_args()[-1]
	DirAccess.make_dir_recursive_absolute(output)
	look(camp_deck.global_position + Vector3(1.5, 1.6, 2.8), camp_deck.global_position)
	await physics_frames(12)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(output.path_join("returned-camp.png"))
	look(loose.global_position + Vector3(0.6, 0.5, 0.8), loose.global_position)
	await physics_frames(8)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(output.path_join("returned-loose-supply.png"))
