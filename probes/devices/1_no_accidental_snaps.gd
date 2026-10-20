extends HandsProbe
## Devices & mods probe 1: no accidental snaps or sticks. Parts are pressed
## into free slots, rested in them and on chassis tops, dropped on, thrown at
## and dragged against devices thousands of times, and let go through the
## hands while the tug is pulling them in or while they're shown where they'd
## stick. Nothing fits or sticks. Then, so this can't pass by nothing ever
## going on, held and aimed parts go on through the hands: a battery stuck on
## a chassis top, a root-tuber and a battery into a planter by aim alone, and
## a hover tray slid under a resting planter with take. And standing at your
## full height by a chassis and a planter on the sand, looking at them is
## enough: a tray is shown under the chassis, a hook offered the ring on your
## side, or from a side where neither of a planter's rings faces you the one
## nearer your aim, and a shield shown on the chassis top; each waits for
## take. A fitted part still comes out to an empty hand.

const ROUNDS := 30
const THROWN := 30
const DRAGGED := 16
const LET_GO := 4

var _resting: Device
var _planter: Device
var _floater: Device
var _devices: Array[Device] = []
var _homes: Array[Transform3D] = []
var _loose: Array[Part] = []
var _events := 0
var _hand_fits := 0


func run() -> void:
	await load_hands()
	speed_up(20)
	_resting = device(&"chassis", spot(-2.5, -4.0), 0.07)
	_planter = device(&"planter", spot(1.5, -4.0), 0.2)
	_floater = device(&"chassis", spot(-0.5, -8.0), 1.2)
	Stick.put(_floater as Chassis, _floater as Chassis, Chassis.BOTTOM, Vector2.ZERO, 0.0, Catalog.part(&"hover_tray"))
	Stick.put(_floater as Chassis, _floater as Chassis, Chassis.BOTTOM, Vector2(0.4, 0.4), 0.0, Catalog.part(&"battery"))
	_devices = [_resting, _planter, _floater]
	await simulate(3.0)
	for each in _devices:
		_homes.append(each.global_transform)
	var before := _fitted()
	hands.fitted.connect(func(_p: Part, _d: Device, _s: Socket) -> void: _hand_fits += 1)

	for n in ROUNDS:
		for step: Callable in [_pressed_in, _thrown, _dragged, _let_go_in_the_tug, _let_go_where_shown]:
			await step.call()
			if _fitted() != before:
				printerr("parts fitted on their own in round %d, %s" % [n, step.get_method()])
				break
		if _fitted() != before:
			break
	var after := _fitted()
	print("%d parts pressed, dropped, thrown, dragged or let go against devices; fitted before %s, after %s"
		% [_events, before, after])
	check(_events >= 2000, "thousands of tries (%d)" % _events)
	check(after == before and _hand_fits == 0, "nothing fitted that wasn't held and aimed")
	await _held_and_aimed_fits()
	await _fits_standing()
	speed_up(1)


## Every free socket gets its own part sitting right in its seat or just out
## from it, pushed in, plus a part of some other kind; you look at the device
## empty-handed.
func _pressed_in() -> void:
	for each in _devices:
		for socket in each.sockets().filter(func(s: Socket) -> bool: return FILL.has(s.kind)):
			var at := seat(socket)
			var tip := at * Vector3(0.0, 0.0, 0.1)
			if socket.part != null or tip.y < world.height_under(tip):
				continue
			var nudge := Basis.from_euler(Vector3(randf_range(-0.05, 0.05), randf_range(-0.05, 0.05),
				randf_range(-0.05, 0.05)))
			var pose := Transform3D(at.basis * nudge, at * Vector3(randf_range(-0.02, 0.02),
				randf_range(-0.02, 0.02), randf_range(0.0, 0.12)))
			var pressed := _add(FILL[socket.kind], pose)
			pressed.linear_velocity = -at.basis.z * randf_range(0.0, 1.5)
			_add(_any_id(), pose.translated(at.basis.z * 0.3 + Vector3.UP * 0.2))
	# Rested and pressed on the chassis tops, right where they'd stick.
	for deck: Chassis in [_resting as Chassis, _floater as Chassis]:
		for k in 3:
			var at := deck.global_transform * Chassis.FACES[Chassis.TOP] * Vector3(randf_range(-0.3, 0.3), randf_range(-0.3, 0.3), 0.08)
			var pressed := _add(_any_id(), Transform3D(Basis(Vector3.RIGHT, -PI / 2.0) * Basis(Vector3.BACK, randf() * TAU), at))
			pressed.linear_velocity = Vector3.DOWN * randf_range(0.0, 1.5)
	look(_floater.global_position + Vector3(0.0, 0.4, 1.4), _floater.global_position)
	await _settle(1.0)


