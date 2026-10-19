extends WeatherProbe
## Devices & mods probe 28: devices switch from the Console's power page. A
## Console, a radio, a shield, a lamp and two big batteries are stuck on a
## floating deck of three pieces. Use on the screen's power tab opens the
## page, and its switches, pressed where they're drawn, work each device as
## its own use would: the shield on and off, the radio on, swept to the next
## carrier and turned down, the deck's lamp off, its trays resting. The
## panel's watts are the pool's: what it says is drawn is what the pool's
## devices draw, and its bank what they hold.


func run() -> void:
	await load_weather()
	world.player.set_physics_process(false)
	var rig := Scenarios.rig_at(world, [[&"piece", Vector2i(1, 0)], [&"piece", Vector2i(-1, 0)],
		[&"stick", Vector2i(0, 0), &"bottom", Vector2.ZERO, 0.0, &"hover_tray"],
		[&"stick", Vector2i(1, 0), &"bottom", Vector2.ZERO, 0.0, &"hover_tray"],
		[&"stick", Vector2i(-1, 0), &"bottom", Vector2.ZERO, 0.0, &"hover_tray"],
		[&"stick", Vector2i(0, 0), &"top", Vector2(0.0, -0.15), 0.0, [&"console", [&"screen"]], &"console"],
		[&"stick", Vector2i(0, 0), &"top", Vector2(0.3, 0.35), 0.0, [&"radio", [&"battery"]], &"radio"],
		[&"stick", Vector2i(1, 0), &"top", Vector2.ZERO, 0.0, &"shield", &"shield"],
		[&"stick", Vector2i(-1, 0), &"top", Vector2(-0.2, 0.0), 0.0, &"big_battery"],
		[&"stick", Vector2i(-1, 0), &"top", Vector2(0.2, 0.0), 0.0, &"big_battery"],
		[&"stick", Vector2i(-1, 0), &"top", Vector2(0.0, 0.3), 0.0, &"lamp"]], [0.0, 3.0])
	var deck := rig.deck
	var made: Console = rig.named.console
	var radio: Radio = rig.named.radio
	var shield: ShieldGenerator = rig.named.shield
	await physics_frames(60)

	_press(made, null, Console.Page.POWER)
	check(made.page == Console.Page.POWER, "its power tab opens the power page")
	_press(made, shield, &"on")
	await physics_frames(10)
	check(shield.running(), "the shield switches on")
	_press(made, shield, &"off")
	await physics_frames(10)
	check(not shield.on, "and off")
	_press(made, radio, &"on")
	var khz := radio.frequency
	_press(made, radio, &"sweep")
	_press(made, radio, &"quieter")
	check(radio.on and radio.frequency > khz and radio.tuned_to() != &""
		and is_equal_approx(radio.volume, 1.0 - Radio.VOLUME_STEP), "the radio comes on, sweeps to a carrier and turns down")
	var lit := deck.demand_w()
	_press(made, deck, false)
	await physics_frames(10)
	var light := deck.get_children().filter(func(n: Node) -> bool: return n is Light3D)
	check(deck.demand_w() < lit and not light.is_empty() and light.all(func(l: Light3D) -> bool: return not l.visible),
		"the deck's lamp goes off (%.1f W to %.1f W)" % [lit, deck.demand_w()])
	_press(made, deck, &"rest")
	check(deck.resting, "the deck's trays rest")

	var pool := world.power.pool_of(made)
	var drawn := 0.0
	for device: Device in pool:
		drawn += device.demand_w() if device.powered else 0.0
	var said := _number(made, "DRAWS")
	var held := _number(made, "BANK", 3)
	print("the pool draws %.1f W, the panel says %s W; it holds %.0f Wh, the panel %s Wh" % [drawn, said,
		world.power.pool_wh(made), held])
	check(absf(said - drawn) <= 1.0 and absf(held - floorf(world.power.pool_wh(made))) <= 1.0,
		"the panel's watts and charge are the pool's")


## Presses the key that works a device toward a state (a tab with none), at
## its middle, where it's drawn.
func _press(made: Console, device: Device, to: Variant) -> void:
	for key: Dictionary in made.keys():
		if key.device == device and typeof(key.to) == typeof(to) and key.to == to:
			made.press((key.box as Rect2).get_center() / Vector2(Console.PIXELS))
			return
	check(false, "a key for %s on %s" % [to, device])


## A number the power page reads on a row, by the row's label: its number, or its note's.
func _number(made: Console, label: String, cell := 1) -> float:
	for row: String in made.screen_text(Console.Page.POWER).split("\n"):
		if row.begins_with(label + " "):
			var cells := Array(row.split(" ")).filter(func(c: String) -> bool: return c != "")
			return float(cells[cell]) if cells.size() > cell else NAN
	return NAN
