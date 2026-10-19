extends SailProbe
## Rope & tethering probe 18: use unties the same waist line as the reel,
## even after turning toward another line and saving during the untie delay.


func run() -> void:
	await load_sailing()
	rig(open, heading(), &"skates", 1, false)
	hoist(35.0)
	follow(deck.global_position + Vector3(0.0, 0.0, 6.0))
	var sheet := Scenarios.sheet_to_waist(world, mast)
	var me := world.player.global_position
	var stake := driven_stake(me + flat(me - deck.global_position).normalized() * 3.0)
	var moored := Scenarios.to_waist(world, stake.free_tie(me))
	await physics_frames(2)
	look(eye(), Line._tip(sheet.ends[0]).global_position)
	await physics_frames(2)
	var sheet_readout := hands.reel.waist_readout()
	check(hands.reel.waist_body() == sheet.ends[1] and not sheet_readout.is_empty(),
		"the sheet is selected for the reel and its live readout")
	check(hands.interact() and world.player.waist._taking == sheet.ends[1],
		"use starts untying that sheet, even though the stake line was tied last")
	look(eye(), stake.global_position + Stake.RING)
	await physics_frames(2)
	check(hands.reel.waist_body() == moored.ends[1] and hands.reel.waist_readout() != sheet_readout,
		"looking along the other line selects it and shows a different readout")
	hands._show(1.0)
	check(hands._readout.text.contains(hands.reel.waist_readout()), "the selected line appears in the hands readout")
	check(get_node(^"/root/Saves").save(world), "saved during the untie delay")
	check(await resume(), "resumed")
	await simulate(world.tuning.untie_seconds + 0.4)
	check(is_instance_valid(hands.held) and Mast.sheet_end(hands.held)
		and world.player.waist.tied.size() == 1 and not Mast.sheet_end(world.player.waist.tied[0]),
		"the sheet you began untying comes to hand; the other line stays at your waist")
