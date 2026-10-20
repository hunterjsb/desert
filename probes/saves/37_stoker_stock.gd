extends HandsProbe
## One finite store feeds the furnace; saving during its burn and coming back
## cannot reset consumed fuel, claimed stock or the service cache.
## Time limit: 300 s.

func run() -> void:
	await load_hands()
	world.time_warp = 0.0
	world.counts_deeds = true
	var stoker := world.stoker
	hands.stow()
	check(stoker.operate(world.player, &"stock"), "take physical coalcane")
	check(hands.held != null and hands.held.get_meta(&"catalog") == &"coalcane_bundle", "fuel reaches the hands")
	check(stoker.operate(world.player, &"feed"), "feed the furnace")
	await physics_frames(2)
	check(hands.held == null and Stoker.active(world), "feeding consumes the bundle and starts a burn")
	check(get_node(^"/root/Profile").did("first_fire"), "the feeding earns First Fire")
	var saved := Snapshot.take(world)
	world.stoker_state.clear()
	await _restore(saved)
	check(world.stoker_state.get("stock") == 1 and world.stoker_state.get("fed") == 1, "the save keeps spent stock and fuel")
	check(Stoker.active(world), "resume retains the unfinished burn")
	world.time += world.tuning.stoker_burn_s + 1
	Stoker.advance(world)
	check(world.stoker_state.get("opened", false), "the maintenance burn releases the bay")
	check(stoker.operate(world.player, &"cache"), "take the first service part")
	check(hands.held.get_meta(&"catalog") == &"big_battery", "useful camp equipment is the reward")
	saved = Snapshot.take(world)
	await _restore(saved)
	check(world.stoker_state.get("cache") == 1, "claimed rewards stay claimed on resume")
	for k in world.tuning.stoker_stock - 1:
		var old := hands.stow()
		if is_instance_valid(old):
			old.queue_free()
		stoker.operate(world.player, &"stock")
	var old := hands.stow()
	if is_instance_valid(old):
		old.queue_free()
	stoker.operate(world.player, &"stock")
	check(hands.held == null, "the depleted store cannot dispense again")


func _restore(data: Dictionary) -> void:
	var snapshot := Snapshot.new(world)
	snapshot.begin(data)
	await settle()
	snapshot.finish(data)
	await physics_frames(2)
