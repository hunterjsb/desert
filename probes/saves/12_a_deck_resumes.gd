extends DeckProbe
## Profile & saves probe 12: a deck resumes. A deck of three pieces in an L,
## two of them turned, trays under all, floats moored to a stake by a hook on
## one of its rings, a crate standing on it with its batteries and a hook of
## its own, a light shield running on another piece. Saved and resumed into
## a fresh world on the same seed, the same deck stands where it was: its
## pieces on the same places of its grid and turned as they were, every tray,
## the crate on the same piece with its charge, the shield running, the line
## still tied, and it floats on.

var saves: Node


func run() -> void:
	saves = get_node(^"/root/Saves")
	await load_lines()
	var deck := piece(spot(0.0, 4.0))
	deck.join(piece(spot(-3.0, 1.0)), ring(deck, Vector2i.ZERO, Vector2i(1, 0)), 1)
	deck.join(piece(spot(-3.0, 2.5)), ring(deck, Vector2i(1, 0), Vector2i(0, 1)), 2)
	for i in 3:
		fit_part(deck, &"hover_tray")
	var crate := Catalog.device(&"crate_frame")
	world.content.add_child(crate)
	for id: StringName in [&"battery", &"battery", &"hook"]:
		fit_part(crate, id)
	deck.mount(crate, socket_on(deck, Vector2i(1, 0), &"deck"))
	var shield := Catalog.device(&"light_shield") as ShieldGenerator
	deck.mount(shield, socket_on(deck, Vector2i(1, 1), &"deck"))
	shield.stand(true)
	var hook := ring(deck, Vector2i.ZERO, Vector2i(-1, 0))
	deck.fit(Catalog.part(&"hook"), hook)
	await simulate(4.0)
	lay(deck, driven_stake(spot(-3.0, 4.0)), 0.3)
	await simulate(4.0)
	var before := _reading(deck)
	print("saved: ", before)
	check(before.hovering and before.running, "the deck floats, its shield running")
	check(saves.save(world), "saved")

	check(await resume(), "resumed")
	var decks := world.content.get_children().filter(func(n: Node) -> bool: return n is Chassis)
	check(decks.size() == 1, "one deck came back")
	if decks.is_empty():
		return
	var after := _reading(decks[0])
	print("resumed: ", after)
	var moved: float = before.at.distance_to(after.at)
	after.at = before.at
	check(moved < 1e-3 and str(after) == str(before), "the same deck, where it was (%.5f m off)" % moved)
	await simulate(4.0)
	var again := _reading(decks[0])
	check(again.hovering and again.running and again.lines == 1 and absf(clearance(decks[0]) - world.tuning.hover_height) < 0.15,
		"and it floats on, moored, its shield running")


## What a save must keep of a deck: where it is, its pieces' places and
## turns, its trays, what stands where with what charge, and its line.
func _reading(deck: Chassis) -> Dictionary:
	var standing := []
	for seated in deck.mounted():
		var on: Chassis = deck._piece_of(seated) if deck._piece_of(seated) != null else deck
		standing.append([str(seated.get_meta(&"catalog")), on.cell, snappedf(seated.charge_share(), 1e-4)])
	return {"at": Vector3(world.world_x(deck.global_position.x), deck.global_position.y, world.world_z(deck.global_position.z)),
		"pieces": deck.pieces().map(func(p: Chassis) -> Array: return [p.cell, p.turns]),
		"short": deck.stats().trays_short, "standing": standing, "mass": snappedf(deck.mass, 1e-3),
		"hovering": deck.stats().hovering, "running": (deck.mounted().filter(func(d: Device) -> bool:
			return d is ShieldGenerator)[0] as ShieldGenerator).running(),
		"lines": world.ropes.ropes.filter(func(r: Rope) -> bool: return r.a.holder == deck or r.b.holder == deck).size()}
