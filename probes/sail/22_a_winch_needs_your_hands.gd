extends SailProbe
## A manual drum stops drawing when its operator stops attending it.

func run() -> void:
	await load_sailing()
	rig(open, heading())
	deck.freeze = true
	var winch := Catalog.device(&"hand_winch") as ManualWinch
	Stick.put(deck, Rig.piece(deck, Vector2i(1, 0)), Chassis.TOP, Vector2.ZERO, 0.0, winch)
	await physics_frames(3)
	var laid := mast.rig_hoist(winch)
	look(winch.global_position + winch.global_basis * Vector3(0, 0.6, 1.2), winch.global_position)
	await physics_frames(2)
	winch.notch(10, world.player)
	await simulate(0.25)
	var started := laid.rope.length
	look(eye(), eye() + Vector3.UP)
	await physics_frames(3)
	var stopped := laid.rope.length
	await simulate(0.7)
	check(stopped < laid.full and absf(laid.rope.length - stopped) < 0.001
		and started - stopped <= world.tuning.winch_pace_mps * 0.06,
		"looking away cancels queued winding; the brake holds the reached length")