## Parts of every kind thrown at free sockets from a few metres, spinning; you
## hold a part meanwhile, looking at the sky.
func _thrown() -> void:
	await _take_in_hand(&"battery")
	look(eye(), eye() + Vector3.UP)
	for i in THROWN:
		var target := seat(_random_free_socket())
		var from := target.origin + Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)).normalized() \
			* randf_range(2.0, 3.5)
		from.y = world.height_under(from) + randf_range(0.3, 1.5)
		var thrown := _add(_any_id(), Transform3D(Basis.from_euler(Vector3(randf(), randf(), randf()) * TAU), from))
		thrown.linear_velocity = (target.origin - from).normalized() * randf_range(4.0, 9.0)
		thrown.angular_velocity = Vector3(randf(), randf(), randf()) * 6.0
	await _settle(1.5)
	hands.drop()


## Both resting devices dragged across a strip of parts lying on the sand.
func _dragged() -> void:
	for each: Device in [_resting, _planter]:
		var start := each.global_position
		for i in DRAGGED / 2:
			var at := start + Vector3(0.8 + i * 0.25, 0.0, randf_range(-0.3, 0.3))
			at.y = world.height_under(at) + 0.02
			_add(_any_id(), Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), at))
	await simulate(0.3)
	await simulate(1.5, func() -> void:
		for each: Device in [_resting, _planter]:
			each.linear_velocity = Vector3(2.0, each.linear_velocity.y, 0.0))
	await _settle(0.0)


## A part taken in hand and aimed just beside a free socket's seat, so the
## tug pulls but it isn't home, then dropped or thrown into the device.
func _let_go_in_the_tug() -> void:
	for i in LET_GO:
		var socket := _random_free_socket()
		var lying := await _take_in_hand(FILL[socket.kind])
		var beside := _beside(socket, lying)
		if beside.is_empty():
			hands.drop()
			await _settle(0.5)
			continue
		look(beside.eye, beside.target)
		await simulate(0.15)
		check(hands.socket == socket and hands.pull > 0.0 and hands.held == lying,
			"the tug was pulling a %s when it was let go (gap %.2f, %s)" % [lying.label, hands.gap,
				"the one aimed at" if hands.socket == socket else "%s, aimed at %s" % [_named(hands.socket), _named(socket)]])
		if i % 2 == 0:
			hands.drop()
		else:
			hands.throw()
		await _settle(1.0)


## A part taken in hand and shown where it would stick on a chassis's top,
## then dropped or thrown onto it.
func _let_go_where_shown() -> void:
	for i in LET_GO:
		var deck: Chassis = [_resting, _floater][i % 2]
		var lying := await _take_in_hand([&"battery", &"lamp", &"solar_panel", &"canister"][i])
		var at := deck.global_transform * Chassis.FACES[Chassis.TOP] * Vector3(randf_range(-0.3, 0.3), randf_range(-0.3, 0.3), 0.0)
		look(at + Vector3(0.0, 1.2, 1.0), at)
		await simulate(0.15)
		check(not hands.sticking.is_empty() and hands.held == lying and lying.socket == null,
			"a %s was shown where it would stick when it was let go" % lying.label)
		if i % 2 == 0:
			hands.drop()
		else:
			hands.throw()
		await _settle(1.0)


## Where to look from and at so your sight runs straight down a seat's axis,
## 14-26 cm beside the part as it would sit there, and clear all along of
## every other free seat of its kind; {} if there's no such side.
func _beside(socket: Socket, lying: Part) -> Dictionary:
	var at := seat(socket)
	var mid := at * middle(lying)
	var gap := randf_range(0.14, 0.26)
	for axis: Vector3 in [Vector3.RIGHT, Vector3.LEFT, Vector3.UP, Vector3.DOWN]:
		var target := mid + at.basis * axis * (_half(lying, axis) + gap)
		var clear := true
		for each in _devices:
			for other in each.sockets():
				if other == socket or other.part != null or other.kind != socket.kind:
					continue
				# Anywhere along the look, which runs on across a deck to its far rings.
				for t: float in [0.0, 0.5, 1.0, 1.5, 2.0]:
					if _gap(seat(other), lying, target - at.basis.z * t) < world.tuning.snap_reach + 0.05:
						clear = false
		if clear:
			return {"eye": target + at.basis.z * 1.0, "target": target}
	return {}


## How far a point is from a part as it would sit in a seat.
func _gap(at: Transform3D, of: Part, point: Vector3) -> float:
	var local := at.affine_inverse() * point
	var box := bounds(of)
	return local.distance_to(local.clamp(box.position, box.end))


