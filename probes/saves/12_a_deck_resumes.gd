extends DeckProbe
## Profile & saves probe 12: a deck resumes, everything on it by the face it's
## stuck on. A deck of three pieces in an L, two of them turned, left when the
## first piece joined came off its end, trays under all, floats moored by a
## hook on one of its rings; a frame stands on one piece with a wall on its
## side and a shelf on top, the board hung on the wall and a battery on the
## shelf; a light shield runs on another piece beside two batteries. Saved and
## resumed into a fresh world on the same seed, the same deck stands where it
## was: its pieces where they were, every thing on the same face of the same
## piece in the same pose with its charge, the shield running, the line still
## tied, and it floats on.

var saves: Node


func run() -> void:
	saves = get_node(^"/root/Saves")
	await load_lines()
	var deck := piece(spot(-1.0, 4.0))
	deck.join(piece(spot(-3.0, -0.5)), ring(deck, Vector2i.ZERO, Vector2i(1, 0)))
	deck.join(piece(spot(-3.0, 1.0)), ring(deck, Vector2i(1, 0), Vector2i(1, 0)), 1)
	deck.join(piece(spot(-3.0, 2.5)), ring(deck, Vector2i(2, 0), Vector2i(0, 1)), 2)
	# The first piece off, another takes over the deck's own frame.
	deck.detach(deck).free()
	for each in deck.grid():
		Stick.put(deck, each, Chassis.BOTTOM, Vector2.ZERO, 0.0, Catalog.part(&"hover_tray"))
	var framed := Rig.piece(deck, Vector2i(1, 0))
	Stick.put(deck, framed, Chassis.TOP, Vector2.ZERO, 0.0, Catalog.part(&"frame"))
	var faces := (_frame(deck) as Frame).faces()
	deck.join(Catalog.device(&"chassis") as Chassis, faces[&"back"])
	deck.join(Catalog.device(&"chassis") as Chassis, faces[&"top"])
	var wall := _on(deck, faces[&"back"])
	var shelf := _on(deck, faces[&"top"])
	Stick.put(deck, wall, Chassis.TOP, Vector2(0.0, 0.1), PI / 2.0, Rig.make([&"board", [&"battery"]], 0.4))
	Stick.put(deck, shelf, Chassis.TOP, Vector2(0.2, -0.1), 0.3, Rig.make(&"battery", 0.7))
	var other := Rig.piece(deck, Vector2i(1, 1))
	var shield := Catalog.device(&"light_shield") as ShieldGenerator
	Stick.put(deck, other, Chassis.TOP, Vector2(-0.2, 0.2), 0.0, shield)
	Stick.put(deck, other, Chassis.TOP, Vector2(0.25, -0.25), 0.0, Rig.make(&"battery", 0.9))
	Stick.put(deck, other, Chassis.TOP, Vector2(0.25, 0.25), 0.0, Rig.make(&"big_battery", 0.6))
	shield.stand(true)
	deck.fit(Catalog.part(&"hook"), ring(deck, Vector2i.ZERO, Vector2i(-1, 0)))
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
	check(again.hovering and again.running and again.lines == 1 and absf(clearance(decks[0]) - decks[0].rest_height()) < 0.2,
		"and it floats on, moored, its shield running")


func _frame(deck: Chassis) -> Part:
	for socket in deck.stuck():
		if socket.part is Frame:
			return socket.part
	return null


## The piece on a frame's face.
func _on(deck: Chassis, face: Socket) -> Chassis:
	for each in deck.joined:
		if each.joined_at == face:
			return each
	return null


## What a save must keep of a deck: where it is, its pieces' places and
## turns, what's stuck on which face of which piece, where and with what
## charge, and its line.
func _reading(deck: Chassis) -> Dictionary:
	var stuck := []
	for socket in deck.stuck():
		var thing: Node = socket.part if socket.part != null else socket.mounted
		var on := deck.own_piece(socket)
		var pose := on.pose().affine_inverse() * socket.transform if on.deck != null else socket.transform
		var held := snappedf((thing as Battery).charge_wh, 1e-3) if thing is Battery \
			else (snappedf((thing as Device).charge_share(), 1e-4) if thing is Device else -1.0)
		stuck.append(str([str(thing.get_meta(&"catalog")), deck.pieces().find(on), _rounded(pose), held]))
	# Put back piece by piece, so in another order: what matters is what's where.
	stuck.sort()
	return {"at": Vector3(world.world_x(deck.global_position.x), deck.global_position.y, world.world_z(deck.global_position.z)),
		"pieces": deck.pieces().map(func(p: Chassis) -> Array: return [p.cell, p.turns, _rounded(p.pose())]),
		"lift": deck.stats().lift_kg, "stuck": stuck, "mass": snappedf(deck.mass, 1e-3),
		"hovering": deck.stats().hovering, "running": (deck.mounted().filter(func(d: Device) -> bool:
			return d is ShieldGenerator)[0] as ShieldGenerator).running(),
		"lines": world.ropes.ropes.filter(func(r: Rope) -> bool: return r.a.holder == deck or r.b.holder == deck).size()}


static func _rounded(at: Transform3D) -> String:
	return str([at.origin.snapped(Vector3.ONE * 1e-4), at.basis.x.snapped(Vector3.ONE * 1e-4),
		at.basis.y.snapped(Vector3.ONE * 1e-4)])
