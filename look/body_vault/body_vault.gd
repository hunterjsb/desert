extends "res://look/powered_vault/powered_vault.gd"
## The actual swept climb, ordinary body posing, and both external and own-camera frames.

func run() -> void:
	var out := OS.get_cmdline_user_args()[-1]
	DirAccess.make_dir_recursive_absolute(out)
	# A short live climb can skip a capture phase on a busy GPU; never leave a stale frame.
	for file in DirAccess.get_files_at(out):
		if file.ends_with(".png") and (file.begins_with("30-") or file.begins_with("60-") or file.begins_with("fp-")):
			DirAccess.remove_absolute(out.path_join(file))
	await super.run()

func load_moving(run_seed := 1234, salvage := false) -> void:
	await super.load_moving(run_seed, salvage)
	player.camera.rotation_degrees.x = -25.0

func _shot(label: String) -> void:
	shooting = true
	Dev.hide_overlays()
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(output.path_join(label))
	if label.contains("climb"):
		player.camera.make_current()
		await RenderingServer.frame_post_draw
		for side in ["r", "l"]:
			var hand := player.body.get_node(NodePath("hand_" + side)) as Node3D
			var grip := hand.to_global(Vector3(0, -Body.GRIP, 0))
			print("VAULT_FP ", JSON.stringify({"shot":label,"side":side,"progress":player.vault.progress,
				"hand":grip,"camera":player.camera.global_transform,"projected":player.camera.unproject_position(grip),
				"visible":hand.is_visible_in_tree(),"mask":player.camera.cull_mask}))
		get_viewport().get_texture().get_image().save_png(output.path_join("fp-" + label))
		camera.make_current()
	shooting = false
