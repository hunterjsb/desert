extends ArrivalSaveProbe
## Saved physical panels and nested gear return once, with the same teardown and skins.
func run() -> void:
	await prepare_arrival()
	var at := world.player.global_position + Vector3(0, 0.8, -4)
	var pod := PodShell.build(world.content, Transform3D(Basis.IDENTITY, at))
	pod.deck.freeze = true
	for uid: StringName in pod.named:
		pod.named[uid].set_meta(&"arrival_uid", uid)
	var hatch := pod.deck.detach(pod.named[&"hatch"]) as Chassis
	hatch.global_position += Vector3(0, 0, -2)
	hatch.freeze = true
	var board := device(&"board", at + Vector3(4, 0, 0), 0.5)
	board.freeze = true
	board.set_meta(&"arrival_uid", &"board")
	var cell := fit_part(board, &"battery") as Battery
	cell.set_meta(&"arrival_uid", &"board_cell")
	cell.charge_wh = cell.capacity() * 0.37
	world.arrival_state.merge({"phase": &"recovery", "elapsed": 1.2, "materialized": true}, true)
	for entry: Dictionary in world.arrival_state.structure:
		if entry.uid == &"hatch":
			entry.recovered = true
	var expected := world.arrival_state.duplicate(true)
	var skins := skin_count(world.content)
	var pieces := pod.deck.joined.size()
	var charge := cell.charge_wh
	check(saves.save(world), "partly dismantled pod saved")
	check(await resume_arrival(), "partly dismantled pod resumed")
	var root := world.arrival_nodes.get(&"floor_a") as Chassis
	var loose := world.arrival_nodes.get(&"hatch") as Chassis
	var kept_cell := world.arrival_nodes.get(&"board_cell") as Battery
	check(root != null and loose != null and loose.deck == null and root.joined.size() == pieces,
		"the saved hatch stays detached and no joined panel is replaced")
	check(world.arrival_state == expected and world.arrival_nodes.size() == pod.named.size() + 2,
		"all stable identities and recovered flags reconnect exactly once")
	check(kept_cell != null and kept_cell.socket != null and kept_cell.socket.get_parent() == world.arrival_nodes.get(&"board")
		and absf(kept_cell.charge_wh - charge) < 0.0001, "the board retains its own fitted cell and actual charge")
	for node: Node in world.arrival_nodes.values():
		if node is Chassis:
			PodShell.restore_skin(node)
	check(skin_count(world.content) == skins, "saved role skins return once even after an idempotent second restore")
