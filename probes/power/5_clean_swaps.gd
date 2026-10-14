extends DeviceProbe
## Power probe 5: swap a floating crate's battery by hand and the new one takes
## over on the next tick; the old one keeps exactly what it had, and no charge
## is counted twice.


func run() -> void:
	await load_world()
	var power := world.power
	var crate := spawn_device(&"crate_frame", 4.0, 1.5)
	await physics_frames(120)
	var first := crate.battery()
	var second: Battery = Catalog.part(&"battery")
	world.content.add_child(second)
	second.global_position = crate.global_position + Vector3(0, 3, 2)
	var tick := Tuning.current().power_tick
	var draw := crate.demand_w() - crate.production_w()
	await physics_frames(60)
	var slot: Socket = crate.sockets().filter(func(s: Socket) -> bool: return s.kind == &"battery")[0]
	var before := power.stored_wh()
	var used := power.used_wh
	var made := power.generated_wh
	var taken := crate.take(slot) as Battery
	var kept := taken.charge_wh
	crate.fit(second, slot)
	var fresh := second.charge_wh
	# Wait out one whole power tick.
	var until := world.time + tick * 2.0
	while world.time < until:
		await get_tree().physics_frame
	check(taken == first, "the battery taken out is the one that was in")
	check(taken.charge_wh == kept, "the old battery keeps exactly what it had (%.6f vs %.6f)" % [taken.charge_wh, kept])
	check(second.charge_wh < fresh, "the new battery is drawn on at once")
	check(crate.powered, "the crate never lost power for a swap within a tick")
	var change := (power.stored_wh() - before) + (power.used_wh - used) - (power.generated_wh - made)
	check(absf(change) < 1e-9, "no charge counted twice (off by %.9f Wh)" % change)
	check(draw > 0.0, "the crate was drawing (%.1f W)" % draw)
