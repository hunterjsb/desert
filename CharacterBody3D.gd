extends CharacterBody3D

#==> EXPORT <==#
@export var speed = 5
@export var jump_speed = 5
@export var mouse_sensitivity = 2

# Sprinting parameters
@export var sprint_multiplier = 1.8

# Gait (sway/bob) parameters
@export var walk_sway_intensity = 0.04
@export var walk_sway_frequency = 2.0
@export var sprint_sway_intensity = 0.08
@export var sprint_sway_frequency = 2.5

# Jump / Crouch / Slide parameters
@export var crouch_speed = 3
@export var crouch_offset = 0.4           # how far camera moves down when crouching
@export var slide_duration = 0.6          # seconds the slide lasts
@export var slide_boost_multiplier = 1.2  # slide speed = sprint speed * this
@export var slide_cooldown = 0.2          # small delay before you can slide again (optional)

# HP
var max_health = 100
var current_health = 100

# Movement / gravity
var gravity = 0.0                 # <-- Gravity is now set by default
var walk_cycle_time = 0.0
var original_camera_local_pos
var is_sprinting = false

# bubble shield counters
var inside_bubble_count: int = 0
var is_in_bubble_shield: bool = false

# item carrying
var carried_item: Node3D = null
var carried_item_type: String = ""
var is_carrying_item: bool = false

# RayCast for item detection
@onready var ray = $Camera3D/RayCast3D

# UI's
@onready var menu = preload("res://menu.tscn").instantiate()
@onready var hud = preload("res://hud.tscn").instantiate()

# Movement states
var can_move = true
var on_hoverboard = false
var last_highlighted_item: Node = null

# Crouch / Slide states
var is_crouching = false
var is_sliding = false
var slide_timer = 0.0
var slide_on_cooldown = false
var slide_cooldown_timer = 0.0


func _ready():
	# Instantiate and attach HUD
	add_child(hud)
	_update_health_bar()

	# Lock mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	original_camera_local_pos = $Camera3D.transform.origin

	# Example: spawn a shield in player's hand
	var shield_scene = preload("res://src/shield.tscn")
	var start_shield = shield_scene.instantiate().get_node("Mesh0")
	pick_up_item(start_shield)
	carried_item_type = "shield"

	# Connect bubble shield signals
	for shield in get_tree().get_nodes_in_group("bubble_shield"):
		shield.player_entered_bubble.connect(_on_player_entered_bubble)
		shield.player_exited_bubble.connect(_on_player_exited_bubble)

	menu.name = "Menu"
	add_child(menu)
	menu.hide()


func _physics_process(delta):
	if not can_move:
		return  # Don't move if menu is open

	# Handle slide cooldown
	if slide_on_cooldown:
		slide_cooldown_timer -= delta
		if slide_cooldown_timer <= 0:
			slide_on_cooldown = false

	# Check item under crosshair
	var collider = get_ray_collider("interactable")
	if collider and collider != carried_item:
		if collider != last_highlighted_item and last_highlighted_item:
			reset_outline(last_highlighted_item)
		apply_outline(collider)
		last_highlighted_item = collider
	else:
		if last_highlighted_item:
			reset_outline(last_highlighted_item)
			last_highlighted_item = null

	# Apply gravity
	velocity.y -= gravity * delta

	# Jump if on the floor
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_speed

	# Determine base move speed
	var base_speed = speed
	# If crouched (and not sliding)
	if is_crouching and not is_sliding:
		base_speed = crouch_speed

	# Check sprint
	is_sprinting = Input.is_action_pressed("sprint") and not is_crouching
	var current_speed = base_speed
	if is_sprinting:
		current_speed *= sprint_multiplier

	# Sliding logic
	if is_sliding:
		slide_timer -= delta
		if slide_timer > 0:
			# Force forward velocity
			var forward_dir = transform.basis.z
			forward_dir.y = 0
			forward_dir = forward_dir.normalized()
			# Slight speed boost over normal sprint
			var boosted_speed = speed * sprint_multiplier * slide_boost_multiplier
			velocity.x = -forward_dir.x * boosted_speed
			velocity.z = -forward_dir.z * boosted_speed
		else:
			# End the slide
			is_sliding = false
			slide_on_cooldown = true
			slide_cooldown_timer = slide_cooldown
	else:
		# Normal movement if not sliding
		var input_dir = Input.get_vector("a", "d", "w", "s")
		var direction = transform.basis * Vector3(input_dir.x, 0, input_dir.y)
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed

	# Move the player
	move_and_slide()

	# Footstep sounds
	if is_on_floor():
		var horizontal_vel = Vector2(velocity.x, velocity.z).length()
		if horizontal_vel > 0.1:
			if not $FootstepAudio.playing:
				$FootstepAudio.play()
		else:
			if $FootstepAudio.playing:
				$FootstepAudio.stop()
	else:
		if $FootstepAudio.playing:
			$FootstepAudio.stop()

	# Camera sway: disable it if sliding
	var hv = Vector2(velocity.x, velocity.z).length()
	if is_sliding:
		_reset_camera_sway()  # keep camera stable while sliding
	elif hv > 0.1 and is_on_floor():
		walk_cycle_time += delta * hv
		_update_camera_sway()
	else:
		_reset_camera_sway()

	# Update camera position if crouched
	_update_crouch_height()


