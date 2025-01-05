extends Control

@onready var camera_3d: Camera3D = $Camera3D
@onready var body_3d: Node3D = $Shield/Mesh0
@export var rotation_speed := 0.5

var is_rotating = false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			print("MBLEFTPRESSED")
			if event.pressed:
				# 1) Check if the click hits our 3D body
				if _is_mouse_over_body(event.position):
					print("Start rotating!")
					is_rotating = true
			else:
				# Left mouse button released - stop rotating
				print("Stop rotating!")
				is_rotating = false

	elif event is InputEventMouseMotion and is_rotating:
		# 2) Rotate the body as the mouse moves
		var mouse_delta = event.relative
		print("Rotating: ", mouse_delta)

		# Rotate horizontally around the Y-axis
		body_3d.rotate_y(-mouse_delta.x * rotation_speed)

		# Rotate vertically around the X-axis
		body_3d.rotate_x(-mouse_delta.y * rotation_speed)

func _is_mouse_over_body(screen_pos: Vector2) -> bool:
	"""
	Raycast from the camera into the 3D world to see if we hit 'body_3d'.
	"""
	var from = camera_3d.project_ray_origin(screen_pos)
	var to = from + camera_3d.project_ray_normal(screen_pos) * 1000.0

	# Create the raycast parameters
	var query = PhysicsRayQueryParameters3D.new()
	query.from = from
	query.to = to

	# Perform the raycast
	var space_state = camera_3d.get_world_3d().direct_space_state
	var result = space_state.intersect_ray(query)

	print("Raycast result: ", result)

	# Check if the ray hit the target object
	if result.has("collider"):
		print("Hit object: ", result.collider)
		if result.collider == body_3d:
			return true

	return false
