extends HandsProbe
## The seeded route is reachable and its actual fixtures accept hands actions;
## a fuel bundle cannot be fed through a wall or from beyond reach.
## Time limit: 300 s.

func run() -> void:
	await load_hands(1234, true)
	world.time_warp = 0
	var hall := world.shape.history.landmark(&"halloran")
	var crossing: Dictionary = hall.parts.filter(func(p: Dictionary) -> bool: return p.id == &"crossing")[0]
	world.travel(rad_to_deg(Sphere.latitude(crossing.p)), rad_to_deg(Sphere.longitude(crossing.p)), 0)
	await settle()
	world.stoker._process(1.0)
	check(world.stoker.site != null, "Halloran's landmark creates its connected structure")
	if world.stoker.site == null:
		return
	await aim(HalloranKit.STORE + Vector3(0, 1.5, -2.8), HalloranKit.STORE + Vector3(0, 0.7, 0))
	var old := hands.stow()
	if is_instance_valid(old):
		old.queue_free()
	check(hands.interact(), "use on the actual store")
	check(hands.held != null and hands.held.get_meta(&"catalog") == &"coalcane_bundle", "the store gives a real fuel bundle")
	await aim(HalloranKit.FURNACE + Vector3(-12, 1.65, 0), HalloranKit.FURNACE + Vector3(-2.65, 1.1, 0))
	world.stoker.interact(world.player)
	check(not Stoker.active(world), "cannot feed at a distance")
	await aim(HalloranKit.FURNACE + Vector3(-4.3, 1.65, 0), HalloranKit.FURNACE + Vector3(-2.65, 1.1, 0))
	check(hands.interact(), "use at the feed mouth")
	check(Stoker.active(world) and hands.held == null, "the physical mouth consumes the carried bundle")
	world.time += world.tuning.stoker_burn_s + 1
	world.stoker._process(1)
	await aim(HalloranKit.CACHE + Vector3(0, 1.5, -2.5), HalloranKit.CACHE + Vector3(0, 1, 0))
	check(hands.interact(), "use the released service cache")
	check(hands.held != null and hands.held.get_meta(&"catalog") == &"big_battery", "the door clears the actual reward")
	# Streaming out and returning must not respawn claimed stock or rewards.
	world.travel(0, 0, 0)
	await settle()
	world.travel(rad_to_deg(Sphere.latitude(crossing.p)), rad_to_deg(Sphere.longitude(crossing.p)), 0)
	await settle()
	check(world.stoker_state.get("cache", 0) == 1 and world.stoker_state.get("stock", 0) == 1,
		"the encounter survives leaving the landmark's sheet")


func aim(from: Vector3, target: Vector3) -> void:
	var site := world.stoker.site
	var frame := site.frame()
	frame.origin.x = world.engine_x(frame.origin.x)
	frame.origin.z = world.engine_z(frame.origin.z)
	look(frame * from, frame * target)
	await settle()
	world.stoker._process(1)
	frame = world.stoker.global_transform
	look(frame * from, frame * target)
	await physics_frames(3)