## Waits, counts the tries, then clears the loose parts and puts the devices
## back where they were.
func _settle(seconds: float) -> void:
	await simulate(seconds)
	_events += _loose.size()
	for part in _loose:
		if is_instance_valid(part) and part.get_parent() != null and part != hands.held:
			part.free()
	_loose.clear()
	if hands.held != null:
		_loose.append(hands.held)
	for i in _devices.size():
		_devices[i].global_transform = _homes[i]
		_devices[i].linear_velocity = Vector3.ZERO
		_devices[i].angular_velocity = Vector3.ZERO


## The control: held, aimed and taken home, parts do go on.
func _held_and_aimed_fits() -> void:
	var fits_before := _hand_fits
	var cell := await _take_in_hand(&"battery")
	var top := _resting.global_transform * Chassis.FACES[Chassis.TOP] * Vector3(0.2, -0.2, 0.0)
	look(top + Vector3(0.0, 1.2, 1.0), top)
	await simulate(0.6)
	check(cell.socket == null and not hands.sticking.is_empty() and hands.sticking.why == "",
		"a held battery is shown on the chassis's top and waits for take")
	hands.grab()
	check(cell.socket != null and cell.socket.get_parent() == _resting, "a held battery, aimed, sticks on the chassis's top")
	# The planter gets a battery too: a tray only floats a device with power.
	for job: Array in [[_planter, &"plant_standard", false], [_planter, &"battery", false], [_planter, &"bottom", true]]:
		var owner: Device = job[0]
		var socket: Socket
		for each in owner.sockets():
			if each.kind == job[1] and each.part == null:
				socket = each
		if socket == null:
			check(false, "%s has a free %s socket left to fit" % [owner.label, job[1]])
			continue
		var lying := await _take_in_hand(FILL[socket.kind])
		var at := seat(socket)
		if job[2]:
			# Under a resting device: aim low at its side, just off its front face, and press take.
			var side := owner.global_position + owner.global_basis.z * 0.31 + Vector3.DOWN * 0.12
			look(side + owner.global_basis.z * 1.2 + Vector3.UP * 0.9, side)
			await simulate(0.1)
			check(hands.socket == socket, "aimed at the planter's side, the tray tugs toward its bottom mount")
			hands.grab()
		else:
			look(at * middle(lying) + at.basis.z * 1.0 + Vector3.UP * 0.4, at * middle(lying))
			await simulate(0.6)
			check(socket.part == null and hands.socket == socket,
				"a held %s leans into %s's %s socket and waits for take" % [lying.label, owner.label, socket.kind])
			hands.grab()
		check(socket.part == lying, "a held %s, aimed, fits %s's %s socket" % [lying.label, owner.label, socket.kind])
	check(_hand_fits - fits_before == 4, "through the hands")
	await simulate(2.0)
	check(_planter.stats().hovering and _planter.global_position.y > world.height_under(_planter.global_position) + 0.8,
		"the planter floats on the tray slid under it")


## Standing 1.5 m from a chassis and a planter resting on the sand, you look
## at them, never at a socket, and what you hold is shown where it would
## stick, or offered the slot it fits.
func _fits_standing() -> void:
	var plate := device(&"chassis", spot(6.0, 1.0), 0.07) as Chassis
	var other := device(&"planter", spot(6.0, 5.0), 0.19)
	await simulate(2.0)
	var tray := await _take_in_hand(&"hover_tray")
	look(_stand_by(plate, Vector3.RIGHT), plate.global_transform * Vector3(0.3, 0.06, 0.0))
	await simulate(0.6)
	check(hands.held == tray and hands.sticking.get("face") == Chassis.BOTTOM and tray.socket == null,
		"looking at a resting chassis's top, a held tray is shown under it and waits for take")
	hands.grab()
	await simulate(2.0 / 60.0)
	check(tray.socket != null and tray.socket.get_parent() == plate and _lowest(plate) > -0.005,
		"take sticks the tray under the chassis, lifted clear of the sand (lowest %.2f m)" % _lowest(plate))
	await simulate(1.0)

	var hook := await _take_in_hand(&"hook")
	look(_stand_by(plate, Vector3.BACK), plate.global_transform * Vector3(0.05, 0.06, 0.3))
	await simulate(0.6)
	check(not hands.sticking.is_empty() and hands.sticking.why == "" and hook.socket == null,
		"looking at the chassis's top, a held hook is shown on its face and waits for take")
	hands.grab()
	var placed := hook.socket
	check(placed != null and placed.get_parent() == plate and placed.stuck(), "take fits the hook where aimed on the deck")
	await simulate(0.2)
	look(_stand_by(plate, Vector3.BACK), seat(placed) * middle(hook))
	await simulate(1.0 / 60.0)
	check(hands.grab() and hands.held == hook and hands.phase == Hands.Phase.TAKING and hook.socket == null,
		"looking straight at the fitted hook, an empty hand takes it out")
	await simulate(0.5)
	# Put the removed hook aside before offering a larger device on the panel.
	look(eye(), eye() + plate.global_basis.z)
	await simulate(0.5)
	hands.drop()
	await simulate(0.5)

	var front := _socket_on(other, &"ring", Vector3(0.0, 0.0, -0.3))
	var back := _socket_on(other, &"ring", Vector3(0.0, 0.0, 0.3))
	var side := _stand_by(other, Vector3.RIGHT)
	var second := await _take_in_hand(&"hook")
	look(side, other.global_transform * Vector3(0.15, 0.17, -0.2))
	await _offered(second, front, "from the planter's side, aimed nearer the front ring, a held hook")
	look(side, other.global_transform * Vector3(0.0, 0.17, 0.2))
	await _offered(second, back, "aimed nearer the back ring, it")
	hands.grab()
	check(back.part == second, "take seats the hook on the ring nearer your aim")

	var shield := Catalog.device(&"light_shield")
	world.content.add_child(shield)
	shield.global_position = eye() + Vector3.UP
	hands.hold(shield)
	await simulate(0.5)
	look(_stand_by(plate, Vector3.RIGHT), plate.global_transform * Vector3(0.2, 0.06, 0.25))
	await simulate(0.6)
	check(not hands.sticking.is_empty() and hands.sticking.why == "" and shield.host() == null,
		"looking at the chassis's top, a held shield is shown there, and waits for take")
	hands.grab()
	check(shield.host() == plate, "take sticks the shield there")


