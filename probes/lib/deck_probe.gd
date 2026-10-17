class_name DeckProbe
extends LineProbe
## For chassis probes: pieces lying on the sand, joined into decks through
## your hands, and what stands on them.


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


## A deck's free socket of a kind on the piece at a grid place.
func socket_on(deck: Chassis, at: Vector2i, kind: StringName) -> Socket:
	for socket in deck.sockets():
		if socket.kind == kind and not socket.has_meta(&"socket") and deck._cell_of(socket) == at:
			return socket
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
