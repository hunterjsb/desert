extends WeatherProbe
## Devices & mods probe 45: the Map's filters follow their gear. A bare
## Console's Map offers none; a ground radar brings the survey, an anemometer
## the weather, a Home beacon marked on its deck navigation, each only once
## its gear is there. Switched off from the screen, a filter leaves the Map
## and its switch stays to turn it back on.
## Time limit: 120 s.

## What each filter lays on the Map's model.
const LAYER := {"weather": "map", "survey": "survey", "nav": "chart"}


func run() -> void:
	await load_weather()
	world.player.set_physics_process(false)
	var plate := Scenarios.rig_at(world, [[&"stick", Vector2i.ZERO, &"top", Vector2(-0.32, 0.38), 0.0, &"big_battery"],
		[&"stick", Vector2i.ZERO, &"top", Vector2.ZERO, 0.0, [&"console", [&"screen"]], &"console"]], [0.0, 2.0], false)
	var made: Console = plate.named.console
	await physics_frames(30)
	check(_shown(made) == [[], []], "bare, its map has no filter (%s)" % [_shown(made)])
	var want := []
	for gear: Array in [["survey", &"ground_radar"], ["weather", &"anemometer"], ["nav", &"home_beacon"]]:
		_give(made, gear[1])
		await physics_frames(60)
		want.append(gear[0])
		var shown := _shown(made)
		check(_same(shown[0], want) and _same(shown[1], want), "%s given: %s offered and laid (%s)" % [gear[1], want, shown])
	var live := Chart.layer(made)
	var beacon := world.home.beacon
	beacon.powered = false
	var saved := world.home.snapshot(func(body: Node) -> int: return body.get_instance_id())
	world.home.prepare_restore(saved)
	var stale := Chart.layer(made)
	check(live.live and not stale.live and live.rows != stale.rows and live.home == stale.home,
		"a saved last-known Home fix has a different label from the same live fix")
	world.home.finish_restore(saved, func(id: int) -> Object: return instance_from_id(id))
	beacon.powered = true
	world.home.refresh()
	for name: String in want:
		_press(made, name)
		var shown := _shown(made)
		check(_same(shown[0], want) and not name in shown[1] and shown[1].size() == want.size() - 1,
			"%s off: gone from the map, its switch kept (%s)" % [name, shown])
		_press(made, name)
		check(name in _shown(made)[1], "%s back on" % name)


## The filters the Map offers, and those laid over it.
func _shown(made: Console) -> Array:
	var model := made._model(Console.Page.MAP, made.pooled_readings())
	var offered: Array = model.get("filters", []).map(func(f: Dictionary) -> String: return f.to)
	return [offered, Console.FILTERS.keys().filter(func(f: String) -> bool: return model.has(LAYER[f]))]


static func _same(a: Array, b: Array) -> bool:
	var x := a.duplicate()
	var y := b.duplicate()
	x.sort()
	y.sort()
	return x == y


## A computer mod into its free port, or a Home beacon stuck on its plate and marked.
func _give(made: Console, id: StringName) -> void:
	if id == &"home_beacon":
		var beacon := Catalog.device(id) as HomeBeacon
		world.content.add_child(beacon)
		var deck := made.host() as Chassis
		Stick.put(deck, deck, Chassis.TOP, Vector2(0.3, -0.38), 0.0, beacon)
		var why := world.home.mark(beacon)
		check(why == "", "Home marked (%s)" % why)
		return
	var part := Catalog.part(id)
	world.content.add_child(part)
	made.fit(part, Scenarios._free(made, part.kind))


## Presses a filter's switch at its middle, where it's drawn.
func _press(made: Console, name: String) -> void:
	for key: Dictionary in made.keys(Console.Page.MAP):
		if key.device == null and key.to is String and key.to == name:
			made.page = Console.Page.MAP
			made.press((key.box as Rect2).get_center() / Vector2(Console.PIXELS))
			return
	check(false, "a switch for %s" % name)
