# bubbleplanter.gd
extends RigidBody3D

@export var float_height = 2.0       # desired hover height above terrain
@export var float_stiffness = 15.0   # how strong the "spring" force is
@export var float_damping = 5.0      # how quickly it stabilizes
@export var align_with_slope = true  # if true, align with terrain slope

@onready var raycast_down: RayCast3D = $RayCast3D


func _integrate_forces(state: PhysicsDirectBodyState3D):
	if raycast_down.is_colliding():
		var collision_point = raycast_down.get_collision_point()
		var collision_normal = raycast_down.get_collision_normal()
		var current_distance = global_transform.origin.distance_to(collision_point)

		# The difference between our desired hover height and the current distance
		var distance_error = float_height - current_distance

		# "Spring" force pushing us away from the ground
		# The formula is basically F = (distance_error * float_stiffness) - (velocity * damping)
		# We'll measure the velocity in the "up" (collision_normal) direction to apply damping.
		var up_vel = linear_velocity.dot(collision_normal)
		var force = collision_normal * (distance_error * float_stiffness - up_vel * float_damping)

		apply_central_force(force)

		if align_with_slope:
			# Optionally align the body "up" axis with the terrain normal
			# Note: This does a quick alignment. You may want to smoothly lerp the rotation 
			# for a gentler effect.
			var up_dir = collision_normal.normalized()
			# We'll treat the current "right" vector as basis.x, and "forward" as basis.z
			# so that we can reconstruct a new basis that has 'up_dir' as the y-axis.
			var forward_dir = -global_transform.basis.z
			var right_dir = up_dir.cross(forward_dir).normalized()
			forward_dir = right_dir.cross(up_dir).normalized()

			var new_basis = Basis(
				right_dir,
				up_dir,
				forward_dir
			)
			# If you want an immediate snap, do:
			global_transform.basis = new_basis
			# For smoother transitions, you can slerp the rotation basis over time.
