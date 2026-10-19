class_name DeviceProbe
extends WorldProbe
## For device probes: builds frames with parts fitted, and fast-forwards physics.

## The part that goes in each kind of socket when a device is fitted out.
const FILL := {&"battery": &"battery", &"ring": &"hook", &"bottom": &"hover_tray",
	&"plant_pot": &"vat_fungus", &"plant_standard": &"root_tuber", &"port": &"plug", &"mod": &"harvester"}
## Where fit_part sticks things on a chassis's top, in turn, and its trays
## and runners under it.
const ON_TOP: Array[Vector2] = [Vector2(-0.25, 0.25), Vector2(0.25, 0.25), Vector2(-0.25, -0.25),
	Vector2(0.25, -0.25), Vector2(0.0, 0.0)]


## A device of the catalog, dropped in front of the player at a height, with
## every socket filled (or none).
func spawn_device(id: StringName, ahead := 4.0, above := 1.0, filled := true) -> Device:
	var device := Catalog.device(id)
	world.content.add_child(device)
	var p := world.player.global_position
	device.global_position = Vector3(p.x + ahead, world.height_under(p + Vector3(ahead, 0, 0)) + above, p.z)
	if filled:
		for socket in device.sockets().filter(func(s: Socket) -> bool: return FILL.has(s.kind)):
			var part := Catalog.part(FILL[socket.kind])
			world.content.add_child(part)
			device.fit(part, socket)
	return device


## Fits a fresh catalog part into the device's first free socket of its
## kind, or on a chassis, sticks it: a tray or runners under the first piece
## without, anything else on the first free place on a top.
func fit_part(device: Device, part_id: StringName) -> Part:
	var part := Catalog.part(part_id)
	world.content.add_child(part)
	for socket in device.sockets():
		if socket.kind == part.kind and socket.is_open():
			device.fit(part, socket)
			return part
	var deck := device as Chassis
	if deck != null and Stick.sticks(part) and stick_on(deck, part) != null:
		return part
	check(false, "%s has a free socket for a %s" % [device.label, part.label])
	return part


## Sticks a thing on a deck as fit_part would; the socket it's in, or null
## with no room.
func stick_on(deck: Chassis, thing: RigidBody3D) -> Socket:
	var under := thing is Part and Device.carries(thing as Part) != &""
	for piece in deck.grid():
		var face := Chassis.BOTTOM if under else Chassis.TOP
		var frame := deck.face_frame(piece, face)
		for at in ([Vector2.ZERO] if under else ON_TOP):
			var spot := frame * Vector3(at.x, at.y, 0.0)
			if not deck.stuck().any(func(s: Socket) -> bool:
					return s.out.dot(frame.basis.z) > 0.9 and (s.transform.origin - spot).length() < 0.22):
				return Stick.put(deck, piece, face, at, 0.0, thing)
	return null


## Runs the physics k times faster than real time without changing a tick's
## length, so long probes stay honest and finish.
func fast_forward(seconds: float, k := 10) -> void:
	var ticks := Engine.physics_ticks_per_second
	Engine.physics_ticks_per_second = ticks * k
	Engine.time_scale = k
	Engine.max_physics_steps_per_frame = k + 4
	await physics_frames(roundi(seconds * ticks))
	Engine.physics_ticks_per_second = ticks
	Engine.time_scale = 1.0
	Engine.max_physics_steps_per_frame = 8


## Where a node sits in its device's own frame.
func relative(device: Node3D, node: Node3D) -> Transform3D:
	return device.global_transform.affine_inverse() * node.global_transform
