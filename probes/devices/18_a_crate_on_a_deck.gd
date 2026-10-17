extends DeckProbe
## Devices & mods probe 18: a crate on a deck. Having hold of a crate beside
## a two-piece deck, the nearer free deck mount is offered, and take stands
## the crate on it. Standing there it keeps its own sockets: a battery goes
## into its free slot through your hands, and a light shield onto the other
## piece's deck mount. The deck floats on the crate's batteries and the
## shield runs on them, one pool, drawn down by both. Take at the crate has
## it off again into your hold, too heavy to carry.


func run() -> void:
	await load_lines()
	var deck := piece(spot(0.0, 4.0))
	deck.join(piece(spot(-3.0, 1.0)), ring(deck, Vector2i.ZERO, Vector2i(1, 0)))
	fit_part(deck, &"hover_tray")
	fit_part(deck, &"hover_tray")
	var crate := device(&"crate_frame", spot(-1.0, 4.0), 0.27)
	fit_part(crate, &"battery")
	await simulate(1.0)
	check(not deck.stats().hovering, "with nothing to run on, the deck rests")

	check(await take_at(crate.global_position + Vector3(-1.4, 0.5, 0.0), crate.global_position) and hands.grasp.body == crate,
		"you take hold of the crate")
	await simulate(0.1)
	var first := socket_on(deck, Vector2i.ZERO, &"deck")
	check(hands.stand == first, "having hold of it beside the deck, the nearer deck mount is offered")
	check(hands.grab() and crate.host() == deck and crate.on_deck() and hands.grasp.body == null, "take stands it there")
	await simulate(4.0)
	check(deck.stats().hovering, "and the deck floats on the crate's battery")

	var slot: Socket = crate.sockets().filter(func(s: Socket) -> bool: return s.kind == &"battery" and s.part == null)[0]
	var cell := part(&"battery", Transform3D.IDENTITY.translated(eye()))
	hands.hold(cell)
	await simulate(0.3)
	var at := seat(slot)
	look(at.origin + at.basis.z * 0.9 + Vector3.UP * 0.3, at.origin)
	await simulate(0.3)
	check(hands.socket == slot and hands.grab() and slot.part == cell,
		"standing on the deck, the crate takes a battery into its own slot")

	var shield := Catalog.device(&"light_shield") as ShieldGenerator
	world.content.add_child(shield)
	shield.global_position = eye()
	hands.hold(shield)
	await simulate(0.3)
	var other := socket_on(deck, Vector2i(1, 0), &"deck")
	var top := seat(other).origin
	look(top + Vector3(0.0, 1.0, 1.0), top)
	await simulate(0.3)
	check(hands.socket == other and hands.grab() and shield.host() == deck, "a light shield goes onto the other piece's deck mount")
	shield.stand(true)
	await simulate(6.0)
	var bank := world.power.pool_wh(deck)
	check(deck.stats().hovering and absf(clearance(deck) - world.tuning.hover_height) < 0.15 and shield.running()
		and bank == world.power.pool_wh(crate) and bank == world.power.pool_wh(shield) and bank > 150.0,
		"the deck floats on the crate's batteries, and the shield runs on them: one pool (%.0f Wh)" % bank)
	var draw := deck.demand_w() + shield.demand_w() + crate.demand_w()
	await simulate(20.0)
	var used := bank - world.power.pool_wh(deck)
	print("drawing %.0f W: %.3f Wh in 20 s" % [draw, used])
	check(absf(used - draw * 20.0 / 3600.0) < draw * 2.0 / 3600.0, "both draw it down (%.3f Wh)" % used)

	var middle := crate.global_position
	check(await take_at(middle + Vector3(-1.4, 0.3, 0.0), middle) and hands.grasp.body == crate and hands.held == null
		and crate.host() == null, "take at the crate has it off again into your hold")
