extends WeatherProbe
## Devices & mods probe 23: an instrument shows only when it's fitted. A
## Console with a battery and a screen reads nothing. Each instrument fitted
## alone, its reading and only its reading is on the screen, a radio seated on
## its top the forecast; taken out, its reading goes.

## Each instrument, and the label of the reading it gives.
const SHOWS := [[&"anemometer", "WIND"], [&"barometer", "PRESS"], [&"hygrometer", "HUMID"],
	[&"particle_sensor", "SAND"], [&"radar", "FRONT"], [&"radio", "FCST"]]


func run() -> void:
	await load_weather()
	world.player.set_physics_process(false)
	var x := world.player_world_x()
	var z := world.player_world_z()
	world.time = find_time(func(t: float) -> bool: return field.raw_storm_at(x, z, t) < -0.05)
	var made := Scenarios.standing(world, &"console", [&"battery", &"screen"], [0.0, 2.0]) as Console
	await physics_frames(90)
	check(_labels(made).is_empty() and "NO INSTRUMENTS" in made.screen_text(Console.Page.WEATHER),
		"bare, it reads nothing (%s)" % ", ".join(_labels(made)))
	for each: Array in SHOWS:
		var radio: Radio = null
		var socket: Socket = null
		if each[0] == &"radio":
			radio = Catalog.device(&"radio") as Radio
			world.content.add_child(radio)
			Scenarios.fill(world, radio, [&"battery"])
			socket = Scenarios._free(made, &"top")
			made.mount(radio, socket)
		else:
			var part := Catalog.part(each[0])
			world.content.add_child(part)
			socket = Scenarios._free(made, part.kind)
			made.fit(part, socket)
		await physics_frames(90)
		check(_labels(made) == [each[1]], "%s fitted: %s alone (%s)" % [each[0], each[1], ", ".join(_labels(made))])
		if radio != null:
			made.dismount(socket).free()
		else:
			made.take(socket).free()
		await physics_frames(90)
		check(_labels(made).is_empty(), "%s out: its reading goes (%s)" % [each[0], ", ".join(_labels(made))])


## The readings its weather page shows, by their labels.
func _labels(made: Console) -> Array:
	var found := []
	for line in made.screen_text(Console.Page.WEATHER).split("\n"):
		for each: Array in SHOWS:
			if line.begins_with(each[1] + " "):
				found.append(each[1])
	return found
