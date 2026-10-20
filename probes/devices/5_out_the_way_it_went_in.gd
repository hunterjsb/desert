extends HandsProbe
## Devices & mods probe 5: out the way it went in. Every part of a floating
## chassis loaded on its faces and of a fully fitted planter is taken off
## through the hands from eight directions round its opening. Every tick from
## the take until it's in your hand, it never overlaps what's left of its
## body, and while it slides it moves only straight out of its slot or off
## its face. Then it goes back on through the hands from the same place.

const ANGLES := 8
## Your eyes sit this far from the part, this far off its socket's axis (50°).
const DISTANCE := 1.1
const OFF_AXIS := 0.87
## A socket must be reachable from at least this many of the eight.
const SEEN := 6


func run() -> void:
	await load_hands()
	speed_up(10)
	var deck := device(&"chassis", spot(0.0, -4.0), 1.2, true)
	for id: StringName in [&"hover_tray", &"battery", &"big_battery", &"lamp"]:
		fit_part(deck, id)
	var planter := device(&"planter", spot(4.0, -4.0), 1.2, true)
	await simulate(3.0)
	check(deck.stats().hovering and planter.stats().hovering, "both float, fully loaded")
	var tally := {"taken": 0, "inside": 0, "astray": 0, "slow": 0, "back": 0, "short": 0}
	var filled := 0
	for each: Device in [deck, planter]:
		var home := each.global_transform
		for part in each.parts():
			filled += 1
			var reached := 0
			for k in ANGLES:
				each.global_transform = home
				each.linear_velocity = Vector3.ZERO
				each.angular_velocity = Vector3.ZERO
				if await _take_and_refit(each, part, k, tally):
					reached += 1
			if reached < SEEN:
				tally.short += 1
				printerr("%s %s: reached from only %d of %d" % [each.label, part.label, reached, ANGLES])
	speed_up(1)
	print("%d removals; %d ticks overlapping the device, %d off the straight line, %d slow; %d refitted"
		% [tally.taken, tally.inside, tally.astray, tally.slow, tally.back])
	check(tally.short == 0, "every socket was reached from at least %d of %d directions" % [SEEN, ANGLES])
	check(tally.taken >= filled * SEEN,
		"parts were taken out (%d)" % tally.taken)
	check(tally.inside == 0, "no part ever overlapped its device on the way out")
	check(tally.astray == 0, "every part slid straight out of its slot or off its face")
	check(tally.slow == 0, "every part reached your hand within a second")
	check(tally.back == tally.taken, "every part went back on through the hands (%d of %d)"
		% [tally.back, tally.taken])


## Takes a part off from the k-th direction round its opening, watching each
## tick, then puts it back on. False if it can't be seen from there.
func _take_and_refit(owner: Device, part: Part, k: int, tally: Dictionary) -> bool:
	var socket := part.socket
	var middle := _middle_of(owner, socket)
	var at := seat(socket)
	var stuck := socket.stuck()
	var home := [socket.transform, socket.out, (owner as Chassis).own_piece(socket) if stuck else null]
	var owner_at := owner.global_transform
	var spin := TAU * k / ANGLES
	var side := at.basis.x * cos(spin) + at.basis.y * sin(spin)
	var eye_at := middle + (at.basis.z * cos(OFF_AXIS) + side * sin(OFF_AXIS)) * DISTANCE
	if eye_at.y < world.height_under(eye_at) + 0.1:
		return false
	look(eye_at, middle)
	await simulate(1.0 / 60.0)
	if hands.look_socket != socket:
		printerr("%s %s from %d: the look meets %s" % [owner.label, part.label, k,
			hands.look_socket.part.label if hands.look_socket != null and hands.look_socket.part != null
			else (hands.look_device.label if hands.look_device != null else ("part " + hands.look_part.label if hands.look_part != null else "nothing at %s" % hands.sight_to))])
		return false
	at = seat(socket)
	check(hands.grab() and hands.held == part, "the look takes the part")
	tally.taken += 1
	var seen := {"z": -INF}
	var watch := func() -> void:
		if overlaps(part, owner):
			tally.inside += 1
		if hands.phase == Hands.Phase.TAKING:
			var rel := at.affine_inverse() * part.global_transform
			# Turned at all, beyond the engine's float rounding on a device that floats off level.
			if Vector2(rel.origin.x, rel.origin.y).length() > 0.001 or rel.origin.z < seen.z - 0.0001 \
					or rel.basis.x.distance_to(Vector3.RIGHT) + rel.basis.y.distance_to(Vector3.UP) > 0.0001:
				tally.astray += 1
			seen.z = rel.origin.z
	watch.call()
	for i in 60:
		await simulate(1.0 / 60.0, watch)
		if hands.phase == Hands.Phase.HELD:
			break
	if hands.phase != Hands.Phase.HELD:
		tally.slow += 1
	# Aim away, then back where it was, and put it on there: stuck, at the spot
	# on the face its base was on.
	# Held where it was, so a deck that lost its tray hasn't dropped from under your aim.
	owner.global_transform = owner_at
	owner.freeze = true
	var aim: Vector3 = (owner.global_transform * (home[0] as Transform3D)).origin if stuck else middle
	look(eye_at, eye_at * 2.0 - aim)
	await simulate(1.0 / 60.0)
	look(eye_at, aim)
	await simulate(0.2)
	hands.grab()
	var back := part.socket == socket if not stuck \
		else part.socket != null and part.socket.get_parent() == owner \
			and part.socket.transform.origin.distance_to((home[0] as Transform3D).origin) < 0.03
	owner.freeze = false
	if back:
		tally.back += 1
	else:
		printerr("%s %s from %d: didn't go back on" % [owner.label, part.label, k])
		hands.stow()
		# Back where it was, for the next direction.
		if part.socket != null:
			(part.socket.get_parent() as Device).take(part.socket)
		if stuck:
			owner.stick(part, home[0], home[1], home[2])
		else:
			owner.fit(part, socket)
	return true


## The middle of a part's shapes where it's fitted or stuck, in the world.
func _middle_of(owner: Device, socket: Socket) -> Vector3:
	var sum := Vector3.ZERO
	var count := 0
	for node in socket.fitted:
		if node is CollisionShape3D:
			sum += owner.global_transform * node.position
			count += 1
	return sum / maxi(count, 1)
