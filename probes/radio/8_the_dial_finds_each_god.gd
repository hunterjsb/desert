extends WeatherProbe
## Radio probe 8: the dial finds each far god. Each one's carrier lies inside its
## own band and wanders each day, never more than carrier_drift_khz from the
## day before. Tuned to it, the dial is on
## that god; tuned halfway to the next carrier, it hears only static, and the
## line says nothing but the frequency and static. The sweep goes up through
## every carrier on the dial, the gods, the beacon and any wreck's call, and
## then off: the satellites are on shortwave, above the ceiling, and never on
## this dial. The near gods are on FM.


func run() -> void:
	await load_weather()
	world.player.set_physics_process(false)
	var radio := Scenarios.standing(world, &"radio", [&"battery"], [0.0, 2.0]) as Radio
	radio.freeze = true
	await physics_frames(2)
	var gods := Radio.gods_of(world)
	var t := world.time
	var day := Tuning.current().day_minutes * 60.0
	for id in Gods.ids().filter(func(each: StringName) -> bool: return not Fm.is_god(each)):
		var khz := gods.carrier(id, t)
		var band := Gods.band(id)
		check(khz > band.x and khz < band.y, "%s's carrier, %d kHz, is in its band" % [Gods.title(id), roundi(khz)])
		var moved := false
		for d in range(1, 6):
			moved = moved or gods.carrier(id, t + d * day) != khz
		check(moved, "%s's carrier moves from day to day" % Gods.title(id))
		var most := 0.0
		var inside := true
		var last := gods.carrier(id, t)
		for d in range(1, 61):
			var now := gods.carrier(id, t + d * day)
			most = maxf(most, absf(now - last))
			inside = inside and now > band.x and now < band.y
			last = now
		check(most <= world.tuning.carrier_drift_khz and inside,
			"%s's never more than %d kHz from the day before, over 60 days (%.0f at most)" % [Gods.title(id),
			roundi(world.tuning.carrier_drift_khz), most])
		radio.on = true
		radio.frequency = khz
		check(radio.tuned_to() == id and radio.channel == Radio.GOD,
			"tuned to %d kHz, the dial is on %s" % [roundi(khz), Gods.title(id)])

	var carriers := radio.carriers()
	for i in carriers.size() - 1:
		var between: float = (carriers[i] + carriers[i + 1]) * 0.5
		radio.frequency = between
		check(radio.channel == Radio.STATIC, "between carriers, at %d kHz, only static" % roundi(between))
	radio.frequency = (carriers[2] + carriers[3]) * 0.5
	await physics_frames(2)
	print("between: \"%s\"" % radio.said)
	check(radio.said == "%d kHz · static" % roundi(radio.frequency), "and the line says only that")

	radio.on = false
	var swept: Array[float] = []
	radio.sweep()
	while radio.on and swept.size() <= carriers.size() + Constellation.ROSTER.size():
		swept.append(radio.frequency)
		radio.sweep()
	print("swept %s" % [swept])
	check(swept == carriers and not radio.on, "the sweep finds every carrier, low to high, then off")
