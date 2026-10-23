extends DeckProbe
## Look-test: small things carried in your arms, through your own eyes: a radio
## and a battery looking level, down and well down, and the radio brought up to
## read while you tune it.
##   scripts/unseen.sh --path . --resolution 1280x720 res://look/player_body/held.tscn -- <out dir>

func run() -> void:
	await load_lines()
	var out := OS.get_cmdline_user_args()[-1]
	DirAccess.make_dir_recursive_absolute(out)
	Dev.hide_overlays()
	var player := world.player
	for id: StringName in [&"radio", &"battery"]:
		var made: RigidBody3D = Catalog.device(id) if Catalog.DEVICES.has(id) else Catalog.part(id)
		world.content.add_child(made)
		made.global_position = player.global_position + Vector3(0.0, 1.0, -1.0)
		await physics_frames(2)
		hands.hold(made)
		for pitch in [0.0, -35.0, -60.0]:
			player.camera.rotation_degrees.x = pitch
			await _shot(out, "%s_%d" % [id, -roundi(pitch)])
		if made is Radio:
			player.camera.rotation_degrees.x = 0.0
			player.close_up.tuned(made as Radio, true)
			await _shot(out, "radio_reading")
		hands.drop()
		made.queue_free()
		await physics_frames(2)


func _shot(out: String, name: String) -> void:
	await physics_frames(40)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join(name + ".png"))
