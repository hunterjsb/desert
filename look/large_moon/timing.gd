extends "res://look/sandlight/sandlight.gd"
## Existing alternating GPU measurement, including the apron only in the new draw.
func _wear(look: String) -> void:
	super._wear(look)
	world.terrain._apron.visible = look != "before"
