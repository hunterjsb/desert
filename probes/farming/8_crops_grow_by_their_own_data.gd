extends FarmProbe
## Farming probe 8: crops grow by their own data. Three plants in one planter
## at a clear noon held at 20 °C: a root-tuber, a second whose data says it
## takes no more than 10 m/s of wind to grow, and a saltbush. In a 15 m/s
## wind, felt at 10 to 25 m/s in the lee there, the root-tuber grows at its
## full rate and the second holds, too windy, though nothing else differs; the
## saltbush grows at its own, a quarter of the root-tuber's, as its minutes
## say. In a 45 m/s wind, felt at 25 to 40, the root-tuber holds too, and the
## saltbush, built to take it, grows on.

const SPAN := 25.0


func run() -> void:
	await load_storm(0.0)
	world.moon.latitude = 0.0
	var planter := planter_at(ahead(3.0), [&"root_tuber", &"root_tuber", &"saltbush"])
	hold_temperature(planter.global_position, 20.0)
	var plants := planter.plants()
	var tuber := plants[0]
	var tender := plants[1]
	var bush := plants[2]
	tender.data = tender.data.duplicate(true)
	tender.data.wind = Vector2(10.0, 45.0)
	for blowing: float in [15.0, 45.0]:
		weather_everywhere(0.0, blowing)
		await clock_at(time_of(0.5) - SPAN * 0.5)
		var felt := planter.felt(world.time)
		for plant in plants:
			plant.set_growth(0.5)
		await pass_time(SPAN)
		var gained := plants.map(func(p: Plant) -> float: return p.growth - 0.5)
		print("%.1f m/s felt: %s" % [felt.wind, ", ".join(plants.map(func(p: Plant) -> String:
			return "%s %.5f %s" % [p.label, p.growth - 0.5, p.state]))])
		var full: float = SPAN / tuber.ripen_seconds
		var calm: bool = felt.wind > 10.0 and felt.wind < 25.0
		check(calm or (felt.wind > 25.0 and felt.wind < 40.0), "%.0f m/s blowing is felt between the crops' limits (%.1f)"
			% [blowing, felt.wind])
		if calm:
			check(absf(gained[0] - full) < 1e-9 and tuber.state == Plant.GROWING,
				"%.0f m/s: the root-tuber grows at its full rate" % felt.wind)
			check(gained[1] == 0.0 and tender.state == Plant.WINDY,
				"%.0f m/s: the one whose data takes less wind holds, too windy" % felt.wind)
			check(absf(gained[2] - SPAN / bush.ripen_seconds) < 1e-9 and absf(gained[2] * 4.0 - gained[0]) < 1e-9,
				"%.0f m/s: the saltbush grows at its own rate, a quarter of the root-tuber's" % felt.wind)
		else:
			check(gained[0] == 0.0 and tuber.state == Plant.WINDY, "%.0f m/s: the root-tuber holds, too windy" % felt.wind)
			check(absf(gained[2] - SPAN / bush.ripen_seconds) < 1e-9, "%.0f m/s: the saltbush grows on" % felt.wind)
