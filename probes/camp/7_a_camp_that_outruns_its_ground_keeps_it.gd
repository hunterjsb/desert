extends DeckProbe
## Runs alone
## A camp carried off faster than its ground can follow (a storm-blown rig, a fast
## tow) gets collision where it now is, rather than staying pinned where it was.
func run() -> void:
	await load_lines()
	var deck := piece(world.player.global_position + Vector3(0, 0, -3))
	await simulate(1.0)
	var beacon := Catalog.device(&"home_beacon") as HomeBeacon
	world.content.add_child(beacon)
	Stick.put(deck, deck, Chassis.TOP, Vector2(0.2, 0), 0.0, beacon)
	check(world.home.mark(beacon) == "", "mark admitted")
	await _supported()
	var at := Vector2(world.world_x(deck.global_position.x), world.world_z(deck.global_position.z))
	# Scouting away: only Home's own support holds the camp's ground now.
	teleport(at.x + 1500.0, at.y)
	await settle()
	check(world.home.supported, "the camp stays supported while you scout")
	# Five chunks diagonally in half a second: further than old and new support
	# can share within the budget, so the old ground cannot be kept as well.
	var side := float(world.tuning.chunk_size)
	var to := at + Vector2.ONE * side * 5.0
	deck.freeze = true
	for k in 30:
		var p := at.lerp(to, (k + 1) / 30.0)
		deck.global_position = Vector3(world.engine_x(p.x), deck.global_position.y, world.engine_z(p.y))
		await physics_frames(1)
	await _supported()
	deck.global_position.y = world.height_at(to.x, to.y) + 1.0
	deck.freeze = false
	var rescued := world.rescued
	await simulate(2.0)
	check(world.home.supported and world.terrain.has_collision_at(to.x, to.y) and world.home.contains(deck),
		"the moved camp has its ground and collision at its new place")
	check(is_instance_valid(deck) and not deck.freeze and world.rescued == rescued,
		"it settles on that collision without falling through")


func _supported() -> void:
	var until := Time.get_ticks_msec() + 60000
	while not world.home.supported and Time.get_ticks_msec() < until:
		await get_tree().process_frame
