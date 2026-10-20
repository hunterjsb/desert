extends HandsProbe
## Out-of-order physical stock claims survive snapshots without cloning loose parts.
## Time limit: 300 s.

func run() -> void:
	await load_hands(1234, true)
	world.time_warp = 0.0
	world.counts_deeds = true
	var hall := world.shape.history.landmark(&"halloran")
	var crossing: Dictionary = hall.parts.filter(func(p: Dictionary) -> bool: return p.id == &"crossing")[0]
	world.travel(rad_to_deg(Sphere.latitude(crossing.p)), rad_to_deg(Sphere.longitude(crossing.p)), 0)
	await settle()
	var stoker := world.stoker
	stoker._process(1)
	var old := hands.stow()
	if is_instance_valid(old):
		old.queue_free()
	await take(stoker._stock[1])
	check(stoker.operate(world.player, &"feed"), "feed the claimed bundle")
	await physics_frames(2)
	check(get_node(^"/root/Profile").did("first_fire"), "the feeding earns First Fire")
	var saved := Snapshot.take(world)
	await restore(saved)
	check(world.stoker_state.get("stock_taken") == [1], "the specific fuel slot stays taken")
	check(Stoker.active(world), "resume retains the unfinished burn")
	world.time += world.tuning.stoker_burn_s + 1
	stoker._process(1)
	await physics_frames(2)
	check(world.stoker_state.get("opened", false), "the maintenance burn releases the bay")
	var reward := stoker._cache[2]
	await take(reward)
	check(hands.held == reward and hands.held.get_meta(&"catalog") == &"sealant", "a reward may be taken out of order")
	saved = Snapshot.take(world)
	await restore(saved)
	check(world.stoker_state.get("cache_taken") == [2], "the claimed reward slot stays taken")
	check(stoker._cache.size() == 2 and stoker._stock.size() == world.tuning.stoker_stock - 1,
		"unclaimed physical stock remains without replacing taken slots")
	check(hands.held != null and hands.held.get_meta(&"catalog") == &"sealant", "the same reward remains in the hand")
	var count := world.content.get_children().filter(func(n: Node) -> bool:
		return n.get_meta(&"catalog", &"") == &"sealant").size()
	check(count == 1, "restoring stock cannot clone the claimed item")
	# Legacy sequential counts must not restore rewards already dispensed.
	world.stoker_state = {"stock": 2, "cache": 1, "opened": true}
	stoker.recall()
	stoker._process(1)
	check(stoker._stock.size() == world.tuning.stoker_stock - 2 and stoker._cache.size() == 2,
		"legacy count saves keep their spent stock")


func take(item: Part) -> void:
	var target := item.global_transform * Finds.bounds(item).get_center()
	var front := world.stoker.global_basis * Vector3(0, 0.25, -1.7)
	look(target + front, target)
	await physics_frames(3)
	check(hands.grab(), "ordinary pickup reaches the physical stock")
	await physics_frames(2)


func restore(data: Dictionary) -> void:
	var snapshot := Snapshot.new(world)
	snapshot.begin(data)
	await settle()
	snapshot.finish(data)
	await physics_frames(3)
	world.stoker._process(1)
