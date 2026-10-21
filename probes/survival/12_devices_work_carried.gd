extends HandsProbe
## Survival probe 12: a device works carried. A radio playing in your hands
## goes in with what you carry, whole, and plays on from you on its own
## battery. With the inventory open, use on it switches it off, and again on,
## its dial where it stood and its line of words showing, by frequency alone; use on your canister drinks from it
## where it is, and switches nothing you look at in the world, while use off
## the things you carry switches the shield you look at as ever. Clicked, the
## radio comes back to your hands, still on.


func run() -> void:
	get_window().size = Vector2i(1152, 648)
	await load_hands()
	var player := world.player
	var suit := player.suit
	var broadcast := player.get_node(^"Broadcast") as Broadcast
	# A shield on a plate: a chassis with a battery stuck beside it.
	var plate := device(&"chassis", spot(0.0, -1.5), 0.08) as Chassis
	fit_part(plate, &"battery")
	var shield := Catalog.device(&"shield") as ShieldGenerator
	Stick.put(plate, plate, Chassis.TOP, Vector2.ZERO, 0.0, shield)
	look(eye(), shield.global_position)
	var radio := Catalog.device(&"radio") as Radio
	world.content.add_child(radio)
	radio.global_position = player.global_position + Vector3.UP
	fit_part(radio, &"battery")
	hands.hold(radio)
	await physics_frames(30)
	while radio.channel != Radio.MUSIC:
		radio.sweep()
	await physics_frames(10)
	check(radio.playing() and radio.music.playing, "tuned to music in your hands, it plays")

	press(&"inventory")
	click_at(Vector2(576.0, 60.0))
	check(suit.carried.has(radio) and hands.held == null, "it goes in whole")
	var cell := radio.battery()
	var charge := cell.charge_wh
	await simulate(10.0)
	print("carried: %s, %.4f Wh spent, %.2f m from you" % [Suit._brief([radio]), charge - cell.charge_wh,
		radio.global_position.distance_to(player.global_position)])
	check(radio.playing() and radio.music.playing and cell.charge_wh < charge
		and radio.global_position.distance_to(player.global_position) < 1.5,
		"and plays on from you, on its own battery")

	var khz := radio.frequency
	point_at(suit.tile_rect(stack_of(radio)).get_center())
	press(&"interact")
	await simulate(1.0)
	check(not radio.on, "use on it switches it off")
	press(&"interact")
	await simulate(1.0)
	var swept := radio.channel
	print("used where it is again: %s at %d kHz; it would say \"%s\"" % [Radio.CHANNELS[swept], roundi(radio.frequency),
		broadcast.said])
	check(radio.on and radio.frequency == khz and swept != Radio.OFF
		and broadcast.said.begins_with("%d kHz · " % roundi(radio.frequency)),
		"and on again, its dial where it stood, and its words show")
	var canister := suit.supply(&"water")
	var water := canister.amount
	player.vitals.thirst = 50.0
	point_at(suit.tile_rect(stack_of(canister)).get_center())
	press(&"interact")
	await physics_frames(2)
	print("used on the canister: %.2f L drunk, thirst %.0f" % [water - canister.amount, player.vitals.thirst])
	check(canister.amount < water and player.vitals.thirst > 99.0 and suit.carried.has(canister) and not shield.on,
		"use on the canister drinks from it where it is, and nothing in the world")
	point_at(Vector2(576.0, 60.0))
	press(&"interact")
	await physics_frames(2)
	check(shield.on, "off the things you carry, use works the world as ever")

	click_at(suit.tile_rect(stack_of(radio)).get_center())
	await physics_frames(30)
	check(hands.held == radio and radio.visible and radio.playing() and radio.channel == swept,
		"clicked, it comes back to your hands, still on")
