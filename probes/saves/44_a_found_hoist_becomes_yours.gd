extends NomadHoistProbe
## Claiming a kept rig promotes its internal halyard into the persistent camp.

func run() -> void:
	await load_nomads()
	var deck := lay_nomad(&"runner")
	await physics_frames(3)
	var mast := mast_on(deck)
	var winch := winch_on(deck)
	look(winch.global_position + winch.global_basis * Vector3(0, 0.6, 1.2), winch.global_position)
	await physics_frames(2)
	winch.notch(5, world.player)
	await simulate(0.8)
	deck.freeze = true
	var line: Line = mast.halyard_socket().part.get_meta(&"line")
	check(line.get_parent() == world.content and not line.rope.strand.has_meta(&"unclaimed_rig"),
		"the claimed rig's halyard is ordinary owned rope")
	var height := mast.raise
	var paid := line.rope.length
	check(get_node(^"/root/Saves").save(world), "saved the claimed rig")
	check(await resume(), "resumed")
	var decks := world.content.get_children().filter(func(n: Node) -> bool: return n is Chassis)
	check(decks.size() == 1, "the same claimed deck returns")
	if decks.size() != 1:
		return
	deck = decks[0]
	mast = mast_on(deck)
	winch = winch_on(deck)
	await physics_frames(3)
	check(mast != null and winch != null and mast.halyard() == winch.line()
		and mast.halyard().through == mast.pulley and absf(mast.halyard().length - paid) < 0.001
		and absf(mast.raise - height) < 0.001,
		"the claimed wheel, route, paid length and cloth height survive together")
