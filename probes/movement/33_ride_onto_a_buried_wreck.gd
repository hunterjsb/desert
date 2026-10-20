extends MovementProbe
## Movement probe 33: a board rides onto a partly buried, leaning wreck roof.
## Sand meets the skimmer's low end; holding forward must climb the exposed
## roof, not keep following sand through it or hit the junk inside its bay.

func run() -> void:
	Tuning.current().storm_threshold = 10.0
	await load_moving(1234, true)
	world.time_warp = 0.0
	blow(Vector2.ZERO)
	player.set_physics_process(false)
	var sites := world.shape.sites
	var site: Structure
	for tries in 100:
		site = sites.by_hand(&"wreck_hull", world.player_world_x() + 40.0 + tries * 8.0,
			world.player_world_z(), 0.4, 3.0, 0.55)
		if site.stands():
			break
	check(site.stands(), "a skimmer stands across the sand")
	if not site.stands():
		return
	# Half exposed, with weather held still throughout the approach.
	site.dug_m = 2.0
	site.depth = 1.5 * (site.pure_taken(world.time) + site.dug_m)
	sites.add(site)
	teleport(site.x, site.z)
	await settle(true)
	await physics_frames(10)
	var pose := site.placed(Vector3(world.engine_x(site.x), site.floor_y, world.engine_z(site.z)))
	var roof := site.piece.boxes[6]
	player.global_position = pose * Vector3(1.0, roof.end.y, -4.0) + Vector3.UP * 0.3
	player.global_position.y = maxf(player.global_position.y, world.height_under(player.global_position) + 0.3)
	player.own = Vector2.ZERO
	player.velocity = Vector3.ZERO
	face(Vector2(pose.basis.z.x, pose.basis.z.z))
	player.set_physics_process(true)
	await simulate(0.8)
	await ride_here()
	var ride := player.ride
	if ride == null:
		return
	var began := where()
	var seen := {"lowest": INF}
	hold(["move_forward"])
	await ride_for(1.5, func() -> void:
		var underside := Vector3(player.global_position.x, ride.y, player.global_position.z)
		seen.lowest = minf(seen.lowest, (pose.affine_inverse() * underside).y))
	hold([])
	var local := pose.affine_inverse() * player.global_position
	print("wreck roof: %.2f m travelled, %.2f m risen, local end %s, lowest underside %.3f, thrown %s" %
		[where().distance_to(began), where().y - began.y, local, seen.lowest, ride.thrown])
	check(player.ride == ride and not ride.caught and local.z > 2.0 and local.z < roof.end.z
		and seen.lowest >= roof.end.y and where().y - began.y > 0.6,
		"forward input carries the board up the exposed roof without clipping or throwing")
	player.step_off()
