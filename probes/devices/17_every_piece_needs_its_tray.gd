extends DeckProbe
## Devices & mods probe 17: every piece needs its tray. A deck of three
## pieces with a charged crate standing on it and trays under two rests on
## the sand, its trays drawing nothing, though two would lift it. The third
## tray in, it floats, drawing for everything it floats; use at the deck sets
## the whole of it resting, and again floating. One tray out, and down it comes.


func run() -> void:
	await load_lines()
	var deck := piece(spot(0.0, 4.0))
	for i in 2:
		deck.join(piece(spot(-3.0, 1.0 + i * 1.5)), ring(deck, Vector2i(i, 0), Vector2i(1, 0)))
	fit_part(deck, &"hover_tray")
	fit_part(deck, &"hover_tray")
	var crate := Catalog.device(&"crate_frame")
	world.content.add_child(crate)
	fit_part(crate, &"battery")
	fit_part(crate, &"battery")
	deck.mount(crate, socket_on(deck, Vector2i(1, 0), &"deck"))
	await simulate(4.0)
	check(deck.stats().lift_kg > deck.mass and not deck.stats().hovering and clearance(deck) < 0.4 and deck.demand_w() == 0.0,
		"trays under two of three pieces: it rests on the sand, drawing nothing, though they'd lift it")

	var third := fit_part(deck, &"hover_tray")
	await simulate(5.0)
	var draw := deck.demand_w()
	check(deck.stats().hovering and absf(clearance(deck) - world.tuning.hover_height) < 0.1
		and absf(draw - deck.mass * world.tuning.hover_watts_per_kg) < 1e-6 and deck.mass > 60.0,
		"the third tray in, it floats, drawing %.0f W for the %.0f kg it floats" % [draw, deck.mass])

	check(await _use(deck), "use at the deck")
	await simulate(5.0)
	check(clearance(deck) < 0.4 and deck.demand_w() == 0.0, "sets the whole of it resting")
	check(await _use(deck), "use again")
	await simulate(5.0)
	check(deck.stats().hovering and absf(clearance(deck) - world.tuning.hover_height) < 0.1, "and it floats")

	deck.take(third.socket).queue_free()
	await simulate(4.0)
	check(not deck.stats().hovering and clearance(deck) < 0.4 and deck.demand_w() == 0.0, "one tray out, and down it comes")


## Looks at the deck's first piece from beside it, and uses it.
func _use(deck: Chassis) -> bool:
	var middle := deck.global_position
	look(middle + deck.global_basis.x * -1.5 + Vector3.UP * 0.1, middle)
	await simulate(0.05)
	check(hands.look_device == deck, "looking at the deck, the look ray meets it")
	return hands.interact()
