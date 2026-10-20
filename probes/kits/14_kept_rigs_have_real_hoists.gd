extends NomadHoistProbe
## A kept runner or yacht includes usable hoisting hardware, not a mast toggle.

func run() -> void:
	await load_nomads()
	for kind: StringName in [&"runner", &"yacht"]:
		var deck := lay_nomad(kind)
		await physics_frames(3)
		var mast := mast_on(deck)
		var winch := winch_on(deck)
		var rope := mast.halyard() if mast != null else null
		check(winch != null and rope != null and rope == winch.line() and rope.through == mast.pulley,
			"the kept %s has a mounted wheel and actual routed halyard" % kind)
		if winch == null or rope == null:
			return
		check(Stick.clear(winch, winch.global_transform, world.player) == "",
			"the %s winch has real clearance from the rig's other equipment" % kind)
		for each in mast.mounted():
			if each is CrowsNest:
				var low := each.global_position.y - Catalog.DEVICES[&"crows_nest"].size.y * 0.5
				check(mast.pulley.global_position.y + RopeStrand.RADIUS < low,
					"the halyard turns below the crow's nest floor")
		look(winch.global_position + winch.global_basis * Vector3(0, 0.6, 1.2), winch.global_position)
		await physics_frames(2)
		Controls.mouse_free = false
		press(&"reel_in")
		await simulate(0.4)
		check(not deck.has_meta(&"find") and mast.raise > 0.01,
			"working the %s wheel claims the rig and begins raising cloth" % kind)
		var line: Line = mast.halyard_socket().part.get_meta(&"line")
		world.salvage._lots[world.terrain.chunk_at(world.world_x(deck.global_position.x), world.world_z(deck.global_position.z))].finds.erase(deck)
		world.ropes.untie(line.rope)
		line.free()
		deck.free()
		await physics_frames(3)
