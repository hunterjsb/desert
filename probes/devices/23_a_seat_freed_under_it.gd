extends LineProbe
## Devices probe 23: what's stuck freed under its deck. A shield stuck on a
## floating chassis is freed outright, as a scenario clearing the kit or the
## ground forgetting it would: the chassis runs on without error, nothing
## stuck on it now, and another shield sticks in the same place.


func run() -> void:
	await load_lines()
	var deck := device(&"chassis", spot(0.0, 3.0), 0.2) as Chassis
	fit_part(deck, &"hover_tray")
	fit_part(deck, &"battery")
	var shield := Catalog.device(&"shield")
	Stick.put(deck, deck, Chassis.TOP, Vector2(-0.2, 0.2), 0.0, shield)
	await simulate(0.5)
	shield.free()
	await simulate(0.5)
	check(deck.mounted().is_empty() and deck.stuck().size() == 2, "the chassis runs on, the shield gone from it")
	var another := Catalog.device(&"shield")
	var into := Stick.put(deck, deck, Chassis.TOP, Vector2(-0.2, 0.2), 0.0, another)
	await simulate(0.5)
	check(deck.seat_of(another) == into and another.on_deck(), "and another shield sticks there")
