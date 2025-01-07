extends CharacterBody3D

@export var fall_damage_threshold = -10.0
@export var fall_damage_multiplier = 2.0
var peak_fall_speed: float = 0.0

@export var speed = 5
@export var jump_speed = 5
@export var mouse_sensitivity = 2

@export var sprint_multiplier = 1.8

@export var walk_sway_intensity = 0.05
@export var walk_sway_frequency = 2.0
@export var sprint_sway_intensity = 0.08
@export var sprint_sway_frequency = 2.5

@export var crouch_speed = 3
@export var crouch_offset = 0.4
@export var slide_duration = 0.6
@export var slide_boost_multiplier = 1.2
@export var slide_cooldown = 0.2

var max_health = 100
var current_health = 100

@export var gravity = 0.0
var walk_cycle_time = 0.0
var original_camera_local_pos
var is_sprinting = false

var inside_bubble_count: int = 0
var is_in_bubble_shield: bool = false
var is_in_storm: bool = false

var carried_item: Node3D = null
var carried_item_type: String = ""
var is_carrying_item: bool = false

@onready var ray = $Camera3D/RayCast3D

@onready var menu = preload("res://menu.tscn").instantiate()
@onready var hud = preload("res://hud.tscn").instantiate()

var can_move = true
var on_hoverboard = false
var last_highlighted_item: Node = null

var is_crouching = false
var is_sliding = false
var slide_timer = 0.0
var slide_on_cooldown = false
var slide_cooldown_timer = 0.0

@export var AmbientAudio : AudioStreamPlayer3D

# Index of the low-pass filter effect on the Storm bus (adjust if needed)
var storm_filter_effect_index = 0

func _ready():
	add_child(hud)
	_update_health_bar()
	AmbientAudio.play()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	original_camera_local_pos = $Camera3D.transform.origin

	var starter_shield: InteractableBody3D = preload("res://src/object/shield/shield01.tscn").instantiate()
	starter_shield.pickup(self)
	starter_shield.energy = 10_000
	
	# Connect bubble shield signals
	for shield in get_tree().get_nodes_in_group("bubble_shield"):
		shield.player_entered_bubble.connect(_on_player_entered_bubble)
		shield.player_exited_bubble.connect(_on_player_exited_bubble)


func _physics_process(delta):
	if not can_move:
		return

	if velocity.y < peak_fall_speed:
		peak_fall_speed = velocity.y  
	if peak_fall_speed < -3 and is_on_floor():  
				$LandingAudio.play()
				peak_fall_speed = 0.0  
	
	# Slide cooldown
	if slide_on_cooldown:
		slide_cooldown_timer -= delta
		if slide_cooldown_timer <= 0:
			slide_on_cooldown = false

	# HOVER LOGIC (highlight + show label if has energy)
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

	# Gravity
	velocity.y -= gravity * delta

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_speed

	# Base move speed
	var base_speed = speed
	if is_crouching and not is_sliding:
		base_speed = crouch_speed

	# Sprint
	is_sprinting = Input.is_action_pressed("sprint") and not is_crouching
	var current_speed = base_speed
	if is_sprinting:
		current_speed *= sprint_multiplier

	# Slide logic
	if is_sliding:
		slide_timer -= delta
		if slide_timer > 0:
			var forward_dir = transform.basis.z
			forward_dir.y = 0
			forward_dir = forward_dir.normalized()
			var boosted_speed = speed * sprint_multiplier * slide_boost_multiplier
			velocity.x = -forward_dir.x * boosted_speed
			velocity.z = -forward_dir.z * boosted_speed
		else:
			$SlideAudio.stop()
			is_sliding = false
			slide_on_cooldown = true
			slide_cooldown_timer = slide_cooldown
	else:
		# Normal input
		var input_dir = Input.get_vector("a", "d", "w", "s")
		var direction = transform.basis * Vector3(input_dir.x, 0, input_dir.y)
		# print(direction.x, current_speed)
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

	# Camera sway
	var hv = Vector2(velocity.x, velocity.z).length()
	if is_sliding:
		_reset_camera_sway()
	elif hv > 0.1 and is_on_floor():
		walk_cycle_time += delta * hv
		_update_camera_sway()
	else:
		_reset_camera_sway()

	# Crouch camera adjust
	_update_crouch_height()

func _input(event):
	# Mouse look
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity / 1000)
		$Camera3D.rotate_x(-event.relative.y * mouse_sensitivity / 1000)
		$Camera3D.rotation.x = clampf($Camera3D.rotation.x, -deg_to_rad(70), deg_to_rad(70))

	# Pan Gesture Rotation for Held Items
	if event is InputEventPanGesture and is_carrying_item:
		var pan_delta = event.get_delta()
		if pan_delta.x != 0.0:
			rotate_held_item(pan_delta.x * 0.01)
		if pan_delta.y != 0.0:
			rotate_held_item(pan_delta.y * 0.01, "x")

	# 1) PICK UP OR THROW ITEM
	if event.is_action_pressed("throw_shield"):
		if is_carrying_item:
			throw_item()
		else:
			var obj: InteractableBody3D = get_ray_collider("interactable")
			if obj:
				var can_pickup = obj.try_pickup(obj)
				obj.pickup(self) if can_pickup else print("TOO WEAK")

	# 2) INTERACT
	elif event.is_action_pressed("interact"):
		if is_carrying_item and carried_item:
			interact_with_item(carried_item)
		else:
			var collider2 = get_ray_collider("interactable")
			if collider2:
				interact_with_item(collider2)

	# Crouch / Slide
	if event.is_action_pressed("crouch"):
		if is_sprinting and is_on_floor() and not is_sliding and not slide_on_cooldown:
			is_sliding = true
			is_crouching = false
			slide_timer = slide_duration
			$SlideAudio.play()
		else:
			is_crouching = true

	if event.is_action_released("crouch"):
		if not is_sliding:
			is_crouching = false


