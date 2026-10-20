extends ShieldProbe
## Bubble shield probe 6: fast boot. Deep in the worst storm, use on a
## shield on its plate blooms its bubble open, and within the boot time,
## shield_bloom_seconds, it protects a chassis 5 m off and its own far edge:
## the chassis stops wearing. It grows there, rather than appearing whole. And
## alone on the sand, with no battery to run on, use won't start one at all.

const WIND := 18.0


func run() -> void:
	await load_storm(1.0, WIND)
	var boot := Tuning.current().shield_bloom_seconds
	var generator := shield_at(ahead(4.0), false)
	var piece := Catalog.device(&"chassis")
	world.content.add_child(piece)
	var spot := generator.global_position + Vector3(0.0, 0.0, 5.0)
	piece.global_position = Vector3(spot.x, world.height_under(spot) + 0.07, spot.z)
	# Staked, so it can't slide in or out on its own.
	piece.freeze = true
	var dud := Catalog.device(&"shield") as ShieldGenerator
	world.content.add_child(dud)
	dud.global_position = ahead(-30.0) + Vector3.UP * 0.22
	await physics_frames(30)
	var centre := generator.shelter.global_position
	var edge := centre + Vector3(0.0, 0.0, -0.97 * generator.size)
	world.time_warp = 1.0
	check(generator.interact(world.player) and generator.on, "use switches it on")
	check(dud.interact(world.player), "use on one with no battery does something: it fizzles")
	var piece_at := INF
	var edge_at := INF
	var first_edge := true
	var worn := 0.0
	for tick in 90:
		await get_tree().physics_frame
		var seconds := (tick + 1) / float(Engine.physics_ticks_per_second)
		if tick == 0:
			first_edge = _protected(edge)
		if piece_at == INF and _protected(piece.global_position):
			piece_at = seconds
			worn = piece.durability
		if edge_at == INF and _protected(edge):
			edge_at = seconds
	world.time_warp = 0.0
	print("boot %.2f s: chassis protected at %.3f s, the far edge at %.3f s" % [boot, piece_at, edge_at])
	check(piece_at <= boot and edge_at <= boot + 0.5 / Engine.physics_ticks_per_second,
		"protecting within the boot time (chassis %.3f s, edge %.3f s)" % [piece_at, edge_at])
	check(not first_edge, "the bubble grows to its edge rather than appearing whole")
	check(piece.durability == worn and piece.durability < 1.0,
		"the chassis wore until the bubble reached it, then never again (%.6f)" % piece.durability)
	check(not dud.on and not dud.running() and dud.shelter.radius == 0.0, "with no battery it never started")


## The game's every reading at p says sheltered.
func _protected(p: Vector3) -> bool:
	var weather := world.weather
	return weather.felt_storm(p) == 0.0 and weather.felt_wind(p) == Vector3.ZERO and world.wear.rate_at(p) == 0.0
