extends StaticBody3D

func _set_transform(pos: Vector3, rotation_y: float, scale_factor: float):
	global_transform.origin = pos
	rotation_degrees.y = rotation_y
	scale *= Vector3(scale_factor, scale_factor, scale_factor)
