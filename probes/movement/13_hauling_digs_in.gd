extends MovementProbe
## Movement probe 13: your feet sink when you haul. Walk or sprint against a
## line pulling you back, as its drag on you says, and you dig in: you go
## slower, your eyes drop a few centimetres, and you tire faster. The load
## gone, you come back up. A line pulling you along, a light pull, or a pull
## while you stand still doesn't dig you in. The line is stood in here by
## its one hook on you, the rope_drag velocity.

const HEAVY := 1.2


func run() -> void:
	await load_moving()
	# The probe is the line: nothing else may set its drag on you.
	world.ropes.set_physics_process(false)
	set_rate(60, 4)
	var t := world.tuning
	# Flat for all of a two-second sprint: a slope changes how deep you dig in.
	var flat := flat_place(world.player_world_x(), world.player_world_z(), 150.0, 10.0)
	var ahead := Vector2(1.0, 0.0)

	var free := await _walk(flat, ahead, ["move_forward"], Vector2.ZERO)
	var hauling := await _walk(flat, ahead, ["move_forward"], -ahead * HEAVY)
	print("walking: %.2f m/s free, %.2f m/s hauling; eyes %.3f m lower; %.1f stamina spent, %.1f free"
		% [free.pace, hauling.pace, free.eye - hauling.eye, hauling.spent, free.spent])
	check(hauling.pace < free.pace * (1.0 - t.haul_slow * 0.8), "hauling, you walk slower (%.2f of %.2f m/s)"
		% [hauling.pace, free.pace])
	check(free.eye - hauling.eye > t.haul_sink * 0.8, "and sink in (%.3f m)" % (free.eye - hauling.eye))
	check(hauling.spent > free.spent + t.haul_stamina_drain * 0.6 * 2.0, "and tire faster (%.1f stamina against %.1f)"
		% [hauling.spent, free.spent])
	var sprinting := await _walk(flat, ahead, ["move_forward", "sprint"], -ahead * t.sprint_speed)
	check(sprinting.sink > 0.9, "sprinting against a pull that takes your whole pace digs you in all the way (%.2f)"
		% sprinting.sink)

	player.set_meta(&"rope_drag", Vector3.ZERO)
	await simulate(2.0)
	check(player.sink < 0.02 and absf(player.camera.position.y - free.rest) < 0.005,
		"the load gone, you come back up (sink %.3f)" % player.sink)

	for case: Array in [["pulled along", ["move_forward"], ahead * HEAVY],
			["a light pull", ["move_forward"], -ahead * 0.2], ["standing", [], -ahead * HEAVY]]:
		var felt := await _walk(flat, ahead, case[1], case[2])
		check(felt.sink < 0.02, "%s doesn't dig you in (%.3f)" % [case[0], felt.sink])
	player.remove_meta(&"rope_drag")
	set_rate(60)


## Two seconds holding keys while a line drags you at `drag`, set fresh each
## tick as the rope sets it: your own pace, your eyes at rest and, as the ticks
## hold them, over the last second (the drawn bob sits lower the faster you go),
## the sink and the stamina spent.
func _walk(flat: Dictionary, ahead: Vector2, keys: Array, drag: Vector2) -> Dictionary:
	player.set_meta(&"rope_drag", Vector3.ZERO)
	await place(flat.x, flat.z, ahead)
	player.stamina = world.tuning.stamina_max * 0.5
	var seen := {"rest": player.camera.position.y, "eye": 0.0, "spent": player.stamina, "ticks": 0}
	hold(keys)
	await simulate(1.0, func() -> void: player.set_meta(&"rope_drag", Vector3(drag.x, 0.0, drag.y)))
	await simulate(1.0, func() -> void:
		player.set_meta(&"rope_drag", Vector3(drag.x, 0.0, drag.y))
		seen.eye += player.feel.steady_eye().y
		seen.ticks += 1)
	seen.eye /= seen.ticks
	seen.pace = player.own.length()
	seen.sink = player.sink
	seen.spent -= player.stamina
	hold([])
	return seen
