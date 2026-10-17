extends MovementProbe
## Survival probe 14: weight is the only limit. Whatever you can carry in your
## hands goes in with what you carry, a hoverboard, a light panel, a survival
## kit and a stake among them, and ten batteries stack as one. Carrying the
## run's kit you walk at your full pace, standing tall; carrying all that too,
## twice what you carry easily, you sink in and walk slower, by the share the
## inventory says, which says you're encumbered and by how much.


func run() -> void:
	await load_moving()
	set_rate(60, 4)
	var suit := player.suit
	var hands := player.hands
	var flat := flat_place(world.player_world_x(), world.player_world_z(), 150.0, 10.0)
	var ahead := Vector2(1.0, 0.0)
	await place(flat.x, flat.z, ahead)
	var light := await _walk(flat, ahead)
	print("with the kit's %.1f kg: %.2f m/s, sunk %.2f; \"%s\"" % [suit.kg(), light.pace, light.sink,
		suit.weight_words()])
	check(absf(light.pace - world.tuning.walk_speed) < 0.02 and light.sink < 0.02 and suit.burden() == 0.0,
		"carrying the kit, you walk at your full pace, standing tall")

	var went := 0
	var things: Array[RigidBody3D] = [Catalog.device(&"board"), Catalog.device(&"light_panel"),
		Catalog.device(&"survival_kit"), Catalog.stake()]
	for i in 10:
		things.append(Catalog.part(&"battery"))
	for thing in things:
		world.content.add_child(thing)
		thing.global_position = player.global_position + Vector3.UP * 1.5
		hands.hold(thing)
		await simulate(0.3)
		went += int(suit.put_in())
	var cells := suit.stacks().filter(func(s: Array) -> bool: return s[0] is Battery)
	print("%d of %d went in; %d stacks; %.1f kg" % [went, things.size(), suit.stacks().size(), suit.kg()])
	check(went == things.size(), "whatever you can carry goes in: a board, a light panel, a survival kit, a stake")
	check(cells.size() == 1 and cells[0].size() == 10, "ten batteries stack as one")

	var heavy := await _walk(flat, ahead)
	var words := suit.weight_words()
	print("with %.1f kg: %.2f m/s, sunk %.2f, eyes %.3f m lower; \"%s\"" % [suit.kg(), heavy.pace, heavy.sink,
		light.eye - heavy.eye, words])
	var over := suit.kg() - world.tuning.carry_easy_kg
	check(heavy.sink > minf(suit.burden(), 1.0) * 0.95
		and light.eye - heavy.eye > world.tuning.haul_sink * minf(suit.burden(), 1.0) * 0.8,
		"past what you carry easily, you sink in")
	check(absf(heavy.pace - world.tuning.walk_speed * suit.pace()) < 0.03 and heavy.pace < light.pace * 0.9,
		"and walk slower, by the share the inventory says (%d%%)" % roundi(suit.pace() * 100.0))
	check(words.contains("encumbered") and words.contains("%.1f over" % over)
		and words.contains("%d%%" % roundi(suit.pace() * 100.0)),
		"the inventory says you're encumbered, by how much, and what it leaves of your pace")
	set_rate(60)


## Two seconds walking on the flat: your own pace, your eyes over the last
## second (the bob averages out) and how far you're sunk in.
func _walk(flat: Dictionary, ahead: Vector2) -> Dictionary:
	await place(flat.x, flat.z, ahead)
	var seen := {"eye": 0.0, "ticks": 0}
	hold(["move_forward"])
	await simulate(1.0)
	await simulate(1.0, func() -> void:
		seen.eye += player.camera.position.y
		seen.ticks += 1)
	seen.eye /= seen.ticks
	seen.pace = player.own.length()
	seen.sink = player.sink
	hold([])
	return seen
