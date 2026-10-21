extends DeckProbe
## Refusing to mark an untouched find must not claim it through generic device use.
func run() -> void:
	await load_lines()
	var deck := piece(world.player.global_position + Vector3(0, 0, -2))
	deck.freeze = true
	var beacon := Catalog.device(&"home_beacon") as HomeBeacon
	world.content.add_child(beacon)
	Stick.put(deck, deck, Chassis.TOP, Vector2.ZERO, 0.0, beacon)
	deck.set_meta(&"find", [Vector2i(999, 999), 0])
	await physics_frames(2)
	var at := beacon.global_position
	look(at + Vector3(0, 0.03, 0.7), at)
	hands._look()
	var aimed := hands.look_device == beacon
	hands.interact()
	check(aimed and not world.home.has_home() and deck.has_meta(&"find"),
		"a refused mark leaves the found chassis unclaimed")
