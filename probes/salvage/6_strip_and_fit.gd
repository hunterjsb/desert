extends SalvageProbe
## Salvage & ruins probe 6: strip and fit. Every kind of device the sand
## holds is found buried with every socket a layer can fill filled. Through
## the hands, every part comes out of it, as it lies where your eyes can reach
## its socket, or once you've taken hold of the device and pulled it up out of
## the sand where they can't, and goes into a device of your own. What you
## take from becomes yours; nothing is left in the find.

## Your eyes look at a socket from this far off, from any of these many sides
## round its opening, these far off its axis, rad; from beside it, a little higher.
const DISTANCE := 1.1
const SIDES := 8
const OFF_AXIS := [0.0, 0.7, 1.2, PI / 2.0]
const BESIDE_UP := 0.5
## Crouched at arm's length, your eyes are this far off and this high over
## the sand: low enough to see under a frame's edge.
const CROUCHED_OFF := 2.1
const CROUCHED_EYE := 1.1


func run() -> void:
	await load_salvage()
	world.time_warp = 0.0
	var ids := {}
	for layer: StringName in Finds.DEVICES:
		for entry: Array in Finds.DEVICES[layer]:
			if entry[0] != &"stake":
				ids[entry[0]] = true
	var tally := {"parts": 0, "out": 0, "fitted": 0, "pulled": 0, "yours": 0}
	var k := 0
	for id: StringName in ids:
		await _strip(id, k, tally)
		k += 1
	print("%d device kinds: %d parts, %d taken out, %d fitted to yours; %d pulled up out of the sand first"
		% [ids.size(), tally.parts, tally.out, tally.fitted, tally.pulled])
	check(ids.size() >= 6, "every kind of found device was stripped (%d)" % ids.size())
	check(tally.out == tally.parts, "every part came out of its find (%d of %d)" % [tally.out, tally.parts])
	check(tally.fitted == tally.parts, "every part went into a device of yours (%d of %d)" % [tally.fitted, tally.parts])
	check(tally.yours == ids.size(), "every find you took from became yours (%d of %d)" % [tally.yours, ids.size()])


## One found device of a kind, every fillable socket full from both layers'
## fills, buried a few metres in front of you, and a bare one of your own
## beside it.
func _strip(id: StringName, k: int, tally: Dictionary) -> void:
	var here := Vector2(world.player_world_x(), world.player_world_z())
	var at := here + Vector2(4.0 * k - 10.0, -6.0)
	var spec := {"index": 900 + k, "id": id, "device": true, "layer": Finds.DEEP, "x": at.x, "z": at.y,
		"yaw": 0.4 * k, "lean": 1.0, "lean_by": 0.1, "bury": 0.35, "sound": 0.9, "charge": 0.5, "fill": []}
	var sockets: Array = Catalog.DEVICES[id].sockets
	for i in sockets.size():
		var kind: StringName = sockets[i][0]
		for layer: StringName in [Finds.DEEP, Finds.SURFACE]:
			if Finds.FILLS[layer].has(kind):
				spec.fill.append([i, Finds.FILLS[layer][kind][0], 0.5])
				break
	var coord := world.terrain.chunk_at(at.x, at.y)
	var found := salvage.lay(coord, spec) as Device
	var parts := found.parts()
	tally.parts += parts.size()
	var mine := device(id, spot(4.0 * k - 10.0, -2.5), Catalog.DEVICES[id].size.y * 0.5 + 0.02)
	await simulate(0.5)
	for part in parts:
		var socket := part.socket
		if not await _take(found, socket):
			# Out of sight in the sand: taking hold of it pulls it up, as the hands do.
			salvage.unbury(found)
			tally.pulled += 1
			await simulate(1.5)
			if not await _take(found, socket):
				printerr("%s %s: couldn't be taken out" % [found.label, socket.kind])
				continue
		tally.out += 1
		if await _fit_into(mine, part):
			tally.fitted += 1
		else:
			printerr("%s %s: didn't go into yours" % [found.label, part.label])
			hands.drop()
			await simulate(0.2)
	if found.get_parent() == world.content and not found.has_meta(&"find") and found.parts().is_empty():
		tally.yours += 1
	found.free()
	mine.free()


## Takes a fitted part out through the hands, from wherever your eyes reach
## its socket. Whether it came to your hand.
func _take(found: Device, socket: Socket) -> bool:
	var middle := seat(socket) * Vector3(0.0, 0.0, 0.05)
	for look_at in _eyes(seat(socket), middle):
		look(look_at[0], look_at[1])
		await simulate(1.0 / 60.0)
		hands._look()
		if hands.look_socket != socket:
			continue
		hands.grab()
		for i in 90:
			await simulate(1.0 / 60.0)
			if hands.phase == Hands.Phase.HELD:
				return true
		return false
	return false


## Aims what you hold at a free socket of its kind on your device and takes
## it home. Whether it went in.
func _fit_into(mine: Device, part: Part) -> bool:
	for socket in mine.sockets():
		if socket.kind != part.kind or socket.part != null:
			continue
		var middle := seat(socket) * Vector3(0.0, 0.0, 0.05)
		for look_at in _eyes(seat(socket), middle):
			look(look_at[0], look_at[1])
			await simulate(4.0 / 60.0)
			if hands.socket == socket:
				hands.grab()
				await simulate(1.0 / 60.0)
				return socket.part == part
	return false


## Where your eyes might stand, and what they look at, to see a socket's
## part: its middle from round its axis, and from beside it a little higher,
## its middle or its edge toward you, as you'd look under a thing. Never from
## in the sand.
func _eyes(at: Transform3D, middle: Vector3) -> Array[Array]:
	var out: Array[Array] = []
	for off: float in OFF_AXIS:
		for s in SIDES if off > 0.0 else 1:
			var spin := TAU * s / SIDES
			var side := at.basis.x * cos(spin) + at.basis.y * sin(spin)
			var eye_at := middle + (at.basis.z * cos(off) + side * sin(off)) * DISTANCE
			if off == PI / 2.0:
				eye_at += Vector3.UP * BESIDE_UP
			if eye_at.y > world.height_under(eye_at) + 0.2:
				for edge: float in ([0.0, 0.15, 0.3] if off == PI / 2.0 else [0.0]):
					out.append([eye_at, middle + side * edge])
			if off == PI / 2.0:
				var low := middle + side * CROUCHED_OFF
				low.y = world.height_under(low) + CROUCHED_EYE
				for edge: float in [0.0, 0.2, 0.33]:
					out.append([low, middle + side * edge])
	return out
