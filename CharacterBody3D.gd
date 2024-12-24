extends CharacterBody3D

#==> EXPORT <==#
@export var speed = 5
@export var jump_speed = 5
@export var mouse_sensitivity = 2

# Sprinting parameters
@export var sprint_multiplier = 1.8

# Gait (sway/bob) parameters
@export var walk_sway_intensity = 0.05
@export var walk_sway_frequency = 2.0
@export var sprint_sway_intensity = 0.08
@export var sprint_sway_frequency = 2.5

#==> OTHER <==#
var gravity = 0.0
var walk_cycle_time = 0.0
var original_camera_local_pos
var is_sprinting = false

# Shield
var shield_scene = preload("res://shield.tscn")
var has_shield = true
var carried_shield

@onready var ray = $Camera3D/RayCast3D


func _ready():
	var ui_scene = preload("res://hud.tscn").instantiate()
	add_child(ui_scene)

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	original_camera_local_pos = $Camera3D.transform.origin
	
	# Instantiate the shield and attach it to the player's "hand"
	carried_shield = shield_scene.instantiate()
	carried_shield.freeze = true
	carried_shield.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	$Camera3D/HandPoint.add_child(carried_shield)

func _physics_process(delta):
	# Apply gravity
	velocity.y += -gravity * delta

	# Gather movement input
	var input_dir = Input.get_vector("a", "d", "w", "s")
	var direction = transform.basis * Vector3(input_dir.x, 0, input_dir.y)
	
	# Check sprint
	is_sprinting = Input.is_action_pressed("sprint")
	var current_speed = speed
	if is_sprinting:
		current_speed *= sprint_multiplier
	
	# Move the player
	velocity.x = direction.x * current_speed
	velocity.z = direction.z * current_speed
	move_and_slide()
	
	# Jump
	if is_on_floor() and Input.is_action_just_pressed("ui_accept"):
		velocity.y = jump_speed

	# Update gait if moving
	var horizontal_vel = Vector2(velocity.x, velocity.z).length()
	if horizontal_vel > 0.1 and is_on_floor():
		walk_cycle_time += delta * horizontal_vel
		_update_camera_sway()
	else:
		_reset_camera_sway()

func _input(event):
	# Mouse look
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity / 1000)
		$Camera3D.rotate_x(-event.relative.y * mouse_sensitivity / 1000)
		$Camera3D.rotation.x = clampf($Camera3D.rotation.x, -deg_to_rad(70), deg_to_rad(70))
		
	# Mouse Release/Recapture
	if event.is_action_pressed("esc"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED

	if event.is_action_pressed("throw_shield") and has_shield and carried_shield:
		has_shield = false
		carried_shield.freeze = false
		carried_shield.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
		$Camera3D/HandPoint.remove_child(carried_shield)
		get_parent().add_child(carried_shield)
		carried_shield.global_transform = $Camera3D/HandPoint.global_transform
		var throw_dir = -$Camera3D.transform.basis.z.normalized()
		carried_shield.apply_central_impulse(throw_dir * 5.0)
		carried_shield = null
	elif event.is_action_pressed("throw_shield") and not has_shield and not carried_shield:
		var collider = get_ray_collider("interactable")
		if collider:
			pick_up_shield(collider)
		
	if event.is_action_pressed("interact") and not has_shield:
		var collider = get_ray_collider("interactable")
		if collider:
			collider.toggle_bubble_shield()
		
func get_ray_collider(group: String):
	if ray.is_colliding():
		var collider = ray.get_collider()
		if collider and collider.is_in_group(group):
			return collider

func pick_up_shield(shield):
	shield.get_parent().remove_child(shield)
	$Camera3D/HandPoint.add_child(shield)
	shield.transform = Transform3D()
	shield.collision_layer = 0
	shield.collision_mask = 0
	shield.freeze = true
	shield.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	
	carried_shield = shield
	has_shield = true

func _on_terrain_map_ready():
	gravity = 9.8

func _update_camera_sway():
	var intensity = sprint_sway_intensity if is_sprinting else walk_sway_intensity
	var frequency = sprint_sway_frequency if is_sprinting else walk_sway_frequency
	var vertical_offset = sin(walk_cycle_time * frequency) * intensity
	var horizontal_offset = sin(walk_cycle_time * frequency * 0.5) * intensity * 0.5
	$Camera3D.transform.origin = original_camera_local_pos + Vector3(horizontal_offset, vertical_offset, 0)

func _reset_camera_sway():
	$Camera3D.transform.origin = original_camera_local_pos
