extends SailingAidProbe
## Reading the ideal in hand mode leaves the passive rig's physical leg unchanged.

func run() -> void:
	var legs := []
	for advice: bool in [false, true]:
		await aid_rig()
		computer.set_physics_process(advice)
		speed_up(4)
		var from := place()
		await sail_for(12.0)
		legs.append({"distance": progress(from, course), "speed": way(), "boom": mast.boom, "length": sheet_line.rope.length})
		if not advice:
			await reset_aid_world()
	print("HAND MODE legs: ", legs)
	check(absf(legs[0].distance - legs[1].distance) < 0.05 and (legs[0].speed as Vector2).distance_to(legs[1].speed) < 0.03
		and absf(legs[0].boom - legs[1].boom) < 0.01 and legs[0].length == legs[1].length,
		"the displayed advice adds no force, motion or rope adjustment")
