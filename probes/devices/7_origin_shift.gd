extends DeviceProbe
## Devices & mods probe 7: parts stuck on a floating chassis and a loose
## stack on its top come through an origin shift untouched.


func run() -> void:
	await load_world()
	var deck := spawn_device(&"chassis", 4.0, 1.5)
	fit_part(deck, &"hover_tray")
	# Under it, clear of the stack on its top.
	Stick.put(deck as Chassis, deck as Chassis, Chassis.BOTTOM, Vector2(0.38, 0.38), 0.0, Catalog.part(&"battery"))
	await physics_frames(120)
	var stack: Array[RigidBody3D] = []
	for i in 2:
		var box := drop_box(world.world_x(deck.global_position.x), world.world_z(deck.global_position.z), 0.0)
		# On its top, 0.06 m above its middle.
		box.global_position = deck.global_transform * Vector3(0.0, 0.06 + BOX_SIZE * 0.5 + 0.01 + i * (BOX_SIZE + 0.02), 0.0)
		# Light enough that the tray floats the piece and its load at its set height.
		box.mass = 2.0
		stack.append(box)
	await physics_frames(600)
	var fitted: Array[Node3D] = []
	for socket in deck.sockets():
		fitted.append_array(socket.fitted)
	var nodes: Array[Node3D] = fitted.duplicate()
	nodes.append_array(stack)
	var before := nodes.map(func(n: Node3D) -> Transform3D: return relative(deck, n))
	var was_at := Vector3(world.world_x(deck.global_position.x), deck.global_position.y,
		world.world_z(deck.global_position.z))
	world.shift_origin(Vector2i(3, -2))
	await physics_frames(60)
	var worst := 0.0
	for i in nodes.size():
		worst = maxf(worst, relative(deck, nodes[i]).origin.distance_to(before[i].origin))
	var now_at := Vector3(world.world_x(deck.global_position.x), deck.global_position.y,
		world.world_z(deck.global_position.z))
	check(worst < 0.01, "stuck parts and the stack kept their places on the piece (worst %.4f m)" % worst)
	check(now_at.distance_to(was_at) < 0.02, "and the piece kept its place in the world (%.4f m)"
		% now_at.distance_to(was_at))
	check(stack.all(func(b: RigidBody3D) -> bool: return (b.linear_velocity - deck.linear_velocity).length() < 0.05),
		"the stack is still at rest")
