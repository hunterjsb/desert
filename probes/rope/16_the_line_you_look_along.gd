extends SailProbe
## Rope & tethering probe 16: reeling works the line you mean. A sail's sheet
## and a line to a stake both at your waist: choosing the sheet reels its
## inboard, and choosing the stake line reels that instead. Looking elsewhere
## cannot change the choice; without one, no line is worked.


func run() -> void:
	await load_sailing()
	rig(open, heading(), &"skates", 1, false)
	hoist(35.0)
	follow(deck.global_position + Vector3(0.0, 0.0, 6.0))
	var sheet := Scenarios.sheet_to_waist(world, mast)
	await physics_frames(2)
	trim(35.0)
	var me := world.player.global_position
	var stake := driven_stake(me + flat(me - deck.global_position).normalized() * 3.0)
	var moored := Scenarios.to_waist(world, stake.free_tie(me))
	check(world.player.waist.tied.size() == 2, "the stake's line is at your waist beside the sheet")

	look(eye(), Line._tip(sheet.ends[0]).global_position)
	check(hands.reel.line() == null and not hands.reel.notch(2) and not world.player.waist.give_back(),
		"without a choice, no rope reels or unties")
	hands.reel.choose(sheet.ends[1])
	var drawn := await _reeled(moored)
	check(absf(drawn.trim - 2.0 * Reel.NOTCH) < 0.01 and absf(drawn.line) < 0.01,
		"choosing the sheet, reeling trims the sail, the stake's line left be (%.2f m, %.2f m)" % [drawn.trim, drawn.line])
	look(eye(), stake.global_position + Vector3.UP * 0.3)
	check(hands.reel.line() == sheet.rope, "looking elsewhere keeps the chosen sheet")
	hands.reel.choose(moored.ends[1])
	drawn = await _reeled(moored)
	check(absf(drawn.line - 2.0 * Reel.NOTCH) < 0.01 and absf(drawn.trim) < 0.01,
		"choosing the stake's line, reeling draws it in, the trim left be (%.2f m, %.2f m)" % [drawn.line, drawn.trim])
	hands.reel.choose(null)
	world.player.waist.untie(moored.ends[1])
	check(hands.reel.line() == sheet.rope and hands.reel.chosen_body() == null and hands.reel.notch(1),
		"a sole remaining rope reels without creating an explicit choice")


## Two notches on the chosen line: how much the sail's trim and the stake's line each took in, m.
func _reeled(moored: Line) -> Dictionary:
	await physics_frames(2)
	var trim_was := mast.sheet().length
	var line_was := moored.rope.length
	check(hands.reel.notch(2), "there's a line at your waist to reel")
	await simulate(1.0)
	return {"trim": trim_was - mast.sheet().length, "line": line_was - moored.rope.length}
