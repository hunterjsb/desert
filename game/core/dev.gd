extends Node
## Every number the game wants seen: systems put() values here, F3 draws them,
## and probes read() the same values the player would see. Keys are
## "group/name"; each group gets its own column, so nothing runs off screen.

## Columns left to right; groups not listed follow in alphabetical order.
const GROUPS: Array[String] = ["weather", "player", "world", "terrain", "engine"]

var _values: Dictionary = {}
var _layer: CanvasLayer
var _columns: HBoxContainer
var _bodies: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_layer = CanvasLayer.new()
	_layer.layer = 100
	_layer.visible = false
	add_child(_layer)
	_columns = HBoxContainer.new()
	_columns.position = Vector2(8, 8)
	_columns.add_theme_constant_override("separation", 8)
	_layer.add_child(_columns)


func put(key: String, value: Variant) -> void:
	_values[key] = value


func read(key: String, default: Variant = null) -> Variant:
	return _values.get(key, default)


func _process(_delta: float) -> void:
	put("engine/fps", "%d" % Engine.get_frames_per_second())
	put("engine/frame", "%.1f ms" % (Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0))
	put("engine/physics", "%.1f ms" % (Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0))
	put("engine/objects", "%d" % Performance.get_monitor(Performance.OBJECT_COUNT))
	put("engine/memory", "%.0f MB" % (Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0))
	if _layer.visible:
		_draw_columns()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_dev_overlay"):
		_layer.visible = not _layer.visible


func _draw_columns() -> void:
	var lines := {}
	# Within a column, values keep the order systems first put them.
	for key: String in _values:
		var group := key.get_slice("/", 0)
		if group == "probe":
			continue
		if not lines.has(group):
			lines[group] = []
		lines[group].append("%s  %s" % [key.get_slice("/", 1).replace("_", " "), _format(_values[key])])
	var order: Array = GROUPS.filter(func(g: String) -> bool: return lines.has(g))
	var rest: Array = lines.keys().filter(func(g: String) -> bool: return not GROUPS.has(g))
	rest.sort()
	order.append_array(rest)
	for i in order.size():
		var body := _body(order[i])
		body.text = "\n".join(PackedStringArray(lines[order[i]]))
		_columns.move_child(body.get_parent().get_parent(), i)


func _body(group: String) -> Label:
	if _bodies.has(group):
		return _bodies[group]
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.6)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", style)
	var stack := VBoxContainer.new()
	var header := Label.new()
	header.text = group.to_upper()
	header.add_theme_font_size_override("font_size", 13)
	header.add_theme_color_override("font_color", Color(1.0, 0.8, 0.5))
	var body := Label.new()
	body.add_theme_font_size_override("font_size", 14)
	stack.add_child(header)
	stack.add_child(body)
	panel.add_child(stack)
	_columns.add_child(panel)
	_bodies[group] = body
	return body


func _format(value: Variant) -> String:
	if value is float:
		return "%.2f" % value
	if value is bool:
		return "yes" if value else "no"
	return str(value)
