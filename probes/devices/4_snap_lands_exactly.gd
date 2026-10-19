extends DeviceProbe
## Devices & mods probe 4: a part sits precisely where it goes, in a slot or
## stuck on a chassis's face, from wherever and however it arrived.


func run() -> void:
	await load_world()
	var worst := 0.0
	# A planter's slots, then places on a chassis's faces: each a socket and a part.
	var planter := spawn_device(&"planter", 4.0, 2.0, false)
	var deck := spawn_device(&"chassis", -4.0, 2.0, false) as Chassis
	await physics_frames(3)
	var goes: Array[Array] = []
	for socket in planter.sockets().filter(func(s: Socket) -> bool: return FILL.has(s.kind)):
		goes.append([planter, socket, FILL[socket.kind]])
	for each: Array in [[Chassis.TOP, Vector2(0.2, -0.3), 0.7, &"battery"], [Chassis.TOP, Vector2(-0.25, 0.1), 2.0, &"lamp"],
			[Chassis.BOTTOM, Vector2(0.1, 0.05), 0.3, &"hover_tray"]]:
		goes.append([deck, each, each[3]])
	for go: Array in goes:
		var device: Device = go[0]
		var part := Catalog.part(go[2])
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
		var socket: Socket = go[1] if go[1] is Socket else null
		if socket != null:
			device.fit(part, socket)
		else:
			var at: Array = go[1]
			socket = Stick.put(deck, deck, at[0], at[1], at[2], part)
			var want := Stick.pose_on(deck, deck, at[0], at[1], at[2], part)
			worst = maxf(worst, socket.transform.origin.distance_to(want.origin))
		for node: Node3D in own:
			var seated: Transform3D = socket.transform * own[node]
			worst = maxf(worst, node.transform.origin.distance_to(seated.origin))
			worst = maxf(worst, (node.transform.basis * seated.basis.inverse()).get_rotation_quaternion().get_angle())
	print("worst seat error %.7f" % worst)
	check(worst < 1e-4, "every part sits exactly where it goes (worst %.7f)" % worst)
