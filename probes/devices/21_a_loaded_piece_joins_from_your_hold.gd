extends DeckProbe
## Devices & mods probe 21: a loaded piece joins from your hold. A piece with
## a crate standing on it, too heavy to carry, lies just beyond a two-piece
## deck's far ring. Taken hold of, that ring is offered, a ghost showing
## where it would join, and take joins it there: the crate stands on the
## deck now, in its pool.


func run() -> void:
	await load_lines()
	var deck := piece(flat_spot(0.0, 4.0, 4.0))
	deck.join(piece(spot(-4.0, 0.0)), ring(deck, Vector2i.ZERO, Vector2i(1, 0)))
	await simulate(0.5)
	var east := ring(deck, Vector2i(1, 0), Vector2i(1, 0))
	var loaded := piece(deck.global_transform * Vector3(2.3, 0.0, 0.0))
	var crate := Catalog.device(&"crate_frame")
	world.content.add_child(crate)
	fit_part(crate, &"battery")
	loaded.mount(crate, socket_on(loaded, Vector2i.ZERO, &"deck"))
	await simulate(1.0)
	check(not loaded.carryable, "with a crate on it, the piece is too heavy to carry")

	# At its far edge, under the crate's foot.
	var edge := loaded.global_transform * Vector3(0.5, 0.0, 0.0)
	check(await take_at(edge + loaded.global_basis.x * 1.0 + Vector3.UP * 0.3, edge) and hands.grasp.body == loaded,
		"you take hold of it")
	await simulate(0.1)
	check(hands.stand == east and hands._ghost.visible, "beside the deck's far ring, that ring is offered, its ghost showing")
	check(hands.grab() and loaded.deck == deck and deck.pieces().size() == 3 and crate.host() == deck and crate.on_deck(),
		"take joins it there, the crate standing on the deck")
	check(world.power.pool_wh(deck) > 0.0 and world.power.pool_wh(deck) == world.power.pool_wh(crate), "in the deck's pool")
