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
	var fuel := world.stoker._stock[0]
	var fuel_at := fuel.transform * Finds.bounds(fuel).get_center()
	await aim(fuel_at + Vector3(0, 0.3, -1.8), fuel_at)
	var old := hands.stow()
	if is_instance_valid(old):
		old.queue_free()
	check(not hands.interact(), "stock does not dispense through use")
	check(hands.grab(), "take the real coalcane with ordinary pickup")
	check(hands.held != null and hands.held.get_meta(&"catalog") == &"coalcane_bundle", "the store gives a real fuel bundle")
	await aim(HalloranKit.FURNACE + Vector3(-12, 1.65, 0), HalloranKit.FURNACE + Vector3(-2.65, 1.1, 0))
	world.stoker.interact(world.player)
	check(not Stoker.active(world), "cannot feed at a distance")
	await aim(HalloranKit.FURNACE + Vector3(-4.3, 1.65, 0), HalloranKit.FURNACE + Vector3(-2.65, 1.1, 0))
	check(hands.interact(), "use at the feed mouth")
	check(Stoker.active(world) and hands.held == null, "the physical mouth consumes the carried bundle")
	await aim(HalloranKit.CACHE + Vector3(0, 1.5, -2.5), HalloranKit.CACHE + Vector3(0.15, 1.3, -0.5))
	hands.grab()
	check(hands.held == null, "the locked hatch prevents taking preplaced stock")
	var reward := world.stoker._cache[1]
	world.time += world.tuning.stoker_burn_s + 1
	world.stoker._process(1)
	var reward_at := reward.transform * Finds.bounds(reward).get_center()
	await aim(reward_at + Vector3(0, 0.3, -1.8), reward_at)
	check(not hands.interact(), "the cache does not dispense through use")
	check(hands.grab(), "take a released part with ordinary pickup")
	check(hands.held == reward, "pickup takes the part already inside the hatch")
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
