extends SailProbe
## Sailing probe 12: the sheet draws the boom, the wind takes it out. A camp
## moored across a steady 10 m/s wind, its sail up and its sheet at your
## waist: reeling in takes line in through the block at the boom's end and
## the boom comes in after it over two seconds, the sheet taut and pulling
## the whole way, never a jump. Paying out, the wind takes the boom out after
## the line until the sheet holds it again. With no wind, paying out leaves
## the boom where it is and the sheet hangs slack, till the wind comes back.


func run() -> void:
	await load_sailing()
	rig(open, heading(), &"skates", 1, false)
	moor()
	blow(downwind * 10.0)
	hoist(60.0)
	course = heading()
	follow(deck.global_position + Vector3(0.0, 0.0, 6.0))
	var sheet := Scenarios.sheet_to_waist(world, mast)
	look(eye(), Line._tip(sheet.ends[0]).global_position)
	await _hold_for(4.0)
	var reel := hands.reel
	check(mast.sheeted() and mast.sheet_n > 0.0 and absf(rad_to_deg(absf(mast.boom) - mast.trimmed_to())) < 1.0,
		"the wind holds the boom out against its sheet (%.0f°, %d N)" % [rad_to_deg(absf(mast.boom)), roundi(mast.sheet_n)])

	# Reeling in: line through the block, the boom drawn in after it.
	var seen := _watch()
	check(reel.notch(8), "the reel works the sheet at your waist")
	await _hold_for(3.0, func() -> void: _note(seen))
	print("reeled in 2 m: the boom %.0f° to %.0f° over %.2f s, at most %.2f° a tick, %.1f° off the line at most, the sheet %d to %d N" % [
		seen.from, rad_to_deg(absf(mast.boom)), seen.moving, seen.most_tick, seen.off, roundi(seen.least_n), roundi(seen.most_n)])
	check(seen.moving > 1.5 and seen.most_tick < 1.5, "the boom comes in over time, never in a step (%.2f s, %.2f° a tick)" % [seen.moving, seen.most_tick])
	check(seen.least_n > 0.0 and seen.off < 2.0, "the sheet pulls it the whole way, taut (%d N at least)" % roundi(seen.least_n))

	# Paying out: the wind takes it out after the line.
	seen = _watch()
	check(reel.notch(-8), "the reel pays the sheet out")
	await _hold_for(3.0, func() -> void: _note(seen))
	print("paid out 2 m: the boom %.0f° to %.0f° over %.2f s, %.1f° behind the line at most, the sheet taut again at %d N" % [
		seen.from, rad_to_deg(absf(mast.boom)), seen.moving, seen.off, roundi(mast.sheet_n)])
	check(seen.moving > 1.5 and mast.sheet_n > 0.0 and absf(rad_to_deg(absf(mast.boom) - mast.trimmed_to())) < 1.0,
		"the wind takes it out after the line, till the sheet holds it again")

	# No wind: paying out leaves it, the sheet slack.
	await _haul_to(30.0)
	blow(Vector2.ZERO)
	await _hold_for(2.0)
	var was := absf(mast.boom)
	check(reel.notch(-4), "paying out in still air")
	await _hold_for(2.0)
	var slack := mast.trim - 2.0 * Mast.BOOM * sin(absf(mast.boom) * 0.5)
	print("in still air, paid out 1 m: the boom %.0f° to %.0f°, the sheet %.2f m slack, %d N" % [
		rad_to_deg(was), rad_to_deg(absf(mast.boom)), slack, roundi(mast.sheet_n)])
	check(absf(absf(mast.boom) - was) < deg_to_rad(3.0) and slack > 0.8 and mast.sheet_n == 0.0,
		"with no wind the boom stays and the sheet hangs slack (%.2f m)" % slack)
	blow(downwind * 10.0)
	await _hold_for(2.0)
	check(mast.sheet_n > 0.0 and absf(mast.boom) > was + deg_to_rad(15.0), "the wind back, it takes the boom out to its sheet (%.0f°)" % rad_to_deg(absf(mast.boom)))


## Ticks with the camp held to its heading and you standing where you are.
func _hold_for(seconds: float, each := Callable()) -> void:
	await simulate(seconds, func() -> void:
		_steer()
		if each.is_valid():
			each.call())


func _watch() -> Dictionary:
	return {"from": rad_to_deg(absf(mast.boom)), "was": absf(mast.boom), "moving": 0.0, "most_tick": 0.0, "off": 0.0,
		"least_n": INF, "most_n": 0.0}


## A tick of the boom: how long it moves, its biggest step, how far it strays
## from where its sheet's inboard holds it, and what the sheet pulls.
func _note(seen: Dictionary) -> void:
	var now := absf(mast.boom)
	var moved := absf(now - seen.was)
	if moved > deg_to_rad(0.05):
		seen.moving += 1.0 / 60.0
	seen.most_tick = maxf(seen.most_tick, rad_to_deg(moved))
	seen.was = now
	if hands.reel.rope != null and absf(hands.reel.wanted - hands.reel.rope.length) > 1e-4:
		seen.off = maxf(seen.off, rad_to_deg(absf(now - mast.trimmed_to())))
		seen.least_n = minf(seen.least_n, mast.sheet_n)
		seen.most_n = maxf(seen.most_n, mast.sheet_n)


## Reeled to hold the boom near this swing, degrees.
func _haul_to(degrees: float) -> void:
	var notches := roundi((mast.trim - 2.0 * Mast.BOOM * sin(deg_to_rad(degrees) * 0.5)) / Reel.NOTCH)
	hands.reel.notch(notches)
	await _hold_for(absf(notches) * Reel.NOTCH / Reel.PACE + 1.5)
