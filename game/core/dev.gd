extends Node
## Every number the game wants seen: systems put() values here, F3 draws them,
## and probes read() the same values the player would see. Keys are
## "group/name"; each group gets its own column, so nothing runs off screen.
## F1 lists the keys, one per line; on screen there's only a hint that it does.

## Columns left to right, with their headings; unlisted groups follow, alphabetically.
const GROUPS := {"weather": "WX", "player": "YOU", "world": "WLD", "terrain": "TER", "engine": "ENG"}

var _values: Dictionary = {}
var _layer: CanvasLayer
var _columns: HBoxContainer
var _bodies: Dictionary = {}
var _keys_layer: CanvasLayer
var _keys: Label
var _hint: Label
var _scene_keys: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_layer = CanvasLayer.new()
	_layer.layer = 100
	_layer.visible = false
	add_child(_layer)
	_columns = HBoxContainer.new()
	_columns.position = Vector2(8, 8)
	_columns.add_theme_constant_override("separation", 14)
	_layer.add_child(_columns)

	var hint_layer := CanvasLayer.new()
	hint_layer.layer = 100
	add_child(hint_layer)
	_hint = _text(Color(1, 1, 1, 0.7))
	_hint.text = "F1 keys"
	_hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 10)
	_hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hint_layer.add_child(_hint)
	_keys_layer = CanvasLayer.new()
	_keys_layer.layer = 100
	_keys_layer.visible = false
	add_child(_keys_layer)
	_keys = _text(Color.WHITE)
	_keys.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 10)
	_keys.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_keys_layer.add_child(_keys)
	_write_keys()


func put(key: String, value: Variant) -> void:
	_values[key] = value


func read(key: String, default: Variant = null) -> Variant:
	return _values.get(key, default)


## A scene's own keys, as [key, what it does] pairs, listed after the game's.
func set_scene_keys(keys: Array) -> void:
	_scene_keys = keys
	_write_keys()


## Captures want a clean frame.
func hide_overlays() -> void:
	_layer.visible = false
	_keys_layer.visible = false
	_hint.visible = false


func _write_keys() -> void:
	var lines := PackedStringArray()
	for pair: Array in Controls.HELP + _scene_keys:
		lines.append("%s  %s" % pair)
	_keys.text = "\n".join(lines)


func _process(_delta: float) -> void:
	put("engine/fps", "%d" % Engine.get_frames_per_second())
	put("engine/frm", "%.1fms" % (Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0))
	put("engine/phy", "%.1fms" % (Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0))
	put("engine/obj", "%d" % Performance.get_monitor(Performance.OBJECT_COUNT))
	put("engine/mem", "%.0fMB" % (Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0))
	if _layer.visible:
		_draw_columns()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_dev_overlay"):
		_layer.visible = not _layer.visible
	elif event.is_action_pressed("toggle_keys"):
		_keys_layer.visible = not _keys_layer.visible
		_hint.visible = not _keys_layer.visible


func _draw_columns() -> void:
	var lines := {}
	# Within a column, values keep the order systems first put them.
	for key: String in _values:
		var group := key.get_slice("/", 0)
		if group == "probe":
			continue
		if not lines.has(group):
			lines[group] = []
		lines[group].append("%s %s" % [key.get_slice("/", 1), _format(_values[key])])
	var order: Array = GROUPS.keys().filter(func(g: String) -> bool: return lines.has(g))
	var rest: Array = lines.keys().filter(func(g: String) -> bool: return not GROUPS.has(g))
	rest.sort()
	order.append_array(rest)
	for i in order.size():
		var body := _body(order[i])
		body.text = "\n".join(PackedStringArray(lines[order[i]]))
		_columns.move_child(body.get_parent(), i)


## A column is bare outlined text, so the world shows through it.
func _body(group: String) -> Label:
	if _bodies.has(group):
		return _bodies[group]
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 0)
	var header := _text(Color(1.0, 0.8, 0.5))
	header.text = GROUPS.get(group, group.to_upper())
	var body := _text(Color.WHITE)
	stack.add_child(header)
	stack.add_child(body)
	_columns.add_child(stack)
	_bodies[group] = body
	return body


func _text(color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_constant_override("line_spacing", 0)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	return label


func _format(value: Variant) -> String:
	if value is float:
		return "%.2f" % value
	if value is bool:
		return "yes" if value else "no"
	return str(value)
