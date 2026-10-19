extends WeatherProbe
## Wind & storms probe 21: a run meets no anomaly in its first days. A fresh
## run begins where and when a new one would, days into the weather's clock;
## through its first five days no anomaly's heart comes within 60 km of
## where it began. Lifted, as for a dev run that asks for one, some does.

const REACH := 60000.0


func run() -> void:
	await load_weather()
	var place := Scenarios.find(world, Runs.START)
	if place.is_empty():
		var any := Runs.START.duplicate()
		any.erase("lasts")
		place = Scenarios.find(world, any)
	world.respawn(place.x, place.z, place.yaw, place.time)
	var grace := world.tuning.anomaly_grace_days * world.tuning.day_minutes * 60.0
	var hearts := func() -> int:
		var count := 0
		var t := world.began
		while t < world.began + grace:
			count += field.anomalies_near(place.x, place.z, t, REACH).size()
			t += 120.0
		return count
	var quiet: int = hearts.call()
	world.anomalies_any_time = true
	var lifted: int = hearts.call()
	world.anomalies_any_time = false
	print("the run begins on day %.1f of the clock: %d hearts near in its first days, %d with them lifted" % [
		world.began / (world.tuning.day_minutes * 60.0), quiet, lifted])
	check(world.began > grace, "it begins past the clock's own first days")
	check(quiet == 0 and lifted > 0, "none comes near in its first days, where some would")
