extends Control

@onready var camera_3d: Camera3D = $MenuScene3D/Camera3D
@onready var rotatables: Array[RigidBody3D] = [$MenuScene3D/Shield/Mesh0, $MenuScene3D/radio/Mesh1_Mesh1_108]
@onready var dev_mode_indicator: Label = $DevModeIndicator
var last_highlighted_item = null

@export var max_tilt_degrees := 30.0
@export var tilt_lerp_speed := 0.1

# Dragging state variables
var is_dragging: bool = false
var dragged_object: RigidBody3D = null
var drag_distance: float = 0.0
var grab_offset_in_object_space: Vector3 = Vector3.ZERO

func _ready() -> void:
	for body_3d in rotatables:
		body_3d.freeze = true
	
	# Connect to dev mode changes and set initial state
	if DebugManager:
		DebugManager.dev_mode_changed.connect(_on_dev_mode_changed)
		dev_mode_indicator.visible = DebugManager.is_dev_mode()
	
func _process(delta: float) -> void:
	# --- Mouse tilt logic ---
	var screen_size = get_viewport().get_size()
	var screen_center = screen_size * 0.5
	var mouse_pos = get_viewport().get_mouse_position()

	var offset_x = (mouse_pos.x - screen_center.x) / screen_center.x
	var offset_y = (mouse_pos.y - screen_center.y) / screen_center.y

	var target_rot_x = deg_to_rad(clamp(-offset_y * max_tilt_degrees, -max_tilt_degrees, max_tilt_degrees))
	var target_rot_z = deg_to_rad(clamp(offset_x * max_tilt_degrees, -max_tilt_degrees, max_tilt_degrees))

	for body_3d in rotatables:
		body_3d.rotation.x = lerp(body_3d.rotation.x, target_rot_x, tilt_lerp_speed)
		body_3d.rotation.z = lerp(body_3d.rotation.z, target_rot_z, tilt_lerp_speed)

	# --- Dragging logic ---
	if is_dragging and dragged_object:
		var ray_origin = camera_3d.project_ray_origin(mouse_pos)
		var ray_direction = camera_3d.project_ray_normal(mouse_pos)
		var target_point = ray_origin + ray_direction * drag_distance
		var global_offset = dragged_object.to_global(grab_offset_in_object_space) - dragged_object.global_transform.origin

		var new_transform = dragged_object.global_transform
		new_transform.origin = target_point - global_offset
		dragged_object.global_transform = new_transform
	else:
		# --- Hover and outline logic ---
		var ray_origin = camera_3d.project_ray_origin(mouse_pos)
		var ray_direction = camera_3d.project_ray_normal(mouse_pos)
		var ray_end = ray_origin + ray_direction * 1000.0

		var space_state = camera_3d.get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
		var result = space_state.intersect_ray(query)

		if result:
			var hit_collider = result.collider
			if rotatables.has(hit_collider):
				if last_highlighted_item != hit_collider:
					if last_highlighted_item:
						reset_outline(last_highlighted_item)
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
	# --- Mouse press/release for dragging ---
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Start dragging if clicking on a highlighted item
				if last_highlighted_item:
					is_dragging = true
					dragged_object = last_highlighted_item
					dragged_object.freeze = false  # Allow movement
					var mouse_pos = get_viewport().get_mouse_position()
					var ray_origin = camera_3d.project_ray_origin(mouse_pos)
					var ray_direction = camera_3d.project_ray_normal(mouse_pos)
					var result = camera_3d.get_world_3d().direct_space_state.intersect_ray(
						PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_direction * 1000)
					)
					if result:
						drag_distance = ray_origin.distance_to(result.position)
						grab_offset_in_object_space = dragged_object.to_local(result.position)
			else:
				# Stop dragging on mouse release
				if is_dragging:
					is_dragging = false
					dragged_object.freeze = true  # Freeze again to prevent physics issues
					dragged_object = null

	# --- Interaction logic ---
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if last_highlighted_item and "interact" in last_highlighted_item:
			last_highlighted_item.interact(self)
		else:
			print("No interact() method on hovered item!")

# --- Outline helper methods ---
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

func _on_start_pressed() -> void:
	# Dev mode is controlled by F3 toggle in DebugManager
	get_tree().change_scene_to_file("res://main.tscn")


func _on_skybox_pressed() -> void:
	get_tree().change_scene_to_file("res://skybox.tscn")

func _on_dev_mode_changed(enabled: bool) -> void:
	dev_mode_indicator.visible = enabled