func _input(event):
	if event.is_action_pressed("esc"):
		if menu:
			menu.toggle_menu()
			can_move = !can_move
		Input.mouse_mode = (
			Input.MOUSE_MODE_CAPTURED
			if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE
			else Input.MOUSE_MODE_VISIBLE
		)

	# Mouse look
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity / 1000)
		$Camera3D.rotate_x(-event.relative.y * mouse_sensitivity / 1000)
		$Camera3D.rotation.x = clampf($Camera3D.rotation.x, -deg_to_rad(70), deg_to_rad(70))

	# 1) PICK UP OR THROW ITEM
	if event.is_action_pressed("throw_shield"):
		if is_carrying_item:
			throw_item()
		else:
			var collider = get_ray_collider("interactable")
			if collider:
				pick_up_item(collider)

	# 2) INTERACT WITH THE CARRIED ITEM
	elif event.is_action_pressed("interact"):
		if is_carrying_item and carried_item:
			interact_with_item(carried_item)
		else:
			var collider2 = get_ray_collider("interactable")
			if collider2:
				interact_with_item(collider2)

	# Crouch
	if event.is_action_pressed("crouch"):
		# If sprinting and on floor and not on cooldown -> Slide
		if is_sprinting and is_on_floor() and not is_sliding and not slide_on_cooldown:
			is_sliding = true
			is_crouching = false  # typically, we stay at lower collision, but let's keep it simple
			slide_timer = slide_duration
		else:
			# Normal crouch
			is_crouching = true

	if event.is_action_released("crouch"):
		# If sliding, let the timer handle it
		if not is_sliding:
			is_crouching = false


#
# ==> Crouch Height
#
func _update_crouch_height():
	# Basic approach: If crouching, lower camera; if not, restore
	var cam_transform = $Camera3D.transform
	var target_y = original_camera_local_pos.y

	if is_crouching or is_sliding:
		target_y = original_camera_local_pos.y - crouch_offset

	# Lerp the current camera height to target for smooth transition
	var current_cam_pos = cam_transform.origin
	current_cam_pos.y = lerp(current_cam_pos.y, target_y, 0.2)  # 0.2 = smoothing factor
	cam_transform.origin = current_cam_pos
	$Camera3D.transform = cam_transform


#
# ==> Ray Check
#
func get_ray_collider(group: String) -> Node:
	if ray.is_colliding():
		var collider = ray.get_collider()
		if collider and collider.is_in_group(group):
			return collider
	return null


#
# ==> PICKUP / THROW / INTERACT <==
#
func pick_up_item(item: Node3D):
	if item.get_parent():
		item.get_parent().remove_child(item)
	$Camera3D/HandPoint.add_child(item)
	item.transform = Transform3D()
	item.rotation_degrees = Vector3(90, 0, 0)

	if item is RigidBody3D:
		item.freeze = true

	carried_item = item
	is_carrying_item = true
	
	if "on_pickup" in item:
		item.on_pickup(self)
	if "item_type" in item:
		carried_item_type = item.item_type
	else:
		carried_item_type = "unknown"


