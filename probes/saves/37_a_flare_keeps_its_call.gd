extends SavesProbe
## Loading a burning flare preserves its burn and its one delivery.

func run() -> void:
	saves = get_node("/root/Saves")
	await load_storm(0.0)
	var flare := Catalog.part(&"flare") as Flare
	world.content.add_child(flare)
	flare.global_position = world.player.global_position + Vector3.UP
	flare.burnt = 12.0
	flare.called = true
	flare.light()
	check(saves.save(world), "saved while burning after a delivery")
	check(await resume(), "resumed")
	var found := world.content.get_children().filter(func(node: Node) -> bool: return node is Flare)
	check(found.size() == 1, "the same flare is restored")
	if found.size() != 1:
		return
	var back := found[0] as Flare
	check(back.lit and back.called and back.burnt >= 12.0 and back.burnt < 13.0
		and is_instance_valid(back._light), "it is still burning, with its delivery already called")
	await physics_frames(20)
	check(world.content.get_children().all(func(node: Node) -> bool: return not node is Airdrop),
		"it does not call a second container")
