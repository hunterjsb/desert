extends DeckProbe
## A line end on a deck hook can be picked through the ring's visible hole.

func run() -> void:
	await load_lines()
	var at := world.player.global_position + Vector3(0, 0, -2)
	var deck := piece(at)
	deck.freeze = true
	var hook := Catalog.part(&"hook")
	Stick.put(deck, deck, Chassis.TOP, Vector2(0.2, 0.0), 0.0, hook)
	var stake := driven_stake(at + Vector3(2, 0, 0))
	var tie := deck.free_tie(stake.global_position)
	var line := Line.between(world, tie, stake.free_tie(at), 0.4)
	await physics_frames(3)
	var target := tie.global_position + tie.global_basis.z * 0.03
	look(target + Vector3(0.04, 0.8, 0.8), target)
	await physics_frames(2)
	check(hands.grab(), "take responds at the board's tied hook")
	await simulate(0.5)
	check(hands.held == line.ends[0] and tie.part == null and line.ends[1].socket != null,
		"the board end comes free while its other anchor remains tied")
	hands.drop()
	await simulate(0.7)
	var loose := line.ends[0]
	var point := loose.global_position + Vector3(0.025, 0.0, 0.025)
	look(point + Vector3(0, 0.8, 0.6), point)
	await physics_frames(2)
	hands._look()
	check(hands.grab(), "the remaining loose end is pickable on the floor")
	await simulate(0.5)
	check(hands.held == loose and line.ends[1].socket != null,
		"picking the loose floor end does not detach the other anchor")
