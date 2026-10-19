extends DeckProbe
## Power probe 16: a skimmer rack's dead bays hold nothing. Held to one, a
## battery is offered a live bay or none, never the dead one; filled from
## data or found, a rack's dead bays stay empty, their strips dark; and use
## at a live bay says the rack is shared pool only.


func run() -> void:
	await load_lines()
	var rack := device(&"power_rack", spot(0.0, 3.0), 0.55) as PowerBox
	rack.freeze = true
	var dead := rack.bays().filter(func(b: Socket) -> bool: return b.kind == PowerBox.DEAD)
	check(dead.size() == 3, "three of its twelve bays are dead")
	var cell := part(&"battery", Transform3D(Basis.IDENTITY, world.player.global_position + Vector3(0.4, 0.6, 0.0)))
	hands.hold(cell)
	await simulate(0.3)
	var offered := []
	for bay: Socket in dead:
		var at := seat(bay)
		look(at.origin + at.basis.z * 0.8 + Vector3.UP * 0.2, at.origin)
		await simulate(0.2)
		offered.append(hands.socket)
	check(not offered.any(func(s: Socket) -> bool: return s in dead) and hands.grab() and cell.socket != null
		and not cell.socket in dead, "held to a dead bay, a battery goes in a live one or none")

	var ids: Array[StringName] = []
	for i in 12:
		ids.append(&"battery")
	var full := Rig.make([&"power_rack", ids]) as PowerBox
	world.content.add_child(full)
	full.global_position = spot(2.0, 3.0) + Vector3.UP * 0.55
	full.freeze = true
	await simulate(0.2)
	var holds := Finds.holds(&"power_rack")
	var found_dead := dead.all(func(b: Socket) -> bool: return holds[rack.frame_sockets().find(b)] == PowerBox.DEAD)
	check(full.batteries().size() == 9 and found_dead and not Finds.FILLS[Finds.DEEP].has(PowerBox.DEAD)
		and not Finds.FILLS[Finds.SURFACE].has(PowerBox.DEAD), "filled from data or found, nine take batteries and the dead stay empty")
	var states := full.strip_states
	check(range(12).all(func(i: int) -> bool: return (states[i].b == 2.0) == (full.bays()[i].kind == PowerBox.DEAD)),
		"each dead bay's strip is dark")

	var live := full.bays()[0]
	var at := seat(live) * Vector3(0.0, 0.0, 0.09)
	look(at + full.global_basis * Vector3(0.0, 0.3, -1.0), at)
	await simulate(2.0 / 60.0)
	check(hands.interact() and hands.notice == "shared pool only" and not full.is_held(0), "use at a bay: shared pool only")
