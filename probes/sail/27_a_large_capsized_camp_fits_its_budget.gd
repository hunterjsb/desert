extends LargeCampProbe
## Runs alone
## A real loaded 108-frame camp settles on its chassis and mast within budget.

const BUDGET_MS := 12.0

func run() -> void:
	await large_camp()
	deck.global_basis = Basis(Vector3.FORWARD, deg_to_rad(100.0))
	var low := INF
	var points := PackedVector3Array()
	var clearances := PackedFloat32Array()
	deck.frame_contact_points(points, clearances, 0.0)
	for point in points:
		low = minf(low, point.y - world.height_under(point))
	deck.global_position.y += 0.5 - low
	deck.linear_velocity = Vector3.ZERO
	deck.angular_velocity = Vector3.ZERO
	await sail_for(6.0)
	await measure("Large capsized camp", BUDGET_MS)
	check(heel() > 70.0, "the measured camp stays capsized")

	check(sunk() < 0.2, "the large camp rests above the sand")
	world.shift_origin(Vector2i(3, -2))
	await sail_for(1.0)
	check(sunk() < 0.2 and deck.angular_velocity.length() < 0.3,
		"contacts stay supported after the origin shifts")
