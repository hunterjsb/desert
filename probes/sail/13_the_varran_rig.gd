extends SailProbe
## Sailing probe 13: the Varran rig sails with you on the board as its keel.
## His kit's rig floats, with no runners or keel of its own: its bow line
## and its sheet at your waist both stay tied as you step onto the board,
## and in a steady 10 m/s, the sheet tended and the edge dug, it tows you
## across the wind on either tack, its bow line on the hook to that side,
## holding your line. Left undug, the same start runs off downwind.

const DIG := 0.25
const WIND := 10.0

var _lines: Array[Line] = []


func run() -> void:
	await load_sailing()
	var player := world.player
	player.set_physics_process(true)
	player.collision_layer = 1
	player.collision_mask = 1
	speed_up(4)
	for windward: int in [1, -1]:
		var made := await _reach(windward, DIG)
		check(made.x > 3.0 and absf(made.y) < 0.15 * made.x,
			"with the wind on your %s it tows you across at %.2f m/s, %.1f m/s off your line" % [
			"left" if windward > 0 else "right", made.x, made.y])
	var loose := await _reach(1, 0.0)
	check(loose.y > loose.x, "undug, it runs off downwind (%.2f m/s across, %.2f down)" % [loose.x, loose.y])
	speed_up(1)


## A beam reach from the rig's launch, 25 s: your way across and downwind
## over its last 10 s, m/s.
func _reach(windward: int, dig: float) -> Vector2:
	await _clear()
	follow(open)
	await settle(true)
	var player := world.player
	var way := heading(windward)
	_lines = await varran(way, windward)
	check(player.board != null and _lines.all(func(l: Line) -> bool: return player.waist.holds(l.ends[1])),
		"on the board, its bow line and its sheet both still at your waist")
	blow(downwind * WIND)
	tending = deg_to_rad(15.0)
	var seen := {"t": 0, "across": 0.0, "down": 0.0}
	await simulate(25.0, func() -> void:
		player.rotation.y = atan2(-way.x, -way.y)
		_steer()
		seen.t += 1
		if seen.t == 120 and dig > 0.0:
			Input.action_press("move_forward", 1.0)
			Input.action_press("move_back", dig)
		if seen.t > 900:
			var mine := Vector2(player.velocity.x, player.velocity.z)
			seen.across += mine.dot(way) / 600.0
			seen.down += mine.dot(downwind) / 600.0)
	Input.action_release("move_forward")
	Input.action_release("move_back")
	print("wind on the %s, dug %.2f: %.2f m/s across, %.2f downwind; the bow line %d N, the sheet %d N, heeling %.1f°" % [
		"left" if windward > 0 else "right", dig, seen.across, seen.down, _lines[0].rope.tension,
		_lines[1].rope.tension, heel()])
	return Vector2(seen.across, seen.down)


func _clear() -> void:
	var player := world.player
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
