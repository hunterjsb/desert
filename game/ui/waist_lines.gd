class_name WaistLines
extends Control
## Physical lines at your waist, selected from the existing carry view.
## The list scrolls within its own space; the world keeps moving behind it.

const HEIGHT := 136.0
const ROW := 24.0

var reel: Reel
var waist: Waist
var _lines: Array[RigidBody3D] = []
var _scroll := 0.0
var _hover := -1
var _bar := PageBar.new()


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_bar.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	_bar.offset_left = -PageBar.ACROSS
	_bar.moved.connect(func(at: float) -> void:
		_scroll = at
		queue_redraw())
	add_child(_bar)
	mouse_exited.connect(func() -> void:
		_hover = -1
		queue_redraw())


func refresh() -> void:
	_lines = reel.waist_lines()
	visible = not waist.tied.is_empty()
	_scroll = clampf(_scroll, 0.0, maxf((_lines.size() + 2) * ROW - size.y, 0.0))
	_bar.show_page((_lines.size() + 2) * ROW, size.y, _scroll)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_hover = floori((event.position.y + _scroll) / ROW)
		queue_redraw()
	var press := event as InputEventMouseButton
	if press == null or not press.pressed:
		return
	if press.button_index == MOUSE_BUTTON_WHEEL_UP:
		_scroll -= ROW
	elif press.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_scroll += ROW
	elif press.button_index == MOUSE_BUTTON_LEFT:
		var at := floori((press.position.y + _scroll) / ROW)
		if at == 0:
			reel.choose(null)
		elif at == _lines.size() + 1:
			waist.release_all()
		elif at > 0 and at <= _lines.size() and is_instance_valid(_lines[at - 1]):
			reel.choose(_lines[at - 1])
	refresh()
	accept_event()


func _draw() -> void:
	var font := get_theme_font(&"font", &"Label")
	var font_size := get_theme_font_size(&"font_size", &"Label")
	var chosen := reel.chosen_body()
	for i in _lines.size() + 2:
		var y := i * ROW - _scroll
		if y + ROW < 0.0 or y >= size.y:
			continue
		var releasing := i == _lines.size() + 1
		var selected := chosen == null if i == 0 else not releasing and chosen == _lines[i - 1]
		var words := "Follow gaze" if i == 0 else "Release all waist lines" if releasing \
			else reel.waist_description(_lines[i - 1])
		if releasing and waist.untying >= 0.0:
			words = waist.release_readout()
			if words == "":
				words = "Untying a line · %.1f s" % maxf(waist.untying, 0.0)
		words = ("> " if selected else "  ") + words
		var ink := get_theme_color(&"accent" if releasing else &"text" if selected or i == _hover else &"dim", &"Palette")
		var at := Vector2(0.0, y + (ROW + font_size) * 0.5 - 2.0)
		draw_string_outline(font, at, words, HORIZONTAL_ALIGNMENT_LEFT, size.x - PageBar.ACROSS,
			font_size, get_theme_constant(&"outline_size", &"Label"), get_theme_color(&"shadow", &"Palette"))
		draw_string(font, at, words, HORIZONTAL_ALIGNMENT_LEFT, size.x - PageBar.ACROSS, font_size, ink)
		if releasing and waist.release_readout() != "":
			var bar := Rect2(0.0, y + ROW - 2.0, size.x - PageBar.ACROSS, 2.0)
			draw_rect(bar, get_theme_color(&"faint", &"Palette"))
			bar.size.x *= waist.release_progress()
			draw_rect(bar, ink)
