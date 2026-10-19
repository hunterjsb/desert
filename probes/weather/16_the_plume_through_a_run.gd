extends WeatherProbe
## Wind & storms probe 16: the plume keeps to its vent through everything a
## run does round it, and the world never waits on it. With the clock stopped
## it holds still, and paused nothing moves; across an origin shift it stays
## where it was; walked away from until its mouth's ground is forgotten and
## back, it rises from the same place; stood in its dust the air closes in
## round you; a storm over the vent hides it and it comes back after; what it
## shows is the vent's venting at that moment; and it costs the main thread
## little.

## Its mean main-thread cost a frame may be this, ms.
const BUDGET := 0.25


func run() -> void:
	await load_weather(1234, true)
	var vent := await beside_vent(250.0)
	var plume := world.weather.plume_for(&"live_vent")
	var geology := world.shape.history.geology
	world.time_warp = 0.0
	# Everything laid that will be, its mouth among it.
	for i in 600:
		await get_tree().process_frame
		if world.shape.sites.is_idle() and _mouth() != null:
			break
	# A few points a frame are worked out again: all of them, at the stopped clock.
	for i in 3 * Plume.OLD_EVERY * (Plume.POINTS - Plume.YOUNG):
		await get_tree().process_frame
	var root := plume.root
	var line := plume.line.duplicate()
	check(plume.visible and _mouth() != null, "beside the vent its mouth stands and its plume is drawn")
	for i in 20:
		await get_tree().process_frame
	check(plume.line == line, "with the clock stopped it holds still")
	get_tree().paused = true
	for i in 10:
		await get_tree().process_frame
	get_tree().paused = false
	check(plume.line == line and plume.root == root, "paused, nothing moves")

	world.shift_origin(Vector2i(3, -2))
	await get_tree().process_frame
	var drawn := plume.drawn()
	check(plume.root == root and drawn.is_equal_approx(Vector3(world.engine_x(root.x), root.y, world.engine_z(root.z))),
		"across an origin shift it stays where it was")

	# Straight east or west and back, which dead reckoning comes home from exactly.
	var away := Vector2(world.player_world_x(), world.player_world_z())
	var out := Vector2(signf(away.x - root.x), 0.0)
	teleport(away.x + out.x * 3500.0, away.y)
	await settle()
	var far := plume.root
	check(_mouth() == null and plume.visible, "walked away, its mouth's ground is forgotten and it still shows")
	teleport(away.x, away.y)
	await settle()
	for i in 600:
		await get_tree().process_frame
		if world.shape.sites.is_idle() and _mouth() != null:
			break
	await get_tree().process_frame
	print("its mouth from 3.5 km off %.2f m from where it stood, and %.2f m back beside it"
		% [Vector2(far.x, far.z).distance_to(Vector2(root.x, root.z)), Vector2(plume.root.x, plume.root.z).distance_to(Vector2(root.x, root.z))])
	check(_mouth() != null and Vector2(plume.root.x, plume.root.z).distance_to(Vector2(root.x, root.z)) < 0.5,
		"back beside it, it rises from the same place")

	# Stood in its dust at the mouth in clear weather, and well upwind of it.
	world.time = find_time(func(t: float) -> bool: return field.raw_storm_at(root.x, root.z, t) < -0.08)
	world.weather.forecast_now()
	var upwind := Vector2(root.x, root.z) - field.steady_wind_at(root.x, root.z, world.time).normalized() * 800.0
	var fog := (world.get_node("WorldEnvironment") as WorldEnvironment).environment
	var seen := []
	for spot: Vector2 in [Vector2(root.x + 40.0, root.z), upwind]:
		teleport(spot.x, spot.y)
		await settle()
		for i in 12:
			await get_tree().process_frame
		await physics_frames(3)
		seen.append([plume.air, fog.fog_depth_end])
	print("stood in its dust, its air %.2f and the haze %.0f m off; upwind of it %.2f and %.0f m"
		% [seen[0][0], seen[0][1], seen[1][0], seen[1][1]])
	check(seen[0][0] > 0.5 and seen[1][0] == 0.0 and seen[0][1] < seen[1][1] * 0.5,
		"stood in its dust the air closes in round you, and opens out again upwind of it")

	var at := Vector2(world.player_world_x(), world.player_world_z())
	var over := find_time(func(t: float) -> bool: return field.raw_storm_at(root.x, root.z, t) > 0.08 \
		and field.raw_storm_at(at.x, at.y, t) > 0.08)
	var after := find_time(func(t: float) -> bool: return field.raw_storm_at(root.x, root.z, t) < -0.06 \
		and field.raw_storm_at(at.x, at.y, t) < -0.06, over)
	for t: float in [over, after]:
		world.time = t
		world.weather.forecast_now()
		await physics_frames(3)
		for i in Plume.READS.size() * 4:
			await get_tree().process_frame
		if t == over:
			check(plume.seen[0].x < 0.05, "a storm over the vent hides it (%.2f)" % plume.seen[0].x)
		else:
			check(plume.seen[0].x > 0.9, "and it comes back after (%.2f)" % plume.seen[0].x)
		check(plume.venting == geology.venting(vent, world.time), "it shows the vent's venting at that moment")

	world.time_warp = 1.0
	var spent := 0.0
	for i in 120:
		await get_tree().process_frame
		spent += plume.frame_ms + world.weather.plumes_hand_ms
	print("its main-thread cost: %.3f ms a frame on average, %.3f at most" % [spent / 120.0, plume.slowest_ms])
	check(spent / 120.0 < BUDGET, "it costs the main thread little (%.3f ms a frame)" % (spent / 120.0))


## The live vent's mouth, laid and standing, or null.
func _mouth() -> VentMouth:
	for unit in world.shape.sites.units():
		for site in unit.sites:
			if site is VentMouth and site.stands():
				return site
	return null
