extends DeckProbe
## Power probe 13: a power box joins its deck's pool. A battery goes into the
## company's dock's bay by hand, and the dock sticks by hand on a deck beside
## a shield with no battery of its own: the shield runs on the bay's battery,
## which drains. Taken out of its bay by hand, the shield goes dark; put
## straight back, it runs.


func run() -> void:
	await load_lines()
	var deck := piece(spot(0.0, 4.0))
	var shield := Catalog.device(&"shield") as ShieldGenerator
	Stick.put(deck, deck, Chassis.TOP, Vector2(0.25, 0.32), 0.0, shield)
	var box := device(&"power_box", spot(-1.2, 2.5), 0.08) as PowerBox
	await simulate(0.5)
	var cell := part(&"big_battery", Transform3D(Basis.IDENTITY, world.player.global_position + Vector3(0.4, 0.6, 0.0))) as Battery
	cell.charge_wh = cell.capacity() * 0.6
	hands.hold(cell)
	await simulate(0.3)
	var bay := box.bays()[0]
	check(await snap_onto(bay) and cell.socket == bay, "a battery goes into the dock's bay by hand")
	check(await stick_by_hand(box, on_face(deck, deck, Chassis.TOP, Vector2(-0.1, -0.17)), Vector3(0.0, 1.4, -1.0)),
		"the dock sticks on the deck")
	shield.switch(true)
	await simulate(3.0)
	check(world.power.pool_of(deck).has(box) and shield.running(), "the shield runs on the dock's bay, in the deck's pool")
	var was := cell.charge_wh
	await simulate(5.0)
	check(cell.charge_wh < was, "the bay's battery drains for it (%.3f to %.3f Wh)" % [was, cell.charge_wh])

	var at := seat(bay) * Vector3(0.0, 0.0, 0.12)
	look(at + Vector3(0.0, 0.9, -0.5), at)
	await simulate(2.0 / 60.0)
	check(hands.grab() and hands.held == cell, "it comes out of its bay by hand")
	await simulate(1.0)
	check(not shield.running(), "and the shield goes dark")
	check(hands.grab(), "take again at once")
	await simulate(1.0)
	check(cell.socket == bay and shield.running(), "back in its bay, the shield runs")
