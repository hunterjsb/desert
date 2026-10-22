class_name PodProbe
extends DeckProbe
## For pod probes: the real ship and its staged stores hanging over the sand,
## sealed and landed beside you through the same calls the opening makes.

var ship: SurveyorShip
var state: Dictionary


func board_ship() -> Dictionary:
	ship = SurveyorShip.new()
	world.add_child(ship)
	ship.setup(world, Transform3D(Basis.IDENTITY, world.player.global_position + Vector3.UP * 60.0))
	state = {"phase": &"preflight", "preflight": {"version": 1, "launched": false},
		"landing_point": Sphere.point(world.moon.latitude, world.moon.longitude),
		"landing_world": Vector2(world.player_world_x() + 6.0, world.player_world_z()), "heading": 0.0}
	return PreflightCargo.stage(world, ship, state)


## Seals what is aboard at these odds and lands it beside you.
func drop(odds := {}) -> Dictionary:
	state = PreflightCargo.seal(world, ship, state, SurveyorManifest.approach(world.tuning, &"standard").merged(odds, true))
	check(not state.is_empty(), "the staged pod seals")
	return {} if state.is_empty() else SurveyorRecovery.land(world, state)
