class_name LaunchComputer
extends Control
## Modal regional landing choices; the owner suspends ship movement while open.

signal closed

var _world: World
var _plan := {}
var _changed: Callable
var _previous_mouse := Input.MOUSE_MODE_VISIBLE
var _has_mouse := false
var _refreshing := false
var _choices := GridContainer.new()
var _buttons := {}
var _details := Label.new()
var _reading_scroll := ScrollContainer.new()
var _bar := PageBar.new()
var _trajectory := Label.new()
var _heading := SpinBox.new()
var _profile := OptionButton.new()
var _chart := Control.new()
var _body := HBoxContainer.new()
var _layout := VBoxContainer.new()
var _panel := PanelContainer.new()
var _back := Button.new()


func setup(world: World, plan: Dictionary, changed: Callable) -> void:
	_world = world
	_plan = plan.duplicate(true)
	_changed = changed
	if is_node_ready():
		for button: Button in _buttons.values():
			_choices.remove_child(button)
			button.queue_free()
		_buttons.clear()
		refresh()


func _ready() -> void:
	theme = preload("res://game/ui/theme.tres")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_previous_mouse = Input.mouse_mode
	_has_mouse = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.035, 0.04, 0.96)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	add_child(_panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	_panel.add_child(margin)
	margin.add_child(_layout)
	_layout.add_theme_constant_override("separation", 14)
	_word(_layout, "TILG / DROP CONTROL", &"AsideName")
	_word(_layout, "Choose your landing", &"MenuWordSide")
	_word(_layout, "Drop corridor only · coarse structure readings · contents unknown", &"MenuLineLead")
	_layout.add_child(_body)
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 24)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_child(left)
	_chart.custom_minimum_size = Vector2(240, 200)
	_chart.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_chart.draw.connect(_draw_chart)
	left.add_child(_chart)
	_choices.columns = 2
	left.add_child(_choices)
	var right := VBoxContainer.new()
	right.custom_minimum_size.x = 320
	_body.add_child(right)
	_details.theme_type_variation = &"MenuLineLead"
	_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var readings := HBoxContainer.new()
	readings.size_flags_vertical = Control.SIZE_EXPAND_FILL
	readings.custom_minimum_size.y = 100
	right.add_child(readings)
	_reading_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_reading_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_reading_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_reading_scroll.add_child(_details)
	readings.add_child(_reading_scroll)
	readings.add_child(_bar)
	_bar.moved.connect(func(at: float) -> void: _reading_scroll.scroll_vertical = roundi(at))
	_word(right, "Approach heading", &"MenuLineLead")
	_heading.min_value = 0.0
	_heading.max_value = 359.0
	_heading.step = 1.0
	_heading.suffix = "°"
	_heading.get_line_edit().theme_type_variation = &"MenuLineLead"
	_heading.value_changed.connect(func(_value: float) -> void: _choose())
	right.add_child(_heading)
	_word(right, "Trajectory", &"MenuLineLead")
	_profile.theme_type_variation = &"MenuWordMain"
	for name in ["Shallow", "Standard", "Steep"]:
		_profile.add_item(name)
	_profile.item_selected.connect(func(_index: int) -> void: _choose())
	right.add_child(_profile)
	_trajectory.theme_type_variation = &"MenuNote"
	_trajectory.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(_trajectory)
	_word(right, "Terrain clearance is checked again before launch.", &"MenuNote")
	_back.text = "Return to ship"
	_back.theme_type_variation = &"MenuWordMain"
	_back.pressed.connect(_close)
	_layout.add_child(_back)
	resized.connect(_fit)
	refresh()
	_back.grab_focus()


