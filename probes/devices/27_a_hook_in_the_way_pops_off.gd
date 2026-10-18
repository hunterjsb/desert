extends DeckProbe
## Devices & mods probe 27: a hook in the way pops off. A piece lies on the
## sand with a hook on its east ring and another on its west, each with a
## line to a stake beyond. A piece carried to the east ring is offered it and
## joins, and a third joins beyond it, where the hook landed; a piece with a
## crate on it joins at the west from your hold. Each hook comes loose onto
## the sand clear of the deck, its line still tied to it. Saved and resumed,
## the loose hooks keep their lines, and one put back on a free ring ties its
## line to the deck again.

var saves: Node


func run() -> void:
	saves = get_node(^"/root/Saves")
	await load_lines()
	var deck := piece(flat_spot(0.0, 4.0, 8.0))
	await simulate(0.5)
	var east := ring(deck, Vector2i.ZERO, Vector2i(1, 0))
	var west := ring(deck, Vector2i.ZERO, Vector2i(-1, 0))
	var east_stake := _moored(deck, east, 3.5)
	var west_stake := _moored(deck, west, -3.5)
	var east_hook := east.part
	var west_hook := west.part
	await simulate(1.0)

	check(await join_by_hand(deck, piece(spot(-3.0, 0.0)), east), "a carried piece is offered the hooked ring and joins")
	await simulate(1.0)
	var landed := deck.global_transform.affine_inverse() * east_hook.global_position
	print("popped east, it lies at %.2f, %.2f on the deck's grid" % [landed.x, landed.z])
	check(absf(landed.x - 2.0) < 0.5 and await join_by_hand(deck, piece(spot(-3.0, 1.5)), ring(deck, Vector2i(1, 0),
		Vector2i(1, 0))) and deck.pieces().size() == 3, "a third piece joins beyond it, where the hook lies")
	var loaded := piece(deck.global_transform * Vector3(-1.3, 0.0, 0.0))
	var crate := Catalog.device(&"crate_frame")
	world.content.add_child(crate)
	fit_part(crate, &"battery")
	loaded.mount(crate, socket_on(loaded, Vector2i.ZERO, &"deck"))
	await simulate(1.0)
	var edge := loaded.global_transform * Vector3(-0.5, 0.0, 0.0)
	check(await take_at(edge - loaded.global_basis.x * 1.0 + Vector3.UP * 0.3, edge) and hands.grasp.body == loaded,
		"you take hold of a piece with a crate on it")
	await simulate(0.1)
	check(hands.stand == west and hands.grab() and loaded.deck == deck and crate.on_deck(),
		"beside the other hooked ring, it's offered and joins from your hold")
	await simulate(1.5)
	for pair: Array in [[east_hook, east_stake], [west_hook, west_stake]]:
		var hook: Part = pair[0]
		var sand := hook.global_position.y - world.height_under(hook.global_position)
		print("popped: %.2f m up, %.2f m from the first piece's middle" % [sand, flat(hook.global_position - deck.global_position).length()])
		check(hook.socket == null and hook.is_inside_tree() and sand < 0.15 and not overlaps(hook, deck),
			"the hook is loose on the sand, clear of the deck")
		check(_tied(hook, pair[1]), "its line is still tied to it")

	check(saves.save(world), "saved")
	check(await resume(), "resumed")
	var hooks := world.content.get_children().filter(func(n: Node) -> bool: return n is Part and n.get_meta(&"catalog", &"") == &"hook")
	var stakes := world.content.get_children().filter(func(n: Node) -> bool: return n is Stake)
	check(hooks.size() == 2 and hooks.all(func(h: Part) -> bool: return stakes.any(func(s: Stake) -> bool: return _tied(h, s))),
		"resumed, both loose hooks keep their lines")
	deck = world.content.get_children().filter(func(n: Node) -> bool: return n is Chassis)[0]
	var north := ring(deck, Vector2i(1, 0), Vector2i(0, -1))
	hooks.sort_custom(func(a: Part, b: Part) -> bool:
		return a.global_position.distance_to(seat(north).origin) < b.global_position.distance_to(seat(north).origin))
	var back: Part = hooks[0]
	var grip := back.global_transform * Vector3(0.0, 0.0, 0.05)
	look(grip + Vector3(0.0, 1.2, 0.8), grip)
	await simulate(2.0 / 60.0)
	check(hands.grab(), "you take up a loose hook, its line coming with it")
	await simulate(0.4)
	check(await snap_onto(north) and north.part == back and ropes.ropes.any(func(r: Rope) -> bool:
		return r.a.holder == deck or r.b.holder == deck), "put back on a free ring, its line ties to the deck again")


## A hook on a ring, its line to a stake driven `x` m along the deck's east.
func _moored(deck: Chassis, at: Socket, x: float) -> Stake:
	deck.fit(Catalog.part(&"hook"), at)
	var stake := driven_stake(deck.global_transform * Vector3(x, 0.0, 0.0))
	Line.between(world, at.fitted.filter(func(n: Node) -> bool: return n is Socket)[0], stake.free_tie(deck.global_position))
	return stake


## Whether a line runs from a hook to a stake.
func _tied(hook: Part, stake: Stake) -> bool:
	return ropes.ropes.any(func(r: Rope) -> bool:
		return r.a.holder == hook and r.b.holder == stake or r.b.holder == hook and r.a.holder == stake)
