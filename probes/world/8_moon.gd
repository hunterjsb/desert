extends Probe
## World & terrain probe 8: dead reckoning behaves like a sphere. A lap of the
## equator comes home, distance is measured round the moon, a lap is shorter at
## 60 degrees, and walking over a pole comes down the other side.

const STEP := 100.0


func run() -> void:
	var tuning := Tuning.current()
	var round := tuning.moon_circumference

	var moon := MoonPosition.new(tuning)
	_walk(moon, round / 4.0, 0.0)
	check(absf(moon.distance_from_spawn() - round / 4.0) < 1.0, "a quarter lap east is a quarter of the way round")
	_walk(moon, round * 3.0 / 4.0, 0.0)
	check(moon.distance_from_spawn() < 1.0, "a full lap of the equator comes home (%.2f m off)" % moon.distance_from_spawn())

	var sixty := MoonPosition.new(tuning)
	_walk(sixty, 0.0, round / 6.0)
	check(absf(rad_to_deg(sixty.latitude) - 60.0) < 0.01, "a sixth of the way north is 60 degrees")
	var start_longitude := sixty.longitude
	_walk(sixty, round / 2.0, 0.0)
	check(absf(angle_difference(sixty.longitude, start_longitude)) < 0.001, "a lap at 60 degrees is half as long")

	var pole := MoonPosition.new(tuning)
	_walk(pole, 0.0, round / 4.0 + 10000.0)
	check(absf(rad_to_deg(pole.latitude) - (90.0 - rad_to_deg(10000.0 / pole.radius))) < 0.01,
		"walking over the pole comes down the other side")
	check(absf(absf(rad_to_deg(pole.longitude)) - 180.0) < 0.01, "on the opposite meridian")
	check(absf(pole.distance_from_spawn() - (round / 4.0 + 10000.0)) < 1.0, "the distance kept growing")
	var before := pole.latitude
	_walk(pole, 0.0, 1000.0)
	check(pole.latitude < before, "and the same way on the ground is now south")


func _walk(moon: MoonPosition, east: float, north: float) -> void:
	var steps := ceili(maxf(absf(east), absf(north)) / STEP)
	for i in steps:
		moon.advance(east / steps, north / steps)
