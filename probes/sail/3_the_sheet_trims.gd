extends SailProbe
## Sailing probe 3: the sheet trims the drive. Steered on a beam reach in a
## steady 10 m/s wind, its sheet tended to meet the wind well it sails
## fastest; eased right out it spills the wind and barely moves, and hauled
## in flat it stalls and slows. Reeling the sheet at your waist takes its
## inboard in through the block at the boom's end a notch at a time, the line
## to you no shorter and the coil at your waist growing by it; letting go of
## the sheet spills the wind.


func run() -> void:
	await load_sailing()
	speed_up(4)
	var speed := {}
	for degrees: float in [85.0, -1.0, 0.0]:
		rig(open, heading())
		blow(downwind * 10.0)
		hoist(60.0 if degrees < 0.0 else degrees)
		course = heading()
		tending = deg_to_rad(15.0) if degrees < 0.0 else 0.0
		await sail_for(20.0)
		speed[degrees] = way().dot(heading())
		print("%s: %.2f m/s" % ["tended" if degrees < 0.0 else "swung out at most %d°" % degrees, speed[degrees]])
		deck.free()
		follow(open)
		await settle(true)
	tending = 0.0
	check(speed[-1.0] > 2.5 * maxf(speed[85.0], 0.1), "eased right out it spills the wind (%.2f against %.2f)" % [speed[85.0], speed[-1.0]])
	check(speed[-1.0] > 2.0 * maxf(speed[0.0], 0.1), "hauled in flat it stalls (%.2f)" % speed[0.0])

	# The sheet to your waist: reeling hauls the sail, not the line.
	rig(open, heading(), &"skates", 1, false)
	blow(downwind * 10.0)
	hoist(35.0)
	follow(deck.global_position + Vector3(0.0, 0.0, 6.0))
	var sheet := Scenarios.sheet_to_waist(world, mast)
	hands.reel.choose(sheet.ends[1])
	await physics_frames(2)
	trim(35.0)
	var length := sheet.rope.length
	var coiled := sheet.full - length
	check(hands.reel.notch(2), "the reel works the sheet at your waist")
	await simulate(1.0)
	check(absf(length - sheet.rope.length - 2.0 * Reel.NOTCH) < 0.01
		and absf(sheet.full - sheet.rope.length - coiled - 2.0 * Reel.NOTCH) < 0.01,
		"two notches take in half a metre of actual sheet and gather it on the coil")
	world.player.waist.untie(sheet.ends[1])
	await sail_for(2.0)
	check(not mast.sheeted() and absf(mast.boom) > deg_to_rad(60.0), "let go, the sheet runs and the sail swings free (%.0f°)" % rad_to_deg(mast.boom))
	speed_up(1)
