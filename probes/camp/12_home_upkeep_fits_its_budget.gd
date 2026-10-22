extends DeckProbe
## Runs alone
## Home's upkeep at its 272-work-item production cap fits the main thread: a rebuild,
## which waits for a change or the slow sweep, stays inside its budget, and the
## ticks between rebuilds cost next to nothing.
const REBUILD_MS := 1.0
const TICK_MS := 0.05

func run() -> void:
	await load_lines()
	var deck := piece(world.player.global_position + Vector3(0, 0, -3))
	deck.freeze = true
	var beacon := Catalog.device(&"home_beacon") as HomeBeacon
	world.content.add_child(beacon)
	Stick.put(deck, deck, Chassis.TOP, Vector2(0.2, 0), 0.0, beacon)
	var shield := Catalog.device(&"light_shield") as ShieldGenerator
	world.content.add_child(shield)
	Stick.put(deck, deck, Chassis.TOP, Vector2(-0.2, 0.1), 0.0, shield)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var reach := shield.size * 0.8
	check(world.home.mark(beacon) == "", "the camp is admitted")
	while world.home.work_count() < world.tuning.home_max_bodies:
		var supply := Catalog.part(&"coalcane_bundle")
		world.content.add_child(supply)
		supply.freeze = true
		supply.global_position = deck.global_position + Vector3(rng.randf_range(-reach, reach) * 0.7, 0.6,
			rng.randf_range(-reach, reach) * 0.7)
		world.home.refresh()
		if not world.home.contains(supply):
			supply.free()
			break
	var count := world.home.work_count()
	check(count >= world.tuning.home_max_bodies - 1, "the camp fills Home to its body cap (%d)" % count)
	var rebuilds := PackedFloat64Array()
	for k in 60:
		var started := Time.get_ticks_usec()
		world.home.refresh()
		rebuilds.append((Time.get_ticks_usec() - started) / 1000.0)
	var ticks := PackedFloat64Array()
	for k in 240:
		var started := Time.get_ticks_usec()
		world.home.tick(0.0)
		ticks.append((Time.get_ticks_usec() - started) / 1000.0)
	rebuilds.sort()
	ticks.sort()
	# Medians: a shared desktop's scheduler pauses land in any single sample.
	var rebuild := rebuilds[rebuilds.size() / 2]
	var tick := ticks[ticks.size() / 2]
	print("HOME UPKEEP items=%d rebuild p50 %.3f p95 %.3f ms, tick p50 %.4f p95 %.4f ms" % [count,
		rebuild, rebuilds[int(rebuilds.size() * 0.95)], tick, ticks[int(ticks.size() * 0.95)]])
	metric("Home rebuild at its body cap", rebuild, "ms", REBUILD_MS)
	metric("Home tick between rebuilds", tick, "ms", TICK_MS)
	check(rebuild <= REBUILD_MS and tick <= TICK_MS, "Home's upkeep stays inside its main-thread budget")
