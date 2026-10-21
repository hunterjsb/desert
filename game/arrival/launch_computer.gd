class_name LaunchComputer
extends Control
## A persistent physical display; focusing changes input, never its contents.
signal closed
var _world: World
var _plan := {}
var _changed: Callable
var _focused := false
var _chart := Control.new()
var _orbit_view := SubViewportContainer.new()
var _orbit_port := SubViewport.new()
var _orbit := ArrivalOrbit.new()
var _title := Label.new()
var _instruction := Label.new()
var _readiness := Label.new()
var _result := Label.new()
var _confirm := Button.new()
var _back := Button.new()
var _clock := 0.0
var _dragging := false
var _sample := {}
var _forecast := {}
var _pending := true
var _refresh_at := 0.0

func setup(world: World, plan: Dictionary, changed: Callable) -> void:
	_world = world
	_plan = plan.duplicate(true)
	_changed = changed
	if is_node_ready():
		refresh()

func _ready() -> void:
	theme = preload("res://game/ui/theme.tres")
	mouse_filter = Control.MOUSE_FILTER_STOP
	var background := ColorRect.new()
	background.color = Color(0.018, 0.035, 0.04)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	_title.theme_type_variation = &"AsideName"
	_title.text = "TILG / DEPARTURE CONTROL"
	add_child(_title)
	_chart.clip_contents = true
	_chart.mouse_filter = Control.MOUSE_FILTER_STOP
	_chart.draw.connect(_draw_chart)
	_chart.gui_input.connect(_chart_input)
	add_child(_chart)
	_orbit_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_orbit_view.stretch = true
	_orbit_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_chart.add_child(_orbit_view)
	_orbit_port.own_world_3d = true
	_orbit_port.gui_disable_input = true
	_orbit_port.size = Vector2i(720, 560)
	_orbit_view.add_child(_orbit_port)
	_orbit_port.add_child(_orbit)
	if is_instance_valid(_world):
		_orbit.setup(_world.shape.history, _world.weather.day)
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.draw.connect(func() -> void: _draw_overlay(overlay))
	_chart.add_child(overlay)
	for label: Label in [_instruction, _readiness, _result]:
		label.theme_type_variation = &"MenuLineLead"
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		add_child(label)
	_confirm.text = "Set launch pulse"
	_confirm.theme_type_variation = &"MenuWordMain"
	_confirm.pressed.connect(_commit)
	add_child(_confirm)
	_back.text = "Step back"
	_back.theme_type_variation = &"MenuWordMain"
	_back.pressed.connect(func() -> void: closed.emit())
	add_child(_back)
	resized.connect(_fit)
	_fit()
	refresh()
	set_focused(false)

func _fit() -> void:
	_title.position = Vector2(28, 18)
	_title.size = Vector2(size.x - 56, 40)
	_chart.position = Vector2(20, 68)
	_chart.size = Vector2(size.x * 0.65 - 30, size.y - 90)
	var x := size.x * 0.65 + 12
	var width := size.x - x - 26
	_instruction.position = Vector2(x, 78)
	_instruction.size = Vector2(width, 90)
	_result.position = Vector2(x, 186)
	_result.size = Vector2(width, 170)
	_readiness.position = Vector2(x, 366)
	_readiness.size = Vector2(width, 160)
	_confirm.position = Vector2(x, size.y - 132)
	_confirm.size = Vector2(width, 48)
	_back.position = Vector2(x, size.y - 72)
	_back.size = Vector2(width, 44)

func set_focused(value: bool) -> void:
	_focused = value
	_dragging = false
	_confirm.disabled = not value
	_back.visible = value
	_instruction.text = "Drag the pulse handle.\nWatch the predicted landing." if value else "Use the station to plan your drop."

func refresh() -> void:
	if not is_node_ready():
		return
	var candidate: Dictionary = _forecast.get("candidate", LandingPlan.selected(_plan))
	if candidate.is_empty():
		_result.text = "Outside the surveyed corridor. Adjust the pulse to bring the landing back."
		return
	_result.text = "Landing forecast\n" + ("Long approach · gentler impact" if _sample.get("profile", _plan.profile) == &"shallow" else "Short approach · harder impact" if _sample.get("profile", _plan.profile) == &"steep" else "Balanced approach")
	var kinds: Array[String] = []
	for reading: Dictionary in candidate.get("signals", []):
		var kind := String(reading.kind).replace("_", " ")
		if not kinds.has(kind):
			kinds.append(kind)
	_result.text += "\n\n" + ("Coarse survey: " + ", ".join(kinds) if not kinds.is_empty() else "No structure reading nearby.")
	_result.text += "\nContents unknown."
	_update_readiness()

func _update_readiness() -> void:
	if not is_instance_valid(_world) or not is_instance_valid(_world.arrival) or not is_instance_valid(_world.arrival.preflight):
		_readiness.text = ""
		return
	var missing := _world.arrival.preflight.readiness()
	_readiness.text = "Ready: load, enter pod, launch." if missing.is_empty() else "Before launch\n• " + "\n• ".join(missing)

