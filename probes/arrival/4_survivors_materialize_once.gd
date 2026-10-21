extends DeckProbe
## Each resolved survivor is one physical object, including the board's own fitted cell.
func run() -> void:
	await load_lines()
	var at := Vector2(world.player_world_x() + 6.0, world.player_world_z())
	var state := SurveyorManifest.resolve(1234, world.start, {"frame_survival": 1.0, "outer_survival": 1.0, "extra_survival": 1.0})
	state.landing_world = at
	state.heading = 0.4
	state.exit_world = at + Vector2(-3.0, 1.0)
	var made := SurveyorRecovery.materialize(world, state)
	var expected: int = state.structure.size() + state.equipment.size()
	check(state.get("materialized", false) and made.size() == expected, "all surviving roles materialize as physical objects")
	if made.size() != expected:
		return
	check((made[&"board"] as Device).battery() == made[&"board_cell"], "the board owns its resolved cell")
	var record: Dictionary = state.equipment.filter(func(e: Dictionary) -> bool: return e.uid == &"board_cell")[0]
	check(is_equal_approx(made[&"board_cell"].charge_wh / made[&"board_cell"].capacity(), record.state.charge_fraction), "its resolved charge is applied")
	check(made[&"hatch"].deck == null and made[&"roof_a"].deck == null, "real exit panels are open and reusable")
	var count := world.content.get_child_count()
	var twice := SurveyorRecovery.materialize(world, state)
	check(twice == made and world.content.get_child_count() == count, "materializing again returns the same objects without grants")
