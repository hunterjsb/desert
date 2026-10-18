extends FarmProbe
## Farming probe 9: vat fungus fruits in a storm. Inside a test-only bubble
## that keeps out wind, dust and temperature, held at 20 °C, a vat fungus a
## breath from mature grows to it in the clear night and then waits: three
## minutes on it isn't ripe. A storm comes over, whose humid dark no bubble
## keeps out, and it fruits in a burst, ripe in its burst's minute. Picked by
## the harvester, it starts again and waits for the next.

const ALL := {&"wind": 1.0, &"storm": 1.0, &"temperature": 1.0}
const WAIT := 180.0


func run() -> void:
	await load_storm(0.0)
	world.moon.latitude = 0.0
	var planter := planter_at(ahead(3.0), [&"vat_fungus"], true)
	planter.split = 1.0
	var bubble := hold_temperature(planter.global_position, 20.0)
	bubble.blocks = ALL
	var fungus: Plant = planter.plants()[0]
	await clock_at(time_of(0.0))
	fungus.set_growth(0.99)
	await pass_time(WAIT, Callable(), 10.0)
	print("clear night: %.3f grown, %.3f fruited, %s, %d ripened" % [fungus.growth, fungus.fruit, fungus.state,
		planter.ripened.get(&"vat_fungus", 0)])
	check(fungus.growth == 1.0 and not fungus.ripe() and fungus.state == Plant.WAITING
		and planter.ripened.get(&"vat_fungus", 0) == 0, "mature in the clear, it waits for a storm, unripe")

	weather_everywhere(1.0)
	var start := world.time
	var seen := {"ripe_at": INF}
	await pass_time(fungus.burst_seconds * 2.0, func() -> void:
		if seen.ripe_at == INF and planter.ripened.get(&"vat_fungus", 0) > 0:
			seen.ripe_at = world.time - start, 1.0)
	var ripe_at: float = seen.ripe_at
	print("in the storm: ripe after %.2f s (its burst %.0f s), %.3f grown, %s" % [ripe_at, fungus.burst_seconds,
		fungus.growth, fungus.state])
	check(world.weather.felt_storm(planter.global_position) == 0.0 and ripe_at <= fungus.burst_seconds + 1.0
		and ripe_at > fungus.burst_seconds - 1.0, "a storm over the bubble, it fruits in a burst (%.1f s)" % ripe_at)
	check(fungus.socket != null and fungus.growth < 1.0 and fungus.fruit == 0.0, "harvested, it starts again")
