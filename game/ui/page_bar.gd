class_name PageBar
extends Control
## A bar beside a page longer than shows: what shows, along the whole, in the
## theme's dim ink over its faint, brighter while held or pointed at. Drawn
## here, since an engine scroll bar styles itself past the one theme. Dragged,
## or pressed along it, it says where what shows should start; the wheel over
## it reaches its page.

signal moved(at: float)

## Wide enough to take hold of, the bar drawn down its middle, and the
## shortest what shows is drawn, px.
const ACROSS := 12.0
const WIDE := 4.0
const SHORTEST := 18.0

## The page's length, how much of it shows and where what shows starts, in
## the page's own units: px, or lines.
var whole := 0.0
var shown := 0.0
var at := 0.0
## Where along what shows it was taken hold of, px; below 0 while it isn't.
var _held := -1.0
var _pointed := false


func _init() -> void:
	custom_minimum_size.x = ACROSS
	mouse_filter = Control.MOUSE_FILTER_PASS


func show_page(length: float, showing: float, start: float) -> void:
	whole = length
	shown = showing
	at = clampf(start, 0.0, maxf(whole - shown, 0.0))
	queue_redraw()


func _notification(what: int) -> void:
	if what in [NOTIFICATION_MOUSE_ENTER, NOTIFICATION_MOUSE_EXIT]:
		_pointed = what == NOTIFICATION_MOUSE_ENTER
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var press := event as InputEventMouseButton
	if press != null and press.button_index == MOUSE_BUTTON_LEFT and whole > shown:
		_held = -1.0
		if press.pressed:
			var thumb := _thumb()
			var on := press.position.y >= thumb.x and press.position.y <= thumb.x + thumb.y
			_held = press.position.y - thumb.x if on else thumb.y * 0.5
			_drag(press.position.y)
		queue_redraw()
		accept_event()
	elif event is InputEventMouseMotion and _held >= 0.0:
		_drag(event.position.y)
		accept_event()


func _drag(y: float) -> void:
	var room := size.y - _thumb().y
	moved.emit(clampf((y - _held) / room, 0.0, 1.0) * (whole - shown) if room > 0.0 else 0.0)


## What shows: how far down it starts and how long it is, px.
func _thumb() -> Vector2:
	var length := clampf(size.y * shown / whole, minf(SHORTEST, size.y), size.y) if whole > 0.0 else size.y
	var spare := whole - shown
	return Vector2((size.y - length) * at / spare if spare > 0.0 else 0.0, length)


func _draw() -> void:
	if whole <= shown + 0.5:
		return
	var x := (size.x - WIDE) * 0.5
	draw_rect(Rect2(x, 0.0, WIDE, size.y), get_theme_color(&"faint", &"Palette") * Color(1.0, 1.0, 1.0, 0.5))
	var thumb := _thumb()
	var lit := _held >= 0.0 or _pointed
	draw_rect(Rect2(x, thumb.x, WIDE, thumb.y), get_theme_color(&"text" if lit else &"dim", &"Palette"))
