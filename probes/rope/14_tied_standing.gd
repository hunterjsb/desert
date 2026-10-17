extends LineProbe
## Rope & tethering probe 14: tied standing. A coil taken out of a slot comes
## to your hands, its first end in hand. Standing a step and a half from a
## driven stake, a look at its foot ties that end to its ring. Walked off
## paying out, a look at the ring of another stake ahead ties the second end,
## and the line laid between them reaches from ring to ring.

const SLOT := 2
## How far ahead of you each stake is driven, m.
const AHEAD := 1.8

var suit: Suit


func run() -> void:
	await load_lines()
	suit = world.player.suit
	var coil := Line.make(world, world.tuning.rope_coil_length)
	coil.coil.global_position = world.player.global_position + Vector3(0.5, 0.1, 0.5)
	await simulate(0.5)
	look(eye(), coil.coil.global_position)
	await simulate(1.0 / 60.0)
	check(hands.grab(), "you take up a coil")
	await simulate(0.5)
	check(suit.click(SLOT) and suit.click(SLOT), "it goes in a slot and comes out")
	await simulate(0.5)
	var line := hands.held.get_meta(&"line") as Line if hands.held != null and hands.held.has_meta(&"line") else null
	check(line != null and line.state == Line.State.FIRST, "its first end in your hand")
	if line == null:
		return

	var ends: Array[Part] = line.ends.duplicate()
	var first := _ahead(AHEAD)
	var foot := Vector3(first.global_position.x, world.height_under(first.global_position), first.global_position.z)
	check(await _tie(first, foot, ends[0]), "a standing look at a stake's foot ties the first end to its ring")
	await simulate(0.3)
	var paying: bool = line.state == Line.State.PAYING and is_instance_valid(ends[1]) and hands.held == ends[1]
	check(paying, "the coil comes to your hand, paying out")
	if not paying:
		return

	await walk_to(world.player.global_position - world.player.global_basis.z * 4.0)
	var second := _ahead(AHEAD)
	check(await _tie(second, second.global_position + Stake.RING, ends[1]),
		"a standing look at the next stake's ring ties the second end")
	await simulate(0.5)
	var span := first.ring.global_position.distance_to(second.ring.global_position)
	print("laid %.2f m between rings %.2f m apart" % [line.rope.length, span])
	check(line.state == Line.State.LAID and line.rope.length >= span, "laid, it reaches from ring to ring")


## A stake driven this far ahead of where you stand.
func _ahead(by: float) -> Stake:
	var player := world.player
	var at := player.global_position - player.global_basis.z * by
	at.y = world.height_under(at)
	return driven_stake(at)


## Standing where you are, looking at a point, take: whether the end is on the stake's ring after.
func _tie(stake: Stake, at: Vector3, end: Part) -> bool:
	var feet := world.player.global_position
	look(Vector3(feet.x, world.height_under(feet) + world.player.camera.position.y, feet.z), at)
	await simulate(4.0 / 60.0)
	hands.grab()
	await simulate(1.0 / 60.0)
	return is_instance_valid(end) and stake.sockets()[0].part == end
