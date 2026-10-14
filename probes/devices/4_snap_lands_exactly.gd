extends DeviceProbe
## Devices & mods probe 4: a fitted part sits precisely at its socket, from
## wherever and however it arrived.


func run() -> void:
	await load_world()
	var worst := 0.0
	for id: StringName in [&"crate_frame", &"planter"]:
		var device := spawn_device(id, 4.0, 2.0, false)
		await physics_frames(3)
		for socket in device.sockets():
			var part := Catalog.part(FILL[socket.kind])
			# Its own layout, before it joins: each shape and mesh as the part holds it.
			var own := {}
			for child in part.get_children():
				if child is Node3D:
					own[child] = child.transform
			world.content.add_child(part)
			# Arriving from anywhere, at any angle.
			part.global_position = device.global_position + Vector3(randf_range(-2, 2), randf_range(0.5, 2), randf_range(-2, 2))
			part.rotation = Vector3(randf() * TAU, randf() * TAU, randf() * TAU)
			await get_tree().physics_frame
			device.fit(part, socket)
			for node: Node3D in own:
				var seated: Transform3D = socket.transform * own[node]
				worst = maxf(worst, node.transform.origin.distance_to(seated.origin))
				worst = maxf(worst, (node.transform.basis * seated.basis.inverse()).get_rotation_quaternion().get_angle())
	print("worst seat error %.7f" % worst)
	check(worst < 1e-4, "every fitted part sits exactly at its socket (worst %.7f)" % worst)
