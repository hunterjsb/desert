extends Control

@onready var camera_3d: Camera3D = $MenuScene3D/Camera3D
# @onready var shield: Node3D = $MenuScene3D/Shield/Mesh0
# I know these are named "MeshX" but they're RigidBody3D's (actually InteracableBody3D's)
# but I can't change the name from the imported fbx model
@onready var rotatables: Array[RigidBody3D] = [$MenuScene3D/Shield/Mesh0, $MenuScene3D/radio/Mesh1_Mesh1_108]
var last_highlighted_item = null

@export var max_tilt_degrees := 30.0
@export var tilt_lerp_speed := 0.1

func _ready() -> void:
	for body_3d in rotatables:
		body_3d.freeze = true
	
func _process(_elta: float) -> void:
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
	for body_3d in rotatables:
		body_3d.rotation.x = lerp(body_3d.rotation.x, target_rot_x, tilt_lerp_speed)
		body_3d.rotation.z = lerp(body_3d.rotation.z, target_rot_z, tilt_lerp_speed)
		
	# Raycast
	# var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera_3d.project_ray_origin(mouse_pos)
	var ray_direction = camera_3d.project_ray_normal(mouse_pos)
	var ray_end = ray_origin + ray_direction * 1000.0

	var space_state = camera_3d.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	var result = space_state.intersect_ray(query)

	if result:
		var hit_collider = result.collider
		# highlight if it's in rotatables
		if rotatables.has(hit_collider):
			if last_highlighted_item != hit_collider:
				# un-highlight previous
				if last_highlighted_item:
					reset_outline(last_highlighted_item)
				# highlight this one
				apply_outline(hit_collider)
				last_highlighted_item = hit_collider
		else:
			if last_highlighted_item:
				reset_outline(last_highlighted_item)
			last_highlighted_item = null
	else:
		if last_highlighted_item:
			reset_outline(last_highlighted_item)
		last_highlighted_item = null

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if last_highlighted_item:
				if "interact" in last_highlighted_item:
					last_highlighted_item.interact(self)
				else:
					print("No interact() method on hovered item!")

# Outline helper methods
func apply_outline(obj: Node) -> void:
	var mesh = find_mesh_instance(obj)
	if mesh and mesh.material_overlay:
		var mat = mesh.material_overlay
		if mat is ShaderMaterial:
			mat.set_shader_parameter("border_width", 0.03)

func reset_outline(obj: Node) -> void:
	var mesh = find_mesh_instance(obj)
	if mesh and mesh.material_overlay:
		var mat = mesh.material_overlay
		if mat is ShaderMaterial:
			mat.set_shader_parameter("border_width", 0.0)

func find_mesh_instance(obj: Node) -> MeshInstance3D:
	if obj is MeshInstance3D:
		return obj
	for child in obj.get_children():
		var found = find_mesh_instance(child)
		if found:
			return found
	return null
