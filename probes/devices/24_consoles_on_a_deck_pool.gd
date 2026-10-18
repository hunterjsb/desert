extends WeatherProbe
## Devices & mods probe 24: Consoles on one deck are one system. Two stand on
## a deck of two pieces, one with an anemometer and one with a barometer, and
## each screen shows both readings; a third on the sand beside it, with a
## hygrometer, shows only its own and lends them nothing. Lifted off the
## deck, the second keeps only its own.


func run() -> void:
	await load_weather()
	world.player.set_physics_process(false)
	var deck := Scenarios.standing(world, &"chassis", [], [0.0, 2.5]) as Chassis
	deck.join(Catalog.device(&"chassis") as Chassis, Scenarios._on_piece(deck, Vector2i.ZERO, &"ring", Vector2i(1, 0)), 0)
	var first := Scenarios._stand_on(world, deck, &"console", [&"battery", &"screen", &"anemometer"], Vector2i.ZERO) as Console
	var second := Scenarios._stand_on(world, deck, &"console", [&"battery", &"screen", &"barometer"], Vector2i(1, 0)) as Console
	var apart := Scenarios.standing(world, &"console", [&"battery", &"screen", &"hygrometer"], [-2.5, 2.5]) as Console
	await physics_frames(90)
	check(_labels(first) == ["WIND", "PRESS"] and _labels(second) == ["WIND", "PRESS"],
		"on one deck, each shows both (%s; %s)" % [_labels(first), _labels(second)])
	check(_labels(apart) == ["HUMID"] and first.linked().size() == 2 and apart.linked().size() == 1,
		"one off the deck shows only its own (%s)" % [_labels(apart)])
	deck.dismount(deck.seat_of(second))
	await physics_frames(90)
	check(_labels(first) == ["WIND"] and _labels(second) == ["PRESS"],
		"lifted off, each keeps only its own (%s; %s)" % [_labels(first), _labels(second)])


func _labels(made: Console) -> Array:
	var found := []
	for line in made.screen_text(Console.Page.WEATHER).split("\n"):
		for label in ["WIND", "PRESS", "HUMID"]:
			if line.begins_with(label + " "):
				found.append(label)
	return found
