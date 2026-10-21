extends LineProbe
## Laying a new line must show its remaining coil at the active end, not an older waist line.

func run() -> void:
	await load_lines()
	var player := world.player
	var here := player.global_position
	var old_stake := driven_stake(here + Vector3(-2, 0, 0))
	var old := Line.to_waist(world, old_stake.free_tie(here), 1.0)
	old.full = 12.0
	old.rope.full = old.full
	hands.reel.choose(old.ends[1])
	var line := Line.make(world, 12.0)
	line.coil.global_position = here + Vector3(0, 1, -1)
	hands.hold(line.coil)
	await simulate(0.5)
	var stake := driven_stake(here + Vector3(0, 0, -1.5))
	check(await snap_onto(stake.free_tie(here)), "the new line's first end is tied normally")
	await simulate(0.5)
	look(eye(), eye() + Vector3(0, 0.5, 3))
	await simulate(0.5)
	check(line.state == Line.State.PAYING and hands.held == line.ends[1], "the remaining end is in the hand")
	var held_was := hands.held.global_position
	await walk_to(player.global_position + Vector3(0, 0, 2))
	await get_tree().process_frame
	var end := Line._tip(line.ends[1])
	var gap := hands.reel._coil.global_position.distance_to(end.global_position)
	print("paying coil: %.3fm from held end after moving %.3fm; held phase %d, socket %s" % [gap,
		hands.held.global_position.distance_to(held_was), hands.phase, hands.socket != null])
	check(hands.reel._coil.visible and gap < 0.3, "the remaining coil moves with the paying end in your hand")
	check(hands.held.global_position.distance_to(held_was) > 1.5 and hands.socket == null,
		"walking away carries the held end without a stale attachment offer")
