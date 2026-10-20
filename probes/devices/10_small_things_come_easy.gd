extends HandsProbe
## Devices probe 10: small things come easy. Aim at the sand beside a battery
## and it's the one you'd take; two lying together, a wavering aim between them
## settles on one rather than flickering. A condenser needs looking at, and a
## part hidden behind it isn't taken through it.


func run() -> void:
	await load_hands()
	var battery := part(&"battery", Transform3D(Basis.IDENTITY, spot(0.0, 1.2) + Vector3.UP * 0.1))
	var big := device(&"condenser", spot(1.4, 1.0), 0.36)
	var eye_at := spot(0.0, 0.0) + Vector3.UP * 1.65
	var away := Vector3(big.global_position.x - eye_at.x, 0.0, big.global_position.z - eye_at.z).normalized()
	var behind := big.global_position + away * 0.7
	var hidden := part(&"battery", Transform3D(Basis.IDENTITY, Vector3(behind.x, world.height_under(behind) + 0.1, behind.z)))
	await simulate(1.0)

	look(eye_at, battery.global_position + Vector3(0.15, -0.05, 0.0))
	await simulate(2.0 / 60.0)
	check(hands.look_part == battery and hands.grab() and hands.held == battery,
		"aimed at the sand beside a battery, you take it")
	hands.drop()
	await simulate(1.0)

	var other := part(&"battery", Transform3D(Basis.IDENTITY, battery.global_position + Vector3(0.25, 0.0, 0.0)))
	await simulate(1.0)
	var between := (battery.global_position + other.global_position) * 0.5 + Vector3.DOWN * 0.1
	var flips := 0
	var was: Part = null
	for i in 60:
		look(eye_at, between + Vector3(0.03 * sin(i * 1.7), 0.0, 0.0))
		await simulate(1.0 / 60.0)
		if hands.look_part != was and was != null:
			flips += 1
		was = hands.look_part
	check(was != null and flips == 0, "a wavering aim between two settles on one (%d flips)" % flips)

	look(eye_at, big.global_position + Vector3(-0.55, -0.35, 0.0))
	await simulate(2.0 / 60.0)
	check(hands.look_device == null, "aimed at the sand beside a condenser, you're not taking it")
	look(eye_at, hidden.global_position + Vector3(0.1, 0.0, 0.0))
	await simulate(2.0 / 60.0)
	check(hands.look_part != hidden, "nor a battery hidden behind it")
