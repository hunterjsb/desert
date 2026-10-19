extends DeckProbe
## Devices & mods probe 30: anything sticks on every kind of sticky face, by
## hand. Held to a bare piece's top, a battery is shown there itself, its
## back flat on the face where you aim, and take leaves it there, part of
## the piece's body. A tray aimed at the top goes under it facing the sand,
## and the piece lifts clear. A frame aimed off its middle stands square on
## the top. A piece held to the frame's side joins upright as a wall, and one
## to its top lies flat as a shelf. The board sticks on the wall's outer face,
## a battery on the shelf, a battery inside the frame on the wall's inner
## face, and fabric goes on the frame's open front.


func run() -> void:
	await load_lines()
	var deck := piece(spot(0.0, 4.0))
	await simulate(0.5)
	var top := on_face(deck, deck, Chassis.TOP, Vector2(0.25, -0.2))
	var cell := Catalog.part(&"battery")
	await hold_at(cell, top, Vector3(0.0, 1.2, 1.0))
	var shown: Transform3D = deck.global_transform * hands.sticking.get("pose", Transform3D())
	check(not hands.sticking.is_empty() and cell.global_position.distance_to(shown.origin) < 0.02,
		"a battery held to a piece's top is shown there itself")
	check(hands.grab() and cell.socket != null and cell.socket.get_parent() == deck, "and take sticks it there")
	check(_flat(deck, cell.socket, deck, Chassis.TOP, Vector2(0.25, -0.2)), "its back flat on the top, where you aimed")

	var tray := Catalog.part(&"hover_tray")
	check(await stick_by_hand(tray, on_face(deck, deck, Chassis.TOP, Vector2(-0.1, 0.1)), Vector3(0.0, 1.2, 1.0)),
		"a tray aimed at the top sticks")
	check(_flat(deck, tray.socket, deck, Chassis.BOTTOM) and (deck.global_basis * tray.socket.out).y < -0.99,
		"under it, facing the sand")
	await simulate(1.0)
	check(clearance(deck) > 0.3, "and the piece lifts clear on it (%.2f m)" % clearance(deck))
	# Resting, so what goes on it next doesn't tip it about.
	deck.rest(true)
	await simulate(3.0)

	var frame := Catalog.part(&"frame") as Frame
	check(await stick_by_hand(frame, on_face(deck, deck, Chassis.TOP, Vector2(0.2, 0.15)), Vector3(0.0, 1.6, 1.4)),
		"a frame sticks on the top")
	var square := deck.face_frame(deck, Chassis.TOP).affine_inverse() * frame.socket.transform
	check(square.origin.length() < 1e-3 and absf(fposmod(square.basis.get_euler().z, Chassis.QUARTER)) < 1e-3,
		"square and in the middle, though aimed off it")

	var faces := frame.faces()
	var wall := piece(spot(-2.0, 1.5))
	check(await _join_face(deck, wall, faces[&"right"]) and wall.on_frame(), "a piece joins the frame's side")
	check(absf(wall.pose().basis.y.y) < 0.01, "upright, a wall")
	var shelf := piece(spot(-2.0, 2.5))
	check(await _join_face(deck, shelf, faces[&"top"]) and shelf.on_frame(), "a piece joins the frame's top")
	check(shelf.pose().basis.y.y > 0.99 and shelf.pose().origin.y > 1.0, "flat and raised, a shelf")

	var board := Rig.make(&"board") as Device
	var outside := on_face(deck, wall, Chassis.TOP)
	check(await stick_by_hand(board, outside, (deck.global_basis * wall.pose().basis.y) * 1.2 + Vector3.UP * 0.3),
		"the board sticks on the wall's outer face")
	check(board.host() == deck and _flat(deck, board.host().seat_of(board), wall, Chassis.TOP), "its foot on the wall")
	var spare := Catalog.part(&"battery")
	check(await stick_by_hand(spare, on_face(deck, shelf, Chassis.TOP, Vector2(-0.2, 0.0)), Vector3(0.0, 1.0, 1.0)),
		"a battery sticks on the shelf")
	var inside := Catalog.part(&"battery")
	var inner := on_face(deck, wall, Chassis.BOTTOM, Vector2(0.0, 0.1))
	check(await stick_by_hand(inside, inner, -(deck.global_basis * wall.pose().basis.y) * 0.6 + Vector3(0.0, 0.3, 0.6)),
		"and one inside the frame, on the wall's inner face")
	check(_flat(deck, inside.socket, wall, Chassis.BOTTOM), "flat on it")

	var fabric := Catalog.part(&"fabric")
	var front: Socket = faces[&"front"]
	world.content.add_child(fabric)
	hands.hold(fabric)
	await simulate(0.3)
	var at := deck.global_transform * front.transform.origin
	look(at + (deck.global_basis * front.transform.basis.z) * 1.3 + Vector3.UP * 0.4, at)
	await simulate(0.4)
	check(hands.socket == front and hands.grab() and fabric.socket == front, "fabric goes on the frame's open front")
	check(deck.stats().pieces == 3 and deck.batteries().size() == 3, "all of it one deck")


## Whether a thing's base sits flat on a piece's face, its place there `at`
## if given.
func _flat(deck: Chassis, socket: Socket, on: Chassis, face: StringName, at := Vector2(NAN, NAN)) -> bool:
	var local := deck.face_frame(on, face).affine_inverse() * socket.transform
	var base := local.origin
	if socket.mounted != null:
		base = (local * socket.mounted.seat().affine_inverse()).origin
	var placed := is_nan(at.x) or Vector2(base.x, base.y).distance_to(at) < 0.045
	return absf(base.z) < 1e-3 and placed and socket.out.dot(deck.face_frame(on, face).basis.z) > 0.999


## A piece held up to a frame's face from outside it, and taken: whether it joined.
func _join_face(deck: Chassis, piece: Chassis, face: Socket) -> bool:
	hands.hold(piece)
	await simulate(0.3)
	var at := deck.global_transform * face.transform.origin
	look(at + (deck.global_basis * face.transform.basis.z) * 1.6 + Vector3.UP * 0.6, at)
	await simulate(0.4)
	if hands.socket != face:
		hands.drop()
		return false
	return hands.grab() and piece.deck == deck
