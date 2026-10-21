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
var _pulse := Vector2(0.2, -0.25)
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
	var candidate := LandingPlan.selected(_plan)
	if candidate.is_empty():
		_result.text = "No safe landing forecast."
		return
	_result.text = "Landing forecast\n" + ("Long approach · gentler impact" if _plan.profile == &"shallow" else "Short approach · harder impact" if _plan.profile == &"steep" else "Balanced approach")
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
		_orbit.update_light(_world.time)
		_update_orbit()
	if _clock >= _refresh_at:
		_refresh_at = _clock + 0.3
		_update_readiness()
	_chart.queue_redraw()
	if _chart.get_child_count() > 1:
		_chart.get_child(1).queue_redraw()

func _update_orbit() -> void:
	var point: Vector3 = _plan.get("anchor", {}).get("point", Vector3.RIGHT)
	var north := Sphere.north(point)
	var direction := (point + north * 0.3).normalized()
	_orbit.camera.position = direction * ArrivalOrbit.RADIUS * 3.0
	_orbit.camera.look_at(Vector3.ZERO, north)
	_orbit.camera.fov = 45.0

func _draw_chart() -> void:
	pass

func _draw_overlay(canvas: Control) -> void:
	# The trajectory model supplies positions in this same globe frame.
	if not is_instance_valid(_orbit.camera) or _plan.is_empty():
		return
	var center := _chart.size * 0.5
	var handle := center + _pulse * _chart.size * 0.5
	canvas.draw_line(center, handle, Color(0.95, 0.73, 0.36), 3.0)
	canvas.draw_circle(handle, 12.0, Color(0.95, 0.73, 0.36), false, 3.0)

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
	_pulse = ((at / _chart.size - Vector2(0.5, 0.5)) * 2.0).limit_length(0.85)
	_pending = true
	_confirm.text = "Set launch pulse"
	_chart.queue_redraw()

func _commit() -> void:
	if not _focused or _plan.is_empty():
		return
	if _changed.is_valid():
		_changed.call(_plan.duplicate(true))
	_pending = false
	_confirm.text = "Launch pulse set"
	_update_readiness()

func dispose() -> void:
	_orbit_port.render_target_update_mode = SubViewport.UPDATE_DISABLED
	queue_free()
