extends SailProbe
## A camp's ordinary hook can hold the same kite; recovering it preserves the line.


func run() -> void:
	await load_sailing()
	blow(downwind * 9.0)
	var camp := Catalog.device(&"chassis") as Chassis
	world.content.add_child(camp)
	camp.global_position = open + Vector3.UP * 0.5
	fit_part(camp, &"hook")
	camp.freeze = true
	var kite := Catalog.device(&"salvage_kite") as SalvageKite
	world.content.add_child(kite)
	kite.global_position = open + Vector3.UP * 2.0
	var line := Line.between(world, kite.bridle(), camp.free_tie(kite.global_position), 1.0)
	line.full = world.tuning.traction_line_m
	line.rope.full = line.full
	check(kite.use(world.player, kite.global_position), "the camp's line launches the kite")
	await simulate(35.0)
	var height := kite.global_position.y - world.height_under(kite.global_position)
	var apart := kite.global_position.distance_to(camp.global_position)
	print("camp kite %.1f m aloft, %.1f m from its hook; %.1f N" % [height, apart, line.rope.tension])
	metric("camp flight height", height, "m")
	metric("camp pull", line.rope.tension, "N")
	check(height > 15.0 and apart < line.full * 1.15, "the kite flies high over camp on its ordinary line")
	check(line.rope.tension > 10.0, "the camp hook bears real pull")
	# Recover in a lull with the ordinary line in hand, then free that hand.
	blow(downwind * 4.0)
	var tail := camp.take(line.ends[1].socket)
	hands.hold(tail)
	check(hands.reel.notch(220), "the ordinary rope in hand reels the kite back")
	speed_up(4)
	await simulate(65.0)
	speed_up(1)
	check(world.player.waist.take_from_hands(), "the recovered line ties at the waist")
	var camera := world.player.camera
	check(camera.global_position.distance_to(kite.global_position) < world.tuning.reach,
		"ordinary reeling brings the kite within reach")
	look(camera.global_position, kite.global_position)
	await physics_frames(3)
	check(hands.interact() and not kite.flying, "the reachable kite folds through the ordinary use action")
	check(kite.laid() == line and world.ropes.ropes.has(line.rope), "folding preserves the rope and both attachments")
	check(kite.carryable and not kite.flying, "the recovered kite can be carried")
	var full := line.full
	check(kite.use(world.player, kite.global_position), "the same line launches again")
	check(kite.laid() == line and line.full == full, "relaunch does not create or consume another line")
