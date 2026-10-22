extends SailingAidProbe
## Runs alone
## Computer trim reaches its recommendation through a loaded, rate-limited drum.

func run() -> void:
	await aid_rig()
	speed_up(4)
	world.counts_deeds = true
	computer.sailing.choose(computer, SailingAid.Mode.TRIM)
	var seen := {"pace": 0.0, "last": sheet_line.rope.length}
	await sail_for(16.0, func() -> void:
		var length := sheet_line.rope.length
		seen.pace = maxf(seen.pace, absf(length - seen.last) / get_physics_process_delta_time())
		seen.last = length)
	var ideal := computer.sailing.ideal
	check(not ideal.is_empty() and absf(sheet_line.rope.length - ideal.length) < 0.2,
		"the real drum follows the recommended sheet length")
	check(seen.pace <= world.tuning.winch_pace_mps + 0.001, "computer trim obeys the hand drum's pace")
	check(get_node(^"/root/Profile").did(&"sail_by_wire"), "working the loaded sheet earns Learning the Ropes")
	check(drum.notch(1, world.player) and computer.sailing.mode == SailingAid.Mode.HAND,
		"working the hand drum takes authority back from the computer")
	computer.sailing.choose(computer, SailingAid.Mode.TRIM)
	await physics_frames(4)
	for cell in deck.batteries():
		cell.charge_wh = 0.0
	await sail_for(1.0)
	var held := sheet_line.rope.length
	await sail_for(2.0)
	check(computer.sailing.mode == SailingAid.Mode.HAND and absf(sheet_line.rope.length - held) < 0.001,
		"losing Console power leaves the ordinary brake holding its line")
