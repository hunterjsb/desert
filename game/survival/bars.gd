class_name Bars
extends CanvasLayer
## Health and stamina as two small bars in the corner, and under them what
## you're prepared with, by name: rested, fed, hydrated (Buffs). Fed, the
## stamina bar runs longer. With what you carry open, each says the hours it
## has left, and fed and hydrated the food and water you carry. Hunger and
## thirst never show: going without only means going unprepared. The one
## exception to almost no menus, until the suit and your senses can say it.

const WIDTH := 110.0
const ROW := 14.0
const NAME := 52.0
## Health this low is danger, and shows in the accent.
const LOW := 0.25
## A buff not on you, shown only while you look, or Rested while you rest toward it.
const FAINT := 0.45

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


## Each row: its name, how full its bar (none below 0), whether low is
## danger, its readout, how long its bar runs and how strongly it shows.
func _draw_bars() -> void:
	var player := vitals.get_parent() as Player
	if player.world == null:
		return
	var tuning := player.world.tuning
	var full := player.stamina_full()
	var rows := [
		["health", vitals.health / Vitals.FULL, true, "", 1.0, 1.0],
		["stamina", player.stamina / full, false, "", full / tuning.stamina_max, 1.0],
	]
	var looking := player.suit.open
	var buffs := vitals.buffs
	var hour := tuning.day_minutes * 60.0 / 24.0
	for buff: StringName in Buffs.ALL:
		var on := buffs.active(buff)
		if not (on or looking or (buff == &"rested" and buffs.resting > 0.0)):
			continue
		var says := PackedStringArray()
		if looking and on:
			says.append("%d h" % ceili(buffs.get(buff) / hour))
		if looking and buff == &"fed":
			says.append("%d kcal" % roundi(player.suit.stock(&"food")))
		elif looking and buff == &"hydrated":
			says.append("%.2f L" % player.suit.stock(&"water"))
		rows.append([String(buff), -1.0, false, "  ".join(says), 0.0, 1.0 if on else FAINT])
	# A wound shows while it lasts: what's left of it.
	var wounds := vitals.wounds
	if wounds != null:
		if wounds.sick > 0.0:
			rows.append(["sick", wounds.sick / tuning.sickness_seconds, true, "%d s" % ceili(wounds.sick), 1.0, 1.0])
		if wounds.stunned():
			rows.append(["stunned", wounds.stun / tuning.shock_stun, true, "", 1.0, 1.0])
	var size := _view.get_rect().size
	var corner := Vector2(size.x - NAME - WIDTH - 70.0, size.y - rows.size() * ROW - 12.0)
	for i in rows.size():
		var row: Array = rows[i]
		var at := corner + Vector2(0.0, i * ROW)
		_text(&"Label", at + Vector2(0.0, 9.0), row[0], row[5])
		if row[1] < 0.0:
			if row[3] != "":
				_text(&"Readout", at + Vector2(NAME + 6.0, 9.0), row[3], row[5])
			continue
		var bar := Rect2(at + Vector2(NAME, 3.0), Vector2(WIDTH * row[4], 6.0))
		_view.draw_rect(bar.grow(1.0), _view.get_theme_color(&"panel", &"Palette"))
		var fill := _view.get_theme_color(&"accent" if row[2] and row[1] < LOW else &"text", &"Palette")
		_view.draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(row[1], 0.0, 1.0), bar.size.y)), fill)
		if row[3] != "":
			_text(&"Readout", at + Vector2(NAME + bar.size.x + 6.0, 9.0), row[3], row[5])


## In the theme: names as text, amounts as a readout.
func _text(type: StringName, at: Vector2, line: String, alpha := 1.0) -> void:
	var font := _view.get_theme_font(&"font", type)
	var size := _view.get_theme_font_size(&"font_size", type)
	var shadow := _view.get_theme_color(&"shadow", &"Palette")
	var text := _view.get_theme_color(&"text", &"Palette")
	shadow.a *= alpha
	text.a *= alpha
	_view.draw_string_outline(font, at, line, HORIZONTAL_ALIGNMENT_LEFT, -1, size,
		_view.get_theme_constant(&"outline_size", &"Label"), shadow)
	_view.draw_string(font, at, line, HORIZONTAL_ALIGNMENT_LEFT, -1, size, text)
