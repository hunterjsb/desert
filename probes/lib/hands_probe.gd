class_name HandsProbe
extends DeviceProbe
## For probes of the hands: the world in still air, your eyes wherever a probe
## puts them, and catalog devices and parts to work on. Physics can run faster
## than real time without changing a tick's length.

var hands: Hands


func load_hands(run_seed := 1234, salvage := false) -> void:
	await load_world(run_seed, true, salvage)
	hands = world.player.hands
	# You go where the probe puts you, and touch nothing on the way.
	world.player.set_physics_process(false)
	world.player.collision_layer = 0
	world.player.collision_mask = 0


## Puts your eyes at `eye`, looking at `target`. Engine coordinates.
func look(eye: Vector3, target: Vector3) -> void:
	var player := world.player
	var to := target - eye
	player.rotation = Vector3(0.0, atan2(-to.x, -to.z), 0.0)
	player.global_position = eye - player.camera.position
	player.camera.rotation = Vector3(atan2(to.y, Vector2(to.x, to.z).length()), 0.0, 0.0)


func eye() -> Vector3:
	return world.player.camera.global_position


## A catalog device at `at` on the sand, `above` m up, every socket filled or none.
func device(id: StringName, at: Vector3, above: float, filled := false) -> Device:
	var made := Catalog.device(id)
	world.content.add_child(made)
	made.global_position = Vector3(at.x, world.height_under(at) + above, at.z)
	if filled:
		for socket in made.sockets():
			var part := Catalog.part(FILL[socket.kind])
			world.content.add_child(part)
			made.fit(part, socket)
	return made


## A loose catalog part at a pose.
func part(id: StringName, pose: Transform3D) -> Part:
	var made := Catalog.part(id)
	world.content.add_child(made)
	made.global_transform = pose
	return made


## A place on the sand in engine coordinates, `x` and `z` metres from where
## the world put the player.
func spot(x: float, z: float) -> Vector3:
	var at := Vector3(world.engine_x(world.spawn.x) + x, 0.0, world.engine_z(world.spawn.y) + z)
	at.y = world.height_under(at)
	return at


## Where a part sits in a socket, in the world.
func seat(socket: Socket) -> Transform3D:
	return (socket.get_parent() as Node3D).global_transform * socket.transform


## The bounds of a loose part's shapes, in its own frame.
func bounds(of: Part) -> AABB:
	var box := AABB()
	var first := true
	for child in of.get_children():
		var shape := child as CollisionShape3D
		if shape != null:
			var each := shape.transform * shape.shape.get_debug_mesh().get_aabb()
			box = each if first else box.merge(each)
			first = false
	return box


func middle(of: Part) -> Vector3:
	return bounds(of).get_center()


## Physics runs k times faster than real time, each tick still 1/60 s; 1 restores it.
func speed_up(k: int) -> void:
	Engine.physics_ticks_per_second = 60 * k
	Engine.time_scale = k
	Engine.max_physics_steps_per_frame = k + 4 if k > 1 else 8


## Ticks for a span of simulated time; `each` is called after every tick.
func simulate(seconds: float, each := Callable()) -> void:
	for i in roundi(seconds * 60.0):
		await get_tree().physics_frame
		if each.is_valid():
			each.call()


## Whether any of a body's shapes, shrunk by `skin` a side, overlaps `other`.
func overlaps(body: Node3D, other: CollisionObject3D, skin := 0.005) -> bool:
	var space := world.get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	for child in body.get_children():
		var shape := child as CollisionShape3D
		if shape == null:
			continue
		var box := BoxShape3D.new()
		box.size = (shape.shape as BoxShape3D).size - Vector3.ONE * skin * 2.0
		query.shape = box
		query.transform = shape.global_transform
		for hit in space.intersect_shape(query, 32):
			if hit.collider == other:
				return true
	return false
