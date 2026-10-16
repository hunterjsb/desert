extends SavesProbe
## Profile & saves probe 5: discoveries are recorded once, survive a new run,
## and reset empties them. Taking a find reports every kind it held; the
## second of a kind is no discovery. Unlocks go through the one call. A new
## run, and the profile read back from its file as the next session would,
## still have them all, and a reset leaves nothing.


func run() -> void:
	var profile := get_node("/root/Profile")
	await load_world(1234, false, true)
	for i in 600:
		await get_tree().physics_frame
		if world.salvage.is_idle() and world.terrain.is_idle():
			break
	var found := []
	profile.discovered.connect(func(kind: String) -> void: found.append(kind))
	var device: Device = null
	for body in world.salvage.finds():
		if body is Device and not (body as Device).parts().is_empty():
			device = body
			break
	check(device != null, "a found device with parts in it")
	var kinds := [str(device.get_meta(&"catalog"))]
	for part in device.parts():
		if not kinds.has(str(part.get_meta(&"catalog"))):
			kinds.append(str(part.get_meta(&"catalog")))
	world.salvage.claim(device)
	check(found == kinds, "taking it discovers each kind it held (%s)" % [found])
	for body in world.salvage.finds():
		if body.get_meta(&"catalog") == device.get_meta(&"catalog"):
			world.salvage.claim(body)
			break
	var once := {}
	for kind: String in found:
		once[kind] = true
	check(not profile.discover(kinds[0]) and once.size() == found.size(), "a kind found again is no discovery")
	check(profile.unlock("kit_turbine") and not profile.unlock("kit_turbine"), "an unlock is new once")

	await fresh_world()
	profile.dir = user_dir
	for kind: String in found + ["kit_turbine"]:
		check(profile.has(kind), "%s survives a new run, read back from the file" % kind)
	check(profile.discoveries() == found, "in the order found")
	profile.reset()
	profile.dir = user_dir
	check(profile.discoveries().is_empty() and not profile.has("kit_turbine"), "reset empties it")
