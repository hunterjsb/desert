extends LineProbe
## Survival probe 7: rope goes in as a coil. The run's kit is set down beside
## you. Its cable, plugged in at one end, stays out of your slots; plugged
## into nothing, it goes in whole and comes out whole, its other plug
## following, and a strong cable the same. The kit's 6 m coil and a found
## 12 m one, each taken up, go in a slot as a coil, leaving nothing of the
## line in the world. A kilometre on, the land they lay on gone, each comes
## out as its first end in your hand and the rest at your belt, pays out to
## the same length and ties onto a stake's ring. Paying out, or laid, a line
## stays out.

## How far you go with a coil in a slot, m, in hops the ground keeps up with.
const AWAY := 1000.0
const HOP := 100.0
const SLOT := 2
## How far short of a line's length you walk off with it, m.
const SHORT := 0.3

var suit: Suit


func run() -> void:
	await load_lines(1234, true)
	suit = world.player.suit
	var kit := Runs.kit(world)
	await simulate(1.0)
	var line: Line = null
	var cable: Cable = null
	for node in kit:
		if node is Line:
			line = node
		elif node is Cable:
			cable = node
	await _cables(cable)
	await _round(line.coil, Kit.standard().rope_m)

	var here := Vector2(world.player_world_x(), world.player_world_z()) + Vector2(0.0, 3.0)
	var spec := {"index": 950, "id": &"coil", "device": false, "layer": Finds.SURFACE, "x": here.x, "z": here.y,
		"yaw": 0.3, "lean": 0.0, "lean_by": 0.0, "bury": 0.0, "loose": true, "sound": 1.0, "charge": 0.0, "fill": []}
	var found := world.salvage.lay(world.terrain.chunk_at(here.x, here.y), spec) as Part
	await simulate(1.0)
	await _round(found, world.tuning.rope_coil_length)


## The kit's cable plugged in at one end, then at neither, and a strong cable.
func _cables(kit_cable: Cable) -> void:
	var plug := kit_cable.plugs[0]
	(plug.socket.get_parent() as Device).take(plug.socket)
	hands.hold(plug)
	await simulate(0.5)
	check(not suit.click(3) and hands.held == plug, "a cable plugged in at its other end stays out")
	var other := kit_cable.plugs[1]
	(other.socket.get_parent() as Device).take(other.socket)
	await simulate(0.5)
	var strong := Catalog.cable(world, world.player.global_position + Vector3(1.0, 0.1, -1.0), true)
	for cable: Cable in [kit_cable, strong]:
		if cable == strong:
			hands.hold(strong.plugs[0])
			await simulate(0.5)
		var ropes_were := ropes.ropes.size() - (1 if cable == strong else 0)
		check(suit.click(3) and hands.held == null, "a %s plugged into nothing goes in" % cable.plugs[0].label)
		await simulate(0.1)
		check(not is_instance_valid(cable) and ropes.ropes.size() == ropes_were, "whole, nothing of it left out")
		print("in the slot: %s, %s" % [Suit._name(suit.slots[3]), Suit._brief(suit.slots[3])])
		check(suit.click(3), "taken out")
		await simulate(0.5)
		var back := _cable_of(hands.held)
		check(back != null and (back is StrongCable) == (cable == strong) and is_instance_valid(back.plugs[1])
			and back.plugs[1].global_position.distance_to(hands.held.global_position) < back.length
			and (back is not StrongCable or ropes.ropes.has((back as StrongCable).rope)),
			"it comes out whole, its other plug following")
		hands.drop()
		await simulate(0.3)


## A coil taken up and stowed, carried a kilometre, taken out and laid.
func _round(coil: Part, metres: float) -> void:
	var at := coil.global_transform * Finds.bounds(coil).get_center()
	look(at + Vector3(0.0, 1.2, 0.8), at)
	await simulate(1.0 / 60.0)
	check(hands.grab(), "you take up a %.0f m coil" % metres)
	await simulate(0.5)
	var line := _line_in_hand()
	if line == null:
		check(false, "and hold its first end")
		return
	var ropes_were := ropes.ropes.size() - 1
	check(suit.click(SLOT) and hands.held == null and world.player.waist.tied.is_empty(),
		"held but not laid, it goes in a slot")
	await simulate(0.1)
	var stowed := suit.slots[SLOT]
	check(not is_instance_valid(line) and ropes.ropes.size() == ropes_were, "as a coil, nothing of its line left out")
	if stowed == null:
		return
	print("in the slot: %s, %s" % [Suit._name(stowed), Suit._brief(stowed)])

	var left := Vector2(world.player_world_x(), world.player_world_z())
	for i in roundi(AWAY / HOP):
		teleport(left.x + HOP * (i + 1), left.y)
		await settle(true)
	await simulate(1.0)
	check(not world.terrain.is_loaded_at(left.x, left.y) and suit.slots[SLOT] == stowed,
		"a kilometre on, the land it was stowed on gone, it's still in its slot")
	check(suit.click(SLOT), "taken out")
	await simulate(0.5)
	line = _line_in_hand()
	check(line != null and line.state == Line.State.FIRST and hands.held == line.ends[0]
		and world.player.waist.holds(line.ends[1]) and line.full == metres,
		"it's its first end in your hand, the rest at your belt, %.0f m of it" % metres)
	if line == null:
		return

	var here := world.player.global_position
	var a := driven_stake(here + Vector3(0.0, 0.0, -1.5))
	check(await snap_onto(a.free_tie(here)), "its first end ties onto a stake")
	await simulate(0.3)
	check(line.state == Line.State.PAYING and not suit.click(SLOT) and hands.held == line.ends[1],
		"paying out, it stays out")
	# Just short of its length: past it, a probe's walk can't be held back, and it would snap.
	await walk_to(a.global_position + Vector3(metres - SHORT, 0.0, 0.0))
	var span := line.rope.a.global_position.distance_to(line.rope.b.global_position)
	print("%.0f m coil: paid out %.2f m over %.2f m" % [metres, line.rope.length, span])
	check(line.rope.length == metres and span + world.tuning.rope_pay_slack > metres,
		"it pays out to its full length, and no more")
	var b := driven_stake(a.global_position + Vector3(metres - 1.5, 0.0, 0.0))
	check(await snap_onto(b.free_tie(a.global_position)), "its other end ties onto another")
	await simulate(0.3)
	check(line.state == Line.State.LAID and line.ends.all(func(e: Part) -> bool: return e.socket != null),
		"laid stake to stake")
	look(b.global_position + Vector3(0.0, 1.4, 0.9), b.global_position + Vector3.UP * 0.45)
	await simulate(0.05)
	check(hands.grab(), "you take its end off the stake")
	await simulate(0.5)
	check(line.state == Line.State.LAID and hands.held == line.ends[1] and not suit.click(SLOT)
		and hands.held == line.ends[1], "laid, it stays out")
	hands.drop()
	await simulate(0.3)


func _line_in_hand() -> Line:
	var held := hands.held
	return held.get_meta(&"line") as Line if held != null and held.has_meta(&"line") else null


func _cable_of(plug: Node) -> Cable:
	for node in world.content.get_children():
		if node is Cable and (node as Cable).plugs.has(plug):
			return node
	return null
