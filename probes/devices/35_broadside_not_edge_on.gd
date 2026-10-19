extends DeckProbe
## Devices & mods probe 35: a wall meets the wind as a flat plate. Broadside
## to a steady wind it's pushed downwind as hard as a flat face its size; edge-on
## it lets the wind by; at 45° it's pushed square to itself, so off the wind too.

const WIND := 12.0


func run() -> void:
	await load_lines()
	var deck := Rig.build(world.content, [[&"frame", Vector2i.ZERO, 0], [&"wall", Vector2i.ZERO, &"back"]]).deck
	deck.global_position = flat_spot(0.0, 5.0, 3.0) + Vector3.UP * 0.1
	await simulate(1.0)
	var out := deck.global_basis * (deck.plates()[0][1] as Vector3)
	var along := out.cross(Vector3.UP)
	var broadside := await push(deck, -out)
	var edge_on := await push(deck, along)
	var angled := await push(deck, (along - out).normalized())
	var flat := world.tuning.wind_catch_per_m2 * WIND * WIND
	check(absf(broadside.dot(-out) - flat) < flat * 0.03,
		"broadside, it's pushed downwind as a flat face its size (%.0f of %.0f N)" % [broadside.dot(-out), flat])
	check(edge_on.length() < broadside.length() * 0.02, "edge-on, next to nothing (%.1f N)" % edge_on.length())
	var way := (along - out).normalized()
	var off := (angled - way * angled.dot(way)).length()
	check(off > angled.dot(way) * 0.5 and angled.length() < broadside.length(),
		"at 45° it's pushed off the wind as well as down it (%.0f N across, %.0f down)" % [off, angled.dot(way)])


## The wall's push a few ticks into a steady wind along `way`, from still.
func push(deck: Chassis, way: Vector3) -> Vector3:
	blow(Vector2.ZERO)
	await simulate(0.5)
	blow(Vector2(way.x, way.z) * WIND)
	await simulate(3.0 / 60.0)
	return deck.faces.pushes[0]
