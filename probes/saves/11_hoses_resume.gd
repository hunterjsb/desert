extends SavesProbe
## Profile & saves probe 11: hoses resume. A condenser on its plate, on the
## plate's battery, hosed to a planter, a
## canister on the hose's end at the planter and water in its tank, is saved
## mid-flow. Resumed into a fresh world on the same seed, the hose joins the
## same two, a hose still, the canister on its end; the water in the tank and
## the canister is what was saved plus what the condenser made since, and its
## water still goes down the hose.


func run() -> void:
	saves = get_node("/root/Saves")
	await load_storm(0.0)
	var plate := Catalog.device(&"chassis") as Chassis
	world.content.add_child(plate)
	var at := ahead(2.0)
	plate.global_position = Vector3(at.x, world.height_under(at) + Chassis.THICK * 0.5 + 0.01, at.z)
	var condenser := Catalog.device(&"condenser") as Condenser
	Stick.put(plate, plate, Chassis.TOP, Vector2(-0.15, 0.0), 0.0, condenser)
	Stick.put(plate, plate, Chassis.TOP, Vector2(0.35, 0.3), 0.0, Catalog.part(&"battery"))
	var planter := Catalog.device(&"planter") as Planter
	world.content.add_child(planter)
	at = ahead(4.5)
	planter.global_position = Vector3(at.x, world.height_under(at) + 0.18, at.z)
	Scenarios.plumb(world, condenser, planter)
	var can := fit_part(planter, &"canister") as Supply
	can.drain(0.5)
	planter.tank_l = 3.0
	world.time_warp = 10.0
	await physics_frames(120)
	var kept := _water(world)
	print("saved: %s" % kept)
	check(kept.made > 0.0 and kept.can > 0.5, "water flows: the tank full, the condenser fills the canister")
	check(saves.save(world), "saved")

	check(await resume(), "resumed")
	world.time_warp = 10.0
	await physics_frames(2)
	var back := _water(world)
	print("resumed: %s" % back)
	check(back.joins == kept.joins and back.can > 0.0, "the hose joins the condenser and the planter, a canister on its end")
	check(absf(back.tank + back.can - back.made - (kept.tank + kept.can - kept.made)) < 1e-9,
		"the water is all there: what was saved and what was made since")
	await physics_frames(120)
	var later := _water(world)
	check(later.made > back.made and absf(later.tank + later.can - later.made - (kept.tank + kept.can - kept.made)) < 1e-9,
		"its water still goes down the hose")


## The run's water: the condenser's made, the tank's, the canister's on the
## hose's end, and what each hose joins.
func _water(on: World) -> Dictionary:
	var out := {"made": 0.0, "tank": 0.0, "can": 0.0, "joins": []}
	for device in on.devices():
		if device is Condenser:
			out.made = (device as Condenser).made_l
		elif device is Planter:
			out.tank = (device as Planter).tank_l
			for socket in device.sockets():
				if socket.has_meta(&"socket") and socket.part is Supply:
					out.can = (socket.part as Supply).amount
	for node in on.content.get_children():
		if node is Hose:
			out.joins.append((node as Hose).joined().map(func(d: Device) -> String: return d.label))
	return out
