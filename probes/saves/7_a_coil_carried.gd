extends LineProbe
## Profile & saves probe 7: a coil carried. A 6 m coil, the kit's length,
## taken up, and a cable plugged into nothing go in with what you carry, and
## the run is saved.
## Resumed into a fresh world on the same seed, the coil comes out a working
## line of the same length, paying out to all of it and tying onto a stake,
## and the cable comes out whole, its other plug following.

## How far short of the line's length you walk off with it, m: past it, a
## probe's walk can't be held back, and it would snap.
const SHORT := 0.3

var saves: Node


func run() -> void:
	saves = get_node(^"/root/Saves")
	await load_lines()
	var metres := Kit.standard().rope_m
	var suit := world.player.suit
	var line := Line.make(world, metres)
	line.coil.global_position = world.player.global_position + Vector3.UP
	hands.hold(line.coil)
	await simulate(0.5)
	check(suit.put_in(), "a coil you hold goes in")
	var cable := Catalog.cable(world, world.player.global_position + Vector3(1.0, 0.1, -1.0))
	hands.hold(cable.plugs[0])
	await simulate(0.5)
	check(suit.put_in(), "and a cable plugged into nothing")
	await simulate(0.1)
	check(saves.save(world), "saved")

	check(await resume(), "resumed")
	suit = world.player.suit
	var coil := suit.carried.filter(func(p: RigidBody3D) -> bool: return p.has_meta(&"rolled_m"))
	check(coil.size() == 1 and suit.take_out(stack_of(coil[0])), "the coil comes out")
	await simulate(0.5)
	var held := hands.held
	line = held.get_meta(&"line") as Line if held != null and held.has_meta(&"line") else null
	check(line != null and line.state == Line.State.FIRST and line.full == metres
		and world.player.waist.holds(line.ends[1]), "its first end in your hand, %.0f m of it" % metres)
	if line == null:
		return
	var here := world.player.global_position
	var stake := driven_stake(here + Vector3(0.0, 0.0, -1.5))
	check(await snap_onto(stake.free_tie(here)), "its first end ties onto a stake")
	await walk_to(stake.global_position + Vector3(metres - SHORT, 0.0, 0.0))
	print("resumed coil: paid out %.2f m of %.0f" % [line.rope.length, metres])
	check(line.state == Line.State.PAYING and line.rope.length == metres, "it pays out to its full length")
	check(world.player.waist.take_from_hands(), "and ties on at your waist")
	await simulate(0.3)
	check(line.state == Line.State.LAID and world.ropes.at_waist(line.rope), "laid from the stake to you")

	var plug := suit.carried.filter(func(p: RigidBody3D) -> bool: return p.get_meta(&"rolled", &"") == &"plug")
	check(plug.size() == 1 and suit.take_out(stack_of(plug[0])), "the cable comes out")
	await simulate(0.5)
	var back: Cable = null
	for node in world.content.get_children():
		if node is Cable and (node as Cable).plugs.has(hands.held):
			back = node
	check(back != null and is_instance_valid(back.plugs[1]), "whole, its other plug following")
