class_name SurveyorArrival
extends Node
## One saved Surveyor opening. Rendering, physical recovery and saves share its state.
var world: World
var restoring := false

func start() -> void:
	pass

func restore() -> void:
	pass

func recover(_body: Node) -> void:
	pass

func active() -> bool:
	return not world.arrival_state.is_empty() and world.arrival_state.get("phase", &"recovery") != &"recovery"