func throw_item():
	# Remove from hand and put back in the world
	$Camera3D/HandPoint.remove_child(carried_item)
	get_parent().add_child(carried_item)
	carried_item.global_transform = $Camera3D/HandPoint.global_transform

	if carried_item is RigidBody3D:
		carried_item.freeze = false
		# Use the camera’s forward vector (XYZ throw, includes pitch)
		var throw_dir = -$Camera3D.global_transform.basis.z.normalized()
		carried_item.apply_central_impulse(throw_dir * 5.0)

	carried_item = null
	carried_item_type = ""
	is_carrying_item = false


func interact_with_item(item: Node3D):
	if "interact" in item:
		item.interact(self)
	else:
		print("Item does not implement interact().")


#
# ==> Outline Helpers
#
func apply_outline(obj: Node):
	var mesh = find_mesh_instance(obj)
	if mesh and mesh.material_overlay:
		var mat = mesh.material_overlay
		if mat is ShaderMaterial:
			mat.set_shader_parameter("border_width", 0.03)


func reset_outline(obj: Node):
	var mesh = find_mesh_instance(obj)
	if mesh and mesh.material_overlay:
		var mat = mesh.material_overlay
		if mat is ShaderMaterial:
			mat.set_shader_parameter("border_width", 0.0)


func find_mesh_instance(obj: Node) -> MeshInstance3D:
	# Recursively search for first MeshInstance3D in hierarchy
	if obj is MeshInstance3D:
		return obj
	for child in obj.get_children():
		var result = find_mesh_instance(child)
		if result:
			return result
	return null


#
# ==> TERRAIN READY (HOVERBOARD SPAWN) <==
#
func _on_terrain_map_ready():
	gravity = 9.8
	var hoverboard_scene = preload("res://hoverboard.tscn")
	var hoverboard = hoverboard_scene.instantiate()
	var spawn_offset = Vector3(2, 1, 0)
	var spawn_position = global_transform.origin + spawn_offset
	get_parent().add_child(hoverboard)
	hoverboard.call_deferred("set_global_position", spawn_position)


#
# ==> CAMERA SWAY <==
#
func _update_camera_sway():
	var intensity = sprint_sway_intensity if is_sprinting else walk_sway_intensity
	var frequency = sprint_sway_frequency if is_sprinting else walk_sway_frequency

	var vertical_offset = sin(walk_cycle_time * frequency) * intensity
	var horizontal_offset = sin(walk_cycle_time * frequency * 0.5) * intensity * 0.5
	$Camera3D.transform.origin.x = original_camera_local_pos.x + horizontal_offset
	$Camera3D.transform.origin.y = $Camera3D.transform.origin.y + vertical_offset
	# We only sway X/Y; Z remains as is to preserve forward/back offset.


func _reset_camera_sway():
	# Reset just the X offset, not the crouch Y offset
	$Camera3D.transform.origin.x = original_camera_local_pos.x
	# We'll keep $Camera3D.transform.origin.y as set by crouch logic.


#
# ==> HEALTH/BUBBLE LOGIC <==
#
func take_damage(amount: int) -> void:
	current_health -= amount
	if current_health < 0:
		current_health = 0
		# TODO: handle Player death or game-over
	_update_health_bar()


func _update_health_bar() -> void:
	if hud and hud.has_node("ProgressBar"):
		var health_bar = hud.get_node("ProgressBar")
		health_bar.value = current_health


func _on_player_entered_bubble(player: Node) -> void:
	if player == self:
		inside_bubble_count += 1
		if inside_bubble_count > 0:
			_set_in_bubble(true)


func _on_player_exited_bubble(player: Node) -> void:
	if player == self:
		inside_bubble_count -= 1
		if inside_bubble_count <= 0:
			inside_bubble_count = 0
			_set_in_bubble(false)


func _set_in_bubble(value: bool) -> void:
	is_in_bubble_shield = value
	print("Player is_in_bubble_shield: ", is_in_bubble_shield)
