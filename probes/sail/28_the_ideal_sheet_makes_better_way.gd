extends SailingAidProbe
## A Console tending the actual sheet makes better way than leaving it fixed.

func run() -> void:
	var distances := []
	for aided: bool in [false, true]:
		await aid_rig()
		computer.sailing.choose(computer, SailingAid.Mode.TRIM if aided else SailingAid.Mode.HAND)
		speed_up(4)
		var from := place()
		await sail_for(26.0)
		distances.append(progress(from, course))
		metric("Trimmed leg" if aided else "Fixed-sheet leg", distances[-1], "m")
		print("SAILING IDEAL %s distance=%.3f speed=%.3f boom=%.1f" % ["trimmed" if aided else "fixed", distances[-1], way().length(), rad_to_deg(mast.boom)])
		if not aided:
			await reset_aid_world()
	check(distances[1] > distances[0] + 2.0 and distances[1] > distances[0] * 1.15,
		"working the recommended sheet beats the fixed sheet over the same leg")
