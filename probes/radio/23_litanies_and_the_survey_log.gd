extends ShieldProbe
## Radio probe 23: litanies and the survey log. Outside its window a god
## recites its litany in order and over again, word for word, opening and
## closing the same way each round. The Walker's survey log, after its
## forecast, is true: how far it has walked, and the steady wind at its feet,
## read from the field; it shows on the line and is never read aloud. Under
## clear skies everywhere, with a steady wind of WIND m/s.

const WIND := 6.0


func run() -> void:
	await load_storm(0.0, WIND)
	var radio := Scenarios.standing(world, &"radio", [&"battery"], [0.0, 2.0]) as Radio
	radio.freeze = true
	await physics_frames(2)
	var gods := Radio.gods_of(world)

	# A litany, in order, round after round.
	var lines: Array = Transmissions.IDLE[&"quartermaster"]
	var every := Transmissions.IDLE_EVERY
	var opens := true
	var challenges := {}
	for round in 6:
		var from := round * lines.size() * every + 0.5 * every
		opens = opens and Transmissions.idle(&"quartermaster", from).begins_with("NET SEVEN") \
			and Transmissions.idle(&"quartermaster", from + (lines.size() - 1) * every).begins_with("NET CONTROL OUT")
		challenges[Transmissions.idle(&"quartermaster", from + 3 * every)] = true
	check(opens, "the Quartermaster's litany opens and closes the same way every round")
	check(challenges.size() > 1, "with a new challenge each round, %d in 6" % challenges.size())
	print(Transmissions.idle(&"quartermaster", 3.5 * every))

	# The Walker's survey log is true, on the line and never spoken.
	var x := world.world_x(radio.global_position.x)
	var z := world.world_z(radio.global_position.z)
	var p := radio.point_at(x, z)
	var t := world.time
	var walker := Transmissions.say(&"walker", radio, gods, p, x, z, t)
	var feet := radio.ground_of(gods.home(&"walker", t))
	var wind := world.weather.field.steady_wind_at(feet.x, feet.y, t)
	var leg := floori(Tuning.current().walker_speed * t / 1000.0)
	print(walker.log)
	check(walker.log.contains("leg %d" % leg), "its log gives the km it has walked, %d" % leg)
	check(absf(wind.length() - WIND) < 0.01 and walker.log.contains("wind %d m/s" % roundi(WIND)),
		"and the wind at its feet, %.1f m/s" % wind.length())
	radio.on = true
	radio.frequency = gods.carrier(&"walker", t)
	world.time = (floori(t / every / 2.0) * 2.0 + 1.5) * every
	await physics_frames(5)
	print("the line: \"%s\"; the words: \"%s\"" % [radio.said, radio.reception.get("report", "")])
	check(radio.reception.clean > 0.999 and radio.said.contains("survey") and radio.said.contains("log"),
		"on the line every other spell")
	check(not String(radio.reception.report).contains("survey log"), "and never in the words read aloud")
