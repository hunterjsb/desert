extends Node3D

var radio: Node3D
@onready var detection_area: Area3D = $DetectionArea


func _set_transform(position: Vector3, rotation_y: float, scale_factor: float):
	global_transform.origin = position
	rotation_degrees.y = rotation_y
	scale *= Vector3(scale_factor, scale_factor, scale_factor)

func spawn_loot(position: Vector3):
	radio = preload("res://src/object/radio.tscn").instantiate()
	get_parent().add_child(radio)
	radio.call_deferred("set_global_position", position)
	radio.call_deferred("freeze")

func _on_body_entered(body: Node3D) -> void:
	if radio:
		radio.unfreeze()
