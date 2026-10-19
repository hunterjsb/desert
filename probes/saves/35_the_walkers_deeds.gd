extends HandsProbe
## Profile & saves probe 35: the Walker's deeds, each where it happens.
## Beside the Walker, a Console holding all three tells, its cable's plug put
## in the Walker's port: Taught. The Console noting the Walker's contacts
## fixes the living city from three crossing bearings: Triangulated. A kilometre
## from the city on a clear night, its lights in view over the dunes: The
## Living City.
## Time limit: 300 s.

## Nights it looks on, and ways round the city each night.
const NIGHTS := 4
const WAYS := 4


func run() -> void:
	# Clear skies: the far side's storms would hide it most nights.
	Tuning.current().storm_threshold = 2.0
	await load_hands()
	world.counts_deeds = true
	var profile := get_node(^"/root/Profile")
	var scenario := Scenarios.by_key("walker")
	var place := Scenarios.find(world, scenario)
	Scenarios.stand(world, scenario, place)
	world.time_warp = 0.0
	await settle(true)
	var dropped := await Scenarios.lay(world, scenario, place)
	var console: Console = dropped.filter(func(n: Node) -> bool: return n is Console)[0]
	var walker: Walker = get_tree().get_nodes_in_group(&"walker")[0]
	world.time_warp = 1.0
	while walker.port.global_position.distance_to(eye()) > 4.0 and world.time < place.time + 300.0:
		await physics_frames(1)
	world.time_warp = 0.0
	look(walker.port.global_position + walker.port.global_basis.z * 1.0, walker.port.global_position)
	await physics_frames(3)
	hands.grab()
	await physics_frames(3)
	check(profile.did("taught"), "the Console plugged into the Walker: Taught")

	var every := world.tuning.walker_log_every
	var slot := ceilf(world.time / every) * every
	for k in world.tuning.walker_contacts_kept + 1:
		world.time = slot + k * every + 1.0
		await physics_frames(3)
	check(profile.did("triangulated"), "three crossing bearings noted: Triangulated")

	# A night, from where its lights show over the dunes.
	var city := Radio.gods_of(world).city
	var day := world.weather.day
	var length := world.tuning.day_minutes * 60.0
	var t := world.time
	for night in NIGHTS:
		while city.moving(t) or day.time_of_day(t, Sphere.longitude(city.at(t))) > 0.02:
			t += 5.0
		for k in WAYS:
			var at := Sphere.toward(city.at(t), TAU * (k + 0.5 * night) / WAYS, 1000.0 / world.shape.history.radius)
			world.travel(rad_to_deg(Sphere.latitude(at)), rad_to_deg(Sphere.longitude(at)), 0.0)
			world.time = t
			world.time_warp = 0.0
			await settle(true)
			var to := Walker.ground(world, city.at(t))
			look(eye(), Vector3(world.engine_x(to.x), eye().y + 5.0, world.engine_z(to.y)))
			world.time_warp = 1.0
			await physics_frames(60)
			if profile.did("living_city"):
				break
		if profile.did("living_city"):
			break
		t += length * 0.5
	check(profile.did("living_city"), "its lights seen at night: The Living City")
