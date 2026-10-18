class_name ConsoleScreen
extends Control
## A Console's screen as its own small canvas: a terminal in the game's theme,
## monospaced. It draws rows as a Terminal prints them: labels in the accent,
## what's urgent in amber, rows that run on dim, an empty row a rule. A storm
## map at the right when there's one, and the keys use presses along its foot.
## Drawn only when the Console hands it something new.

const FONT := preload("res://assets/fonts/GeistMono-Regular.ttf")
const THEME := preload("res://game/ui/theme.tres")
const SIZE := 16
const HEAD := 34.0
const ROW := 21.0
const MARGIN := 14.0
## Its glass, and what reads urgent: a storm's amber.
const GLASS := Color(0.02, 0.045, 0.05)
const URGENT := Color(0.98, 0.7, 0.25)
## The storm map's side, px, and its clear air and storm at its fullest.
const MAP := 300.0
const CLEAR := Color(0.05, 0.1, 0.1)
const STORM := Color(0.75, 0.45, 0.18)

var _model := {}


func show_model(model: Dictionary) -> void:
	_model = model
	queue_redraw()


func _draw() -> void:
	var text := THEME.get_color(&"text", &"Palette")
	var dim := THEME.get_color(&"dim", &"Palette")
	var accent := THEME.get_color(&"accent", &"Palette")
	draw_rect(Rect2(Vector2.ZERO, size), GLASS)
	if _model.is_empty():
		return
	var advance := FONT.get_char_size(ord("M"), SIZE).x
	var ascent := FONT.get_ascent(SIZE)
	draw_string(FONT, Vector2(MARGIN, 8.0 + ascent), _model.head, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE, accent)
	draw_string(FONT, Vector2(MARGIN, 8.0 + ascent), _model.clock, HORIZONTAL_ALIGNMENT_RIGHT, size.x - 2.0 * MARGIN,
		SIZE, accent)
	draw_line(Vector2(MARGIN, HEAD), Vector2(size.x - MARGIN, HEAD), Color(accent, 0.4))
	var keys_top := size.y * (1.0 - Console.KEY_SHARE)
	var map: Dictionary = _model.map
	var right := size.x - MARGIN - (MAP + MARGIN if not map.is_empty() else 0.0)
	var most := floori((right - MARGIN) / advance)
	var y := HEAD + 6.0
	for row: String in _model.rows:
		if y + ROW > keys_top:
			break
		var urgent := row.begins_with("!")
		var line := row.trim_prefix("!")
		if line == "":
			draw_line(Vector2(MARGIN, y + ROW * 0.5), Vector2(right, y + ROW * 0.5), Color(dim, 0.3))
		else:
			line = line.left(most)
			var color: Color = URGENT if urgent else (dim if line.begins_with(" ") else text)
			# The label column in the accent, what it reads after.
			var label := line.left(7) if line.length() > 7 and line[6] == " " and line[0] != " " and not urgent \
				and not line[0].is_valid_int() else ""
			if label != "":
				draw_string(FONT, Vector2(MARGIN, y + ascent), label, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE, accent)
			draw_string(FONT, Vector2(MARGIN + label.length() * advance, y + ascent), line.substr(label.length()),
				HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE, color)
		y += ROW
	if not map.is_empty():
		_draw_map(map, Vector2(size.x - MARGIN - MAP, HEAD + 10.0), text, dim, accent)
	_draw_keys(keys_top, text, accent)


## North up: each cell its storm, you at the middle, the nearest edge marked
## and the way storms ride shown at its foot.
func _draw_map(map: Dictionary, at: Vector2, text: Color, dim: Color, accent: Color) -> void:
	var n: int = map.n
	var cells: PackedFloat32Array = map.cells
	var cell := MAP / n
	var flip: bool = map.flip
	for j in n:
		for i in n:
			var s := cells[j * n + i]
			var col := (n - 1 - i) if flip else i
			var row := (n - 1 - j) if flip else j
			draw_rect(Rect2(at + Vector2(col, row) * cell, Vector2(cell, cell) - Vector2.ONE),
				CLEAR.lerp(STORM, 0.35 + 0.65 * s) if s > 0.0 else CLEAR)
	var middle := at + Vector2.ONE * MAP * 0.5
	var turn := PI if flip else 0.0
	var front: Array = map.front
	if not front.is_empty() and map.reach > 0.0:
		var way := Vector2.from_angle(deg_to_rad(front[1]) + turn - PI * 0.5)
		draw_line(middle, middle + way * front[0] / map.reach * MAP * 0.5, URGENT, 2.0)
	draw_line(middle - Vector2(6.0, 0.0), middle + Vector2(6.0, 0.0), text, 2.0)
	draw_line(middle - Vector2(0.0, 6.0), middle + Vector2(0.0, 6.0), text, 2.0)
	draw_rect(Rect2(at, Vector2.ONE * MAP), Color(accent, 0.5), false, 1.0)
	var ascent := FONT.get_ascent(SIZE)
	var advance := FONT.get_char_size(ord("M"), SIZE).x
	draw_rect(Rect2(at + Vector2(1.0, 1.0), Vector2(advance + 8.0, ROW)), GLASS)
	draw_string(FONT, at + Vector2(4.0, ascent + 2.0), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE, accent)
	var moving := Vector2.from_angle(deg_to_rad(map.moving) + turn - PI * 0.5)
	var foot := at + Vector2(MAP - 24.0, MAP - 24.0)
	draw_line(foot - moving * 12.0, foot + moving * 12.0, dim, 2.0)
	draw_circle(foot + moving * 12.0, 3.5, dim)
	var scale := "%d km" % roundi(map.reach / 1000.0)
	draw_rect(Rect2(at + Vector2(1.0, MAP - ROW - 1.0), Vector2(advance * scale.length() + 8.0, ROW)), GLASS)
	draw_string(FONT, at + Vector2(4.0, MAP - 8.0), scale, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE, dim)


## The keys along its foot, a third of it each; the one you aim at lit.
func _draw_keys(top: float, text: Color, accent: Color) -> void:
	var keys: Array = _model.keys
	var wide := size.x / 3.0
	var ascent := FONT.get_ascent(SIZE)
	for k in keys.size():
		var box := Rect2(Vector2(k * wide + 6.0, top + 6.0), Vector2(wide - 12.0, size.y - top - 12.0))
		var aimed: bool = _model.aim == k
		draw_rect(box, Color(accent, 0.9) if aimed else Color(accent, 0.12))
		draw_rect(box, Color(accent, 0.7), false, 1.0)
		draw_string(FONT, Vector2(box.position.x, box.position.y + (box.size.y + ascent) * 0.5 - 2.0), keys[k],
			HORIZONTAL_ALIGNMENT_CENTER, box.size.x, SIZE, GLASS if aimed else text)
