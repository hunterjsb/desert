extends Node3D
@export var env: Node3D
@onready var mesh = $Mesh1_Mesh1_108

func _ready():
	mesh.env = env
	
func _set_transform(position: Vector3, rotation_y: float, scale_factor: float):
	global_transform.origin = position
	rotation_degrees.y = rotation_y
	scale *= Vector3(scale_factor, scale_factor, scale_factor)


func _set_scale(scale_factor: float):
	scale = Vector3(scale_factor, scale_factor, scale_factor)
