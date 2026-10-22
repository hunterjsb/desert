extends SailProbe
## Replacing a kite's bridle line gives the old line back its ordinary reel behavior.


func run() -> void:
	await load_sailing()
	blow(downwind * 9.0)
	var kite := Catalog.device(&"salvage_kite") as SalvageKite
	world.content.add_child(kite)
	kite.global_position = world.player.global_position + Vector3.UP * 1.5
	kite.use(world.player, kite.global_position)
	await physics_frames(2)
	var old := kite.laid()
	check(old.rope.hauls.is_valid(), "the flying kite pays its current line")
	var loose := kite.take(kite.bridle())
	world.content.add_child(loose)
	loose.global_position = kite.global_position
	await physics_frames(2)
	check(not old.rope.hauls.is_valid(), "the disconnected rope loses the kite's reel callback")
	kite.use(world.player, kite.global_position)
	kite.use(world.player, kite.global_position)
	check(not kite.flying, "the missing bridle line is explained instead of duplicated")
	var replacement := Line.to_waist(world, kite.bridle(), 1.0)
	replacement.full = world.tuning.traction_line_m
	replacement.rope.full = replacement.full
	check(kite.use(world.player, kite.global_position), "an ordinary replacement line launches the kite")
	await physics_frames(2)
	check(kite.paying and kite.laid() == replacement, "the replacement line owns its payout")
