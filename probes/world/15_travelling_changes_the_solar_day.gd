extends Probe
## Compressed travel changes local sunlight without changing the global day clock.
func run() -> void:
	var tuning := Tuning.current()
	tuning.spawn_latitude_degrees = 0.0
	tuning.spawn_longitude_degrees = 0.0
	tuning.start_time_of_day = 0.75
	var day := DayCycle.new(tuning)
	var speed := tuning.board_top_speed
	var equator := MoonPosition.new(tuning)
	var east := MoonPosition.new(tuning)
	var arctic := MoonPosition.new(tuning)
	arctic.place(81.0, 0.0)
	var time := 0.0
	while time < 60.0:
		equator.advance(-speed, 0.0)
		east.advance(speed, 0.0)
		arctic.advance(-speed, 0.0)
		time += 1.0
	var fixed := day.sun_direction(time, 0.0, 0.0).y
	var west := day.sun_direction(time, equator.latitude, equator.longitude).y
	var ahead := day.sun_direction(time, east.latitude, east.longitude).y
	check(fixed < 0.0 and west > fixed and west < 0.0 and ahead < fixed,
		"west delays sunset and east advances it, but a normal equatorial board cannot stop it")
	var polar_fixed := day.sun_direction(time, arctic.latitude, 0.0).y
	var polar_west := day.sun_direction(time, arctic.latitude, arctic.longitude).y
	check(polar_fixed < 0.0 and polar_west > 0.0,
		"the same westward board speed can return the sun above the horizon near a pole")
	var noon := day.time_of_day(tuning.day_minutes * 60.0, 0.0)
	check(is_equal_approx(noon, tuning.start_time_of_day), "movement never changes the fixed-longitude day period")
	print("Sunset: equatorial fixed=%.6f west=%.6f east=%.6f; 81deg fixed=%.6f west=%.6f" % [fixed, west, ahead, polar_fixed, polar_west])
