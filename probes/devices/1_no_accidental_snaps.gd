extends HandsProbe
## Devices & mods probe 1: no accidental snaps. Parts are pressed into free
## sockets, rested in them, dropped on, thrown at and dragged against devices
## thousands of times, and let go through the hands while the tug is pulling
## them in. Nothing fits. Then, so this can't pass by nothing ever fitting, a
## held and aimed part fits through the hands: a battery and a seedling by aim
## alone, and a hover tray slid under a resting planter with E.

const ROUNDS := 30
const THROWN := 30
const DRAGGED := 16
const LET_GO := 4

var _crate: Device
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
	_crate = device(&"crate_frame", spot(-2.5, -4.0), 0.27)
	_planter = device(&"planter", spot(1.5, -4.0), 0.2)
	_floater = device(&"crate_frame", spot(-0.5, -8.0), 1.2)
	var tray := Catalog.part(&"hover_tray")
	world.content.add_child(tray)
	for socket in _floater.sockets():
		if socket.kind == &"bottom":
			_floater.fit(tray, socket)
	_devices = [_crate, _planter, _floater]
	await simulate(3.0)
	for each in _devices:
		_homes.append(each.global_transform)
	var before := _fitted()
	hands.fitted.connect(func(_p: Part, _d: Device, _s: Socket) -> void: _hand_fits += 1)

	for n in ROUNDS:
		for step: Callable in [_pressed_in, _thrown, _dragged, _let_go_in_the_tug]:
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
	speed_up(1)


## Every free socket gets its own part sitting right in its seat or just out
## from it, pushed in, plus a part of some other kind; you look at the device
## empty-handed.
func _pressed_in() -> void:
	for each in _devices:
		for socket in each.sockets():
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
	for each: Device in [_crate, _planter]:
		var start := each.global_position
		for i in DRAGGED / 2:
			var at := start + Vector3(0.8 + i * 0.25, 0.0, randf_range(-0.3, 0.3))
			at.y = world.height_under(at) + 0.02
			_add(_any_id(), Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), at))
	await simulate(0.3)
	await simulate(1.5, func() -> void:
		for each: Device in [_crate, _planter]:
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
				"the one aimed at" if hands.socket == socket else hands.socket])
		if i % 2 == 0:
			hands.drop()
		else:
			hands.throw()
		await _settle(1.0)


## Where to look from and at so your sight runs straight down a seat's axis,
## 14-26 cm beside the part as it would sit there, and clear of every other
## free seat of its kind; {} if there's no such side.
func _beside(socket: Socket, lying: Part) -> Dictionary:
	var at := seat(socket)
	var mid := at * middle(lying)
	var gap := randf_range(0.14, 0.26)
	for axis: Vector3 in [Vector3.RIGHT, Vector3.LEFT, Vector3.UP, Vector3.DOWN]:
		var target := mid + at.basis * axis * (_half(lying, axis) + gap)
		var clear := true
		for each in _devices:
			for other in each.sockets():
				if other != socket and other.part == null and other.kind == socket.kind \
						and minf(_gap(seat(other), lying, target), _gap(seat(other), lying,
							target - at.basis.z * 0.5)) < world.tuning.snap_reach + 0.05:
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


## The control: held and aimed, parts do fit.
func _held_and_aimed_fits() -> void:
	var fits_before := _hand_fits
	# The planter gets a battery too: a tray only floats a device with power.
	for job: Array in [[_crate, &"battery", false], [_planter, &"plant_small", false],
			[_planter, &"battery", false], [_planter, &"bottom", true]]:
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
			# Under a resting device: aim low at its side, just off its front face, and press E.
			var side := owner.global_position + owner.global_basis.z * 0.31 + Vector3.DOWN * 0.12
			look(side + owner.global_basis.z * 1.2 + Vector3.UP * 0.9, side)
			await simulate(0.1)
			check(hands.socket == socket, "aimed at the planter's side, the tray tugs toward its bottom mount")
			hands.grab()
		else:
			look(at * middle(lying) + at.basis.z * 1.0 + Vector3.UP * 0.4, at * middle(lying))
			await simulate(0.6)
		check(socket.part == lying, "a held %s, aimed, fits %s's %s socket" % [lying.label, owner.label, socket.kind])
	check(_hand_fits - fits_before == 4, "through the hands")
	await simulate(2.0)
	check(_planter.stats().hovering and _planter.global_position.y > world.height_under(_planter.global_position) + 0.8,
		"the planter floats on the tray slid under it")


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
		for socket in each.sockets():
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
