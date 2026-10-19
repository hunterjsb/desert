extends DeviceProbe
## Power probe 5: swap a floating deck's loose battery by hand and the new
## one takes over on the next tick; the old one keeps exactly what it had,
## and no charge is counted twice.

## Where the deck's battery is stuck on its top.
const CELL_AT := Vector2(0.25, 0.25)


func run() -> void:
	await load_world()
	var power := world.power
	var deck := spawn_device(&"chassis", 4.0, 1.5) as Chassis
	fit_part(deck, &"hover_tray")
	Stick.put(deck, deck, Chassis.TOP, CELL_AT, 0.0, Catalog.part(&"battery"))
	await physics_frames(120)
	var first := deck.battery()
	var second: Battery = Catalog.part(&"battery")
	world.content.add_child(second)
	second.global_position = deck.global_position + Vector3(0, 3, 2)
	var tick := Tuning.current().power_tick
	var draw := deck.demand_w() - deck.production_w()
	await physics_frames(60)
	var before := power.stored_wh()
	var used := power.used_wh
	var made := power.generated_wh
	var taken := deck.unstick(first.socket) as Battery
	var kept := taken.charge_wh
	Stick.put(deck, deck, Chassis.TOP, CELL_AT, 0.0, second)
	var fresh := second.charge_wh
	# Wait out one whole power tick.
	var until := world.time + tick * 2.0
	while world.time < until:
		await get_tree().physics_frame
	check(taken == first, "the battery taken out is the one that was in")
	check(taken.charge_wh == kept, "the old battery keeps exactly what it had (%.6f vs %.6f)" % [taken.charge_wh, kept])
	check(second.charge_wh < fresh, "the new battery is drawn on at once")
	check(deck.powered, "the deck never lost power for a swap within a tick")
	var change := (power.stored_wh() - before) + (power.used_wh - used) - (power.generated_wh - made)
	check(absf(change) < 1e-9, "no charge counted twice (off by %.9f Wh)" % change)
	check(draw > 0.0, "the deck was drawing (%.1f W)" % draw)
