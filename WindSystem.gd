extends Node3D

@export var wind_direction: Vector3 = Vector3(1, 0, 0) # Wind blowing along X axis by default
@export_range(0.0,10.0,0.1) var wind_strength: float = 2.0

func _process(delta: float):
	# Optionally, add dynamic wind changes here.
	# For example:
	# wind_direction = wind_direction.rotated(Vector3.UP, delta * 0.1)
	# wind_strength = 2.0 + sin(TIME) * 0.5
	pass
