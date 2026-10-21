extends DeckProbe
## A moving unpowered camp does not silently update its last received geographic fix.
func run() -> void:
	await load_lines()
	var deck := piece(world.player.global_position + Vector3(0, 0, -2))
	deck.freeze = true
	var beacon := Catalog.device(&"home_beacon") as HomeBeacon
	world.content.add_child(beacon)
	Stick.put(deck, deck, Chassis.TOP, Vector2.ZERO, 0.0, beacon)
	world.home.mark(beacon)
	beacon.powered = false
	var before := world.home.nav()
	deck.global_position.x += 10
	deck.global_position.y = world.height_under(deck.global_position) + 0.08
	world.home.refresh()
	var silent := world.home.nav()
	beacon.powered = true
	world.home.refresh()
	var heard := world.home.nav()
	check(not silent.live and is_equal_approx(silent.metres, before.metres) \
		and heard.live and heard.metres > silent.metres + 5.0,
		"only a received transmission moves the known home fix")
