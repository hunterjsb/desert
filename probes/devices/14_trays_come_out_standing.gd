extends HandsProbe
## Devices probe 14: trays come out standing. Standing a step and a half off
## a floating crate's side, a look at its frame's lower edge, or just under
## it, is a look at its tray: use there still sets the crate resting, and
## take takes the tray out. A look at the frame's middle still takes hold of
## the crate.

## Aims this far over the frame's lower edge, or under it, m.
const AIMS := [0.12, 0.05, -0.1, -0.18]


func run() -> void:
	await load_hands()
	var crate := device(&"crate_frame", spot(0.0, -4.0), world.tuning.hover_height)
	fit_part(crate, &"battery")
	var tray := fit_part(crate, &"hover_tray")
	await simulate(3.0)
	var foot := crate.global_position + crate.global_basis.x * 1.9
	var eye_at := Vector3(foot.x, world.height_under(foot) + world.player.camera.position.y, foot.z)
	var edge := func(over: float) -> Vector3: return crate.global_transform * Vector3(0.4, -0.25 + over, 0.0)
	for over: float in AIMS:
		look(eye_at, edge.call(over))
		await simulate(1.0 / 60.0)
		check(hands.look_socket != null and hands.look_socket.part == tray,
			"aimed %+d cm off the frame's lower edge, you look at the tray" % roundi(over * 100.0))
	look(eye_at, edge.call(0.05))
	await simulate(1.0 / 60.0)
	check(hands.interact() and crate.resting, "use at the lower edge sets the crate resting")
	check(hands.interact() and not crate.resting, "and floating again")
	look(eye_at, crate.global_position)
	await simulate(1.0 / 60.0)
	check(hands.grab() and hands.grasp.body == crate, "take at the frame's middle takes hold of the crate")
	hands.grab()
	look(eye_at, edge.call(0.05))
	await simulate(1.0 / 60.0)
	check(hands.grab() and hands.held == tray and hands.phase == Hands.Phase.TAKING,
		"take at the lower edge takes the tray out")
