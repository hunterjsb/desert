extends WeatherProbe
## Devices & mods probe 24: Consoles on one deck are one system. Two stand on
## a deck of two pieces running on its battery, one with an anemometer and one
## with a barometer, and each one's stats show both readings; a third on a
## plate of its own beside them, with a hygrometer, shows only its own and
## lends them nothing. A radar on each of the two, both draw one map, finer
## than either radar alone would. The second lifted off onto a plate of its
## own, each keeps only its own.


func run() -> void:
	await load_weather()
	world.player.set_physics_process(false)
	var rig := Scenarios.rig_at(world, [[&"piece", Vector2i(1, 0)],
		[&"stick", Vector2i.ZERO, &"top", Vector2(0.0, 0.0), 0.0, [&"console", [&"screen", &"anemometer"]], &"first"],
		[&"stick", Vector2i(1, 0), &"top", Vector2(0.0, 0.0), 0.0, [&"console", [&"screen", &"barometer"]], &"second"],
		[&"stick", Vector2i.ZERO, &"top", Vector2(0.3, 0.4), 0.0, &"big_battery"]], [0.0, 2.5], false)
	var first: Console = rig.named.first
	var second: Console = rig.named.second
	var apart := _on_plate(Rig.make([&"console", [&"screen", &"hygrometer"]]) as Console, [-2.5, 2.5])
	await physics_frames(90)
	check(_labels(first) == ["WIND", "PRESS"] and _labels(second) == ["WIND", "PRESS"],
		"on one deck, each shows both (%s; %s)" % [_labels(first), _labels(second)])
	check(_labels(apart) == ["HUMID"] and first.linked().size() == 2 and apart.linked().size() == 1,
		"one off the deck shows only its own (%s)" % [_labels(apart)])
	var tuning := Tuning.current()
	var alone := tuning.storm_map_radar_cells + 2 * tuning.storm_map_cells_per_instrument
	for each in [first, second]:
		Scenarios.fill(world, each, [&"radar"])
	await physics_frames(120)
	var cells := first.map_cells()
	check(cells == roundi(alone * tuning.storm_map_second_radar) and second.map_cells() == cells and cells > alone
		and first._map.size() == cells * cells and second._map.is_empty(),
		"a radar on each, one map, finer than one radar's %d cells (%d)" % [alone, cells])
	rig.deck.dismount(rig.deck.seat_of(second))
	_on_plate(second, [2.5, 2.5])
	await physics_frames(90)
	check(_labels(first) == ["WIND", "FRONT"] and _labels(second) == ["PRESS", "FRONT"],
		"lifted off onto a plate of its own, each keeps only its own (%s; %s)" % [_labels(first), _labels(second)])


## A Console stuck on a plate of its own with a battery, right and ahead of you.
func _on_plate(console: Console, where: Array) -> Console:
	var plate := Scenarios.rig_at(world, [[&"stick", Vector2i.ZERO, &"top", Vector2(0.32, 0.38), 0.0, &"big_battery"]],
		where, false).deck
	Stick.put(plate, plate, Chassis.TOP, Vector2.ZERO, 0.0, console)
	return console


func _labels(made: Console) -> Array:
	var found := []
	for line in made.screen_text(Console.Page.STATS).split("\n"):
		for label in ["WIND", "PRESS", "HUMID", "FRONT", "STORM"]:
			if line.begins_with(label + " "):
				found.append("FRONT" if label == "STORM" else label)
	return found
