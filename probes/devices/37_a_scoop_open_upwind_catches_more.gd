extends DeckProbe
## Devices & mods probe 37: a scoop open upwind catches more. A frame walled
## on its back, both sides and top, open in front: with the wind blowing into
## its open side the deck is pushed harder than with the same wind on its
## closed back, a parachute's cup against a flat plate.

const WIND := 12.0


func run() -> void:
	await load_lines()
	var deck := Rig.build(world.content, [[&"frame", Vector2i.ZERO, 0], [&"wall", Vector2i.ZERO, &"back"],
		[&"wall", Vector2i.ZERO, &"left"], [&"wall", Vector2i.ZERO, &"right"], [&"wall", Vector2i.ZERO, &"top"]]).deck
	deck.global_position = flat_spot(0.0, 5.0, 3.0) + Vector3.UP * 0.1
	await simulate(1.0)
	var open: Socket = Rig.face_of(deck, Vector2i.ZERO, &"front")
	var out := deck.global_basis * open.transform.basis.z.normalized()
	var into := await pushed(deck, -out)
	var onto_back := await pushed(deck, out)
	check(into > onto_back * 1.15, "open into the wind it's pushed harder than on its back (%.0f against %.0f N)" % [into, onto_back])


## The deck's push from all its faces a few ticks into a steady wind along
## `way`, from still.
func pushed(deck: Chassis, way: Vector3) -> float:
	blow(Vector2.ZERO)
	await simulate(0.5)
	blow(Vector2(way.x, way.z) * WIND)
	await simulate(3.0 / 60.0)
	var all := Vector3.ZERO
	for each in deck.faces.pushes:
		all += each
	return all.dot(way)
