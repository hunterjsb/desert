extends ShieldProbe
## Wind & storms probe 23: a Console keeps evidence of each anomaly tell only
## as the sensor that sees it witnesses it. On a deck in a storm, a Console
## reading the wind, a radio on and a shield running beside it: in the
## storm alone it keeps nothing. As an anomaly's heart comes over, its radio
## crackles and it keeps that; the shield's load climbs past a full storm's,
## but with no particle sensor to read the sand by it that isn't evidence,
## nor is the compass's lean with no compass on its deck. A compass stuck on
## the deck, and a particle sensor fitted, and it holds all three. The heart
## is staged, as deep as asked, a kilometre east.

const RIG := [[&"piece", Vector2i(1, 0)],
	[&"stick", Vector2i(0, 0), &"top", Vector2(0.0, -0.18), 180.0, [&"console", [&"screen", &"anemometer"]], &"console"],
	[&"stick", Vector2i(0, 0), &"top", Vector2(-0.3, 0.32), 0.0, &"big_battery"],
	[&"stick", Vector2i(0, 0), &"top", Vector2(0.3, 0.32), 0.0, [&"radio", [&"battery"]], &"radio"],
	[&"stick", Vector2i(1, 0), &"top", Vector2(-0.2, -0.1), 0.0, &"shield", &"shield"],
	[&"stick", Vector2i(1, 0), &"top", Vector2(0.27, 0.25), 0.0, &"big_battery"]]


class Staged extends WeatherField:
	var deep := 0.0

	func anomaly_at(_x: float, _z: float, _t: float) -> float:
		return deep

	func anomalies_near(x: float, z: float, _t: float, reach: float) -> Array[Dictionary]:
		var out: Array[Dictionary] = []
		if deep > 0.0:
			out.append({"x": x + 1000.0, "z": z, "radius": reach, "peak": 0.0, "strength": deep, "share": deep})
		return out


func run() -> void:
	await load_storm(1.0)
	var staged := Staged.new(world.run_seed, Tuning.current())
	world.weather.field = staged
	var rig := Scenarios.rig_at(world, RIG, [0.0, 3.0], false)
	var console: Console = rig.named.console
	(rig.named.radio as Radio).on = true
	(rig.named.shield as ShieldGenerator).stand(true)
	await live(4.0, 1.0)
	check(console.running() and console.evidence.is_empty(), "in a storm alone, no evidence")
	staged.deep = 1.0
	await live(4.0, 1.0)
	print("its heart over: kept %s, the shield bearing %d%%" % [console.evidence.keys(),
		roundi((rig.named.shield as ShieldGenerator).particle_load() * 100.0)])
	check(console.evidence.keys() == [&"crackle"], "its radio's crackle kept; the load and the lean unseen")
	Stick.put(rig.deck, Rig.piece(rig.deck, Vector2i(1, 0)), Chassis.TOP, Vector2(0.25, -0.3), 0.0, Catalog.part(&"compass"))
	await live(2.0, 1.0)
	check(console.evidence.has(&"compass") and not console.evidence.has(&"load"), "a compass on its deck: its lean kept")
	fit_part(console, &"particle_sensor")
	await live(2.0, 1.0)
	check(console.evidence.size() == Deeds.TELLS.size() and "EVIDENCE · 3 OF 3" in console.screen_text(Console.Page.LOG),
		"a particle sensor reading the sand: the shield's load kept, all three")
	print(console.screen_text(Console.Page.LOG))
