extends LineProbe
## Continuing the same Use gathers original ends one at a time; releasing
## cancels the next untie, keeping both the hand and remaining waist ties.

func run() -> void:
	await load_lines()
	var player := world.player
	var at := player.global_position
	var lines: Array[Line] = []
	for offset in [Vector3(-4, 0, -4), Vector3(0, 0, -5), Vector3(4, 0, -4)]:
		var stake := driven_stake(at + offset)
		lines.append(Line.to_waist(world, stake.free_tie(at), 2.0))
	var lengths := lines.map(func(line: Line) -> float: return line.rope.length)
	var ends := lines.map(func(line: Line) -> Part: return line.ends[1])
	look(eye(), eye() + Vector3(0, 5, -10))
	await physics_frames(2)
	hands.reel.choose(ends[1])
	use_held(true)
	await simulate(world.tuning.untie_seconds * 0.5)
	check(hands.held == null and player.waist.tied.size() == 3, "first end keeps its full untie delay")
	await simulate(world.tuning.untie_seconds * 0.5 + Hands.ARRIVE + 0.1)
	check(hands.held == ends[1] and player.waist.tied.size() == 2, "the selected original end comes to hand first")
	check(player.waist.gathering() and player.waist._taking == ends[0], "continued Use starts the next end in tie order")
	await simulate(0.25)
	use_held(false)
	await simulate(world.tuning.untie_seconds + 0.1)
	check(player.waist.tied.size() == 2 and hands.held == ends[1] and not player.waist.gathering(), "release cancels the next transfer without dropping the first")

	# A fresh Use keeps its ordinary meaning: return this held end to the waist.
	press(&"interact")
	await physics_frames(2)
	check(hands.held == null and player.waist.holds(ends[1]), "fresh Use still ties the held end to the waist")
	hands.reel.choose(ends[1])
	use_held(true)
	await simulate(world.tuning.untie_seconds * 3.0 + Hands.ARRIVE + 0.3)
	use_held(false)
	check(player.waist.tied.is_empty() and hands.held == ends[1], "continued unties gather every remaining original end")
	if hands.held != ends[1]:
		return
	var members := RopeBundle.members(hands.held)
	check(members == [ends[1], ends[0], ends[2]], "gathered ends retain selected-first and remaining tie order")
	for i in lines.size():
		check(world.ropes.ropes.has(lines[i].rope) and lines[i].ends[1] == ends[i]
			and absf(lines[i].rope.length - lengths[i]) < 0.001, "each original line keeps its end and length")
	check(absf(hands.held.mass - 0.9) < 0.001, "the carried knot includes all three end masses")
	hands.reel.choose(ends[2])
	check(hands.reel.in_hand() == lines[2].rope and hands.reel.waist_lines().size() == 3,
		"the physical picker can select an individual held member")

func use_held(down: bool) -> void:
	if down:
		Input.action_press(&"interact")
	else:
		Input.action_release(&"interact")
	var event := InputEventAction.new()
	event.action = &"interact"
	event.pressed = down
	get_viewport().push_input(event)
