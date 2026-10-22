extends KiteProbe
## Radio probe 55: a kite flies on the wind. Used in too little wind it won't
## go up; in a breeze it pays its line out and flies where the wind puts it,
## as high as its line's angle says; on a cable from the radio's top hook it's
## the set's shortwave aerial, hearing far past a long wire; used again it
## reels in and comes down to its reel.


func run() -> void:
	await load_storm(0.0, 1.5)
	var tuning := Tuning.current()
	var rig := await kite_rig(false)
	var radio: Radio = rig.radio
	var kite: AntennaKite = rig.kite
	check(not kite.use(world.player, kite.global_position) or not kite.flying, "in a 1.5 m/s wind it won't fly")
	weather_everywhere(0.0, 9.0)
	await physics_frames(2)
	check(kite.find_rig().get("radio") == radio, "its lead runs to the radio's top hook")
	radio.on = true
	radio.switch_band()
	check(radio.band == Radio.SW_BAND, "the radio on shortwave")
	var bare := radio.antenna_gain()
	kite.fly()
	await physics_frames(120)
	check(kite.line_out > tuning.kite_payout_ms * 1.5, "used in a breeze, it pays out its line (%.1f m)" % kite.line_out)
	kite.line_out = tuning.kite_line_m
	await physics_frames(240)
	var want := AntennaKite.height_in(9.0, tuning.kite_line_m, tuning)
	var downwind := Vector2(kite.kite_at.x - kite.anchor().x, kite.kite_at.z - kite.anchor().z)
	print("in 9 m/s on %d m of line: %.0f m up (%.0f m by its angle), %.0f m downwind; gain %.2f bare, %.2f flown" % [
		tuning.kite_line_m, kite.height(), want, downwind.length(), bare, radio.antenna_gain()])
	check(absf(kite.height() - want) < want * 0.2, "it flies as high as its line's angle says")
	check(downwind.normalized().dot(world.weather.field.wind_at(0.0, 0.0, world.time).normalized()) > 0.8,
		"downwind of its reel")
	check(radio.antenna_gain() > 1.0 and radio.antenna_gain() > bare * 4.0, "the set hears on it far past a long wire")
	kite.use(world.player, kite.global_position)
	for i in ceili(tuning.kite_line_m / tuning.kite_reel_ms * 60.0) + 60:
		await get_tree().physics_frame
		if kite.line_out <= 0.0:
			break
	check(kite.line_out == 0.0 and not kite.flying and radio.antenna_gain() == bare, "used again, it reels in to its reel")
