extends DeckProbe
## Power probe 15: a Console switches devices off and ranks who's served, as
## far as the deck's power box allows. A colonial cabinet, a Console, a shield
## and a condenser on a deck: the condenser's switch on the power page turns
## it off, a draw the pool skips with the bank full, and on again. The bank
## short, the shield is served and the condenser gives way; ranked above the
## shield, the condenser runs and the shield gives way. With a skimmer's rack
## in the cabinet's place, the page offers neither, and the ranks set no
## longer count.


func run() -> void:
	await load_lines()
	var rig := Rig.build(world.content, [[&"piece", Vector2i(1, 0)],
		[&"stick", Vector2i(0, 0), &"top", Vector2(0.0, -0.15), 0.0, [&"console", [&"screen"]], &"console"],
		[&"stick", Vector2i(0, 0), &"top", Vector2(0.28, 0.3), 0.0, &"shield", &"shield"],
		[&"stick", Vector2i(1, 0), &"top", Vector2(0.0, 0.22), 0.0, [&"power_cabinet", [&"big_battery"]], &"box"],
		[&"stick", Vector2i(1, 0), &"top", Vector2(0.0, -0.3), 0.0, [&"condenser", [&"canister"]], &"condenser"]])
	var deck := rig.deck
	deck.global_position = spot(0.0, 4.0) + Vector3.UP * 0.1
	var made: Console = rig.named.console
	var shield: ShieldGenerator = rig.named.shield
	var condenser: Condenser = rig.named.condenser
	var box: PowerBox = rig.named.box
	(condenser.parts()[0] as Supply).drain(INF)
	var cell := box.batteries()[0]
	shield.switch(true)
	made.page = Console.Page.POWER
	await simulate(2.0)
	check(condenser.powered and condenser.demand_w() > 0.0, "the condenser draws")

	_press(made, condenser, &"switch_off")
	await simulate(1.0)
	check(condenser.switched_off and not condenser.powered and cell.charge_wh > 0.9 * cell.capacity(),
		"switched off on the page, it's dark with the bank full: a draw the pool skips")
	check(made.screen_text().contains("CONDENSER") and _row(made, "CONDENSER").ends_with("OFF"), "its row says so")
	_press(made, condenser, &"switch_on")
	await simulate(1.0)
	check(condenser.powered, "switched on, it runs")

	cell.charge_wh = 0.1 * cell.capacity()
	await simulate(1.0)
	check(shield.running() and not condenser.powered, "the bank short, the shield is served and the condenser gives way")
	cell.charge_wh = 0.8 * cell.capacity()
	await simulate(1.0)
	_press(made, condenser, &"rank_up")
	_press(made, condenser, &"rank_up")
	cell.charge_wh = 0.1 * cell.capacity()
	await simulate(1.0)
	check(condenser.powered and not shield.running(), "ranked above the shield, the condenser runs and the shield gives way")

	cell.charge_wh = 0.8 * cell.capacity()
	var spot_at := deck.seat_of(box)
	var pose := [spot_at.transform, spot_at.out, deck.own_piece(spot_at)]
	deck.unstick(spot_at).free()
	var rack := Rig.make([&"power_rack", [&"big_battery"]], 0.1) as PowerBox
	deck.stick(rack, pose[0], pose[1], pose[2])
	await simulate(1.0)
	var circuit := [&"rank_up", &"rank_down", &"switch_on", &"switch_off"]
	check(made.keys().all(func(k: Dictionary) -> bool: return not k.to in circuit), "with a skimmer's rack, the page offers neither")
	check(shield.running() and not condenser.powered, "and the condenser's rank no longer counts")


## Presses the key that works a device toward a state, at its middle.
func _press(made: Console, device: Device, to: Variant) -> void:
	for key: Dictionary in made.keys():
		if key.device == device and typeof(key.to) == typeof(to) and key.to == to:
			made.press((key.box as Rect2).get_center() / Vector2(Console.PIXELS))
			return
	check(false, "a key for %s on %s" % [to, device])


## The power page's row for a device, as words.
func _row(made: Console, called: String) -> String:
	for row: String in made.screen_text(Console.Page.POWER).split("\n"):
		if row.contains(called):
			return row
	return ""
