extends Probe
## Wind & storms probe 1: the same seed, place and time always give the same
## wind and storm, and a different seed gives different weather.


func run() -> void:
	var tuning := Tuning.current()
	var first := WeatherField.new(7, tuning)
	var again := WeatherField.new(7, tuning)
	var other := WeatherField.new(8, tuning)
	var same := true
	var wind_differs := 0
	var storm_differs := 0
	for i in 10000:
		var x := randf_range(-200000.0, 200000.0)
		var z := randf_range(-200000.0, 200000.0)
		var t := randf_range(0.0, 7.0 * 24.0 * 3600.0)
		if first.storm_at(x, z, t) != again.storm_at(x, z, t) or first.wind_at(x, z, t) != again.wind_at(x, z, t):
			same = false
		if first.wind_at(x, z, t) != other.wind_at(x, z, t):
			wind_differs += 1
		if (first.raw_storm_at(x, z, t) > 0.0) != (other.raw_storm_at(x, z, t) > 0.0):
			storm_differs += 1
	check(same, "the same seed, place and time give the same weather")
	check(wind_differs > 9900, "a different seed gives different wind (%d of 10000)" % wind_differs)
	# Two independent fields at 70% cover disagree about 42% of the time.
	check(storm_differs > 3000, "and different storms (%d of 10000 disagree)" % storm_differs)
