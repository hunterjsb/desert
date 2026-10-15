extends ShieldProbe
## Bubble shield probe 6: fast boot. Deep in the worst storm, F on a shield
## generator blooms its bubble open, and within the boot time,
## shield_bloom_seconds, it protects a crate 5 m off and its own far edge: the
## crate stops wearing. It grows there, rather than appearing whole. And with
## no battery to run on, F won't start it at all.

const WIND := 18.0


func run() -> void:
	await load_storm(1.0, WIND)
	var boot := Tuning.current().shield_bloom_seconds
	var generator := shield_at(ahead(4.0), false)
	var crate := Catalog.device(&"crate_frame")
	world.content.add_child(crate)
	var spot := generator.global_position + Vector3(0.0, 0.0, 5.0)
	crate.global_position = Vector3(spot.x, world.height_under(spot) + 0.26, spot.z)
	# Staked, so it can't slide in or out on its own.
	crate.freeze = true
	var dud := Catalog.device(&"shield") as ShieldGenerator
	world.content.add_child(dud)
	dud.global_position = ahead(-30.0) + Vector3.UP * 0.22
	await physics_frames(30)
	var centre := generator.shelter.global_position
	var edge := centre + Vector3(0.0, 0.0, -0.97 * generator.size)
	world.time_warp = 1.0
	check(generator.interact(world.player) and generator.on, "use switches it on")
	check(dud.interact(world.player), "use on one with no battery does something: it fizzles")
	var crate_at := INF
	var edge_at := INF
	var first_edge := true
	var worn := 0.0
	for tick in 90:
		await get_tree().physics_frame
		var seconds := (tick + 1) / float(Engine.physics_ticks_per_second)
		if tick == 0:
			first_edge = _protected(edge)
		if crate_at == INF and _protected(crate.global_position):
			crate_at = seconds
			worn = crate.durability
		if edge_at == INF and _protected(edge):
			edge_at = seconds
	world.time_warp = 0.0
	print("boot %.2f s: crate protected at %.3f s, the far edge at %.3f s" % [boot, crate_at, edge_at])
	check(crate_at <= boot and edge_at <= boot + 0.5 / Engine.physics_ticks_per_second,
		"protecting within the boot time (crate %.3f s, edge %.3f s)" % [crate_at, edge_at])
	check(not first_edge, "the bubble grows to its edge rather than appearing whole")
	check(crate.durability == worn and crate.durability < 1.0,
		"the crate wore until the bubble reached it, then never again (%.6f)" % crate.durability)
	check(not dud.on and not dud.running() and dud.shelter.radius == 0.0, "with no battery it never started")


## The game's every reading at p says sheltered.
func _protected(p: Vector3) -> bool:
	var weather := world.weather
	return weather.felt_storm(p) == 0.0 and weather.felt_wind(p) == Vector3.ZERO and world.wear.rate_at(p) == 0.0
