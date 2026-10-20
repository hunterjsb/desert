extends SailProbe
## A worked drum raises cloth through its own routed halyard, without trimming.

func run() -> void:
	await load_sailing()
	rig(open, heading())
	deck.freeze = true
	var winch := Catalog.device(&"hand_winch") as ManualWinch
	Stick.put(deck, Rig.piece(deck, Vector2i(1, 0)), Chassis.TOP, Vector2.ZERO, 0.0, winch)
	await physics_frames(3)
	var line := mast.rig_hoist(winch)
	check(line != null, "the rig has a routed halyard")
	if line == null:
		return
	var sheet := mast.sheet()
	var sheet_length := sheet.length
	var target := winch.global_position
	look(target + winch.global_basis * Vector3(0, 0.6, 1.2), target)
	Controls.mouse_free = false
	await physics_frames(2)
	world.counts_deeds = true
	for i in 16:
		press(&"reel_in")
	await simulate(5.0)
	check(mast.raise > 0.95 and absf(sheet.length - sheet_length) < 0.001,
		"wheel input raises the cloth without shortening the sheet")
	check(get_node(^"/root/Profile").did(&"hand_hoist"), "working the actual halyard earns All Hands")
	var height := mast.raise
	await simulate(0.4)
	check(absf(mast.raise - height) < 0.001, "the drum brake holds without more input")
	winch.take(winch.frame_sockets()[0])
	await simulate(1.8)
	check(mast.raise < 0.01, "disconnecting the halyard lowers the sail")
