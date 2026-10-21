extends DeckProbe
## A refused graph extension preserves existing membership and admits none of the addition.
func run() -> void:
	await load_lines()
	var deck := piece(world.player.global_position + Vector3(0, 0, -2))
	deck.freeze = true
	var beacon := Catalog.device(&"home_beacon") as HomeBeacon
	world.content.add_child(beacon)
	Stick.put(deck, deck, Chassis.TOP, Vector2.ZERO, 0.0, beacon)
	world.home.mark(beacon)
	fit_part(deck, &"hook")
	var stake := driven_stake(deck.global_position + Vector3(world.tuning.home_span_m + 20, 0, 0))
	Line.between(world, deck.free_tie(stake.global_position), stake.free_tie(deck.global_position))
	world.home.refresh()
	check(world.home.contains(deck) and not world.home.contains(stake) and world.home.attention != "",
		"an oversized connected addition is refused without losing home")
