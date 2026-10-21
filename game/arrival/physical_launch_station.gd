class_name PhysicalLaunchStation
extends Node3D
## The same lit glass is readable while walking and interactive when focused.
signal closed
var ui := LaunchComputer.new()
var viewport := SubViewport.new()
var focused := false
var _world: World
var _ship: SurveyorShip
var _display := MeshInstance3D.new()
var _return_pose := Transform3D.IDENTITY
var _start_pose := Transform3D.IDENTITY
var _target_pose := Transform3D.IDENTITY
var _transition := 1.0
var _leaving := false
var _previous_mouse := Input.MOUSE_MODE_CAPTURED
var _saved_fov := 75.0
const PIXELS := Vector2i(1152, 680)

func setup(world: World, ship: SurveyorShip, plan: Dictionary, changed: Callable) -> void:
	_world = world
	_ship = ship
	viewport.size = PIXELS
	viewport.handle_input_locally = true
	viewport.gui_disable_input = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	ui.setup(world, plan, changed)
	ui.size = PIXELS
	viewport.add_child(ui)
	ui.closed.connect(leave)
	var mesh := QuadMesh.new()
	mesh.size = ship.computer_screen_size()
	_display.mesh = mesh
	_display.transform = ship.computer_screen_pose()
	var glass := StandardMaterial3D.new()
	glass.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glass.albedo_texture = viewport.get_texture()
	_display.material_override = glass
	_display.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_display)

func enter() -> void:
	if focused:
		return
	focused = true
	_leaving = false
	_previous_mouse = Input.mouse_mode
	_return_pose = _world.player.camera.global_transform
	_start_pose = _return_pose
	_saved_fov = _world.player.camera.fov
	_target_pose = _ship.global_transform * _ship.computer_focus_pose()
	_transition = 0.0
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	ui.set_focused(true)

func leave() -> void:
	if not focused or _leaving:
		return
	_leaving = true
	ui.set_focused(false)
	_start_pose = _world.player.camera.global_transform
	_target_pose = _return_pose
	_transition = 0.0
	Input.mouse_mode = _previous_mouse

func _process(delta: float) -> void:
	if not is_instance_valid(_world) or not focused:
		return
	var seconds := float(_world.tuning.surveyor_preflight.get("computer_focus_s", 0.45))
	_transition = minf(_transition + delta / maxf(seconds, 0.001), 1.0)
	_world.player.camera.global_transform = _start_pose.interpolate_with(_target_pose, smoothstep(0.0, 1.0, _transition))
	if _leaving and _transition >= 1.0:
		focused = false
		_world.player.camera.fov = _saved_fov
		closed.emit()

func _input(event: InputEvent) -> void:
	if not focused or _leaving:
		return
	if event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"interact"):
		leave()
		get_viewport().set_input_as_handled()
		return
	if not event is InputEventMouse or _transition < 1.0:
		return
	var mouse := event as InputEventMouse
	var camera := _world.player.camera
	var origin := _display.to_local(camera.project_ray_origin(mouse.position))
	var direction := _display.global_basis.inverse() * camera.project_ray_normal(mouse.position)
	if absf(direction.z) < 0.00001:
		return
	var travel := -origin.z / direction.z
	if travel <= 0.0:
		return
	var at := origin + direction * travel
	var extent := _ship.computer_screen_size()
	var uv := Vector2(at.x / extent.x + 0.5, 0.5 - at.y / extent.y)
	var copy := event.duplicate() as InputEventMouse
	copy.position = uv * Vector2(PIXELS)
	copy.global_position = copy.position
	if copy is InputEventMouseMotion:
		copy.relative = Vector2.ZERO
	viewport.push_input(copy, true)
	get_viewport().set_input_as_handled()

func dispose() -> void:
	if focused and is_instance_valid(_world):
		_world.player.camera.global_transform = _return_pose
		Input.mouse_mode = _previous_mouse
	focused = false
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	queue_free()
