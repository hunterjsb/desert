extends DeviceProbe
## Devices & mods probe 7: fitted parts and a loose stack on a floating device
## come through an origin shift untouched.


func run() -> void:
	await load_world()
	var crate := spawn_device(&"crate_frame", 4.0, 1.5)
	await physics_frames(120)
	var stack: Array[RigidBody3D] = []
	for i in 2:
		var box := drop_box(world.world_x(crate.global_position.x), world.world_z(crate.global_position.z), 0.0)
		# On the solar panel, whose face is 0.29 m above the crate's middle.
		box.global_position = crate.global_transform * Vector3(0.0, 0.29 + BOX_SIZE * 0.5 + 0.01 + i * (BOX_SIZE + 0.02), 0.0)
		# Light enough that the tray floats the crate and its load at its set height.
		box.mass = 2.0
		stack.append(box)
	await physics_frames(600)
	var fitted: Array[Node3D] = []
	for socket in crate.sockets():
		fitted.append_array(socket.fitted)
	var nodes: Array[Node3D] = fitted.duplicate()
	nodes.append_array(stack)
	var before := nodes.map(func(n: Node3D) -> Transform3D: return relative(crate, n))
	var crate_world := Vector3(world.world_x(crate.global_position.x), crate.global_position.y,
		world.world_z(crate.global_position.z))
	world.shift_origin(Vector2i(3, -2))
	await physics_frames(60)
	var worst := 0.0
	for i in nodes.size():
		worst = maxf(worst, relative(crate, nodes[i]).origin.distance_to(before[i].origin))
	var crate_now := Vector3(world.world_x(crate.global_position.x), crate.global_position.y,
		world.world_z(crate.global_position.z))
	check(worst < 0.01, "fitted parts and the stack kept their places on the crate (worst %.4f m)" % worst)
	check(crate_now.distance_to(crate_world) < 0.02, "and the crate kept its place in the world (%.4f m)"
		% crate_now.distance_to(crate_world))
	check(stack.all(func(b: RigidBody3D) -> bool: return (b.linear_velocity - crate.linear_velocity).length() < 0.05),
		"the stack is still at rest")
