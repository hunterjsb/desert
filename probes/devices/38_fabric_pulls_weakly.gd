extends DeckProbe
## Devices & mods probe 38: fabric is a crude sail. On a floating deck with a
## mast, fabric on a frame facing aft is pushed by a wind from astern and
## draws the deck downwind with the sail furled, but weakly: under a quarter
## of what the sail raised on the same deck pulls in the same wind.

const WIND := 10.0


func run() -> void:
	await load_lines()
	var rig := Rig.build(world.content, [[&"piece", Vector2i(1, 0)],
		[&"stick", Vector2i(0, 0), &"bottom", Vector2.ZERO, 0.0, &"hover_tray"],
		[&"stick", Vector2i(1, 0), &"bottom", Vector2.ZERO, 0.0, &"hover_tray"],
		[&"stick", Vector2i(0, 0), &"top", Vector2.ZERO, 180.0, [&"mast", [&"sail"]], &"mast"],
		[&"stick", Vector2i(0, 0), &"top", Vector2(0.3, 0.3), 0.0, &"big_battery"],
		[&"frame", Vector2i(1, 0), 0]])
	var deck := rig.deck
	var mast: Mast = rig.named[&"mast"]
	deck.global_position = flat_spot(0.0, 8.0, 4.0) + Vector3.UP * deck.rest_height()
	await simulate(1.5)
	# Aft, the way its boom lies back from the mast; fabric on the frame's face that way.
	var aft := (mast.global_transform * Vector3(0.0, 0.3, -Mast.BOOM) - mast.global_transform * Vector3(0.0, 0.3, 0.0)).normalized()
	var facing: Socket = null
	for side: StringName in [&"front", &"back", &"left", &"right"]:
		var face := Rig.face_of(deck, Vector2i(1, 0), side)
		if facing == null or (deck.global_basis * face.transform.basis.z).dot(aft) > (deck.global_basis * facing.transform.basis.z).dot(aft):
			facing = face
	deck.fit(Catalog.part(&"fabric"), facing)
	await simulate(0.5)

	blow(Vector2(-aft.x, -aft.z) * WIND)
	await simulate(3.0 / 60.0)
	var fabric := deck.faces.pushes[0].dot(-aft)
	await simulate(2.0)
	var drawn := deck.linear_velocity.dot(-aft)
	check(fabric > 0.0 and drawn > 0.3, "the fabric draws the deck downwind (%.0f N, %.2f m/s)" % [fabric, drawn])

	blow(Vector2.ZERO)
	deck.linear_velocity = Vector3.ZERO
	deck.angular_velocity = Vector3.ZERO
	await simulate(0.5)
	mast.raised = true
	mast.raise = 1.0
	blow(Vector2(-aft.x, -aft.z) * WIND)
	var sail := 0.0
	for i in 90:
		await get_tree().physics_frame
		sail = maxf(sail, mast.force.dot(-aft))
	check(fabric < sail * 0.25, "but weakly: under a quarter of the sail's pull (%.0f against %.0f N)" % [fabric, sail])
