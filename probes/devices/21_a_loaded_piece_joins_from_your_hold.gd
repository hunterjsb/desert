extends DeckProbe
## Devices & mods probe 21: a loaded piece joins from your hold. A piece with
## a condenser stuck on it, too heavy to carry, lies just beyond a two-piece
## deck's far ring. Taken hold of, that ring is offered, the piece itself
## shown where it would join, touching nothing, and take joins it there: the
## condenser is on the deck now, in its pool.


func run() -> void:
	await load_lines()
	var deck := piece(flat_spot(0.0, 4.0, 4.0))
	deck.join(piece(spot(-4.0, 0.0)), ring(deck, Vector2i.ZERO, Vector2i(1, 0)))
	await simulate(0.5)
	var east := ring(deck, Vector2i(1, 0), Vector2i(1, 0))
	var loaded := piece(deck.global_transform * Vector3(2.3, 0.0, 0.0))
	var condenser := Catalog.device(&"condenser")
	Stick.put(loaded, loaded, Chassis.TOP, Vector2.ZERO, 0.0, condenser)
	fit_part(loaded, &"battery")
	await simulate(1.0)
	check(not loaded.carryable, "with a condenser on it, the piece is too heavy to carry")

	# At its far edge, under the condenser's foot.
	var edge := loaded.global_transform * Vector3(0.5, 0.0, 0.0)
	check(await take_at(edge + loaded.global_basis.x * 1.0 + Vector3.UP * 0.3, edge) and hands.grasp.body == loaded,
		"you take hold of it")
	await simulate(0.1)
	await simulate(0.3)
	var there := deck.global_transform * deck._pose_at(east, hands._stand_turns)
	check(hands.stand == east and hands.grasp.showing() and loaded.collision_layer == 0 and not hands._ghost.visible
		and loaded.global_position.distance_to(there.origin) < 0.02,
		"beside the deck's far ring, that ring is offered, the piece itself shown there, touching nothing")
	check(hands.grab() and loaded.deck == deck and deck.pieces().size() == 3 and condenser.host() == deck and condenser.on_deck(),
		"take joins it there, the condenser on the deck")
	check(world.power.pool_wh(deck) > 0.0 and world.power.pool_wh(deck) == world.power.pool_wh(condenser), "in the deck's pool")
