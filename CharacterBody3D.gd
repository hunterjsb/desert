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

# hp
var max_health = 100
var current_health = 100

# movement
var gravity = 0.0
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

# Movement controls
var can_move = true
var on_hoverboard = false

# Track which item is currently outlined
var last_highlighted_item: Node = null

func _ready():
	# Instantiate and attach HUD
	add_child(hud)
	_update_health_bar()

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	original_camera_local_pos = $Camera3D.transform.origin

	# Example: spawn a shield in the player's hand
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
		return  # Don't move if the menu is open
		
	# Check the item under the crosshair
	var collider = get_ray_collider("interactable")

	# If we are hovering an item AND it's not the one we're carrying -> highlight it
	if collider and collider != carried_item:
		# If we were highlighting a different item, reset it
		if collider != last_highlighted_item and last_highlighted_item:
			reset_outline(last_highlighted_item)
		apply_outline(collider)
		last_highlighted_item = collider
	else:
		# If we are no longer hovering over an item or we are hovering over the carried item
		if last_highlighted_item:
			reset_outline(last_highlighted_item)
			last_highlighted_item = null

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

	# Update gait if moving
	var hv = Vector2(velocity.x, velocity.z).length()
	if hv > 0.1 and is_on_floor():
		walk_cycle_time += delta * hv
		_update_camera_sway()
	else:
		_reset_camera_sway()

func _input(event):
	if event.is_action_pressed("esc"):
		if menu:
			menu.toggle_menu()
			can_move = !can_move
		Input.mouse_mode = (Input.MOUSE_MODE_CAPTURED if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE else Input.MOUSE_MODE_VISIBLE)
		
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
			var collider = get_ray_collider("interactable")
			if collider:
				interact_with_item(collider)

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
	$Camera3D/HandPoint.remove_child(carried_item)
	get_parent().add_child(carried_item)
	carried_item.global_transform = $Camera3D/HandPoint.global_transform

	if carried_item is RigidBody3D:
		carried_item.freeze = false
		var throw_dir = -$Camera3D.transform.basis.z.normalized()
		carried_item.apply_central_impulse(throw_dir * 5.0)

	carried_item = null
	carried_item_type = ""
	is_carrying_item = false

func interact_with_item(item: Node3D):
	if "interact" in item:
		item.interact(self)
	else:
		print("Item does not implement interact().")
		
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
			mat.set_shader_parameter("border_width", 0.0)  # Disable the outline

func find_mesh_instance(obj: Node) -> MeshInstance3D:
	# Recursively search for the first MeshInstance3D in the object's hierarchy
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
	$Camera3D.transform.origin = original_camera_local_pos + Vector3(horizontal_offset, vertical_offset, 0)

func _reset_camera_sway():
	$Camera3D.transform.origin = original_camera_local_pos

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
