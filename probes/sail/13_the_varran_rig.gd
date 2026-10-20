extends SailProbe
## Sailing probe 13: the Varran rig sails both tacks with you on the board as
## its keel, without moving a line. His kit's rig floats, with no runners or
## keel of its own: a bow line from each bow hook and its sheet at your waist
## all stay tied as you step onto the board. In a steady 10 m/s, the sheet
## tended and the edge dug, it tows you across the wind with the wind on your
## left; reeling in its far bow line at your hands' pace as you turn pulls it
## across, and paid out again, it tows you across the other way, every line
## where it was laid. Left undug, the same start runs off downwind.

const DIG := 0.25
const WIND := 10.0
## The far bow line taken in at your hands' pace, m, as you turn.
const REEL := 6.0

var _lines: Array[Line] = []


func run() -> void:
	await load_sailing()
	var player := world.player
	player.set_physics_process(true)
	player.collision_layer = 1
	player.collision_mask = 1
	speed_up(4)
	await _launch(1)
	var hooked := _lines.map(func(l: Line) -> Socket: return (l.ends[0] as Part).socket)
	check(player.board != null and _lines.size() == 3 and _lines.all(func(l: Line) -> bool: return player.waist.holds(l.ends[1])),
		"on the board, its bow lines and its sheet all still at your waist")
	var first := await _sail(heading(1), 25.0, DIG)
	check(first.x > 3.0 and absf(first.y) < 0.15 * first.x,
		"with the wind on your left it tows you across at %.2f m/s, %.1f m/s off your line" % [first.x, first.y])
	await _tack()
	var second := await _sail(heading(-1), 25.0, DIG)
	check(second.x > 3.0 and absf(second.y) < 0.15 * second.x,
		"its far bow line reeled in and out as you turned, it tows you the other way at %.2f m/s, %.1f m/s off" % [
		second.x, second.y])
	check(_lines.all(func(l: Line) -> bool: return is_instance_valid(l) and l.rope != null)
		and _lines.map(func(l: Line) -> Socket: return (l.ends[0] as Part).socket) == hooked,
		"and no line moved: each where it was laid")
	await _launch(1)
	# The undug comparison isolates the wind's sideways shove from powered
	# course changes; the powered reaches and tack were exercised above.
	world.tuning.board_push = 0.0
	var loose := await _sail(heading(1), 25.0, 0.0)
	check(loose.y > loose.x, "undug, it runs off downwind (%.2f m/s across, %.2f down)" % [loose.x, loose.y])
	speed_up(1)


func _launch(windward: int) -> void:
	await _clear()
	follow(open)
	await settle(true)
	_lines = await varran(heading(windward), windward)
	blow(downwind * WIND)
	tending = deg_to_rad(15.0)


## Sailing toward `way` for a span, dug `dig`: your way along it and
## downwind over the last 10 s, m/s.
func _sail(way: Vector2, seconds: float, dig: float) -> Vector2:
	var player := world.player
	var seen := {"t": 0, "across": 0.0, "down": 0.0, "aiding": 0, "hot": 0.0}
	var last := roundi(seconds * 60.0) - 600
	await simulate(seconds, func() -> void:
		player.rotation.y = atan2(-way.x, -way.y)
		_steer()
		seen.t += 1
		if seen.t == 1:
			Input.action_press("move_forward", 1.0)
			Input.action_press("move_back", dig)
		if seen.t > last:
			var mine := Vector2(player.velocity.x, player.velocity.z)
			seen.across += mine.dot(way) / 600.0
			seen.down += mine.dot(downwind) / 600.0
			var pull := Vector3.ZERO
			for force in ropes._on_you:
				pull += force
			if Vector2(pull.x, pull.z).dot(player.ride.ahead) > 30.0:
				seen.aiding += 1
				seen.hot = maxf(seen.hot, player.ride.overload))
	print("toward %s, dug %.2f: %.2f m/s across, %.2f downwind; the bow lines %d and %d N, the sheet %d N, heeling %.1f°" % [
		"the wind's left" if way.dot(heading(1)) > 0.0 else "its right", dig, seen.across, seen.down,
		_lines[0].rope.tension, _lines[2].rope.tension, _lines[1].rope.tension, heel()])
	print("aiding wind load: %d ticks, peak motor heat %.3f" % [seen.aiding, seen.hot])
	if dig > 0.0:
		check(seen.aiding > 60 and seen.hot < 0.1, "loaded aiding wind keeps the motor cool")
	return Vector2(seen.across, seen.down)


## Turned onto the other side, its far bow line reeled in at your hands' pace
## and then paid out again, as a kite's line on the new side is pulled.
func _tack() -> void:
	var player := world.player
	var way := heading(-1)
	var far: Rope = _lines[2].rope
	var full := far.length
	var pace := Reel.PACE / 60.0
	# Ease the motor and brake before sending the rig across; a full-throttle
	# reversal fights its old tack and stalls the hover.
	Input.action_release("move_forward")
	Input.action_press("move_back", 1.0)
	await simulate(2.0)
	Input.action_press("move_back", DIG)
	Input.action_press("move_forward", 1.0)
	var elapsed := {"t": 0.0}
	await simulate(2.0 * REEL / Reel.PACE + 12.5, func() -> void:
		elapsed.t += 1.0 / 60.0
		var broad := (way + downwind).normalized()
		var course := downwind if elapsed.t < 4.0 else broad
		if elapsed.t > REEL / Reel.PACE + 12.0:
			course = broad.slerp(way, clampf((elapsed.t - REEL / Reel.PACE - 12.0) / (REEL / Reel.PACE), 0.0, 1.0))
		player.rotation.y = atan2(-course.x, -course.y)
		_steer()
		if elapsed.t < REEL / Reel.PACE:
			far.length = maxf(far.length - pace, full - REEL)
		elif elapsed.t > REEL / Reel.PACE + 12.0:
			far.length = minf(far.length + pace, full)
	)
	print("tacked: its far bow line taken in %.1f m and let out to %.1f m" % [REEL, far.length])


func _clear() -> void:
	var player := world.player
	Input.action_release("move_forward")
	Input.action_release("move_back")
	player.step_off()
	for body in player.waist.tied.duplicate():
		player.waist.untie(body)
	for line in _lines:
		if is_instance_valid(line):
			for end in line.ends:
				if is_instance_valid(end) and not (end.get_parent() is Device):
					end.free()
			line.free()
	_lines.clear()
	for node in world.content.get_children():
		if node is Device and not node is Stake:
			node.free()
	await physics_frames(2)
