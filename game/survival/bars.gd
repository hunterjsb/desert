class_name Bars
extends CanvasLayer
## Health, hunger, thirst and stamina as four small bars in the corner, with
## the water and food you carry beside thirst and hunger. The one
## exception to almost no menus, until the suit and your senses can say it.

const WIDTH := 110.0
const ROW := 14.0
const NAME := 52.0
## Health, hunger or thirst this low is danger, and shows in the accent.
const LOW := 0.25

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
		["health", vitals.health / Vitals.FULL, true, ""],
		["hunger", vitals.hunger / Vitals.FULL, true, "%d kcal" % roundi(player.suit.stock(&"food"))],
		["thirst", vitals.thirst / Vitals.FULL, true, "%.1f L" % player.suit.stock(&"water")],
		["stamina", player.stamina / player.world.tuning.stamina_max, false, ""],
	] if player.world != null else []
	# A wound shows while it lasts: what's left of it.
	var wounds := vitals.wounds
	if player.world != null and wounds != null:
		var tuning := player.world.tuning
		if wounds.sick > 0.0:
			rows.append(["sick", wounds.sick / tuning.sickness_seconds, true, "%d s" % ceili(wounds.sick)])
		if wounds.stunned():
			rows.append(["stunned", wounds.stun / tuning.shock_stun, true, ""])
	var size := _view.get_rect().size
	var corner := Vector2(size.x - NAME - WIDTH - 70.0, size.y - rows.size() * ROW - 12.0)
	for i in rows.size():
		var row: Array = rows[i]
		var at := corner + Vector2(0.0, i * ROW)
		_text(&"Label", at + Vector2(0.0, 9.0), row[0])
		var bar := Rect2(at + Vector2(NAME, 3.0), Vector2(WIDTH, 6.0))
		_view.draw_rect(bar.grow(1.0), _view.get_theme_color(&"panel", &"Palette"))
		var fill := _view.get_theme_color(&"accent" if row[2] and row[1] < LOW else &"text", &"Palette")
		_view.draw_rect(Rect2(bar.position, Vector2(WIDTH * clampf(row[1], 0.0, 1.0), bar.size.y)), fill)
		if row[3] != "":
			_text(&"Readout", at + Vector2(NAME + WIDTH + 6.0, 9.0), row[3])


## In the theme: names as text, amounts as a readout.
func _text(type: StringName, at: Vector2, line: String) -> void:
	var font := _view.get_theme_font(&"font", type)
	var size := _view.get_theme_font_size(&"font_size", type)
	_view.draw_string_outline(font, at, line, HORIZONTAL_ALIGNMENT_LEFT, -1, size,
		_view.get_theme_constant(&"outline_size", &"Label"), _view.get_theme_color(&"shadow", &"Palette"))
	_view.draw_string(font, at, line, HORIZONTAL_ALIGNMENT_LEFT, -1, size, _view.get_theme_color(&"text", &"Palette"))
