extends DeviceProbe
## Power probe 1: over two hours of days, nights and storms, with a chassis
## in the sun, a panel and a battery stuck on it, cabled from its light
## panel's port to a floating one's running light shield, a turbine on the
## sand and the two decks' loose batteries swapped by hand, everything
## generated was stored, used or spilled. No energy appears from nowhere, and
## no battery goes past empty or full.

## Where each deck's battery is stuck on its top.
const CELL_AT := Vector2(0.3, 0.3)


func run() -> void:
	await load_world(1234, false)
	var power := world.power
	var sunny := spawn_device(&"chassis", 4.0, 0.1, false) as Chassis
	fit_part(sunny, &"solar_panel")
	var panel := Rig.make(&"light_panel") as Device
	Stick.put(sunny, sunny, Chassis.TOP, Vector2(0.0, -0.3), 0.0, panel)
	var spare := Rig.make(&"battery", 0.3) as Battery
	Stick.put(sunny, sunny, Chassis.TOP, CELL_AT, 0.0, spare)
	var floater := spawn_device(&"chassis", 4.0, 1.5, false) as Chassis
	floater.global_position.z += 3.0
	fit_part(floater, &"hover_tray")
	var shield := Catalog.device(&"light_shield") as ShieldGenerator
	Stick.put(floater, floater, Chassis.TOP, Vector2(-0.25, -0.25), 0.0, shield)
	Stick.put(floater, floater, Chassis.TOP, CELL_AT, 0.0, Rig.make(&"battery"))
	shield.stand(true)
	var turbine := spawn_device(&"turbine", -4.0, 0.2, false)
	fit_part(turbine, &"battery")
	var cable := Catalog.cable(world, sunny.global_position)
	panel.fit(cable.plugs[0], _port(panel))
	shield.fit(cable.plugs[1], _port(shield))
	await physics_frames(5)
	check(cable.joined().size() == 2, "the cable joins the two decks")
	var start := power.stored_wh()
	var made := power.generated_wh
	var used := power.used_wh
	var spilled := power.spilled_wh
	world.time_warp = 30.0
	var out_of_range := 0
	for hour_part in 8:
		await fast_forward(30.0)
		# Swap the two decks' batteries by hand, as you would.
		var a := floater.unstick(floater.batteries()[0].socket) as Battery
		var b := sunny.unstick(sunny.batteries()[0].socket) as Battery
		Stick.put(floater, floater, Chassis.TOP, CELL_AT, 0.0, b)
		Stick.put(sunny, sunny, Chassis.TOP, CELL_AT, 0.0, a)
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


static func _port(device: Device) -> Socket:
	return device.sockets().filter(func(s: Socket) -> bool: return s.kind == &"port")[0]
