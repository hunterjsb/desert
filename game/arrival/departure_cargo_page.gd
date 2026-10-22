class_name DepartureCargoPage
extends Control
## A requested readout of physical packing; it never moves or claims equipment.
var text := Label.new()
var bar := PageBar.new()
var scroll := 0.0:
	set(value):
		scroll = clampf(value, 0.0, maxf(text.get_minimum_size().y - size.y, 0.0))
		text.position.y = -scroll
		bar.show_page(text.get_minimum_size().y, size.y, scroll)

func _init() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	text.theme_type_variation = &"MenuLineLead"
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(text)
	bar.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	bar.offset_left = -PageBar.ACROSS
	bar.moved.connect(func(at: float) -> void: scroll = at)
	add_child(bar)
	resized.connect(_fit)

func show_report(report: Array[Dictionary], missing: Array[String]) -> void:
	var rows := PackedStringArray()
	rows.append("Ready to board and launch" if missing.is_empty() else "Before launch\n• " + "\n• ".join(missing))
	for item: Dictionary in report:
		rows.append(item.label + (" · required" if item.required else "") + "\n" + item.reason)
	var content := "\n\n".join(rows)
	if text.text != content:
		text.text = content
	_fit()

func _fit() -> void:
	text.size = Vector2(maxf(size.x - PageBar.ACROSS - 6.0, 1.0), 0.0)
	bar.visible = text.get_minimum_size().y > size.y
	scroll = scroll

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed \
		and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		var line := text.get_theme_font_size(&"font_size") + text.get_theme_constant(&"line_spacing")
		scroll += line * event.factor * (-1.0 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0)
		accept_event()
