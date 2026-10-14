extends HandsProbe
## Devices & mods probe 5: out the way it went in. Every part of both devices,
## fully fitted and floating, is taken out through the hands from eight
## directions round its socket's opening. Every tick from the take until it's
## in your hand, it never overlaps what's left of its device, and while it
## slides it moves only straight out along its socket's +Z. Then it goes back
## in through the hands from the same place.

const ANGLES := 8
## Your eyes sit this far from the part, this far off its socket's axis (50°).
const DISTANCE := 1.1
const OFF_AXIS := 0.87
## A socket must be reachable from at least this many of the eight.
const SEEN := 6


func run() -> void:
	await load_hands()
	speed_up(10)
	var crate := device(&"crate_frame", spot(0.0, -4.0), 1.2, true)
	var planter := device(&"planter", spot(4.0, -4.0), 1.2, true)
	await simulate(3.0)
	check(crate.stats().hovering and planter.stats().hovering, "both devices float, fully fitted")
	var tally := {"taken": 0, "inside": 0, "astray": 0, "slow": 0, "back": 0, "short": 0}
	for each: Device in [crate, planter]:
		var home := each.global_transform
		for socket in each.sockets():
			var reached := 0
			for k in ANGLES:
				each.global_transform = home
				each.linear_velocity = Vector3.ZERO
				each.angular_velocity = Vector3.ZERO
				if await _take_and_refit(each, socket, k, tally):
					reached += 1
			if reached < SEEN:
				tally.short += 1
				printerr("%s %s: reached from only %d of %d" % [each.label, socket.kind, reached, ANGLES])
	speed_up(1)
	print("%d removals; %d ticks overlapping the device, %d off the straight line, %d slow; %d refitted"
		% [tally.taken, tally.inside, tally.astray, tally.slow, tally.back])
	check(tally.short == 0, "every socket was reached from at least %d of %d directions" % [SEEN, ANGLES])
	check(tally.taken >= (crate.sockets().size() + planter.sockets().size()) * SEEN,
		"parts were taken out (%d)" % tally.taken)
	check(tally.inside == 0, "no part ever overlapped its device on the way out")
	check(tally.astray == 0, "every part slid straight out along its socket's +Z")
	check(tally.slow == 0, "every part reached your hand within a second")
	check(tally.back == tally.taken, "every part went back in through the hands (%d of %d)"
		% [tally.back, tally.taken])


## Takes the part in `socket` out from the k-th direction, watching each tick,
## then fits it back. False if it can't be seen from there.
func _take_and_refit(owner: Device, socket: Socket, k: int, tally: Dictionary) -> bool:
	var part := socket.part
	var middle := _middle_of(owner, socket)
	var at := seat(socket)
	var spin := TAU * k / ANGLES
	var side := at.basis.x * cos(spin) + at.basis.y * sin(spin)
	var eye_at := middle + (at.basis.z * cos(OFF_AXIS) + side * sin(OFF_AXIS)) * DISTANCE
	if eye_at.y < world.height_under(eye_at) + 0.1:
		return false
	look(eye_at, middle)
	await simulate(1.0 / 60.0)
	if hands.look_socket != socket:
		return false
	check(hands.grab() and hands.held == part, "the look takes the part")
	tally.taken += 1
	var seen := {"z": -INF}
	var watch := func() -> void:
		if overlaps(part, owner):
			tally.inside += 1
		if hands.phase == Hands.Phase.TAKING:
			var rel := seat(socket).affine_inverse() * part.global_transform
			if Vector2(rel.origin.x, rel.origin.y).length() > 0.001 or rel.origin.z < seen.z - 0.0001 \
					or not rel.basis.is_equal_approx(Basis.IDENTITY):
				tally.astray += 1
			seen.z = rel.origin.z
	watch.call()
	for i in 60:
		await simulate(1.0 / 60.0, watch)
		if hands.phase == Hands.Phase.HELD:
			break
	if hands.phase != Hands.Phase.HELD:
		tally.slow += 1
	# Aim away, then back at its empty seat, and fit it now.
	look(eye_at, eye_at + Vector3.UP)
	await simulate(1.0 / 60.0)
	look(eye_at, middle)
	await simulate(2.0 / 60.0)
	hands.grab()
	if socket.part == part:
		tally.back += 1
	else:
		printerr("%s %s from %d: didn't go back in (tug %s)" % [owner.label, socket.kind, k, hands.socket])
		hands.drop()
	return true


## The middle of a fitted part's shapes, in the world.
func _middle_of(owner: Device, socket: Socket) -> Vector3:
	var sum := Vector3.ZERO
	var count := 0
	for node in socket.fitted:
		if node is CollisionShape3D:
			sum += owner.global_transform * node.position
			count += 1
	return sum / maxi(count, 1)
