extends HandsProbe
## Profile & saves probe 33: the archaeologist's deeds, through play. A big
## dune's ruin a storm has laid bare: stopped near, it builds, and stepping
## onto it is Dune Reader. A scoop held on its sand digs it; half its sand
## and more off by hand, dug out, is Spadework, and not before. On a deck, a
## Console, a scoop and a sieve are no Field Kit until a ground radar is
## fitted to the Console, and then its map's survey finds the ruin.

## Seconds of digging a stroke stands for, so the probe needn't hold use for minutes.
const STROKE := 1.0


func run() -> void:
	# The weather as it blows, so storms come and go over the dunes.
	await load_world(1234, false, true)
	hands = world.player.hands
	world.player.set_physics_process(false)
	world.player.collision_layer = 0
	world.player.collision_mask = 0
	world.counts_deeds = true
	world.time_warp = 0.0
	var profile := get_node(^"/root/Profile")
	var found := Scenarios.bared_dune_ruin(world, Vector2(world.player_world_x(), world.player_world_z()), 2500.0,
		3.0, 0.2, true)
	check(not found.is_empty(), "a big dune's ruin a storm has laid bare")
	if found.is_empty():
		return
	world.time = found.time
	var site: Structure = found.site
	var down := world.shape.downwind()
	var near := Vector2(site.x, site.z) + down * (site.reach + 10.0)
	teleport(near.x, near.y)
	await settle()
	var seed: DuneRuins.Seed = null
	for i in 600:
		await get_tree().physics_frame
		seed = world.shape.sites.dunes._cells.get(found.key)
		if seed != null and seed.built:
			break
	check(seed != null and seed.built, "stopped near it, it builds")
	if seed == null or not seed.built:
		return
	site = seed.site
	check(not profile.did("dune_reader"), "not found yet")
	teleport(site.x, site.z)
	await physics_frames(3)
	check(profile.did("dune_reader"), "stepped onto: Dune Reader")
	# Off its ground, the storm's sand back over it before the dig.
	teleport(near.x, near.y)
	await physics_frames(3)
	# A calm wake can now outlast half an hour. Dig only once enough sand
	# has returned for the deed to be earned by hand.
	for minute in 3 * 24 * 60:
		world.time += 60.0
		if site.pure_taken(world.time) < site.depth * (1.0 - world.tuning.dig_own_share) * 0.9:
			break
	await physics_frames(3)

	# Your eyes over its apron's sand, looking down on it.
	var scoop := Catalog.part(&"sand_scoop")
	world.content.add_child(scoop)
	hands.hold(scoop)
	await physics_frames(10)
	var sand := site.to_world(Vector2(site.piece.half.x + 2.0, 0.0))
	var ground := Vector3(world.engine_x(sand.x), world.height_at(sand.x, sand.y), world.engine_z(sand.y))
	look(ground + Vector3(0.0, 1.6, 0.6), ground)
	await physics_frames(2)
	hands._look()
	check(hands.look_sand, "looking at its sand")
	var weather := site.pure_taken(world.time)
	var strokes := 0
	while not profile.did("dune_dig") and strokes < 600:
		hands._look()
		if not hands.scrap(STROKE):
			break
		strokes += 1
		if site.dug_m < site.depth * world.tuning.dig_own_share:
			check(not profile.did("dune_dig"), "not before half its sand is off by hand")
		await get_tree().physics_frame
	print("dug %.1f m off a dune's ruin %.1f m deep, the storm's %.1f, in %d s of scooping" % [site.dug_m,
		site.depth, weather, strokes])
	check(profile.did("dune_dig") and site.with_dug(site.pure_taken(world.time)) >= site.depth, "dug out: Spadework")

	var deck := Catalog.device(&"chassis") as Chassis
	world.content.add_child(deck)
	deck.global_position = Vector3(world.engine_x(near.x), world.height_at(near.x, near.y) + 0.3, world.engine_z(near.y))
	await physics_frames(10)
	var console := Catalog.device(&"console") as Console
	Stick.put(deck, deck, Chassis.TOP, Vector2(-0.35, 0.3), 0.0, Rig.make(&"battery"))
	Stick.put(deck, deck, Chassis.TOP, Vector2(0.0, 0.2), 0.0, console)
	Stick.put(deck, deck, Chassis.TOP, Vector2(-0.3, -0.3), 0.0, Catalog.part(&"sand_scoop"))
	Stick.put(deck, deck, Chassis.TOP, Vector2(0.3, -0.3), 0.0, Catalog.part(&"sieve"))
	await physics_frames(5)
	check(not profile.did("dig_setup"), "a Console, a scoop and a sieve: not yet")
	var radar := Catalog.part(&"ground_radar")
	world.content.add_child(radar)
	for socket in console.sockets():
		if socket.kind == &"computer_mod" and socket.is_open():
			console.fit(radar, socket)
			break
	await physics_frames(5)
	check(profile.did("dig_setup"), "its ground radar fitted: Field Kit")
	var lists := false
	for i in 300:
		world.time += 0.5
		await get_tree().physics_frame
		if "DUNE RUIN" in console.screen_text(Console.Page.MAP):
			lists = true
			break
	check(lists, "its map finds the ruin")
