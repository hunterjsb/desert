extends SailProbe
## Saving a flying salvage kite keeps its ordinary line and its single included coil.


func run() -> void:
	await load_sailing()
	blow(downwind * 9.0)
	var kite := Catalog.device(&"salvage_kite") as SalvageKite
	world.content.add_child(kite)
	kite.global_position = world.player.global_position + Vector3.UP * 1.5
	kite.use(world.player, kite.global_position)
	await simulate(4.0)
	var length := kite.laid().rope.length
	var before := kite.load_n
	check(get_node(^"/root/Saves").save(world), "the kite saves in flight")
	var preview := Snapshot.new(null)
	var shown := preview.camp(Snapshot.take(world), 1000.0, 20)
	for pair: Array in shown:
		add_child(pair[0])
	preview.dress()
	for pair: Array in shown:
		if is_instance_valid(pair[0]):
			pair[0].free()
	check(await resume(), "the flying kite resumes")
	var found := world.devices().filter(func(device: Device) -> bool: return device is SalvageKite)
	check(found.size() == 1, "one salvage kite returns")
	if found.is_empty():
		return
	kite = found[0]
	check(kite.flying and kite.line_issued and kite.laid() != null, "the wing and its issued line return")
	check(absf(kite.laid().rope.length - length) < 0.2 and kite.load_n.distance_to(before) < 10.0,
		"payout and settled load resume where they were")
