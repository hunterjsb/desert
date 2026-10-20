extends LineProbe
## Taking a fully dropped strand recovers its rope, without another copy.

func run() -> void:
	await load_lines()
	var at := world.player.global_position
	var left := driven_stake(at + Vector3(-3, 0, -2))
	var right := driven_stake(at + Vector3(3, 0, -2))
	var line := lay(left, right, 0.6)
	for end in line.ends:
		var socket := end.socket
		(socket.get_parent() as Device).take(socket)
	await simulate(1.0)
	var full := line.full
	var strand := line.rope.strand
	var middle := strand.points[strand.points.size() / 2]
	look(middle + Vector3(0, 0.9, 0.6), middle)
	await physics_frames(2)
	check(hands.look_line == line, "aiming at the dropped middle finds the loose line")
	check(hands.grab(), "take gathers the dropped strand")
	await simulate(0.5)
	check(is_instance_valid(line) and hands.held != null and hands.held.get_meta(&"line", null) == line
		and absf(line.full - full) < 0.001 and ropes.ropes.size() == 1,
		"the same line comes to hand with its full length, without duplication")
