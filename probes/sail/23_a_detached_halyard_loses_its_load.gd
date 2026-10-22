extends SailProbe
## The halyard is the hoisted cloth's load path: it pulls with the cloth's
## weight, and once the sail is off it carries nothing.

func run() -> void:
	await load_sailing()
	rig(open, heading())
	deck.freeze = true
	var winch := Catalog.device(&"hand_winch") as ManualWinch
	Stick.put(deck, Rig.piece(deck, Vector2i(1, 0)), Chassis.TOP, Vector2.ZERO, 0.0, winch)
	await physics_frames(3)
	var rope := mast.rig_hoist(winch).rope
	hoist(45.0)
	var cloth := mast.sail().mass * world.tuning.gravity
	await physics_frames(3)
	check(absf(rope.tension - cloth) < 0.05 * cloth, "the hoisted cloth's weight pulls on its halyard (%.1f of %.1f N)" % [rope.tension, cloth])
	mast.take(mast._sail_socket())
	await physics_frames(3)
	# What's left is the line's own weight.
	check(rope.tension < 0.1 * cloth and mast.sail() == null, "the detached halyard carries no cloth (%.2f N)" % rope.tension)
