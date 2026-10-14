extends Node
## Every number the game wants seen: systems put() values here, F3 draws them,
## and probes read() the same values the player would see.

var _values: Dictionary = {}
var _layer: CanvasLayer
var _label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not InputMap.has_action("toggle_dev_overlay"):
		var f3 := InputEventKey.new()
		f3.keycode = KEY_F3
		InputMap.add_action("toggle_dev_overlay")
		InputMap.action_add_event("toggle_dev_overlay", f3)

	_layer = CanvasLayer.new()
	_layer.layer = 100
	_layer.visible = false
	add_child(_layer)
	_label = Label.new()
	_label.position = Vector2(12, 12)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 4)
	_layer.add_child(_label)


func put(key: String, value: Variant) -> void:
	_values[key] = value


func read(key: String, default: Variant = null) -> Variant:
	return _values.get(key, default)


func _process(_delta: float) -> void:
	put("engine/fps", Engine.get_frames_per_second())
	put("engine/process_ms", Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
	put("engine/physics_ms", Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
	put("engine/objects", Performance.get_monitor(Performance.OBJECT_COUNT))
	put("engine/static_mb", Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0)
	if _layer.visible:
		_label.text = _format()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_dev_overlay"):
		_layer.visible = not _layer.visible


func _format() -> String:
	var keys := _values.keys()
	keys.sort()
	var lines := PackedStringArray()
	for key: String in keys:
		var value: Variant = _values[key]
		lines.append("%s  %s" % [key, ("%.2f" % value) if value is float else str(value)])
	return "\n".join(lines)
