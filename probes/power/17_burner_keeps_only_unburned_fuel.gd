extends HandsProbe
## Saving an active burner must not refill its chamber or duplicate its next bundle.

func run() -> void:
	await load_hands()
	world.time_warp = 0.0
	world.counts_deeds = true
	var burner := spawn_device(&"burner", 3.0, 0.4, false) as Burner
	burner.freeze = true
	var fuel := part(&"coalcane_bundle", Transform3D.IDENTITY.translated(eye()))
	hands.hold(fuel)
	var mouth := seat(burner.hopper()).origin
	look(mouth + Vector3(0, 0.25, 1.5), mouth)
	await physics_frames(12)
	check(hands.grab() and burner.stocked() and hands.held == null, "hands fit the existing bundle into the hopper")
	if not burner.stocked():
		return
	look(burner.global_position + Vector3(0, 0.1, 1.5), burner.global_position + Vector3(0, -0.12, 0.33))
	await physics_frames(3)
	check(hands.interact() and burner.on, "use opens the burner")
	var before := world.power.generated_wh
	world.power.live(137.5, world.time)
	world.time += 137.5
	fit_part(burner, &"coalcane_bundle")
	var left := burner.fuel_seconds
	for i in 20:
		burner.production_w()
	check(burner.fuel_seconds == left, "reading the power output spends no fuel")
	check(get_node(^"/root/Profile").did("coalcane_power"), "real generation records Night Harvest")
	var saved := Snapshot.take(world)
	var snapshot := Snapshot.new(world)
	snapshot.begin(saved)
	await settle()
	snapshot.finish(saved)
	await physics_frames(2)
	var burners := world.devices().filter(func(d: Device) -> bool: return d is Burner)
	check(burners.size() == 1, "one burner restores")
	burner = burners[0]
	check(burner.on and is_equal_approx(burner.fuel_seconds, left) and burner.stocked(), "partial burn and queued physical fuel restore separately")
	burner.interact(world.player)
	var made := world.power.generated_wh
	world.power.live(100.0, world.time)
	check(world.power.generated_wh == made and burner.fuel_seconds == left, "closed burner spends no fuel")
	burner.interact(world.player)
	world.power.live(2000.0, world.time)
	var total := world.power.generated_wh - before
	var expected := 2.0 * world.tuning.coalcane_bundle_stalks * world.tuning.burner_stalk_seconds * world.tuning.burner_w / 3600.0
	check(absf(total - expected) < 0.000001 and not burner.stocked(), "a long lived tick stops exactly at the two bundles' energy")
	check(burner.fuel_seconds == 0.0 and burner.production_w() == 0.0, "nothing resumes after the last stalk")
	print("two bundles: %.3f Wh, including save and a closed interval" % total)
