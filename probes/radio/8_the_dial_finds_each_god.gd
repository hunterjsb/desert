extends WeatherProbe
## Radio probe 8: the dial finds each god. Each god's carrier lies inside its
## own band and moves to a fresh place each day. Tuned to it, the dial is on
## that god; tuned halfway to the next carrier, it hears only static, and the
## line says nothing but the frequency and static. Use sweeps up through every
## carrier on the dial, the gods, the music and the beacon, and then off.


func run() -> void:
	await load_weather()
	world.player.set_physics_process(false)
	var radio := Scenarios.standing(world, &"radio", [&"battery"], [0.0, 2.0]) as Radio
	radio.freeze = true
	await physics_frames(2)
	var gods := Radio.gods_of(world)
	var t := world.time
	var day := Tuning.current().day_minutes * 60.0
	for id in Gods.ids():
		var khz := gods.carrier(id, t)
		var band := Gods.band(id)
		check(khz > band.x and khz < band.y, "%s's carrier, %d kHz, is in its band" % [Gods.title(id), roundi(khz)])
		var moved := false
		for d in range(1, 6):
			moved = moved or gods.carrier(id, t + d * day) != khz
		check(moved, "%s's carrier moves from day to day" % Gods.title(id))
		radio.on = true
		radio.frequency = khz
		check(radio.tuned_to() == id and radio.channel == (Radio.WEATHER if id == &"walker" else Radio.GOD),
			"tuned to %d kHz, the dial is on %s" % [roundi(khz), Gods.title(id)])

	var carriers := Dial.carriers(gods, t)
	for i in carriers.size() - 1:
		var between: float = (carriers[i][0] + carriers[i + 1][0]) * 0.5
		radio.frequency = between
		check(radio.channel == Radio.STATIC, "between carriers, at %d kHz, only static" % roundi(between))
	radio.frequency = (carriers[2][0] + carriers[3][0]) * 0.5
	await physics_frames(2)
	print("between: \"%s\"" % radio.said)
	check(radio.said == "%d kHz · static" % roundi(radio.frequency), "and the line says only that")

	radio.on = false
	var swept: Array[float] = []
	radio.interact(world.player)
	while radio.on and swept.size() <= carriers.size():
		swept.append(radio.frequency)
		radio.interact(world.player)
	var all: Array[float] = []
	for each in carriers:
		all.append(each[0])
	print("use swept %s" % [swept])
	check(swept == all and not radio.on, "use sweeps every carrier, low to high, then off")
