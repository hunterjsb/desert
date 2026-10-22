extends SailingAidProbe
## Automatic steering works the same limited helm, and yields to the rider.

func run() -> void:
	await aid_rig(&"hover_tray")
	for z in 2:
		var frame := Catalog.device(&"chassis") as Chassis
		deck.join(frame, ring(deck, Vector2i(1, z), Vector2i.RIGHT), 0)
		Stick.put(deck, frame, Chassis.BOTTOM, Vector2.ZERO, 0.0, Catalog.part(&"keel"))
	var helm := Catalog.device(&"helm_seat") as Helm
	Stick.put(deck, Rig.piece(deck, Vector2i(2, 1)), Chassis.TOP, Vector2(-0.2, 0.2), 0.0, helm)
	var player := world.player
	player.set_physics_process(true)
	player.collision_layer = 1
	player.collision_mask = 1
	check(helm.interact(player) and player.helm == helm, "the sailor sits at the real helm")
	course = Vector2.ZERO
	computer.sailing.choose(computer, SailingAid.Mode.STEER)
	speed_up(4)
	var peak := {"spin": 0.0}
	await simulate(18.0, func() -> void: peak.spin = maxf(peak.spin, absf(deck.angular_velocity.y)))
	var ideal := computer.sailing.ideal
	print("STEER mode=%d aboard=%s heel=%.1f spin=%.3f heading=%s wanted=%s health=%s boom=%.1f" % [computer.sailing.mode, player.helm == helm, heel(), peak.spin, SailingIdeal.heading_of(deck), ideal.get("heading", Vector2.ZERO), player.vitals.health, rad_to_deg(mast.boom)])
	check(not ideal.is_empty() and SailingIdeal.heading_of(deck).dot(ideal.heading) > 0.9,
		"the real helm brings the keeled rig toward the recommended heading")
	check(peak.spin <= world.tuning.helm_turn + 0.3 and player.helm == helm, "computer steering stays within the existing helm's working turn")
	Input.action_press(&"move_right")
	await physics_frames(4)
	Input.action_release(&"move_right")
	check(computer.sailing.mode == SailingAid.Mode.TRIM, "the rider's manual turn takes steering back")
