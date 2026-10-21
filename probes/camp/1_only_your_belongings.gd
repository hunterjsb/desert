extends DeckProbe
## Marking keeps claimed belongings without adopting untouched finds in the same shield.
func run() -> void:
	await load_lines()
	var deck := piece(world.player.global_position + Vector3(0, 0, -2))
	deck.freeze = true
	var beacon := Catalog.device(&"home_beacon") as HomeBeacon
	world.content.add_child(beacon)
	Stick.put(deck, deck, Chassis.TOP, Vector2(0.2, 0), 0.0, beacon)
	var shield := Catalog.device(&"light_shield") as ShieldGenerator
	world.content.add_child(shield)
	Stick.put(deck, deck, Chassis.TOP, Vector2(-0.2, 0.1), 0.0, shield)
	var owned := Catalog.part(&"battery")
	world.content.add_child(owned)
	owned.global_position = deck.global_position + Vector3(1, 0.2, 0)
	owned.freeze = true
	var untouched := Catalog.part(&"lamp")
	world.content.add_child(untouched)
	untouched.global_position = deck.global_position + Vector3(-1, 0.2, 0)
	untouched.freeze = true
	untouched.set_meta(&"find", [Vector2i.ZERO, 0])
	var why := world.home.mark(beacon)
	shield.on = false
	shield.powered = false
	world.home.refresh()
	check(why == "" and world.home.contains(deck) and world.home.contains(owned) \
		and not world.home.contains(untouched) and untouched.has_meta(&"find"),
		"a dark shield keeps only claimed camp belongings")
