class_name HomeView
extends Control
## Requested navigation to the one marked camp; never a permanent HUD. Only
## where Home is and how fresh that fix is: its readiness shows on the beacon,
## and Home is marked and unmarked there, by hand.

signal closed

var source: Callable
var heading: Callable
var _panel := Panel.new()
var _list := VBoxContainer.new()
var _direction := Label.new()
var _facing := Label.new()
var _reception := Label.new()
var _back := Button.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.add_child(_list)
	add_child(_panel)
	var title := Label.new()
	title.text = "Home"
	title.theme_type_variation = &"AsideName"
	_list.add_child(title)
	for line in [_reception, _direction, _facing]:
		line.theme_type_variation = &"MenuLineLead"
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_list.add_child(line)
	_back.text = "Back"
	_back.theme_type_variation = &"MenuWordMain"
	_back.pressed.connect(func() -> void: closed.emit())
	_list.add_child(_back)
	refresh()


func show_home() -> void:
	show()
	refresh()
	_back.grab_focus()


func refresh() -> void:
	var width := minf(620.0, maxf(size.x - 48.0, 1.0))
	for line in [_reception, _direction, _facing]:
		line.size.x = width - 40.0
	var home := _home()
	var nav: Dictionary = home.call(&"nav") if home != null and home.has_method(&"nav") else {}
	var marked: bool = nav.get("marked", false)
	var bearing_rad := float(nav.get("bearing", NAN))
	var metres := float(nav.get("metres", NAN))
	var has_fix := is_finite(bearing_rad) and is_finite(metres)
	_direction.visible = marked and has_fix
	_facing.visible = marked and has_fix and heading.is_valid()
	_reception.text = "No data" if not marked or not has_fix else "Live beacon signal" if nav.get("live", false) else "Last-known Home fix"
	if marked and has_fix:
		var bearing := fposmod(rad_to_deg(bearing_rad), 360.0)
		metres = maxf(metres, 0.0)
		_direction.text = "%s · %s · %03d°" % ["%.2f km" % (metres / 1000.0) if metres >= 1000.0 else "%d m" % roundi(metres), Radio.compass(bearing), roundi(bearing) % 360]
		if heading.is_valid():
			var facing: float = heading.call()
			var turn := rad_to_deg(angle_difference(facing, deg_to_rad(bearing)))
			_facing.text = "Facing %s · Home %s" % [Radio.compass(fposmod(rad_to_deg(facing), 360.0)), "ahead" if absf(turn) < 5.0 else "%d° %s" % [roundi(absf(turn)), "right" if turn > 0.0 else "left"]]
	_list.update_minimum_size()
	_list.position = Vector2(20.0, 20.0)
	_list.size = Vector2(width - 40.0, _list.get_combined_minimum_size().y)
	_panel.size = Vector2(width, _list.get_combined_minimum_size().y + 40.0)
	_panel.position = (size - _panel.size) * 0.5


func _process(_delta: float) -> void:
	if is_visible_in_tree():
		refresh()


func _home() -> Object:
	if not source.is_valid():
		return null
	var home: Object = source.call()
	return home if is_instance_valid(home) else null

