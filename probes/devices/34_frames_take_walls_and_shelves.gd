extends DeckProbe
## Devices & mods probe 34: a frame raises walls and shelves, and stands
## only where it should. Aimed at a wall it won't go ("frames go on a deck's
## top"); on a deck's top it stands square. A Console held under it, or a
## frame held over a Console, is "too tall for a frame"; on the bare piece
## beside it the Console stands. A chassis never sticks on a deck's top or a
## device: pieces go only edge to edge or on a frame's face. The wall's and
## the shelf's rings take hooks but never another piece, and the shelf comes
## off by hand once it's bare; the frame won't while its walls are on.


func run() -> void:
	await load_lines()
	var deck := piece(flat_spot(0.0, 4.0, 3.0))
	var beside := piece(spot(-3.0, 1.0))
	check(await join_by_hand(deck, beside, ring(deck, Vector2i.ZERO, Vector2i(1, 0))), "two pieces join")
	var frame := Catalog.part(&"frame") as Frame
	check(await stick_by_hand(frame, on_face(deck, deck, Chassis.TOP), Vector3(0.0, 1.6, 1.4)), "a frame stands on a top")
	var faces := frame.faces()
	deck.join(Catalog.device(&"chassis") as Chassis, faces[&"back"])
	deck.join(Catalog.device(&"chassis") as Chassis, faces[&"top"])
	var wall := on_frame(deck, faces[&"back"])
	var shelf := on_frame(deck, faces[&"top"])
	await simulate(0.5)

	var another := Catalog.part(&"frame")
	await hold_at(another, on_face(deck, wall, Chassis.TOP), (deck.global_basis * wall.pose().basis.y) * 1.4 + Vector3.UP * 0.4)
	check(hands.sticking.get("why", "") == "frames go on a deck's top", "a frame won't go on a wall (%s)" % hands.sticking.get("why", ""))
	hands.drop()
	await simulate(0.3)

	var console := Catalog.device(&"console") as Console
	world.content.add_child(console)
	check(Stick.why_not(deck, deck, Chassis.TOP, console) == "too tall for a frame", "a Console won't go under a frame")
	var right := Rig.piece(deck, Vector2i(1, 0))
	Stick.put(deck, right, Chassis.TOP, Vector2.ZERO, 0.0, console)
	check(console.host() == deck, "on the bare piece beside it, the Console stands")
	check(Stick.why_not(deck, right, Chassis.TOP, Catalog.part(&"frame")) == "too tall for a frame",
		"and no frame goes over it")

	var lone := piece(spot(3.0, 1.0))
	check(not Stick.sticks(lone), "a chassis never sticks")
	await hold_at(lone, on_face(deck, shelf, Chassis.TOP), Vector3(0.0, 1.2, 1.0))
	check(hands.sticking.is_empty(), "held over the shelf, it's shown nowhere on it")
	hands.drop()
	await simulate(0.3)

	var rings := deck.sockets().filter(func(s: Socket) -> bool: return s.kind == &"ring" and deck.own_piece(s) == shelf)
	check(rings.size() == 4 and rings.all(func(s: Socket) -> bool: return not Chassis.free_ring(s) and s.is_open()),
		"the shelf's rings are open for hooks, but no piece joins them")
	deck.fit(Catalog.part(&"hook"), rings[0])
	check(rings[0].part != null, "a hook goes on one")
	deck.take(rings[0]).free()
	check(deck.comes_off(shelf) and not deck.comes_off(deck), "bare, the shelf comes off; the piece under the frame doesn't")
	var rail := deck.global_transform * frame.socket.transform * Vector3(Frame.WIDE * 0.5 - Frame.RAIL * 0.5, Frame.WIDE * 0.5 - Frame.RAIL * 0.5, 0.5)
	look(rail + Vector3(0.0, 0.3, 1.2), rail)
	await simulate(2.0 / 60.0)
	check(hands.look_socket == frame.socket and hands.grab() and hands.held == null and hands.line() == "take its walls off first",
		"its walls on, the frame won't come off: take its walls off first")
	var off := deck.detach(shelf)
	off.free()
	deck.detach(wall).free()
	check(deck.pieces().size() == 2 and frame.faces().values().all(func(s: Socket) -> bool: return s.is_open()),
		"walls off, the frame's faces are free")
