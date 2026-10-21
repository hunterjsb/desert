class_name ControlsPage
extends Control
## One readable window onto the bindings; the title and Back stay outside it.

const ROOM := Vector2(0.8, 0.62)
const ROWS_PER_NOTCH := 3.0

var list := Controls.keys_label()
var bar := PageBar.new()
var scroll := 0.0:
	set(value):
		scroll = clampf(value, 0.0, maxf(list.get_content_height() - size.y, 0.0))
		list.position.y = -scroll
		bar.show_page(list.get_content_height(), size.y, scroll)


func _init() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	list.theme_type_variation = &"KeysList"
	list.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(list)
	bar.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	bar.offset_left = -PageBar.ACROSS
	bar.moved.connect(func(at: float) -> void: scroll = at)
	add_child(bar)


func _process(_delta: float) -> void:
	var text := Controls.help(Dev.extra_keys())
	if list.text != text:
		list.text = text
	custom_minimum_size = get_viewport_rect().size * ROOM
	list.size.x = maxf(size.x - PageBar.ACROSS, 1.0)
	bar.visible = list.get_content_height() > size.y
	scroll = scroll


func _gui_input(event: InputEvent) -> void:
	var wheel := event as InputEventMouseButton
	if wheel != null and wheel.pressed and wheel.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		var row := list.get_theme_font_size(&"normal_font_size") + list.get_theme_constant(&"table_v_separation")
		scroll += row * ROWS_PER_NOTCH * wheel.factor * (-1.0 if wheel.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0)
		accept_event()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	var row := list.get_theme_font_size(&"normal_font_size") + list.get_theme_constant(&"table_v_separation")
	if event.is_action_pressed(&"ui_down"):
		scroll += row
	elif event.is_action_pressed(&"ui_up"):
		scroll -= row
	elif event.is_action_pressed(&"ui_page_down"):
		scroll += size.y
	elif event.is_action_pressed(&"ui_page_up"):
		scroll -= size.y
	else:
		return
	get_viewport().set_input_as_handled()
