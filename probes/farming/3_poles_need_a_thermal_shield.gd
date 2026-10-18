extends FarmProbe
## Farming probe 3: the poles need a thermal shield. Far toward a pole, 60°
## out on a clear day, a root-tuber and a vat fungus sown at dawn and left a
## day in the open wilt in the heat and the cold and end it with nothing.
## Inside a test-only thermal shield, a shield generator whose bubble holds
## back temperature, both grow by its 20 °C: the root-tuber in what sun there
## is, the fungus through the night, and neither ever wilts.

const LATITUDE := 60.0
const DAY := 1200.0
## Everything held back: a test-only thermal shield.
const ALL := {&"wind": 1.0, &"storm": 1.0, &"temperature": 1.0}


func run() -> void:
	await load_storm(0.0)
	var planter := planter_at(ahead(3.0), [&"root_tuber", &"vat_fungus"])
	var shield := shield_at(world.player.global_position, false)
	shield.shelter.blocks = ALL
	shield.freeze = true
	var seen := {}
	for inside: bool in [false, true]:
		shield.stand(inside)
		world.moon.latitude = deg_to_rad(LATITUDE)
		await clock_at(time_of(0.25))
		var day := {}
		for plant in planter.plants():
			plant.set_growth(0.0)
			day[plant.label] = {"best": 0.0, "wilted": false}
		await pass_time(DAY, func() -> void:
			planter.tank_l = world.tuning.planter_tank_litres
			for plant in planter.plants():
				day[plant.label].best = maxf(day[plant.label].best, plant.growth)
				day[plant.label].wilted = day[plant.label].wilted or plant.state == Plant.WILTING, 10.0)
		for plant in planter.plants():
			day[plant.label]["end"] = plant.growth
		seen[inside] = day
		print("%s: %s" % ["inside the thermal shield" if inside else "outside", day])
	for plant in planter.plants():
		var out: Dictionary = seen[false][plant.label]
		var held: Dictionary = seen[true][plant.label]
		check(out.wilted and out.end == 0.0 and out.best < 0.75,
			"outside, the %s wilts and ends the day with nothing (best %.2f)" % [plant.label, out.best])
		check(not held.wilted and held.end > 0.5,
			"inside the thermal shield, the %s grows (%.2f) and never wilts" % [plant.label, held.end])
