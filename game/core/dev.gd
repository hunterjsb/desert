extends Node
## Every number the game wants seen: systems put() values here, the overlay
## draws them, and probes read() the same values the player would see. Keys are
## "group/name"; each group gets its own column, so nothing runs off screen.
## The keys list has every key, one per line, as bound now; on screen there's
## only a hint of how to open it.

## Columns left to right, with their headings; unlisted groups follow, alphabetically.
const GROUPS := {"weather": "WX", "player": "YOU", "world": "WLD", "terrain": "TER", "engine": "ENG"}

var _values: Dictionary = {}
var _layer: CanvasLayer
var _columns: HBoxContainer
var _bodies: Dictionary = {}
var _keys_layer: CanvasLayer
var _keys: RichTextLabel
var _hint: RichTextLabel
var _scene_keys: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_layer = CanvasLayer.new()
	_layer.layer = 100
	_layer.visible = false
	add_child(_layer)
	_columns = HBoxContainer.new()
	_columns.position = Vector2(8, 8)
	_columns.theme_type_variation = &"Columns"
	_layer.add_child(_columns)

	var hint_layer := CanvasLayer.new()
	hint_layer.layer = 100
	add_child(hint_layer)
	_hint = Controls.keys_label()
	_hint.theme_type_variation = &"Hint"
	_hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 10)
	_hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hint_layer.add_child(_hint)
	_keys_layer = CanvasLayer.new()
	_keys_layer.layer = 100
	_keys_layer.visible = false
	add_child(_keys_layer)
	_keys = Controls.keys_label()
	_keys.theme_type_variation = &"KeysList"
	_keys.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 10)
	_keys.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_keys_layer.add_child(_keys)
	_write_keys()


func put(key: String, value: Variant) -> void:
	_values[key] = value


func read(key: String, default: Variant = null) -> Variant:
	return _values.get(key, default)


## A new run: nothing the last one put is left showing.
func clear() -> void:
	_values.clear()
	for group: String in _bodies:
		_bodies[group].text = ""


## A scene's own keys, as [key, what it does] pairs, listed after the game's.
func set_scene_keys(keys: Array) -> void:
	_scene_keys = keys
	_write_keys()


## Captures want a clean frame.
func hide_overlays() -> void:
	_layer.visible = false
	_keys_layer.visible = false
	_hint.visible = false


## The hint of how to open the keys list, off while the main menu is up.
func show_hint(on: bool) -> void:
	_hint.visible = on and not _keys_layer.visible


## Written again whenever it shows, so a key rebound is listed as it is now.
func _write_keys() -> void:
	var hint := Controls.bbcode("{toggle_keys} keys")
	if _hint.text != hint:
		_hint.text = hint
	if not _keys_layer.visible:
		return
	# A look-test's own keys are raw keys, not actions.
	var text := Controls.help(_scene_keys.map(func(pair: Array) -> Array: return [Controls.tint(pair[0]), pair[1]]))
	if _keys.text != text:
		_keys.text = text


func _process(_delta: float) -> void:
	put("engine/fps", "%d" % Engine.get_frames_per_second())
	put("engine/frm", "%.1fms" % (Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0))
	put("engine/phy", "%.1fms" % (Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0))
	put("engine/obj", "%d" % Performance.get_monitor(Performance.OBJECT_COUNT))
	put("engine/mem", "%.0fMB" % (Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0))
	_write_keys()
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
	stack.theme_type_variation = &"Column"
	var header := Label.new()
	header.theme_type_variation = &"ReadoutHead"
	header.text = GROUPS.get(group, group.to_upper())
	var body := Label.new()
	body.theme_type_variation = &"Readout"
	stack.add_child(header)
	stack.add_child(body)
	_columns.add_child(stack)
	_bodies[group] = body
	return body


func _format(value: Variant) -> String:
	if value is float:
		return "%.2f" % value
	if value is bool:
		return "yes" if value else "no"
	return str(value)
