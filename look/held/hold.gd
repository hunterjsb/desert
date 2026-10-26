extends DeckProbe
## Look-test: each held tool, and a ration, in your hands through your own
## eyes, looking level and down.
##   scripts/unseen.sh --path . --resolution 1280x720 res://look/held/hold.tscn -- <out dir>

const HELD: Array[StringName] = [&"compass", &"cutter", &"sand_scoop", &"flare", &"sealant", &"med_kit", &"ration"]


func run() -> void:
	await load_lines()
	var out := OS.get_cmdline_user_args()[-1]
	DirAccess.make_dir_recursive_absolute(out)
	Dev.hide_overlays()
	var player := world.player
	for id: StringName in HELD:
		var made: RigidBody3D = Catalog.device(id) if Catalog.DEVICES.has(id) else Catalog.part(id)
		world.content.add_child(made)
		if made is Device:
			# A cutter's battery, so it's carried as it's used.
			for socket in (made as Device).sockets():
				if socket.kind == &"battery":
					var cell := Catalog.part(&"battery")
					world.content.add_child(cell)
					(made as Device).fit(cell, socket)
		made.global_position = player.global_position + Vector3(0.0, 1.0, -1.0)
		await physics_frames(2)
		hands.hold(made)
		for pitch in [0.0, -35.0, -60.0]:
			player.camera.rotation_degrees.x = pitch
			await _shot(out, "%s_hold_%d" % [id, -roundi(pitch)])
		hands.drop()
		made.queue_free()
		await physics_frames(2)


func _shot(out: String, name: String) -> void:
	await physics_frames(40)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join(name + ".png"))
	print("hold: %s" % name)
