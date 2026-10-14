extends DeviceProbe
## Power probe 1: over two hours of days, nights and storms, with a charger in
## the sun cabled to a floating crate, a turbine on the sand and batteries
## swapped by hand, everything generated was stored, used or spilled. No energy
## appears from nowhere, and no battery goes past empty or full.


func run() -> void:
	await load_world(1234, false)
	var power := world.power
	var charger := spawn_device(&"charger", 4.0, 0.2, false)
	fit_part(charger, &"solar_panel")
	var spare: Battery = fit_part(charger, &"battery")
	spare.charge_wh = spare.capacity() * 0.3
	var crate := spawn_device(&"crate_frame", 4.0, 1.5)
	crate.global_position.z += 3.0
	var turbine := spawn_device(&"turbine", -4.0, 0.2, false)
	fit_part(turbine, &"battery")
	var cable := Catalog.cable(world, charger.global_position)
	charger.fit(cable.plugs[0], charger.sockets().filter(func(s: Socket) -> bool: return s.kind == &"port")[0])
	crate.take(crate.sockets().filter(func(s: Socket) -> bool: return s.kind == &"port")[0]).queue_free()
	crate.fit(cable.plugs[1], crate.sockets().filter(func(s: Socket) -> bool: return s.kind == &"port")[0])
	await physics_frames(5)
	check(cable.joined().size() == 2, "the cable joins the charger and the crate")
	var start := power.stored_wh()
	var made := power.generated_wh
	var used := power.used_wh
	var spilled := power.spilled_wh
	world.time_warp = 30.0
	var out_of_range := 0
	for hour_part in 8:
		await fast_forward(30.0)
		# Swap the crate's and the charger's batteries by hand, as you would.
		var crate_slot: Socket = crate.sockets().filter(func(s: Socket) -> bool: return s.kind == &"battery")[0]
		var charger_slot: Socket = charger.sockets().filter(func(s: Socket) -> bool: return s.kind == &"battery")[0]
		var a := crate.take(crate_slot)
		var b := charger.take(charger_slot)
		crate.fit(b, crate_slot)
		charger.fit(a, charger_slot)
		for cell: Battery in [a, b, turbine.battery()]:
			if cell.charge_wh < -1e-9 or cell.charge_wh > cell.capacity() + 1e-9:
				out_of_range += 1
	world.time_warp = 1.0
	var generated := power.generated_wh - made
	var went := (power.used_wh - used) + (power.spilled_wh - spilled) + (power.stored_wh() - start)
	print("generated %.3f Wh; used %.3f, spilled %.3f, stored %+.3f; %.1f hours of world time"
		% [generated, power.used_wh - used, power.spilled_wh - spilled, power.stored_wh() - start, world.time / 3600.0])
	check(generated > 10.0, "a real amount was generated (%.2f Wh)" % generated)
	check(absf(generated - went) < 1e-6 * maxf(generated, 1.0), "everything generated was stored, used or spilled (off by %.9f Wh)" % (generated - went))
	check(out_of_range == 0, "no battery ever went past empty or full")
