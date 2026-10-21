extends LineProbe
## A coil outside the find registry still gives a usable end when taken.

func run() -> void:
	await load_lines()
	var at := world.player.global_position + Vector3(0, 0.3, -1)
	for rolled in [false, true]:
		var coil := Catalog.part(&"coil")
		if rolled:
			coil.set_meta(&"rolled", &"coil")
			coil.set_meta(&"rolled_m", 7.5)
		world.content.add_child(coil)
		coil.global_position = at
		coil.freeze = true
		look(coil.global_position + Vector3(0, 0.5, 0.6), coil.global_position)
		await physics_frames(2)
		check(hands.grab(), "take the loose coil")
		await simulate(0.5)
		var line := hands.held.get_meta(&"line", null) as Line if hands.held != null and hands.held.has_meta(&"line") else null
		var length := 7.5 if rolled else world.tuning.rope_coil_length
		check(line != null and hands.held.kind == &"tie" and line.state == Line.State.FIRST
			and is_equal_approx(line.full, length) and world.player.waist.holds(line.ends[1]),
			"pickup opens an owned or authored coil at its stored length")
		if line != null:
			check(world.player.suit.put_in(), "stow the opened line")
		elif hands.held != null:
			hands.stow().queue_free()
		await physics_frames(2)