## Waits a moment looking: what you hold leans toward `socket` and stays out of it.
func _offered(held: Part, socket: Socket, what: String) -> void:
	await simulate(0.6)
	check(hands.held == held and hands.socket == socket and hands.pull > 0.0 and socket.part == null,
		"%s is offered its socket and waits for take (offered %s)" % [what, _named(hands.socket)])


## A device's socket of a kind nearest a place in its own frame.
func _socket_on(on: Device, kind: StringName, near: Vector3) -> Socket:
	var best: Socket = null
	for each in on.sockets():
		if each.kind == kind and (best == null or each.position.distance_to(near) < best.position.distance_to(near)):
			best = each
	return best


## Where your eyes are standing 1.5 m off a resting device's face or corner,
## the way `out` points in its frame.
func _stand_by(device: Device, out: Vector3) -> Vector3:
	var away := device.global_basis * out
	away.y = 0.0
	var at := device.global_transform * (out * 0.4) + away.normalized() * 1.5
	at.y = world.height_under(at) + world.player.camera.position.y
	return at


## How far the lowest corner of a device's shapes is above the sand, m.
func _lowest(of: Device) -> float:
	var low := INF
	for child in of.get_children():
		var shape := child as CollisionShape3D
		if shape == null:
			continue
		var box := shape.shape.get_debug_mesh().get_aabb()
		for i in 8:
			var corner := shape.global_transform * box.get_endpoint(i)
			low = minf(low, corner.y - world.height_under(corner))
	return low


func _named(socket: Socket) -> String:
	if socket == null:
		return "nothing"
	return "%s %s at %s" % [(socket.get_parent() as Device).label, socket.kind, socket.position]


## Stands you clear of the devices, drops a part on the sand at your feet and
## takes it in hand.
func _take_in_hand(id: StringName) -> Part:
	var lying := _add(id, Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), spot(0.0, 1.0) + Vector3.UP * 0.02))
	look(spot(0.0, 2.0) + Vector3.UP * 1.65, lying.global_position)
	# A body joins the physics space on the next tick.
	await simulate(2.0 / 60.0)
	look(eye(), lying.global_transform * middle(lying))
	check(hands.grab() and hands.held == lying, "took a %s in hand" % lying.label)
	await simulate(0.25)
	return lying


func _add(id: StringName, pose: Transform3D) -> Part:
	var made := part(id, pose)
	_loose.append(made)
	return made


func _any_id() -> StringName:
	return Catalog.PARTS.keys()[randi() % Catalog.PARTS.size()]


func _random_free_socket() -> Socket:
	var free: Array[Socket] = []
	for each in _devices:
		for socket in each.sockets().filter(func(s: Socket) -> bool: return FILL.has(s.kind)):
			var tip := seat(socket) * Vector3(0.0, 0.0, 0.1)
			if socket.part == null and tip.y > world.height_under(tip):
				free.append(socket)
	return free[randi() % free.size()]


## How far a part reaches from its middle along one of its own axes.
func _half(of: Part, axis: Vector3) -> float:
	return (bounds(of).size * 0.5).dot(axis.abs())


## How many parts each device has fitted.
func _fitted() -> Array[int]:
	var counts: Array[int] = []
	for each in _devices:
		counts.append(each.parts().size())
	return counts
