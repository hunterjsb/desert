extends DeckProbe
## Power probe 12: everything on a deck is one pool. Two pieces joined, a
## loose battery stuck on one, a shield and a Console on the other, none of
## them with a battery of its own: the shield runs and the Console reads on
## the loose battery, which drains for both, and they share the deck's pool
## with its tray. Taken off the deck, the battery is in no pool, and the
## shield and Console go dark; stuck back on, anywhere on the deck, they run.


func run() -> void:
	await load_lines()
	var deck := piece(spot(0.0, 4.0))
	var other := piece(spot(-3.0, 1.0))
	check(await join_by_hand(deck, other, ring(deck, Vector2i.ZERO, Vector2i(1, 0))), "two pieces join")
	var cell := Rig.make(&"big_battery", 0.5) as Battery
	Stick.put(deck, deck, Chassis.TOP, Vector2(0.2, 0.2), 0.0, cell)
	var shield := Catalog.device(&"shield") as ShieldGenerator
	var console := Rig.make([&"console", [&"screen", &"barometer"]]) as Console
	var piece_b := Rig.piece(deck, Vector2i(1, 0))
	Stick.put(deck, piece_b, Chassis.TOP, Vector2(-0.25, 0.25), 0.0, shield)
	Stick.put(deck, piece_b, Chassis.TOP, Vector2(0.12, -0.15), 0.0, console)
	Stick.put(deck, deck, Chassis.BOTTOM, Vector2.ZERO, 0.0, Catalog.part(&"hover_tray"))
	check(shield.batteries().is_empty() and console.batteries().is_empty(), "neither the shield nor the Console has a battery")
	shield.switch(true)
	await simulate(3.0)
	var pool := world.power.pool_of(deck)
	check(pool.has(shield) and pool.has(console) and deck.batteries() == [cell], "the deck, the shield and the Console are one pool on the loose battery")
	check(shield.running() and console.running() and console.pooled_readings().has("pressure"), "the shield runs and the Console reads")
	var held := cell.charge_wh
	await simulate(5.0)
	check(cell.charge_wh < held, "the loose battery drains for them (%.3f to %.3f Wh)" % [held, cell.charge_wh])

	deck.unstick(cell.socket)
	await simulate(1.0)
	check(world.power.pool_of(deck).all(func(d: Device) -> bool: return d.pooled().is_empty()), "taken off, it's in the deck's pool no more")
	check(not shield.running() and not console.running(), "and the shield and Console go dark")
	Stick.put(deck, piece_b, Chassis.TOP, Vector2(0.3, 0.3), 0.0, cell)
	await simulate(1.0)
	check(shield.running() and console.running(), "stuck back on another piece, they run again")
