extends SailProbe
## A save from before the physical hoist holds a raised sail with no halyard
## and the old toggle's fields. It loads whole, its cloth comes down for want
## of a line, and nothing raises it but one over the masthead pulley.

func run() -> void:
	await load_sailing()
	rig(open, heading())
	deck.freeze = true
	await physics_frames(3)
	mast.raise = 1.0
	mast.raised = true
	var data := Snapshot.take(world)
	old_records(data)
	var saves := get_node(^"/root/Saves")
	check(SaveFile.write(saves.path(), saves.KIND, saves.VERSION, data), "wrote the previous mast record shape")
	check(await resume(), "resumed the old rig")
	for child in world.content.get_children():
		if child is Chassis:
			deck = child
	for child in deck.mounted():
		if child is Mast:
			mast = child
	mast.interact(world.player)
	await physics_frames(2)
	check(mast.halyard() == null and mast.raise < 1.0, "the old mast has no toggle to raise it")
	await simulate(2.0)
	check(mast.raise < 0.01, "with no halyard holding it, the old raised cloth comes down")


func old_records(value: Variant) -> void:
	if value is Dictionary:
		if value.get("id", &"") == &"mast" and value.has("state"):
			value.state.erase("head_speed")
			value.state["hoist_enabled"] = false
			value.state["legacy_hoist"] = true
			value.state["trim"] = 1.2
		for child in value.values():
			old_records(child)
	elif value is Array:
		for child in value:
			old_records(child)
