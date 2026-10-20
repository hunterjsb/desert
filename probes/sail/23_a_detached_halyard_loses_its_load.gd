extends SailProbe
## Cloth weight is not left on an ordinary line after its sail is removed.

func run() -> void:
	await load_sailing()
	rig(open, heading())
	deck.freeze = true
	var winch := Catalog.device(&"hand_winch") as ManualWinch
	Stick.put(deck, Rig.piece(deck, Vector2i(1, 0)), Chassis.TOP, Vector2.ZERO, 0.0, winch)
	await physics_frames(3)
	var line := mast.rig_hoist(winch)
	await physics_frames(3)
	var rope := line.rope
	check(rope.haul_n > 0.0, "the connected halyard bears cloth weight")
	mast.take(mast._sail_socket())
	check(rope.haul_n == 0.0, "removing the sail immediately clears its owned hoist load")
	await physics_frames(3)
	check(rope.haul_n == 0.0 and mast.sail() == null,
		"the detached ordinary line carries no phantom cloth load")