func refresh() -> void:
	if not is_node_ready():
		return
	_refreshing = true
	if _buttons.is_empty():
		for candidate: Dictionary in _plan.get("candidates", []):
			var button := Button.new()
			button.theme_type_variation = &"MenuWordMain"
			button.text = "Fallback" if candidate.id == &"fallback" else _name(candidate)
			button.toggle_mode = true
			button.pressed.connect(func() -> void: _choose(candidate.id))
			_choices.add_child(button)
			_buttons[candidate.id] = button
	for candidate: Dictionary in _plan.get("candidates", []):
		var button: Button = _buttons[candidate.id]
		button.set_pressed_no_signal(candidate.id == _plan.selected_id)
		button.disabled = not candidate.safe
	var candidate := LandingPlan.selected(_plan)
	if candidate.is_empty():
		_details.text = "No verified footprint in this corridor. Launch unavailable."
	else:
		var text := "%s\n%.4f° latitude\n%.4f° longitude\n\nGround rise · %.2f m" % [
			_name(candidate), rad_to_deg(candidate.latitude), rad_to_deg(candidate.longitude), candidate.footprint.rise_m]
		var kinds := {}
		var readings: Array = candidate.signals.duplicate()
		readings.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.distance_band.x < b.distance_band.x)
		for reading: Dictionary in readings:
			if kinds.has(reading.kind):
				continue
			kinds[reading.kind] = true
			var band: Vector2 = reading.distance_band
			text += "\n\n%s · %s\n%d–%d m" % [String(reading.kind).replace("_", " ").capitalize(),
				Radio.compass(rad_to_deg(reading.bearing)), roundi(band.x), roundi(band.y)]
		if candidate.signals.is_empty():
			text += "\n\nNo nearby structure reading. Survey further on foot."
		_details.text = text
	_heading.set_value_no_signal(fposmod(rad_to_deg(float(_plan.get("heading", 0.0))), 360.0))
	_profile.select(LandingPlan.PROFILES.find(_plan.get("profile", &"standard")))
	_trajectory.text = ["Longer descent · gentler impact", "Balanced descent and impact", "Shorter descent · harder impact"][_profile.selected]
	_refreshing = false
	_fit()
	_chart.queue_redraw()


func _choose(id: StringName = &"") -> void:
	if _refreshing or _plan.is_empty():
		return
	var choice := LandingPlan.select(_plan, _plan.selected_id if id == &"" else id,
		deg_to_rad(_heading.value), LandingPlan.PROFILES[_profile.selected])
	if choice.is_empty():
		return
	_plan = choice
	if _changed.is_valid():
		_changed.call(choice.duplicate(true))
	refresh()


func _draw_chart() -> void:
	var rect := Rect2(Vector2(16, 16), _chart.size - Vector2(32, 32))
	_chart.draw_rect(rect, Color(0.10, 0.20, 0.21), false, 1.0)
	for i in range(1, 4):
		var t := i / 4.0
		_chart.draw_line(rect.position + Vector2(rect.size.x * t, 0), rect.position + Vector2(rect.size.x * t, rect.size.y), Color(0.07, 0.13, 0.14))
		_chart.draw_line(rect.position + Vector2(0, rect.size.y * t), rect.position + Vector2(rect.size.x, rect.size.y * t), Color(0.07, 0.13, 0.14))
	if _plan.is_empty():
		return
	var origin: Vector2 = _plan.anchor.world
	var scale_m := LandingPlan.RULES.corridor_radius_m * 2.0
	for candidate: Dictionary in _plan.candidates:
		var at: Vector2 = rect.get_center() + (candidate.landing_world - origin) / scale_m * rect.size
		var chosen: bool = candidate.id == _plan.selected_id
		_chart.draw_string(get_theme_font(&"font", &"Label"), at + Vector2(10, -8),
			"F" if candidate.id == &"fallback" else String(candidate.id).trim_prefix("site_"),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.55, 0.85, 0.82))
		_chart.draw_circle(at, 7.0 if chosen else 4.0, Color(0.95, 0.73, 0.36) if chosen else Color(0.55, 0.85, 0.82))
		if chosen:
			var ahead := Vector2(sin(_heading.value * PI / 180.0), -cos(_heading.value * PI / 180.0))
			_chart.draw_line(at - ahead * 28.0, at, Color(0.95, 0.73, 0.36), 2.0)
	_chart.draw_string(get_theme_font(&"font", &"Label"), rect.position + Vector2(8, 20),
		"REGIONAL CORRIDOR · N ↑", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.55, 0.85, 0.82))


func _process(_delta: float) -> void:
	_fit()
	var scroll := _reading_scroll.get_v_scroll_bar()
	_bar.show_page(scroll.max_value, scroll.page, scroll.value)


func _fit() -> void:
	_panel.position = Vector2(24, 24)
	_panel.size = (size - Vector2(48, 48)).max(Vector2(640, 560))


func _word(parent: Node, text: String, variation: StringName) -> void:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = variation
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)


func _name(candidate: Dictionary) -> String:
	return "Surveyor fallback" if candidate.id == &"fallback" else "Landing " + String(candidate.id).trim_prefix("site_")


func _input(event: InputEvent) -> void:
	if is_visible_in_tree() and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()


func _close() -> void:
	closed.emit()
	dispose()


func dispose() -> void:
	hide()
	_restore_mouse()
	queue_free()


func _exit_tree() -> void:
	_restore_mouse()


func _restore_mouse() -> void:
	if _has_mouse:
		Input.mouse_mode = _previous_mouse
		_has_mouse = false
