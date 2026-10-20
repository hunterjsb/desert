extends SalvageProbe
## Salvage & ruins probe 6: strip and fit. Every kind of device the sand
## holds is found buried with every socket and spot a layer can fill filled.
## Through the hands, every part comes out of it, as it lies where your eyes
## can reach it, or once you've taken hold of the device and pulled it up out
## of the sand where they can't, and goes into a device of your own: into its
## socket, or stuck on your own chassis. What you
## take from becomes yours; nothing is left in the find. A found shield
## generator, used as it lies, starts on that first use. A found coil, taken,
## gives you a line's first end to lay, and a found plug brings its cable and
## second plug up out of the sand with it.

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
			# Nothing to strip from a stake, a bedroll or a light panel: nothing of theirs is found filled.
			if entry[0] != &"stake" and Finds.holds(entry[0]).any(func(kind: StringName) -> bool:
					return Finds.FILLS[Finds.DEEP].has(kind) or Finds.FILLS[Finds.SURFACE].has(kind) \
						or entry[0] == &"survival_kit" and Finds.SURVIVAL_KIT.has(kind)):
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
	await _unrolls(&"coil", 0)
	await _unrolls(&"plug", 1)
	await _unrolls(&"strong_plug", 2)


## A found coil or plug lying loose a step ahead, taken through the hands.
func _unrolls(id: StringName, k: int) -> void:
	var here := Vector2(world.player_world_x(), world.player_world_z())
	var at := here + Vector2(1.5 * k - 1.5, -2.0)
	var spec := {"index": 950 + k, "id": id, "device": false, "layer": Finds.SURFACE, "x": at.x, "z": at.y,
		"yaw": 0.3, "lean": 0.0, "lean_by": 0.0, "bury": 0.0, "loose": true, "sound": 1.0, "charge": 0.0, "fill": []}
	var found := salvage.lay(world.terrain.chunk_at(at.x, at.y), spec) as Part
	await simulate(1.0)
	var middle := found.global_transform * Finds.bounds(found).get_center()
	look(middle + Vector3(0.0, 1.2, 0.8), middle)
	await simulate(1.0 / 60.0)
	check(hands.grab(), "take picks up a found %s" % found.label)
	await simulate(0.5)
	if id == &"coil":
		var line := hands.held.get_meta(&"line") as Line if hands.held != null and hands.held.has_meta(&"line") else null
		check(line != null and line.state == Line.State.FIRST and hands.held.kind == &"tie"
			and world.player.waist.holds(line.ends[1]), "a found coil gives you its first end, the rest on your belt")
	else:
		var cable: Cable = null
		for node in world.content.get_children():
			if node is Cable and (node as Cable).plugs.has(found):
				cable = node
		check(hands.held == found and cable != null and cable.plugs.size() == 2 and (cable is StrongCable) == (id == &"strong_plug")
			and cable.plugs[1].global_position.distance_to(found.global_position) < cable.length,
			"a found %s brings its cable and second plug with it" % found.label)
	hands.drop()
	await simulate(0.3)


## One found device of a kind, every fillable socket full from both layers'
## fills, buried a few metres in front of you, and a bare one of your own
## beside it.
func _strip(id: StringName, k: int, tally: Dictionary) -> void:
	var here := Vector2(world.player_world_x(), world.player_world_z())
	var at := here + Vector2(4.0 * k - 10.0, -6.0)
	var spec := {"index": 900 + k, "id": id, "device": true, "layer": Finds.DEEP, "x": at.x, "z": at.y,
		"yaw": 0.4 * k, "lean": 1.0, "lean_by": 0.1, "bury": 0.35, "sound": 0.9, "charge": 0.5, "fill": []}
	var holds := Finds.holds(id)
	for i in holds.size():
		var kind: StringName = holds[i]
		var fills: Array = [Finds.SURVIVAL_KIT] if id == &"survival_kit" else [Finds.FILLS[Finds.DEEP], Finds.FILLS[Finds.SURFACE]]
		for each: Dictionary in fills:
			if each.has(kind):
				spec.fill.append([i, each[kind][0], 0.5])
				break
	var coord := world.terrain.chunk_at(at.x, at.y)
	var found := salvage.lay(coord, spec) as Device
	var parts := found.parts()
	tally.parts += parts.size()
	var mine := device(id, spot(4.0 * k - 10.0, -2.5), Catalog.DEVICES[id].size.y * 0.5 + 0.02)
	await simulate(0.5)
	if found is ShieldGenerator:
		var top := found.global_transform * Vector3(0.0, 0.15, 0.0)
		look(top + Vector3(0.0, 1.0, 1.0), top)
		await simulate(1.0 / 60.0)
		check(hands.interact() and found.running(), "a found shield generator starts on the first use")
		hands.interact()
	var stuck_on := 0
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
		var put := false
		if mine is Chassis and Stick.sticks(part):
			put = await _stick_into(mine as Chassis, part, stuck_on)
			stuck_on += 1
		else:
			put = await _fit_into(mine, part)
		if put:
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


## Holds a part over a place on your own chassis's top, and takes it home
## where it's shown: a tray goes under. Whether it stuck there.
func _stick_into(mine: Chassis, part: Part, k: int) -> bool:
	var at: Vector2 = DeviceProbe.ON_TOP[k % DeviceProbe.ON_TOP.size()]
	for i in 30:
		var point := mine.global_transform * mine.face_frame(mine, Chassis.TOP) * Vector3(at.x, at.y, 0.0)
		look(point + Vector3(0.0, 1.2, 0.9), point)
		await simulate(1.0 / 60.0)
		if not hands.sticking.is_empty() and hands.sticking.why == "":
			hands.grab()
			await simulate(1.0 / 60.0)
			return part.socket != null and part.socket.get_parent() == mine
	return false


## Where your eyes might stand, and what they look at, to see a socket's
## part: its middle from round its axis, and from beside it a little higher,
## its middle, its edge toward you or just under a chassis piece's edge, as
## you'd look under a thing. Never from in the sand.
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
				for edge: float in ([0.0, 0.15, 0.3, 0.5] if off == PI / 2.0 else [0.0]):
					out.append([eye_at, middle + side * edge])
			if off == PI / 2.0:
				var low := middle + side * CROUCHED_OFF
				low.y = world.height_under(low) + CROUCHED_EYE
				for edge: float in [0.0, 0.2, 0.33]:
					out.append([low, middle + side * edge])
	return out
