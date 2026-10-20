extends WeatherProbe
## Devices & mods probe 28: devices switch from the Console's power page. A
## Console with a radio on its top, a shield and a crate with a lamp stand on
## a floating deck of three pieces. Use on the screen's power tab opens the
## page, and its switches, pressed where they're drawn, work each device as
## its own use would: the shield on and off, the radio on, swept to the next
## carrier and turned down, the lamp off, the deck's trays resting. The panel's watts are the pool's: what it says
## is drawn is what the pool's devices draw, and its bank what they hold.


func run() -> void:
	await load_weather()
	world.player.set_physics_process(false)
	var deck := Scenarios.standing(world, &"chassis", [], [0.0, 3.0]) as Chassis
	for at: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0)]:
		deck.join(Catalog.device(&"chassis") as Chassis, Scenarios._on_piece(deck, Vector2i.ZERO, &"ring", at), 0)
	Scenarios.fill(world, deck, [&"hover_tray", &"hover_tray", &"hover_tray"])
	var made := Scenarios._stand_on(world, deck, &"console", [&"big_battery", &"screen"], Vector2i.ZERO) as Console
	var radio := Catalog.device(&"radio") as Radio
	world.content.add_child(radio)
	Scenarios.fill(world, radio, [&"battery"])
	made.mount(radio, Scenarios._free(made, &"top"))
	var shield := Scenarios._stand_on(world, deck, &"shield", [&"battery"], Vector2i(1, 0)) as ShieldGenerator
	var crate := Scenarios._stand_on(world, deck, &"crate_frame", [&"big_battery", &"lamp"], Vector2i(-1, 0))
	Scenarios._afloat(world, deck)
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
	check(radio.on and radio.frequency > khz and radio.carriers().has(radio.frequency)
		and is_equal_approx(radio.volume, 1.0 - Radio.VOLUME_STEP), "the radio comes on, sweeps to a carrier and turns down")
	var lit := crate.demand_w()
	_press(made, crate, false)
	await physics_frames(10)
	var light := crate.find_children("*", "Light3D", true, false)
	check(crate.demand_w() < lit and light.all(func(l: Light3D) -> bool: return not l.visible),
		"the lamp goes off (%.1f W to %.1f W)" % [lit, crate.demand_w()])
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
