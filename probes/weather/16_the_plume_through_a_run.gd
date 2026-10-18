extends WeatherProbe
## Wind & storms probe 16: the plume keeps to its vent through everything a
## run does round it, and the world never waits on it. With the clock stopped
## it holds still, and paused nothing moves; across an origin shift it stays
## where it was; walked away from until its mouth's ground is forgotten and
## back, it rises from the same place; a storm over the vent hides it and it
## comes back after; what it shows is the vent's venting at that moment; and
## it costs the main thread little.

## Its mean main-thread cost a frame may be this, ms.
const BUDGET := 0.25


func run() -> void:
	await load_weather(1234, true)
	var vent := await beside_vent(250.0)
	var plume := world.weather.plume
	var geology := world.shape.history.geology
	world.time_warp = 0.0
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
	var drawn: Vector3 = plume.material.get_shader_parameter("root")
	check(plume.root == root and drawn.is_equal_approx(Vector3(world.engine_x(root.x), root.y, world.engine_z(root.z))),
		"across an origin shift it stays where it was")

	var away := Vector2(world.player_world_x(), world.player_world_z())
	var out := (away - Vector2(root.x, root.z)).normalized()
	teleport(away.x + out.x * 3500.0, away.y + out.y * 3500.0)
	await settle()
	var far := plume.root
	check(_mouth() == null and plume.visible, "walked away, its mouth's ground is forgotten and it still shows")
	teleport(away.x, away.y)
	await settle()
	await get_tree().process_frame
	print("its mouth from 3.7 km off %.2f m from where it stood, and %.2f m back beside it"
		% [Vector2(far.x, far.z).distance_to(Vector2(root.x, root.z)), Vector2(plume.root.x, plume.root.z).distance_to(Vector2(root.x, root.z))])
	check(_mouth() != null and Vector2(plume.root.x, plume.root.z).distance_to(Vector2(root.x, root.z)) < 0.5,
		"back beside it, it rises from the same place")

	var at := Vector2(world.player_world_x(), world.player_world_z())
	var over := find_time(func(t: float) -> bool: return field.raw_storm_at(root.x, root.z, t) > 0.08
		and field.raw_storm_at(at.x, at.y, t) > 0.08)
	var after := find_time(func(t: float) -> bool: return field.raw_storm_at(root.x, root.z, t) < -0.06
		and field.raw_storm_at(at.x, at.y, t) < -0.06, over)
	for t: float in [over, after]:
		world.time = t
		world.weather.forecast_now()
		await physics_frames(3)
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
		spent += plume.frame_ms
	print("its main-thread cost: %.3f ms a frame on average, %.3f at most" % [spent / 120.0, plume.slowest_ms])
	check(spent / 120.0 < BUDGET, "it costs the main thread little (%.3f ms a frame)" % (spent / 120.0))


## The live vent's mouth, laid and standing, or null.
func _mouth() -> VentMouth:
	for unit in world.shape.sites.units():
		for site in unit.sites:
			if site is VentMouth and site.stands():
				return site
	return null
