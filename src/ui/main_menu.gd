extends Control

@onready var camera_3d: Camera3D = $MenuScene3D/Camera3D
@onready var body_3d: Node3D = $MenuScene3D/Shield/Mesh0

@export var max_tilt_degrees := 30.0
@export var tilt_lerp_speed := 0.1

func _process(_delta: float) -> void:
	# 1) Find how far the mouse is from the screen's center (normalized to [-1..1])
	var screen_size = get_viewport().get_size()
	var screen_center = screen_size * 0.5
	var mouse_pos = get_viewport().get_mouse_position()

	var offset_x = (mouse_pos.x - screen_center.x) / screen_center.x
	var offset_y = (mouse_pos.y - screen_center.y) / screen_center.y

	# 2) Convert offsets to tilt angles
	#    - Usually, tilt around X is driven by -offset_y (moving mouse up tilts the top away)
	#    - Tilt around Z is driven by offset_x (moving mouse right tilts the right side away)
	var target_rot_x = deg_to_rad(clamp(-offset_y * max_tilt_degrees, -max_tilt_degrees, max_tilt_degrees))
	var target_rot_z = deg_to_rad(clamp(offset_x * max_tilt_degrees, -max_tilt_degrees, max_tilt_degrees))

	# 3) Lerp from current rotation to target rotation for smoothness
	#    Keep Y at 180°, so the front is always facing the camera
	# body_3d.rotation_degrees.y = 180.0
	body_3d.rotation.x = lerp(body_3d.rotation.x, target_rot_x, tilt_lerp_speed)
	body_3d.rotation.z = lerp(body_3d.rotation.z, target_rot_z, tilt_lerp_speed)

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://main.tscn")


func _on_skybox_pressed() -> void:
	get_tree().change_scene_to_file("res://skybox.tscn")
