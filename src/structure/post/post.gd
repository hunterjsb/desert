extends StaticBody3D

@onready var tether_component: TetherComponent = null

func _ready() -> void:
	# Find the tether component
	tether_component = get_node_or_null("TetherComponent")

func _set_transform(pos: Vector3, rotation_y: float, scale_factor: float):
	global_transform.origin = pos
	rotation_degrees.y = rotation_y
	scale *= Vector3(scale_factor, scale_factor, scale_factor)

func get_tether_component() -> TetherComponent:
	return tether_component