func rotate_held_item(direction: float, axis: String = "y") -> void:
	var angle_deg = direction * 90.0
	var angle_rad = deg_to_rad(angle_deg)

	if axis == "y":
		carried_item.rotate_y(angle_rad)
	elif axis == "x":
		carried_item.rotate_x(angle_rad)
	elif axis == "z":
		carried_item.rotate_z(angle_rad)


func _update_crouch_height():
	var cam_transform = $Camera3D.transform
	var target_y = original_camera_local_pos.y
	if is_crouching or is_sliding:
		target_y = original_camera_local_pos.y - crouch_offset

	var current_cam_pos = cam_transform.origin
	current_cam_pos.y = lerp(current_cam_pos.y, target_y, 0.2)
	cam_transform.origin = current_cam_pos
	$Camera3D.transform = cam_transform


func get_ray_collider(group: String) -> Node:
	if ray.is_colliding():
		var collider = ray.get_collider()
		if collider and collider.is_in_group(group):
			return collider
	return null


#
# ==> PICKUP / THROW / INTERACT <==
#
func throw_item():
	$Camera3D/HandPoint.remove_child(carried_item)
	get_parent().add_child(carried_item)
	carried_item.global_transform = $Camera3D/HandPoint.global_transform

	if carried_item is RigidBody3D:
		carried_item.freeze = false
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
# ==> SHIELD LABEL VISIBILITY ON HOVER <==
#
func apply_outline(obj: Node):
	var mesh = find_mesh_instance(obj)
	if mesh and mesh.material_overlay:
		var mat = mesh.material_overlay
		if mat is ShaderMaterial:
			mat.set_shader_parameter("border_width", 0.03)

	if "set_energy_label_visible" in obj:
		obj.set_energy_label_visible(true)


func reset_outline(obj: Node):
	var mesh = find_mesh_instance(obj)
	if mesh and mesh.material_overlay:
		var mat = mesh.material_overlay
		if mat is ShaderMaterial:
			mat.set_shader_parameter("border_width", 0.0)

	if "set_energy_label_visible" in obj:
		obj.set_energy_label_visible(false)


func find_mesh_instance(obj: Node) -> MeshInstance3D:
	if obj is MeshInstance3D:
		return obj
	for child in obj.get_children():
		var result = find_mesh_instance(child)
		if result:
			return result
	return null

#
# ==> HOVERBOARD / TERRAIN
#
func _on_terrain_map_ready():
	gravity = 9.8
	
	var hoverboard = preload("res://src/object/hoverboard/hoverboard.tscn").instantiate()
	var spawn_offset = Vector3(2, 1, 0)
	var spawn_position = global_transform.origin + spawn_offset
	get_parent().add_child(hoverboard)
	hoverboard.call_deferred("set_global_position", spawn_position)
	
	var bplanter = preload("res://src/object/bubbleplanter.tscn").instantiate()
	bplanter.wind_manager = $"../Environment/WindManager"
	var bp_spawn_offset = Vector3(2, -1, 1)
	var bp_spawn_position = global_transform.origin + bp_spawn_offset
	get_parent().add_child(bplanter)
	bplanter.call_deferred("set_global_position", bp_spawn_position)


#
# ==> CAMERA SWAY
#
func _update_camera_sway():
	var intensity = sprint_sway_intensity if is_sprinting else walk_sway_intensity
	var frequency = sprint_sway_frequency if is_sprinting else walk_sway_frequency

	var vertical_offset = sin(walk_cycle_time * frequency) * intensity
	var horizontal_offset = sin(walk_cycle_time * frequency * 0.5) * intensity * 0.5
	$Camera3D.transform.origin.x = original_camera_local_pos.x + horizontal_offset
	$Camera3D.transform.origin.y = $Camera3D.transform.origin.y + vertical_offset


func _reset_camera_sway():
	$Camera3D.transform.origin.x = original_camera_local_pos.x
	# We'll keep the Y offset from crouch logic.


#
# ==> HEALTH/BUBBLE LOGIC
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
	update_storm_audio()
	print("Player is_in_bubble_shield: ", is_in_bubble_shield)
	
func calculate_fall_damage():
	var fall_damage = (peak_fall_speed + fall_damage_threshold) * fall_damage_multiplier
	if fall_damage > 0:
		print("Player took ", fall_damage, " fall damage.")
		fall_damage = 0


#
# ==> AUDIO CONTROL FOR STORM BUS
#
func update_storm_audio() -> void:
	var storm_bus_idx = AudioServer.get_bus_index("Storm")

	# If the player is inside the bubble shield:
	if is_in_bubble_shield:
		# Enable Low-Pass filter effect on the Storm bus (assumes effect is at index storm_filter_effect_index)
		AudioServer.set_bus_volume_db(storm_bus_idx, -18.0)  # turn volume down
		AudioServer.set_bus_effect_enabled(storm_bus_idx, storm_filter_effect_index, true)
	
	# If the player is in the storm but NOT inside the bubble
	elif is_in_storm and not is_in_bubble_shield:
		AudioServer.set_bus_volume_db(storm_bus_idx, 0.0)  # normal volume
		AudioServer.set_bus_effect_enabled(storm_bus_idx, storm_filter_effect_index, false)
	
	# If the player isn't in the storm at all
	else:
		AudioServer.set_bus_volume_db(storm_bus_idx, 0.0)   # normal volume (or fade out if you prefer)
		AudioServer.set_bus_effect_enabled(storm_bus_idx, storm_filter_effect_index, false)
