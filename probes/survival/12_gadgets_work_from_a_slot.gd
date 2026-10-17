extends HandsProbe
## Survival probe 12: gadgets work from a slot. A radio playing music in your
## hands goes in a slot whole and plays on from you, on its own battery.
## With the inventory open, use on its slot turns its dial to the weather
## station, and its line of words shows; use on another slot does nothing,
## not even to the shield you're looking at. Clicked, it comes back to your
## hands, still on. A bigger device stays out.


func run() -> void:
	get_window().size = Vector2i(1152, 648)
	await load_hands()
	var player := world.player
	var suit := player.suit
	var broadcast := player.get_node(^"Broadcast") as Broadcast
	var shield := device(&"shield", spot(0.0, -3.0), 0.25) as ShieldGenerator
	fit_part(shield, &"battery")
	look(eye(), shield.global_position)
	var radio := Catalog.device(&"radio") as Radio
	world.content.add_child(radio)
	radio.global_position = player.global_position + Vector3.UP
	fit_part(radio, &"battery")
	hands.hold(radio)
	await physics_frames(30)
	radio.interact(player)
	await physics_frames(10)
	check(radio.playing() and radio.music.playing, "tuned to music in your hands, it plays")

	press(&"inventory")
	click_at(suit.slot_rect(2).get_center())
	check(suit.slots[2] == radio and hands.held == null, "it goes in a slot whole")
	var cell := radio.battery()
	var charge := cell.charge_wh
	await simulate(10.0)
	print("from the slot: %s, %.4f Wh spent, %.2f m from you" % [Suit._brief(radio), charge - cell.charge_wh,
		radio.global_position.distance_to(player.global_position)])
	check(radio.playing() and radio.music.playing and cell.charge_wh < charge
		and radio.global_position.distance_to(player.global_position) < 1.5,
		"and plays on from you, on its own battery")

	point_at(suit.slot_rect(2).get_center())
	press(&"interact")
	await simulate(1.0)
	print("used on its slot: %s; the line says \"%s\"" % [Radio.CHANNELS[radio.channel], broadcast.said])
	check(radio.channel == Radio.WEATHER and broadcast.said.begins_with("Weather"),
		"use on its slot turns its dial, and its words show")
	var was := suit.slots.duplicate()
	var water := (suit.slots[0] as Supply).amount
	point_at(suit.slot_rect(0).get_center())
	press(&"interact")
	await physics_frames(2)
	check(suit.slots == was and (suit.slots[0] as Supply).amount == water and hands.held == null
		and not shield.on, "use on another slot does nothing, there or in the world")

	click_at(suit.slot_rect(2).get_center())
	await physics_frames(30)
	check(hands.held == radio and radio.visible and radio.playing() and radio.channel == Radio.WEATHER,
		"clicked, it comes back to your hands, still on")
	var panel := Catalog.device(&"light_panel")
	check(not suit.fits(panel), "a bigger device stays out")
	panel.free()
