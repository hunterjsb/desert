class_name DeckProbe
extends LineProbe
## For chassis probes: pieces lying on the sand, joined into decks through
## your hands, and what's stuck on them.


## A bare chassis piece lying on the sand at a place.
func piece(at: Vector3) -> Chassis:
	return device(&"chassis", at, 0.08) as Chassis


## The ring of a deck on the piece at a grid place, facing a way along the grid.
func ring(deck: Chassis, at: Vector2i, toward: Vector2i) -> Socket:
	for socket in deck.sockets():
		if socket.kind == &"ring" and not socket.has_meta(&"socket") and deck._cell_of(socket) == at \
				and Chassis._step(socket) == toward:
			return socket
	return null


## Holds a thing and looks at a point from `from`, an offset from it, long
## enough for what you hold to go where it would stick there.
func hold_at(thing: RigidBody3D, at: Vector3, from: Vector3) -> void:
	if hands.held != thing:
		if thing.get_parent() == null:
			world.content.add_child(thing)
		hands.hold(thing)
		await simulate(0.3)
	look(at + from, at)
	await simulate(0.3)


## Holds a thing aimed at a point and takes: whether it stuck there.
func stick_by_hand(thing: RigidBody3D, at: Vector3, from: Vector3) -> bool:
	await hold_at(thing, at, from)
	if hands.sticking.is_empty() or hands.sticking.why != "" or not hands.grab():
		print("%s didn't stick: %s" % [thing.get(&"label"), "nothing there" if hands.sticking.is_empty() else hands.sticking.why])
		return false
	return thing.socket != null if thing is Part else (thing as Device).host() != null


## A world point on a piece's face, at a place on it.
func on_face(deck: Chassis, piece: Chassis, face: StringName, at := Vector2.ZERO) -> Vector3:
	return deck.global_transform * deck.face_frame(piece, face) * Vector3(at.x, at.y, 0.0)


## The piece on a frame's face, or null.
func on_frame(deck: Chassis, face: Socket) -> Chassis:
	for each in deck.joined:
		if each.joined_at == face:
			return each
	return null


## The frame stuck on a piece, or null.
func frame_on(deck: Chassis, piece: Chassis) -> Frame:
	for socket in deck.stuck():
		if socket.part is Frame and deck.own_piece(socket) == piece:
			return socket.part
	return null


## Takes a loose piece up and brings it to a deck's ring from beyond it, as
## you would; once the tug offers that ring, take joins it there.
func join_by_hand(deck: Chassis, piece: Chassis, at: Socket) -> bool:
	hands.hold(piece)
	await simulate(0.3)
	var seat := deck.global_transform * deck._pose_at(at, 0)
	var out := (deck.global_basis * at.transform.basis.z).normalized()
	look(seat.origin + out * 1.2 + Vector3.UP * 1.0, seat.origin)
	await simulate(0.2)
	if hands.socket != at:
		hands.drop()
		return false
	return hands.grab() and piece.deck == deck


## Looks at a body's middle from `eye`, waits a tick, and takes.
func take_at(eye_at: Vector3, point: Vector3) -> bool:
	look(eye_at, point)
	await simulate(2.0 / 60.0)
	return hands.grab()
