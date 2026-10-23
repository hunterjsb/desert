extends LargeCampProbe
## Runs alone
## A real loaded 108-frame camp moving under its sail fits the main thread.

const BUDGET_MS := 12.0

func run() -> void:
	await large_camp()
	deck.rest(false)
	blow(downwind * 12.0)
	course = heading()
	deck.global_basis = Basis(Vector3.UP, atan2(-course.x, -course.y))
	await sail_for(6.0)
	check(mast.raise > 0.9 and mast.force.length() > 1.0, "the physical sail is raised and loaded")
	var cost := await measure("Large sailing camp", BUDGET_MS)
	check(cost.distance > 0.5, "the measured camp actually moves under sail")
