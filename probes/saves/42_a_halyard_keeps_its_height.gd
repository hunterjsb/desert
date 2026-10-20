extends SailProbe
## A partly hoisted sail resumes at the same height with its actual routed line.

func run() -> void:
	await load_lines()
	world.kit = Kit.named(&"varran")
	var made := Runs.kit(world, world.kit)
	for body in made:
		if body is Chassis and body.host() == null:
			deck = body
	var winch: ManualWinch
	for body in deck.mounted():
		if body is Mast:
			mast = body
		if body is ManualWinch:
			winch = body
	deck.freeze = true
	await physics_frames(3)
	check(is_instance_valid(mast) and is_instance_valid(winch), "the starter hardware remains on loaded ground")
	if not is_instance_valid(mast) or not is_instance_valid(winch):
		return
	var halyard := mast.halyard()
	check(halyard != null and halyard == winch.line() and world.player.waist.tied.size() == 3
		and world.kit.gear().get(&"line") == 4, "the starter kit supplies a halyard separately from its waist lines")
	look(winch.global_position + winch.global_basis * Vector3(0, 0.6, 1.2), winch.global_position)
	await physics_frames(2)
	winch.notch(6, world.player)
	await simulate(2.0)
	var before := mast.raise
	var paid := halyard.length
	check(before > 0.3 and before < 0.6, "the real drum holds a partly raised sail")
	check(get_node(^"/root/Saves").save(world), "saved")
	check(await resume(), "resumed")
	for child in world.content.get_children():
		if child is Chassis:
			deck = child
	for child in deck.mounted():
		if child is Mast:
			mast = child
		if child is ManualWinch:
			winch = child
	await physics_frames(3)
	var line := mast.halyard()
	check(line != null and line == winch.line() and line.through == mast.pulley
		and absf(line.length - paid) < 0.001 and absf(mast.raise - before) < 0.001
		and world.player.waist.tied.size() == 3,
		"height, paid length, wheel tie and masthead route survive together")
	look(winch.global_position + winch.global_basis * Vector3(0, 0.6, 1.2), winch.global_position)
	await physics_frames(2)
	winch.notch(-3, world.player)
	await simulate(1.2)
	check(mast.raise < before - 0.15, "the restored drum can lower the same sail")
