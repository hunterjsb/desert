extends InteractableBody3D

@export var wind_manager: Node3D
@export var wind_force_multiplier: float = 1.0

@export var plant_slots_large: int = 1
@export var plant_slots_small: int = 4

# Hover physics properties (from bubbleplanter_mesh.gd)
@export var float_height = 2.0
@export var float_stiffness = 15.0
@export var float_damping = 5.0
@export var align_with_slope = true
@export var rotation_smooth_speed = 0.1

# Since we extend InteractableBody3D, self is the RigidBody3D now
@onready var hover_audio = $HoverSound
@onready var raycast_down: RayCast3D = $RayCast3D
@onready var tether_component: TetherComponent = null
@onready var planting_component: PlantingComponent = null

# Hover physics state (from bubbleplanter_mesh.gd)
var last_normal = Vector3.UP
var hover_enabled = true

var debug_label: Label3D = null
var debug_enabled: bool = false

func _ready() -> void:
	# Since we extend InteractableBody3D, self is the RigidBody3D
	# Set hover physics properties
	linear_damp = 0.2
	angular_damp = 0.2
	hover_audio.play()
	
	# Add tether component
	tether_component = preload("res://src/components/TetherComponent.gd").new()
	add_child(tether_component)
	
	# Get planting component reference
	planting_component = get_node_or_null("PlantingComponent")
	
	# Create debug label
	debug_label = Label3D.new()
	debug_label.text = "Planter: 0/5 slots"
	debug_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	debug_label.visible = false
	add_child(debug_label)
	
	# Connect to debug manager
	if DebugManager:
		DebugManager.debug_display_toggled.connect(_on_debug_toggled)
		debug_enabled = DebugManager.is_debug_enabled()


func _process(_delta: float) -> void:
	# Always apply wind forces - tethered objects can still be affected by wind
	var wind_vector = wind_manager.get_wind_vector() / 2
	apply_central_force(wind_vector * wind_force_multiplier)
	
	# Update debug display
	if debug_label and debug_enabled and planting_component:
		var status = planting_component.get_planting_status()
		var info_lines = []
		
		info_lines.append("Planter: %s" % status.status_text)
		
		for crop in status.crops:
			var time_left = crop.time_remaining
			info_lines.append("%s: %.1fs left" % [crop.crop_type, time_left])
		
		debug_label.text = "\n".join(info_lines)
		debug_label.global_position = global_position + Vector3(0, 2, 0)

func _integrate_forces(_state: PhysicsDirectBodyState3D):
	# Only apply hover physics if hover mode is enabled
	if not hover_enabled:
		return
	
	if raycast_down.is_colliding():
		# Get collision data
		var collision_point = raycast_down.get_collision_point()
		var collision_normal = raycast_down.get_collision_normal()
		var current_distance = global_transform.origin.distance_to(collision_point)

		# Smooth the normal to reduce jitter
		collision_normal = last_normal.lerp(collision_normal, 0.2).normalized()
		last_normal = collision_normal

		# Calculate hover force
		var distance_error = float_height - current_distance
		var up_vel = linear_velocity.dot(collision_normal)
		var force = collision_normal * (distance_error * float_stiffness - up_vel * float_damping)
		apply_central_force(force)

		if align_with_slope:
			# Align with terrain slope (simplified from original)
			var current_up = global_transform.basis.y.normalized()
			var target_up = collision_normal
			
			if abs(current_up.dot(target_up)) > 0.99:
				target_up = (target_up + Vector3(0.01, 0, 0.01)).normalized()

			var current_forward = global_transform.basis.z.normalized()
			var right_dir = target_up.cross(current_forward).normalized()
			var new_forward = right_dir.cross(target_up).normalized()

			if current_forward.dot(new_forward) < 0.0:
				new_forward = -new_forward
				right_dir = -right_dir

			var new_basis = Basis(right_dir, target_up, new_forward).orthonormalized()
			var current_quat = global_transform.basis.get_rotation_quaternion()
			var target_quat = new_basis.get_rotation_quaternion()
			var slerped_quat = current_quat.slerp(target_quat, rotation_smooth_speed)
			global_transform.basis = Basis(slerped_quat).orthonormalized()

func interact(_player: Node):
	# Toggle hover mode
	hover_enabled = not hover_enabled
	
	if hover_enabled:
		hover_audio.play()
	else:
		hover_audio.stop()

func try_pickup(_player: Node):
	return false

func _on_debug_toggled(enabled: bool) -> void:
	debug_enabled = enabled
	if debug_label:
		debug_label.visible = enabled

func get_tether_component() -> TetherComponent:
	return tether_component
