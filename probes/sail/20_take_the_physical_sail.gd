extends SailProbe
## The physical spar must remain a removable fitted sail through the hands.

func run() -> void:
	await load_sailing()
	rig(open, heading(), &"skates", 1, false)
	deck.freeze = true
	await physics_frames(3)
	var cloth := mast.sail()
	var target := mast._boom_body.global_transform * (Mast.BOOM_AT + Vector3(0, 0, -1.6))
	look(target + mast.global_basis.x * 1.2, target)
	await physics_frames(2)
	check(hands.grab(), "taking the physical boom responds")
	await simulate(0.6)
	check(hands.held == cloth and mast.sail() == null, "taking the visible spar removes its sail, not the mast")
