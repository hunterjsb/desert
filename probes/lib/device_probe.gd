class_name DeviceProbe
extends WorldProbe
## For device probes: builds frames with parts fitted, and fast-forwards physics.

## The part that goes in each kind of socket when a device is fitted out; a
## rack takes a whole board, so filling leaves it be.
const FILL := {&"battery": &"battery", &"ring": &"hook", &"bottom": &"hover_tray", &"top": &"solar_panel",
	&"plant_small": &"carrot", &"plant_large": &"fungus", &"port": &"plug", &"mod": &"harvester"}


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


## Fits a fresh catalog part into the device's first free socket of its kind.
func fit_part(device: Device, part_id: StringName) -> Part:
	var part := Catalog.part(part_id)
	world.content.add_child(part)
	for socket in device.sockets():
		if socket.kind == part.kind and socket.is_open():
			device.fit(part, socket)
			return part
	check(false, "%s has a free socket for a %s" % [device.label, part.label])
	return part


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
