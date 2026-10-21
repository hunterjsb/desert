extends DeckProbe
## Runs alone
## Saving an already overstretched Home must neither expand support nor hang restore.
func run() -> void:
	await load_lines()
	var deck := piece(world.player.global_position + Vector3(0, 0, -3))
	deck.freeze = true
	var beacon := Catalog.device(&"home_beacon") as HomeBeacon
	world.content.add_child(beacon)
	Stick.put(deck, deck, Chassis.TOP, Vector2.ZERO, 0.0, beacon)
	fit_part(deck, &"hook")
	var stake := driven_stake(deck.global_position + Vector3(5, 0, 0))
	var line := Line.between(world, deck.free_tie(stake.global_position), stake.free_tie(deck.global_position))
	line.full = 1000.0
	line.rope.length = 1000.0
	check(world.home.mark(beacon) == "" and world.home.contains(stake), "connected stake admitted before stretching")
	var until := Time.get_ticks_msec() + 60000
	while not world.home.supported and Time.get_ticks_msec() < until:
		await get_tree().process_frame
	check(world.home.supported, "original camp supported")
	var root_at := Vector2(world.world_x(deck.global_position.x), world.world_z(deck.global_position.z))
	stake.global_position.x += 500.0
	var stake_at := Vector2(world.world_x(stake.global_position.x), world.world_z(stake.global_position.z))
	world.home.refresh()
	teleport(root_at.x + 2100.0, root_at.y)
	await settle()
	check(not world.home.supported and world.home.contains(stake), "overstretch keeps admitted identity and reports unsupported ground")
	var saves := get_node(^"/root/Saves")
	check(saves.save(world), "attention state still saves")
	check(await resume(), "attention state resumes")
	var stakes := world.home.members.filter(func(body: RigidBody3D) -> bool: return body is Stake)
	check(stakes.size() == 1 and not world.home.supported, "outlying member survives without claiming support")
	if stakes.size() == 1:
		var kept := stakes[0] as Stake
		check(kept.freeze and Vector2(world.world_x(kept.global_position.x), world.world_z(kept.global_position.z)).distance_to(stake_at) < 0.1,
			"outlying stake resumes at its actual pose with ordinary ground safety")
	check(world.terrain.home_support().get_area() <= world.tuning.home_support_chunks,
		"restored support remains within the same budget")
