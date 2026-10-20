extends ShieldProbe
## Radio probe 29: litanies. Outside its window a god
## recites its litany in order and over again, word for word, opening and
## closing the same way each round, with a new challenge. (The Walker's log
## is its own now: Radio probes of the Walker.) Under clear skies everywhere.

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
