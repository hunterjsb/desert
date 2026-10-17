extends LineProbe
## Profile & saves probe 11: a gadget in a slot. A radio tuned to the weather
## station and a compass go in your slots, and the run is saved. Resumed into
## a fresh world on the same seed, the radio is back in its slot on the same
## channel with the same charge, playing from you, its line of words showing;
## the compass is in its slot.


func run() -> void:
	var saves := get_node(^"/root/Saves")
	await load_lines()
	var suit := world.player.suit
	var radio := Catalog.device(&"radio") as Radio
	world.content.add_child(radio)
	radio.global_position = world.player.global_position + Vector3.UP
	(fit_part(radio, &"battery") as Battery).charge_wh = 61.5
	hands.hold(radio)
	await simulate(0.5)
	while radio.channel != Radio.WEATHER:
		radio.interact(world.player)
	check(suit.click(2), "a radio on the weather goes in a slot")
	var compass := Catalog.part(&"compass")
	world.content.add_child(compass)
	compass.global_position = world.player.global_position + Vector3.UP
	hands.hold(compass)
	await simulate(0.5)
	check(suit.click(3), "and a compass")
	await simulate(0.5)
	var charge := radio.battery().charge_wh
	check(saves.save(world), "saved")

	check(await resume(), "resumed")
	suit = world.player.suit
	var back := suit.slots[2] as Radio
	check(back != null and back.channel == Radio.WEATHER and back.battery() != null
		and back.battery().charge_wh == charge, "the radio is back in its slot, on the weather, %.4f Wh in it" % charge)
	if back == null:
		return
	await simulate(1.0)
	var said := (world.player.get_node(^"Broadcast") as Broadcast).said
	print("resumed: the radio %s, the line says \"%s\"" % ["plays" if back.playing() else "is silent", said])
	check(back.playing() and back.get_parent() == world.player and said.begins_with("Weather"),
		"playing from you, its words showing")
	check(suit.slots[3] is Compass, "the compass is in its slot")
