extends DeckProbe
## Devices & mods probe 18: a condenser onto a deck from your hold. Having
## hold of a condenser, too heavy to carry, and looking at a two-piece deck's
## top, the condenser itself is shown there, touching nothing; look away and
## it's back in your hold where it was, and take sticks it where it's shown.
## Stuck there it keeps its own tap: a canister goes in through your hands.
## The deck floats on a loose battery stuck on it, and the condenser and a
## light shield on the other piece run on it too, one pool, drawn down by
## all. Take at the condenser has it off into your hold again, and looking
## off the deck it's down on the sand beside it, so dragged away it comes and
## the deck stays.


func run() -> void:
	await load_lines()
	var deck := piece(spot(0.0, 4.0))
	deck.join(piece(spot(-3.0, 1.0)), ring(deck, Vector2i.ZERO, Vector2i(1, 0)))
	fit_part(deck, &"hover_tray")
	fit_part(deck, &"hover_tray")
	var condenser := device(&"condenser", spot(-1.0, 4.0), 0.36) as Condenser
	await simulate(1.0)
	check(not deck.stats().hovering or not deck.powered, "with nothing to run on, the deck doesn't float")

	check(await take_at(condenser.global_position + Vector3(-1.4, 0.5, 0.0), condenser.global_position)
		and hands.grasp.body == condenser, "you take hold of the condenser")
	var was := condenser.global_position
	var top := on_face(deck, deck, Chassis.TOP, Vector2(0.0, 0.1))
	look(top + Vector3(-1.2, 1.2, 0.0), top)
	await simulate(0.5)
	var shown: Transform3D = deck.global_transform * hands.sticking.get("pose", Transform3D())
	check(hands.grasp.showing() and condenser.global_position.distance_to(shown.origin) < 0.02
		and condenser.collision_layer == 0, "looking at the deck's top, the condenser itself is shown there, touching nothing")
	look(top + Vector3(-1.2, 1.2, 0.0), top + Vector3(-1.2, 1.2, 3.0))
	await simulate(0.3)
	check(not hands.grasp.showing() and hands.grasp.body == condenser and condenser.collision_layer != 0
		and condenser.global_position.distance_to(was) < 0.6 and clearance(condenser) < 0.7,
		"look away and it's back in your hold, on the sand where it was")
	look(top + Vector3(-1.2, 1.2, 0.0), top)
	await simulate(0.5)
	check(hands.grab() and condenser.host() == deck and condenser.on_deck() and hands.grasp.body == null,
		"take sticks it where it's shown")

	var tap: Socket = condenser.sockets().filter(func(s: Socket) -> bool: return s.kind == &"water")[0]
	var can := part(&"canister", Transform3D.IDENTITY.translated(eye()))
	hands.hold(can)
	await simulate(0.3)
	var at := seat(tap)
	look(at.origin + at.basis.z * 0.9 + Vector3.UP * 0.3, at.origin)
	await simulate(0.3)
	check(hands.socket == tap and hands.grab() and tap.part == can, "stuck on the deck, it takes a canister into its own tap")

	Stick.put(deck, deck, Chassis.TOP, Vector2(0.3, -0.35), 0.0, Rig.make(&"big_battery", 0.8))
	var shield := Catalog.device(&"light_shield") as ShieldGenerator
	Stick.put(deck, Rig.piece(deck, Vector2i(1, 0)), Chassis.TOP, Vector2.ZERO, 0.0, shield)
	shield.stand(true)
	await simulate(6.0)
	var bank := world.power.pool_wh(deck)
	check(deck.stats().hovering and absf(clearance(deck) - deck.rest_height()) < 0.15 and shield.running() and condenser.powered
		and bank == world.power.pool_wh(condenser) and bank == world.power.pool_wh(shield) and bank > 150.0,
		"the deck floats on its loose battery, and the condenser and shield run on it: one pool (%.0f Wh)" % bank)
	var draw := deck.demand_w() + shield.demand_w() + condenser.demand_w()
	await simulate(20.0)
	var used := bank - world.power.pool_wh(deck)
	print("drawing %.0f W: %.3f Wh in 20 s" % [draw, used])
	check(absf(used - draw * 20.0 / 3600.0) < draw * 2.0 / 3600.0, "all of them draw it down (%.3f Wh)" % used)

	var middle := condenser.global_position
	check(await take_at(middle + Vector3(-1.4, 0.3, 0.0), middle) and hands.grasp.body == condenser and hands.held == null
		and condenser.host() == null, "take at the condenser has it off again into your hold")
	# Looking at the sand off the deck, so it isn't shown back on the deck.
	var sand := condenser.global_position + flat(condenser.global_position - deck.global_position).normalized() * 1.0
	look(world.player.camera.global_position, Vector3(sand.x, world.height_under(sand), sand.z))
	var seen := {"inside": 0}
	await simulate(1.0, func() -> void: seen.inside += int(overlaps(condenser, deck)))
	check(seen.inside == 0, "clear of the deck (%d ticks inside it)" % seen.inside)
	check(clearance(condenser) < 0.7, "down on the sand beside the deck, not left standing on it (%.2f m up)" % clearance(condenser))
	var deck_from := deck.global_position
	var from := condenser.global_position
	var away := flat(condenser.global_position - deck.global_position).normalized()
	await walk_to(world.player.global_position + away * 3.0)
	await simulate(1.0)
	var came := flat(condenser.global_position - from).length()
	var moved := flat(deck.global_position - deck_from).length()
	check(came > 1.5 and moved < 0.3, "dragged away it comes, and the deck stays (condenser %.2f m, deck %.2f m)" % [came, moved])
