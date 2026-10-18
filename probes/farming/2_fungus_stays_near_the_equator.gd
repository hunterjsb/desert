extends FarmProbe
## Farming probe 2: fungus stays near the equator. A vat fungus sown at noon
## and left for a day in the moon's own temperature. In a storm at the
## equator, whose dust blankets the day's swing, it ripens in its own time,
## growing and then fruiting in the storm. In the same storm 60° out, where
## the swing is wider, the heat and cold wilt back what it grows and it never
## ripens; nor does it in the clear at the equator, where its best is short
## of the storm's.

const DAY := 1200.0
## How often it's looked at, s.
const EVERY := 10.0
## [what, storm, latitude °].
const PLACES := [["storm at the equator", 1.0, 0.0], ["storm 60° out", 1.0, 60.0], ["clear at the equator", 0.0, 0.0]]


func run() -> void:
	await load_storm(0.0)
	var planter := planter_at(ahead(3.0), [&"vat_fungus"])
	var fungus: Plant = planter.plants()[0]
	var seen := {}
	for place: Array in PLACES:
		weather_everywhere(place[1])
		world.moon.latitude = deg_to_rad(place[2])
		await clock_at(time_of(0.5))
		fungus.set_growth(0.0)
		planter.tank_l = world.tuning.planter_tank_litres
		var day := {"best": 0.0, "ripe_at": INF, "wilted": false}
		var start := world.time
		await pass_time(DAY, func() -> void:
			day.best = maxf(day.best, fungus.growth)
			day.wilted = day.wilted or fungus.state == Plant.WILTING
			if fungus.ripe() and day.ripe_at == INF:
				day.ripe_at = world.time - start
			planter.tank_l = world.tuning.planter_tank_litres, EVERY)
		seen[place[0]] = day
		print("%s: best %.2f, ripe after %s s, wilted %s" % [place[0], day.best, day.ripe_at, day.wilted])
	var storm: Dictionary = seen[PLACES[0][0]]
	var far: Dictionary = seen[PLACES[1][0]]
	var clear: Dictionary = seen[PLACES[2][0]]
	check(storm.ripe_at <= fungus.ripen_seconds + fungus.burst_seconds + EVERY and not storm.wilted,
		"in a storm at the equator it ripens in its own time (%s s), never wilting" % storm.ripe_at)
	check(far.ripe_at == INF and far.wilted, "60° out it wilts and never ripens (best %.2f)" % far.best)
	check(clear.ripe_at == INF and clear.best < storm.best,
		"in the clear it never ripens, its best (%.2f) short of the storm's" % clear.best)
