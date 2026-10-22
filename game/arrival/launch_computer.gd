class_name LaunchComputer
extends Control
## A persistent physical display; focusing changes input, never its contents.
signal closed
var _world: World
var _preflight: SurveyorPreflight
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
var _cargo_toggle := Button.new()
var _cargo_page := DepartureCargoPage.new()
var _show_cargo := false
var _dragging := false
## The moon, ship and handle now; the drawn path and landing are the controller's forecast.
var _frame := {}
var _shown := {}

func setup(world: World, preflight: SurveyorPreflight) -> void:
	_world = world
	_preflight = preflight
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
	_confirm.pressed.connect(commit)
	add_child(_confirm)
	_back.text = "Step back"
	_back.theme_type_variation = &"MenuWordMain"
	_back.pressed.connect(func() -> void: closed.emit())
	add_child(_back)
	_cargo_toggle.theme_type_variation = &"MenuWordMain"
	_cargo_toggle.pressed.connect(func() -> void:
		_show_cargo = not _show_cargo
		_display_page())
	add_child(_cargo_toggle)
	add_child(_cargo_page)
	resized.connect(_fit)
	_fit()
	refresh()
	set_focused(false)

func _fit() -> void:
	_title.position = Vector2(28, 18)
	_title.size = Vector2(size.x * 0.65 - 40, 40)
	_chart.position = Vector2(20, 68)
	_chart.size = Vector2(size.x * 0.65 - 30, size.y - 90)
	var x := size.x * 0.65 + 12
	var width := size.x - x - 26
	_cargo_toggle.position = Vector2(x, 18)
	_cargo_toggle.size = Vector2(width, 40)
	_cargo_page.position = Vector2(x, 186)
	_cargo_page.size = Vector2(width, size.y - 340)
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
	_cargo_toggle.disabled = not value
	_display_page()

func _display_page() -> void:
	_cargo_page.visible = _show_cargo
	_result.visible = not _show_cargo
	_readiness.visible = not _show_cargo
	_cargo_toggle.text = "Landing view" if _show_cargo else "Cargo"
	_instruction.text = "Drag the pulse. Set it when the landing is clear." if _focused else ""
	refresh()

## One line each: where the pod comes down, and what still stops the launch.
func refresh() -> void:
	if not is_node_ready() or not is_instance_valid(_preflight) or not is_instance_valid(_preflight.ship):
		return
	var forecast := _preflight.forecast
	var sample: Dictionary = forecast.get("sample", {})
	var profile: StringName = sample.get("profile", &"standard")
	if not sample.get("inside_survey", false):
		_result.text = "Landing outside the survey"
	elif not forecast.get("safe", false):
		_result.text = "Rough ground at the landing"
	else:
		_result.text = "Long approach · gentler impact" if profile == &"shallow" else "Short approach · harder impact" if profile == &"steep" else "Balanced approach"
		var kinds: Array[String] = []
		for reading: Dictionary in forecast.get("candidate", {}).get("signals", []):
			var kind := String(reading.kind).replace("_", " ")
			if not kinds.has(kind):
				kinds.append(kind)
		_result.text += "\n" + ("Seen nearby: " + ", ".join(kinds) if not kinds.is_empty() else "Nothing seen nearby")
	var missing := _preflight.readiness()
	_readiness.text = "Ready to launch" if missing.is_empty() else missing[0]
	_confirm.text = "Launch pulse set" if _world.arrival_state.preflight.get("plan_confirmed", false) else "Set launch pulse"
	var report := PreflightCargo.packing_report(_world, _preflight.ship)
	_cargo_toggle.text = "Landing view" if _show_cargo else "Cargo · %d aboard" % report.filter(func(item: Dictionary) -> bool: return item.aboard).size()
	if _show_cargo:
		_cargo_page.show_report(report, missing)

func _process(_delta: float) -> void:
	if not is_instance_valid(_preflight) or not is_instance_valid(_orbit.camera):
		return
	_frame = DepartureTrajectory.frame(_preflight.model(), _preflight.clock())
	if _frame.is_empty():
		return
	var inverse: Basis = (_frame.body_basis as Basis).inverse()
	var pose: Transform3D = _frame.camera_transform
	_orbit.camera.transform = Transform3D(inverse * pose.basis, inverse * pose.origin * ArrivalOrbit.RADIUS)
	_orbit.camera.fov = 45.0
	_orbit.update_light(_preflight.clock())
	# Text changes only with a new forecast, never with the frame rate.
	if not is_same(_preflight.forecast, _shown):
		_shown = _preflight.forecast
		refresh()
	_chart.get_child(1).queue_redraw()