func _process(delta: float) -> void:
	_clock += delta
	if is_instance_valid(_world) and is_instance_valid(_orbit.camera):
		_update_orbit()
	if _clock >= _refresh_at:
		_refresh_at = _clock + 0.3
		if is_instance_valid(_world) and _plan.has("departure_trajectory"):
			_forecast = DepartureTrajectory.resolve(_world.shape, _plan, _plan.departure_trajectory, _departure_time(), _world.tuning)
		refresh()
	_chart.queue_redraw()
	if _chart.get_child_count() > 1:
		_chart.get_child(1).queue_redraw()

func _departure_time() -> float:
	return float(_world.arrival_state.get("preflight", {}).get("departure_time", _world.time))

func _update_orbit() -> void:
	if not _plan.has("departure_trajectory"):
		return
	_sample = DepartureTrajectory.sample(_plan.departure_trajectory, _departure_time(), _world.tuning)
	if not _sample.has("camera_transform"):
		_sample = {}
		return
	var inverse: Basis = (_sample.body_basis as Basis).inverse()
	var pose: Transform3D = _sample.camera_transform
	_orbit.camera.transform = Transform3D(inverse * pose.basis, inverse * pose.origin * ArrivalOrbit.RADIUS)
	_orbit.camera.fov = 45.0
	_orbit.update_light(_departure_time())

func _draw_chart() -> void:
	pass

func _project(point: Vector3) -> Vector2:
	var inverse: Basis = (_sample.body_basis as Basis).inverse()
	return _orbit.camera.unproject_position(inverse * point * ArrivalOrbit.RADIUS) / Vector2(_orbit_port.size) * _chart.size

func _exposed(point: Vector3) -> bool:
	var eye: Vector3 = _sample.camera_transform.origin
	var ray := point - eye
	var along := clampf(-eye.dot(ray) / maxf(ray.length_squared(), 0.000001), 0.0, 1.0)
	return (eye + ray * along).length() >= 0.997

func _draw_overlay(canvas: Control) -> void:
	if not _sample.has("landing_point"):
		return
	var amber := Color(0.95, 0.73, 0.36)
	var teal := Color(0.55, 0.85, 0.82)
	var path: PackedVector3Array = _sample.path
	for i in range(1, path.size()):
		if _exposed(path[i - 1]) and _exposed(path[i]):
			canvas.draw_line(_project(path[i - 1]), _project(path[i]), amber, 2.5, true)
	var ship := _project(_sample.ship_position)
	canvas.draw_circle(ship, 5.0, teal)
	var handle := _project(_sample.pulse_handle)
	canvas.draw_line(ship, handle, amber, 2.0, true)
	canvas.draw_circle(handle, 12.0, amber, false, 3.0, true)
	var font := get_theme_font(&"font", &"Label")
	canvas.draw_string(font, ship + Vector2(10, -10), "SHIP", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, teal)
	canvas.draw_string(font, handle + Vector2(15, 5), "PULSE", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, amber)
	var landing: Vector3 = (_sample.body_basis as Basis) * (_sample.landing_point as Vector3)
	if _exposed(landing):
		var at := _project(landing)
		canvas.draw_arc(at, 9.0, 0.0, TAU, 32, amber, 2.0, true)
		canvas.draw_line(at - Vector2(14, 0), at + Vector2(14, 0), amber, 2.0)
		canvas.draw_line(at - Vector2(0, 14), at + Vector2(0, 14), amber, 2.0)
		canvas.draw_string(font, at + Vector2(16, 24), "LANDING", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, amber)

func _chart_input(event: InputEvent) -> void:
	if not _focused:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		if _dragging:
			_drag(event.position)
		accept_event()
	elif event is InputEventMouseMotion and _dragging:
		_drag(event.position)
		accept_event()

func _drag(at: Vector2) -> void:
	if not is_instance_valid(_world) or _sample.is_empty():
		return
	var pixel := at / _chart.size * Vector2(_orbit_port.size)
	var basis: Basis = _sample.body_basis
	var origin := basis * _orbit.camera.project_ray_origin(pixel) / ArrivalOrbit.RADIUS
	var direction := basis * _orbit.camera.project_ray_normal(pixel)
	_plan.departure_trajectory = DepartureTrajectory.drag(_plan.departure_trajectory, _departure_time(), origin, direction, _world.tuning)
	_world.arrival_state.landing_plan.departure_trajectory = _plan.departure_trajectory.duplicate(true)
	_world.arrival_state.preflight.plan_confirmed = false
	_pending = true
	_confirm.text = "Set launch pulse"
	_refresh_at = 0.0
	_update_orbit()
	_chart.queue_redraw()

func _commit() -> void:
	if not _focused or _plan.is_empty():
		return
	var choice := _plan.duplicate(true)
	if is_instance_valid(_world) and _plan.has("departure_trajectory"):
		_forecast = DepartureTrajectory.resolve(_world.shape, _plan, _plan.departure_trajectory, _departure_time(), _world.tuning)
		if not _forecast.get("safe", false):
			_result.text = "No safe landing forecast. Adjust the pulse inside the survey corridor."
			return
		choice = _forecast.plan
	_plan = choice.duplicate(true)
	if _changed.is_valid():
		_changed.call(choice.duplicate(true))
	_pending = false
	_confirm.text = "Launch pulse set"
	_update_readiness()

func dispose() -> void:
	_orbit_port.render_target_update_mode = SubViewport.UPDATE_DISABLED
	queue_free()
