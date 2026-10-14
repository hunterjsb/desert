class_name Player
extends CharacterBody3D
## The scavenger on foot. Walks at about 5 km/h, sprints on stamina, and pays for
## every climb. Never moves where the ground has no collision yet.

var world: World
var stamina: float
## Dev only: F4 flies through the world, for checking the far view.
var flying := false

var _tuning := Tuning.current()
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var camera: Camera3D = $Camera3D


func _ready() -> void:
	stamina = _tuning.stamina_max


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event.is_action_pressed("dev_fly"):
		flying = not flying
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * _tuning.mouse_sensitivity)
		camera.rotation.x = clampf(camera.rotation.x - event.relative.y * _tuning.mouse_sensitivity,
			-1.5, 1.5)


func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if flying:
		var boost := 5.0 if Input.is_action_pressed("sprint") else 1.0
		global_position += camera.global_basis * Vector3(input.x, 0.0, input.y) \
			* _tuning.dev_fly_speed * boost * delta
		velocity = Vector3.ZERO
		return
	if world == null or not world.has_ground_under(global_position):
		velocity = Vector3.ZERO
		return

	var direction := (global_basis * Vector3(input.x, 0.0, input.y)).normalized()
	var moving := direction != Vector3.ZERO
	var sprinting := moving and Input.is_action_pressed("sprint") and stamina > 0.0
	var speed := _tuning.sprint_speed if sprinting else _tuning.walk_speed
	var climb := 0.0
	if moving:
		climb = maxf(0.0, world.height_under(global_position + direction) \
			- world.height_under(global_position))
		speed *= maxf(0.4, 1.0 - climb * _tuning.uphill_slowdown)
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	velocity.y = 0.0 if is_on_floor() else velocity.y - _gravity * delta
	move_and_slide()

	if sprinting:
		stamina -= _tuning.stamina_sprint_drain * delta
	if climb > 0.0:
		stamina -= climb * _tuning.stamina_uphill_drain * delta
	if not sprinting and climb == 0.0:
		stamina += _tuning.stamina_regen * delta
	stamina = clampf(stamina, 0.0, _tuning.stamina_max)

	Dev.put("player/stamina", stamina)
	Dev.put("player/speed_kmh", Vector2(velocity.x, velocity.z).length() * 3.6)
	Dev.put("player/flying", flying)
