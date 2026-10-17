extends DeckProbe
## Devices & mods probe 17: trays lift where they are. A deck three pieces
## by three, a crate standing in its middle, floats level on four trays at
## its corners. Loaded heavier it rides lower, still level; too heavy for
## four, it rests on the sand drawing nothing, and a tray under every piece
## floats it again, drawing for all it holds up. Use sets the whole of it
## resting and floating. Light again, with its trays bunched along one edge,
## it tips its far edge onto the sand, and draws for less than its weight.

## Level within this, degrees.
const LEVEL := 1.0
const CORNERS: Array[Vector2i] = [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]
const EDGES: Array[Vector2i] = [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, 1)]
const WEST: Array[Vector2i] = [Vector2i(-1, -1), Vector2i(-1, 0), Vector2i(-1, 1)]


func run() -> void:
	await load_lines()
	var deck := piece(flat_spot(0.0, 5.0, 3.0))
	for cell: Vector2i in EDGES:
		deck.join(piece(spot(-4.0, 0.0)), ring(deck, Vector2i.ZERO, cell))
	for cell: Vector2i in CORNERS:
		deck.join(piece(spot(-4.0, 0.0)), ring(deck, Vector2i(cell.x, 0), Vector2i(0, cell.y)))
	for cell: Vector2i in CORNERS:
		_tray(deck, cell)
	_stand(deck, Vector2i.ZERO, [&"battery", &"battery"])
	await simulate(5.0)
	var light := clearance(deck)
	print("light, %.0f kg on four corner trays: %.3f m up, %.2f° from level" % [deck.mass, light, _tilt(deck)])
	check(deck.stats().hovering and _tilt(deck) < LEVEL and absf(light - deck.rest_height()) < 0.05,
		"on four corner trays, a light load floats level")

	for cell: Vector2i in EDGES:
		_stand(deck, cell, [&"big_battery", &"big_battery"])
	await simulate(5.0)
	print("heavier, %.0f kg: %.3f m up, %.2f° from level" % [deck.mass, clearance(deck), _tilt(deck)])
	check(deck.stats().hovering and clearance(deck) < light - 0.03 and _tilt(deck) < LEVEL,
		"loaded heavier, it rides lower, still level")

	for cell: Vector2i in CORNERS:
		_stand(deck, cell, [&"big_battery", &"big_battery"])
	await simulate(5.0)
	check(not deck.stats().hovering and clearance(deck) < 0.4 and deck.demand_w() == 0.0,
		"too heavy for four trays (%.0f kg), it rests on the sand, drawing nothing" % deck.mass)
	for cell: Vector2i in EDGES + [Vector2i.ZERO]:
		_tray(deck, cell)
	await simulate(5.0)
	var draw := deck.demand_w()
	check(deck.stats().hovering and _tilt(deck) < LEVEL and absf(draw - deck.mass * world.tuning.hover_watts_per_kg) < draw * 0.01,
		"a tray under every piece, it floats, drawing %.0f W for the %.0f kg it holds up" % [draw, deck.mass])

	check(await _use(deck), "use at the deck")
	await simulate(5.0)
	check(clearance(deck) < 0.4 and deck.demand_w() == 0.0, "sets the whole of it resting")
	check(await _use(deck), "use again")
	await simulate(5.0)
	check(deck.stats().hovering and _tilt(deck) < LEVEL, "and it floats")

	for socket in deck.sockets():
		if socket.kind == &"deck" and socket.mounted != null and deck._cell_of(socket) != Vector2i.ZERO:
			deck.dismount(socket).free()
		elif socket.kind == &"bottom" and socket.part != null and not WEST.has(deck._cell_of(socket)):
			deck.take(socket).free()
	await simulate(6.0)
	var east := deck.global_transform * Vector3(1.5, -0.06, 0.0)
	var west := deck.global_transform * Vector3(-1.5, -0.06, 0.0)
	draw = deck.demand_w()
	print("trays bunched along the west edge: %.1f° from level, east edge %.3f m up, west %.3f m, drawing %.0f W for %.0f kg"
		% [_tilt(deck), east.y - world.height_under(east), west.y - world.height_under(west), draw, deck.mass])
	check(deck.stats().hovering and _tilt(deck) > 10.0 and east.y - world.height_under(east) < 0.1
		and west.y - world.height_under(west) > 0.5, "its trays bunched along one edge, it tips the far one onto the sand")
	check(draw > 0.0 and draw < deck.mass * world.tuning.hover_watts_per_kg * 0.9,
		"and the sand taking a share, its trays draw for less than its weight")


## A hover tray fitted under the piece at a place.
func _tray(deck: Chassis, at: Vector2i) -> void:
	var tray := Catalog.part(&"hover_tray")
	world.content.add_child(tray)
	deck.fit(tray, socket_on(deck, at, &"bottom"))


## A crate frame with parts in it, standing on the piece at a place.
func _stand(deck: Chassis, at: Vector2i, parts: Array) -> void:
	var crate := Catalog.device(&"crate_frame")
	world.content.add_child(crate)
	for id: StringName in parts:
		fit_part(crate, id)
	deck.mount(crate, socket_on(deck, at, &"deck"))


func _tilt(body: Node3D) -> float:
	return rad_to_deg(body.global_basis.y.normalized().angle_to(Vector3.UP))


## Looks at the deck's west edge from beyond it, and uses it.
func _use(deck: Chassis) -> bool:
	var middle := deck.global_position
	look(middle + deck.global_basis.x * -2.5 + Vector3.UP * 0.1, middle)
	await simulate(0.05)
	check(hands.look_device == deck, "looking at the deck, the look ray meets it")
	return hands.interact()
