class_name Bars
extends CanvasLayer
## Health, hunger, thirst and stamina as four small bars in the corner, with
## the water and food left in your slots beside thirst and hunger. The one
## exception to almost no menus, until the suit and your senses can say it.

const WIDTH := 110.0
const ROW := 14.0
const NAME := 52.0
const RED := Color(0.9, 0.28, 0.22)
const AMBER := Color(0.92, 0.68, 0.25)
const BLUE := Color(0.35, 0.65, 1.0)
const PALE := Color(0.85, 0.85, 0.8)

var vitals: Vitals
var _view: Control


func _ready() -> void:
	layer = 97
	_view = Control.new()
	_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_view.draw.connect(_draw_bars)
	add_child(_view)


func _process(_delta: float) -> void:
	_view.queue_redraw()


func _draw_bars() -> void:
	var player := vitals.get_parent() as Player
	var rows := [
		["health", vitals.health / Vitals.FULL, RED, ""],
		["hunger", vitals.hunger / Vitals.FULL, AMBER, "%d kcal" % roundi(player.suit.stock(&"food"))],
		["thirst", vitals.thirst / Vitals.FULL, BLUE, "%.1f L" % player.suit.stock(&"water")],
		["stamina", player.stamina / player.world.tuning.stamina_max, PALE, ""],
	] if player.world != null else []
	var font := ThemeDB.fallback_font
	var size := _view.get_rect().size
	var corner := Vector2(size.x - NAME - WIDTH - 70.0, size.y - rows.size() * ROW - 12.0)
	for i in rows.size():
		var row: Array = rows[i]
		var at := corner + Vector2(0.0, i * ROW)
		_text(font, at + Vector2(0.0, 9.0), row[0])
		var bar := Rect2(at + Vector2(NAME, 3.0), Vector2(WIDTH, 6.0))
		_view.draw_rect(bar.grow(1.0), Color(0.0, 0.0, 0.0, 0.5))
		_view.draw_rect(Rect2(bar.position, Vector2(WIDTH * clampf(row[1], 0.0, 1.0), bar.size.y)), row[2])
		if row[3] != "":
			_text(font, at + Vector2(NAME + WIDTH + 6.0, 9.0), row[3])


func _text(font: Font, at: Vector2, line: String) -> void:
	_view.draw_string_outline(font, at, line, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, 4, Color.BLACK)
	_view.draw_string(font, at, line, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1.0, 1.0, 1.0, 0.85))
