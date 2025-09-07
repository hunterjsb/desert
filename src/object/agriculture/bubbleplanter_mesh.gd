# bubbleplanter.gd
extends InteractableBody3D

@export var float_height = 2.0       # Desired hover height above terrain
@export var float_stiffness = 15.0   # Strength of the "spring" force
@export var float_damping = 5.0      # How quickly it stabilizes
@export var align_with_slope = true  # Align with the terrain slope
@export var rotation_smooth_speed = 0.1  # Slerp factor for smooth rotation

@onready var hoverAudio = $HoverSound
@onready var raycast_down: RayCast3D = $RayCast3D
@onready var rope_scene = preload("res://src/object/rope/Rope.tscn")

# We'll keep track of the last frame's normal to reduce jitter
var last_normal = Vector3.UP
var hover_enabled = true  # Toggle for hover mode

func _ready():
	# A bit of damping to reduce infinite sliding or spinning
	linear_damp = 0.2
	angular_damp = 0.2
	hoverAudio.play()

func _integrate_forces(_state: PhysicsDirectBodyState3D):
	# Only apply hover physics if hover mode is enabled
	if not hover_enabled:
		return
	
	if raycast_down.is_colliding():
		# 1) Get the collision data
		var collision_point = raycast_down.get_collision_point()
		var collision_normal = raycast_down.get_collision_normal()
		var current_distance = global_transform.origin.distance_to(collision_point)

		# 2) Smooth the normal to reduce small bounces in orientation
		collision_normal = last_normal.lerp(collision_normal, 0.2).normalized()
		last_normal = collision_normal

		# 3) Calculate hover force
		var distance_error = float_height - current_distance
		var up_vel = linear_velocity.dot(collision_normal)
		var force = collision_normal * (distance_error * float_stiffness - up_vel * float_damping)
		apply_central_force(force)

		if align_with_slope:
			# --- Rebuild a stable new basis ---

			# a) We'll treat the current up direction as what we want to slerp FROM
			var current_up = global_transform.basis.y.normalized()

			# b) The "target up" is our smoothed collision normal
			var target_up = collision_normal

			# If target_up is extremely close to or opposite current_up, it can cause a flip
			# We'll do a quick check to avoid some degenerate case:
			if abs(current_up.dot(target_up)) > 0.99:
				# If nearly parallel or antiparallel, nudge it a bit
				target_up = (target_up + Vector3(0.01, 0, 0.01)).normalized()

			# c) Our forward direction is derived from the current transform's forward,
			#    then adjusted to remain perpendicular to target_up.
			var current_forward = global_transform.basis.z.normalized()

			# Recompute right and forward
			var right_dir = target_up.cross(current_forward).normalized()
			var new_forward = right_dir.cross(target_up).normalized()

			# d) Make sure we don't accidentally flip forward 180° from one frame to the next.
			#    Check if new_forward is pointing the opposite direction from current_forward.
			if current_forward.dot(new_forward) < 0.0:
				# Flip forward and right to keep a consistent orientation
				new_forward = -new_forward
				right_dir = -right_dir

			# e) Construct the new basis from right, up, forward
			var new_basis = Basis(
				right_dir, 
				target_up, 
				new_forward
			).orthonormalized()

			# f) Slerp from current to target for a smooth transition
			var current_quat = global_transform.basis.get_rotation_quaternion()
			var target_quat = new_basis.get_rotation_quaternion()
			var slerped_quat = current_quat.slerp(target_quat, rotation_smooth_speed)
			global_transform.basis = Basis(slerped_quat).orthonormalized()
	else:
		# If the RayCast doesn’t collide (off a cliff?), apply gravity or do nothing
		pass
		
func try_pickup(_player: Node):
	return false
		
func interact(_player: Node):
	# Toggle hover mode
	hover_enabled = not hover_enabled
	
	if hover_enabled:
		# Enable hover mode
		hoverAudio.play()
		print("BubblePlanter: Hover mode ENABLED")
	else:
		# Disable hover mode - let it settle to ground
		hoverAudio.stop()
		print("BubblePlanter: Hover mode DISABLED")
	
	# Audio feedback for toggle
	# TODO: Add toggle sound effect here if desired
