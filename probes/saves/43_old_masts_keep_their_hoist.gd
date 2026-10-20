extends SailProbe
## Existing saves lacking hoist fields retain working controls without new hardware.

func run() -> void:
	await load_sailing()
	rig(open, heading())
	deck.freeze = true
	hoist(45.0)
	await physics_frames(3)
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
	check(mast.legacy_hoist and mast.raise > 0.99 and mast.halyard() == null,
		"the old rig retains its raised cloth without inserted hardware")
	check(mast.interact(world.player), "its old mast control remains available")
	await simulate(1.8)
	check(mast.raise < 0.01, "the restored old mast still furls")


func old_records(value: Variant) -> void:
	if value is Dictionary:
		if value.get("id", &"") == &"mast" and value.has("state"):
			value.state.erase("hoist_enabled")
			value.state.erase("legacy_hoist")
		for child in value.values():
			old_records(child)
	elif value is Array:
		for child in value:
			old_records(child)
