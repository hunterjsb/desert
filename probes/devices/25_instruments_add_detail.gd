extends WeatherProbe
## Devices & mods probe 25: instruments add detail, and taking one off takes
## only its detail. A Console with a battery and a screen reads nothing and
## has no map. Fitted one by one, each instrument puts its own reading on the
## stats page and no other's, a radio seated on its top the forecast, and its
## map comes with the first and grows finer with each: estimated before the
## radar, swept by it after. Taken off in turn, each takes its reading, and
## the map coarsens but stays until the last is gone.

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
	made.freeze = true
	await physics_frames(90)
	check(_labels(made).is_empty() and made.map_cells() == 0 and "NO INSTRUMENTS" in made.screen_text(Console.Page.RADAR),
		"bare, it reads nothing and has no map (%s)" % ", ".join(_labels(made)))
	var seats: Array[Socket] = []
	var tiers: Array[int] = []
	for i in SHOWS.size():
		seats.append(_fit(made, SHOWS[i][0]))
		await physics_frames(120)
		var want := SHOWS.slice(0, i + 1).map(func(e: Array) -> String: return e[1])
		tiers.append(made.map_cells())
		check(_labels(made) == want, "%s fitted: %s (%s)" % [SHOWS[i][0], ", ".join(want), ", ".join(_labels(made))])
	print("the map's cells across, instrument by instrument: ", tiers)
	var finer := range(1, tiers.size()).all(func(k: int) -> bool: return tiers[k] > tiers[k - 1])
	check(tiers[0] > 0 and finer and made._map.size() == tiers[-1] * tiers[-1],
		"its map comes with the first and grows finer with each (%s)" % [tiers])
	for i in range(SHOWS.size() - 1, -1, -1):
		var seat := seats[i]
		(made.dismount(seat) if seat.mounted != null else made.take(seat)).free()
		await physics_frames(120)
		var want := SHOWS.slice(0, i).map(func(e: Array) -> String: return e[1])
		check(_labels(made) == want, "%s out: %s left (%s)" % [SHOWS[i][0], ", ".join(want), ", ".join(_labels(made))])
		check(made.map_cells() == (tiers[i - 1] if i > 0 else 0),
			"%s out: the map back to %d cells (%d)" % [SHOWS[i][0], tiers[i - 1] if i > 0 else 0, made.map_cells()])


## An instrument into its free socket, a radio onto the top: the socket.
func _fit(made: Console, id: StringName) -> Socket:
	if id == &"radio":
		var radio := Catalog.device(&"radio")
		world.content.add_child(radio)
		Scenarios.fill(world, radio, [&"battery"])
		var top := Scenarios._free(made, &"top")
		made.mount(radio, top)
		return top
	var part := Catalog.part(id)
	world.content.add_child(part)
	var socket := Scenarios._free(made, part.kind)
	made.fit(part, socket)
	return socket


## The readings its stats page shows, by their labels.
func _labels(made: Console) -> Array:
	var found := []
	for line in made.screen_text(Console.Page.STATS).split("\n"):
		for each: Array in SHOWS:
			if line.begins_with(each[1] + " "):
				found.append(each[1])
	return found
