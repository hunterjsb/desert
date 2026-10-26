extends "res://look/paint/paint.gd"
## The kit in a camp, far away and inside its lit storm bubble.
func _dress() -> void:
	super._dress()
	var ids := [&"deep_planter", &"burner", &"turbine", &"condenser", &"light_panel", &"console", &"cargo", &"survival_kit", &"bedroll"]
	for i in ids.size():
		_set_down(Catalog.device(ids[i]), Vector3(-2.6 + (i % 3) * 1.5, 0, -2.2 - (i / 3) * 1.3), 0.0)
func _shots() -> Array:
	var focus := Vector3(0, 0.6, -1)
	return [["camp20", "midmorning", focus + Vector3(12, 3.4, 15).normalized() * 20.0, focus],
		["bubble", "storm", Vector3(0.9, 1.7, 3.5), Vector3(0, 0.5, -1)]]
