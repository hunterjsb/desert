extends DeckProbe
## Restore exposes Home's support request before restored bodies have been rebuilt.
func run() -> void:
	await load_lines()
	var deck := piece(world.player.global_position + Vector3(0, 0, -2))
	deck.freeze = true
	var beacon := Catalog.device(&"home_beacon") as HomeBeacon
	world.content.add_child(beacon)
	Stick.put(deck, deck, Chassis.TOP, Vector2.ZERO, 0.0, beacon)
	world.home.mark(beacon)
	var refs := {}
	var objects := {}
	var ref := func(body: Node) -> int:
		if not refs.has(body):
			refs[body] = refs.size()
			objects[refs[body]] = body
		return refs[body]
	var saved := world.home.snapshot(ref)
	world.home.prepare_restore(saved)
	var pending: bool = world.home.has_home() and world.home.restoring and world.home.root == null \
		and world.home.anchor != null and world.home.bounds == saved.bounds
	world.home.finish_restore(saved, func(id: int) -> Node: return objects.get(id))
	check(pending and world.home.root == deck and world.home.beacon == beacon and world.home.contains(beacon),
		"support can load before stable Home references reconnect")
