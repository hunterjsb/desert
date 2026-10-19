extends DeckProbe
## Power probe 14: a bay charges and supplies, and its strip shows which. A
## colonial cabinet on a deck, a battery half full in each of two bays, the
## second held to charge by use at it, and a shield running on them: the
## first supplies and its strip runs down, the held one gives nothing. With
## more made than drawn, both charge and both strips run up. Each strip is
## lit as full as its bay.


## What makes power on the deck, as much as the probe says.
class Feed extends Device:
	var watts := 0.0

	func production_w(_t := NAN) -> float:
		return watts


func run() -> void:
	await load_lines()
	var deck := piece(spot(0.0, 4.0))
	var box := Rig.make([&"power_cabinet", [&"battery", &"battery"]], 0.5) as PowerBox
	Stick.put(deck, deck, Chassis.TOP, Vector2(0.0, 0.22), 0.0, box)
	var shield := Catalog.device(&"shield") as ShieldGenerator
	Stick.put(deck, deck, Chassis.TOP, Vector2(0.28, -0.3), 0.0, shield)
	var feed := Feed.new()
	Stick.put(deck, deck, Chassis.TOP, Vector2(-0.3, -0.3), 0.0, feed)
	shield.switch(true)
	await simulate(1.0)

	var cells := box.batteries()
	var at := seat(box.bays()[1]) * Vector3(0.0, 0.0, 0.09)
	look(at + box.global_basis * Vector3(0.0, 0.3, -1.0), at)
	await simulate(2.0 / 60.0)
	check(hands.interact() and box.is_held(1) and hands.notice == "charging only", "use at the second bay holds it to charge")
	var was: Array[float] = [cells[0].charge_wh, cells[1].charge_wh]
	await simulate(2.0)
	var strips := box.strip_states
	print("supplying: %+.1f W and %+.1f W; strips %s and %s" % [cells[0].flow_w, cells[1].flow_w,
		strips[0], strips[1]])
	check(cells[0].charge_wh < was[0] and cells[0].flow_w < 0.0 and strips[0].g < 0.0,
		"the first supplies the shield, its strip running down")
	check(cells[1].charge_wh == was[1] and strips[1].b == 1.0,
		"the held one gives nothing, its strip held")

	feed.watts = 200.0
	await simulate(2.0)
	strips = box.strip_states
	print("charging: %+.1f W and %+.1f W; strips %s and %s" % [cells[0].flow_w, cells[1].flow_w,
		strips[0], strips[1]])
	check(cells.all(func(c: Battery) -> bool: return c.flow_w > 0.0)
		and strips[0].g > 0.0 and strips[1].g > 0.0,
		"with more made than drawn, both charge, both strips running up")
	check(range(2).all(func(i: int) -> bool:
		return absf(strips[i].r - cells[i].charge_wh / cells[i].capacity()) < 0.01),
		"each strip is lit as full as its bay")
