extends SavesProbe
## A save during flight or just after impact must keep the same delivery.

func run() -> void:
	saves = get_node("/root/Saves")
	await load_storm(0.0)
	var drop := Airdrop.fire(world, world.player.global_position)
	world.time = drop.fired_at + 3.0
	await get_tree().process_frame
	for landed in [false, true]:
		if landed:
			world.time = drop.lands_at + 0.1
			await get_tree().process_frame
		await get_tree().process_frame
		var fired := drop.fired_at
		var lands := drop.lands_at
		var boom := drop._boomed
		check(saves.save(world), "saved the active delivery")
		check(await resume(), "resumed")
		var active := world.content.get_children().filter(func(node: Node) -> bool: return node is Airdrop)
		check(active.size() == 1, "one delivery survives loading")
		if active.size() != 1:
			return
		drop = active[0] as Airdrop
		check(drop.fired_at == fired and drop.lands_at == lands and drop.landed == landed and drop._boomed == boom
			and is_instance_valid(drop.cargo) and drop.cargo.freeze == not landed,
			"its clock, impact and cargo survive without another cannon shot")
	var held := drop.cargo.frame_sockets().filter(func(s: Socket) -> bool: return s.part != null).size()
	world.time = drop.lands_at + world.tuning.airdrop_settle_seconds + 0.1
	await get_tree().process_frame
	await get_tree().process_frame
	check(saves.save(world) and await resume(), "saved and resumed after release")
	var cargo := world.content.get_children().filter(func(node: Node) -> bool:
		return node is Device and node.get_meta(&"catalog", &"") == &"cargo")
	check(cargo.size() == 1, "released cargo remains a single ordinary saved container")
	if cargo.size() == 1:
		var packed := (cargo[0] as Device).frame_sockets().filter(func(s: Socket) -> bool: return s.part != null)
		check(held >= Airdrop.LEAST and packed.size() == held, "with its loot still in it")
