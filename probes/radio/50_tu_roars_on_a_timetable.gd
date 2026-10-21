extends ShieldProbe
## Radio probe 50: Tu roars on a timetable. On shortwave, high in the band,
## a radio under Tu hears Tu's roar while Zan is in one of its windows and
## Tu's turn faces its source to Zan, and not outside one; from the far side,
## where Tu never rises, never.

const STEP := 2.0


func run() -> void:
	await load_storm(0.0)
	var radio := Scenarios.standing(world, &"radio", [&"battery", &"sw_converter"], [0.0, 2.0]) as Radio
	radio.freeze = true
	radio.on = true
	radio.switch_band()
	radio.frequency = 22000.0
	var tuning := Tuning.current()
	var day := world.weather.day
	var storming := _first(func(u: float) -> bool: return Shortwave.storm(u, day.tu_turn(u), tuning) > 0.95)
	var quiet := _first(func(u: float) -> bool: return Shortwave.storm(u, day.tu_turn(u), tuning) == 0.0)
	world.time = storming
	await physics_frames(3)
	var loud := radio.roar.volume_db
	world.time = quiet
	await physics_frames(3)
	print("under Tu at 22 MHz: %.1f dB in a storm (%.0f s), %.1f dB out of one (%.0f s)" % [loud, storming,
		radio.roar.volume_db, quiet])
	check(loud > -20.0, "in Tu's storm it roars")
	check(radio.roar.volume_db < -60.0, "out of one it's silent")
	var far := -world.shape.history.sub_tu
	var heard := 0.0
	var t := 0.0
	while t < tuning.day_minutes * 60.0:
		heard = maxf(heard, Shortwave.roar(far, world.shape.history.sub_tu, 22000.0, t, day.tu_turn(t), tuning))
		t += STEP
	check(heard == 0.0, "from the far side, never")


func _first(wanted: Callable) -> float:
	var t := 0.0
	while t < 2.0 * 24.0 * 3600.0:
		if wanted.call(t):
			return t
		t += STEP
	check(false, "found a moment")
	return 0.0
