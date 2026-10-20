extends Probe
## A god repeats its complete litany, with a fresh challenge in each round.

func run() -> void:
	var every := Transmissions.IDLE_EVERY
	var length: int = Transmissions.IDLE[&"quartermaster"].size()
	var opening := Transmissions.idle(&"quartermaster", 0.5 * every)
	var closing := Transmissions.idle(&"quartermaster", (length - 0.5) * every)
	var challenges := {}
	for round in 6:
		var from := round * length * every + 0.5 * every
		check(Transmissions.idle(&"quartermaster", from) == opening
			and Transmissions.idle(&"quartermaster", from + (length - 1) * every) == closing,
			"each round opens and closes with the same transmission")
		challenges[Transmissions.idle(&"quartermaster", from + 3 * every)] = true
	check(challenges.size() > 1, "the challenge changes between rounds")