func _project(point: Vector3) -> Vector2:
	var inverse: Basis = (_frame.body_basis as Basis).inverse()
	return _orbit.camera.unproject_position(inverse * point * ArrivalOrbit.RADIUS) / Vector2(_orbit_port.size) * _chart.size

func _exposed(point: Vector3) -> bool:
	var eye: Vector3 = _frame.camera_transform.origin
	var ray := point - eye
	var along := clampf(-eye.dot(ray) / maxf(ray.length_squared(), 0.000001), 0.0, 1.0)
	return (eye + ray * along).length() >= 0.997

func _draw_overlay(canvas: Control) -> void:
	var sample: Dictionary = _preflight.forecast.get("sample", {}) if is_instance_valid(_preflight) else {}
	if _frame.is_empty() or not sample.has("landing_point"):
		return
	var amber := Color(0.95, 0.73, 0.36)
	var teal := Color(0.55, 0.85, 0.82)
	var anchor: Vector3 = _world.arrival_state.landing_plan.anchor.get("point", Vector3.RIGHT)
	var reach := _world.tuning.arrival_corridor_m / (_world.tuning.moon_circumference / TAU)
	var body: Basis = _frame.body_basis
	for i in 64:
		var a := body * Sphere.toward(anchor, TAU * i / 64.0, reach)
		var b := body * Sphere.toward(anchor, TAU * (i + 1) / 64.0, reach)
		if _exposed(a) and _exposed(b):
			canvas.draw_line(_project(a), _project(b), Color(teal, 0.6), 1.5, true)
	var path: PackedVector3Array = sample.path
	for i in range(1, path.size()):
		if _exposed(path[i - 1]) and _exposed(path[i]):
			canvas.draw_line(_project(path[i - 1]), _project(path[i]), amber, 2.5, true)
	var ship := _project(_frame.ship_position)
	canvas.draw_circle(ship, 5.0, teal)
	var handle := _project(_frame.pulse_handle)
	canvas.draw_line(ship, handle, amber, 2.0, true)
	canvas.draw_circle(handle, 12.0, amber, false, 3.0, true)
	var font := get_theme_font(&"font", &"Label")
	var ship_label := (ship + Vector2(24, -55)).clamp(Vector2(8, 28), _chart.size - Vector2(78, 12))
	var pulse_label := (handle + Vector2(-108, -22)).clamp(Vector2(8, 28), _chart.size - Vector2(94, 12))
	canvas.draw_line(ship, ship_label + Vector2(-3, 6), teal, 1.0, true)
	canvas.draw_line(handle, pulse_label + Vector2(78, 6), amber, 1.0, true)
	canvas.draw_string(font, ship_label, "SHIP", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, teal)
	canvas.draw_string(font, pulse_label, "PULSE", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, amber)
	var landing: Vector3 = body * (sample.landing_point as Vector3)
	if _exposed(landing):
		var at := _project(landing)
		canvas.draw_arc(at, 9.0, 0.0, TAU, 32, amber, 2.0, true)
		canvas.draw_line(at - Vector2(14, 0), at + Vector2(14, 0), amber, 2.0)
		canvas.draw_line(at - Vector2(0, 14), at + Vector2(0, 14), amber, 2.0)
		var landing_label := (at + Vector2(-112, 64)).clamp(Vector2(8, 28), _chart.size - Vector2(104, 12))
		canvas.draw_line(at, landing_label + Vector2(78, -10), amber, 1.0, true)
		canvas.draw_string(font, landing_label, "LANDING", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, amber)

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
	if not is_instance_valid(_preflight) or _frame.is_empty():
		return
	var pixel := at / _chart.size * Vector2(_orbit_port.size)
	var basis: Basis = _frame.body_basis
	_preflight.drag_pulse(basis * _orbit.camera.project_ray_origin(pixel) / ArrivalOrbit.RADIUS,
		basis * _orbit.camera.project_ray_normal(pixel))
	_confirm.text = "Set launch pulse"

## The set pulse is the one launch flies; unclear ground keeps it pending.
func commit() -> void:
	if not _focused or not is_instance_valid(_preflight):
		return
	_preflight.commit_pulse()
	refresh()

func dispose() -> void:
	_orbit_port.render_target_update_mode = SubViewport.UPDATE_DISABLED
	queue_free()
