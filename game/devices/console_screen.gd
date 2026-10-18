class_name ConsoleScreen
extends Control
## A Console's screen as its own small canvas, a terminal in the game's
## theme, monospaced, big enough to read from a step or two back. Its radar
## page is the storm map the whole width of it: storms in amber, as dense as
## their sand where a sensor reads it, humidity laid over the clear air in
## blue, unknown air dark; the front's numbers where the front is, the
## pressure's bar down its edge, the forecast along its foot, and under it the
## wind's gyro and the legend. Its other pages draw rows as a Terminal prints
## them: labels in the accent, what's urgent in amber, rows that run on dim,
## an empty row a rule, and long rows wrapped. The keys use presses run along
## its foot. Drawn only when the Console hands it something new.

const FONT := preload("res://assets/fonts/GeistMono-Regular.ttf")
const THEME := preload("res://game/ui/theme.tres")
## Type: the map's numbers, the legend's and the forecast's, the rows', the keys'.
const BIG := 40
const MID := 32
const SMALL := 28
const KEYS := 22
const MARGIN := 14.0
const ROW := 38.0
## The glass, what reads urgent (a storm's amber), unknown air, clear air dry
## and humid, and a storm at its wall and at its heart.
const GLASS := Color(0.02, 0.045, 0.05)
const URGENT := Color(0.98, 0.7, 0.25)
const UNKNOWN := Color(0.035, 0.05, 0.055)
const DRY := Color(0.06, 0.11, 0.11)
const HUMID := Color(0.07, 0.2, 0.36)
const WALL := Color(0.86, 0.6, 0.24)
const HEART := Color(0.6, 0.26, 0.08)
## The pressure bar's span either side of the storm's line, in the field's units.
const BAR_SPAN := 0.6

var _model := {}


func show_model(model: Dictionary) -> void:
	_model = model
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), GLASS)
	if _model.is_empty():
		return
	var keys_top := size.y * (1.0 - Console.KEY_SHARE)
	if _model.page == "RADAR":
		_draw_radar(keys_top)
	else:
		_draw_rows(keys_top)
	_draw_keys(keys_top)


func _color(name: StringName) -> Color:
	return THEME.get_color(name, &"Palette")


## The map the whole width, the forecast along its foot, the legend under it.
func _draw_radar(keys_top: float) -> void:
	var side := size.x
	var map: Dictionary = _model.get("map", {})
	draw_rect(Rect2(Vector2.ZERO, Vector2(side, side)), UNKNOWN)
	if not map.is_empty() and map.has("cells"):
		_draw_cells(map, side)
	var middle := Vector2(side, side) * 0.5
	var text := _color(&"text")
	var accent := _color(&"accent")
	draw_line(middle - Vector2(10.0, 0.0), middle + Vector2(10.0, 0.0), text, 3.0)
	draw_line(middle - Vector2(0.0, 10.0), middle + Vector2(0.0, 10.0), text, 3.0)
	_label(Vector2(MARGIN, MARGIN), "N", MID, accent)
	if map.has("front"):
		var at: Vector2 = map.front
		var spot: Vector2 = middle + _screen(at) / map.reach * side * 0.5
		draw_line(middle, spot, URGENT, 3.0)
		draw_circle(spot, 7.0, URGENT)
		if _model.get("front", "") != "":
			_label_at(spot, _model.front, BIG, URGENT, side)
	elif _model.get("front", "") != "":
		_label_at(Vector2(side * 0.5, side * 0.18), _model.front, BIG, URGENT, side)
	if _model.get("here", "") != "":
		_label_at(middle + Vector2(0.0, 60.0), _model.here, MID, URGENT if _model.here.begins_with("IN") else text, side)
	if map.has("pressure"):
		_draw_bar(map.pressure, Rect2(side - 52.0, 70.0, 30.0, side - 190.0))
	if _model.get("forecast", "") != "":
		var strip := Rect2(0.0, side - 52.0, side, 52.0)
		draw_rect(strip, Color(GLASS, 0.85))
		var fits := _fit(_model.forecast, SMALL, side - 2.0 * MARGIN)
		draw_string(FONT, Vector2(MARGIN, side - 16.0), fits, HORIZONTAL_ALIGNMENT_CENTER, side - 2.0 * MARGIN, SMALL, text)
	draw_rect(Rect2(Vector2.ZERO, Vector2(side, side)), Color(accent, 0.5), false, 2.0)
	_draw_legend(map, Rect2(0.0, side + 8.0, side, keys_top - side - 8.0))


## Each cell its storm, as dense as its sand where a sensor reads it, or its
## clear air as humid as it is; an estimate hatched, as only guessed.
func _draw_cells(map: Dictionary, side: float) -> void:
	var n: int = map.n
	var cells: Dictionary = map.cells
	var storm: PackedFloat32Array = cells.storm
	var sand: PackedFloat32Array = cells.sand
	var humid: PackedFloat32Array = cells.humid
	var cell := side / n
	var flip: bool = _model.flip
	var dense: bool = map.get("sand", false)
	var guessed: bool = map.estimate
	for j in n:
		for i in n:
			var k := j * n + i
			if storm[k] < 0.0:
				continue
			var col := (n - 1 - i) if flip else i
			var row := (n - 1 - j) if flip else j
			var color := DRY.lerp(HUMID, smoothstep(0.15, 0.75, humid[k])) if k < humid.size() and humid[k] >= 0.0 else DRY
			if storm[k] > 0.0:
				color = WALL.lerp(HEART, sand[k]) if dense else WALL
				color = color.lerp(DRY, 0.4 * (1.0 - storm[k]))
			var box := Rect2(Vector2(col, row) * cell, Vector2(cell, cell)).grow(-1.0)
			draw_rect(box, color)
			if guessed:
				# Hatched: only estimated.
				for s in 3:
					var from := box.position + Vector2(box.size.x * s / 3.0, box.size.y)
					draw_line(from, from + Vector2(box.size.x / 3.0, -box.size.y / 3.0), GLASS, 2.0)


## Pressure as a bar down the map's edge, the storm's line across it, filled
## to where it stands: amber when it warns.
func _draw_bar(pressure: Array, box: Rect2) -> void:
	var hpa: float = pressure[0]
	var line: float = pressure[1]
	var fall: float = pressure[2]
	var warns: bool = pressure[3]
	var top := line + fall * BAR_SPAN
	var bottom := line - fall * BAR_SPAN
	var share := clampf((hpa - bottom) / (top - bottom), 0.0, 1.0)
	draw_rect(box.grow(6.0), Color(GLASS, 0.85))
	draw_rect(box, Color(_color(&"faint"), 0.3))
	var fill := Rect2(box.position + Vector2(0.0, box.size.y * (1.0 - share)), Vector2(box.size.x, box.size.y * share))
	draw_rect(fill, URGENT if warns else _color(&"accent"))
	var storm_y := box.position.y + box.size.y * 0.5
	draw_line(Vector2(box.position.x - 8.0, storm_y), Vector2(box.end.x + 8.0, storm_y), _color(&"text"), 2.0)
	_label(Vector2(box.position.x - 6.0, box.end.y + 10.0), "hPa", SMALL - 6, _color(&"dim"))


## Under the map: the wind's gyro, its speed and where it's from; the
## pressure, humidity and sand as they read; the map's scale and resolution.
func _draw_legend(map: Dictionary, box: Rect2) -> void:
	var text := _color(&"text")
	var dim := _color(&"dim")
	var accent := _color(&"accent")
	var gyro: Array = map.get("gyro", [])
	var centre := box.position + Vector2(130.0, 140.0)
	if not gyro.is_empty():
		_gyro(centre, 105.0, gyro[0], gyro[1], -1.0)
		_label_centred(centre + Vector2(0.0, 132.0), _model.wind, MID, text)
	var x := box.position.x + 270.0
	var y := box.position.y + 34.0
	for item: Array in [["pressure", URGENT if map.get("pressure", [0, 0, 0, false])[3] else accent],
			["humidity", HUMID.lightened(0.4)], ["sand", WALL]]:
		if _model.get(item[0], "") == "":
			continue
		draw_rect(Rect2(Vector2(x, y + 8.0), Vector2(24.0, 24.0)), item[1])
		_label(Vector2(x + 36.0, y), _fit(_model[item[0]], MID, size.x - x - 50.0), MID, text)
		y += 70.0
	if _model.get("cells", "") != "":
		var scale := "%s · %d km" % [_model.cells, roundi(map.get("reach", 0.0) / 1000.0)]
		_label(Vector2(x, box.end.y - 44.0), scale + (" · est." if map.get("estimate", false) else ""), SMALL - 4, dim)


## A gyro: a dial with north marked and the wind's vector across it, the way
## it blows, as long as it's strong; a dimmer one for its steady part.
func _gyro(centre: Vector2, radius: float, from: float, speed: float, steady: float) -> void:
	var text := _color(&"text")
	var dim := _color(&"dim")
	var accent := _color(&"accent")
	draw_arc(centre, radius, 0.0, TAU, 48, Color(accent, 0.6), 2.0)
	var turn := PI if _model.flip else 0.0
	for k in 4:
		var way := Vector2.from_angle(k * PI * 0.5 + turn - PI * 0.5)
		draw_line(centre + way * radius * 0.86, centre + way * radius, accent if k == 0 else dim, 3.0)
	_label_centred(centre + Vector2.from_angle(turn - PI * 0.5) * (radius + 22.0) - Vector2(0.0, SMALL * 0.6), "N", SMALL, accent)
	var toward := Vector2.from_angle(deg_to_rad(from + 180.0) + turn - PI * 0.5)
	if steady >= 0.0:
		_arrow(centre, toward * radius * clampf(steady / 30.0, 0.15, 1.0), dim, 4.0)
	_arrow(centre, toward * radius * clampf(speed / 30.0, 0.15, 1.0), text, 5.0)


func _arrow(from: Vector2, along: Vector2, color: Color, width: float) -> void:
	var tip := from + along
	draw_line(from - along * 0.35, tip, color, width)
	var back := -along.normalized() * 18.0
	draw_line(tip, tip + back.rotated(0.45), color, width)
	draw_line(tip, tip + back.rotated(-0.45), color, width)


## A text page: its name and the clock, then its rows, wrapped, and on the
## stats page the wind's gyro and the pressure's last minutes in detail.
func _draw_rows(keys_top: float) -> void:
	var text := _color(&"text")
	var dim := _color(&"dim")
	var accent := _color(&"accent")
	_label(Vector2(MARGIN, 10.0), _model.page, MID, accent)
	draw_string(FONT, Vector2(MARGIN, 10.0 + FONT.get_ascent(MID)), _model.clock, HORIZONTAL_ALIGNMENT_RIGHT,
		size.x - 2.0 * MARGIN, MID, accent)
	draw_line(Vector2(MARGIN, 56.0), Vector2(size.x - MARGIN, 56.0), Color(accent, 0.4), 2.0)
	var detail := _model.has("gyro") or _model.has("history")
	var bottom := keys_top - (330.0 if detail else 0.0)
	var advance := FONT.get_char_size(ord("M"), SMALL).x
	var most := floori((size.x - 2.0 * MARGIN) / advance)
	var y := 66.0
	for row: String in _wrapped(_model.get("rows", []), most):
		if y + ROW > bottom:
			break
		var urgent := row.begins_with("!")
		var line := row.trim_prefix("!")
		if line == "":
			draw_line(Vector2(MARGIN, y + ROW * 0.5), Vector2(size.x - MARGIN, y + ROW * 0.5), Color(dim, 0.3))
		else:
			var color: Color = URGENT if urgent else (dim if line.begins_with(" ") else text)
			# The label column in the accent, what it reads after.
			var label := line.left(7) if line.length() > 7 and line[6] == " " and line[0] != " " and not urgent \
				and not line[0].is_valid_int() else ""
			if label != "":
				draw_string(FONT, Vector2(MARGIN, y + FONT.get_ascent(SMALL)), label, HORIZONTAL_ALIGNMENT_LEFT, -1, SMALL, accent)
			draw_string(FONT, Vector2(MARGIN + label.length() * advance, y + FONT.get_ascent(SMALL)),
				line.substr(label.length()), HORIZONTAL_ALIGNMENT_LEFT, -1, SMALL, color)
		y += ROW
	if not detail:
		return
	var top := keys_top - 320.0
	draw_line(Vector2(MARGIN, top - 8.0), Vector2(size.x - MARGIN, top - 8.0), Color(dim, 0.3))
	if _model.has("gyro"):
		var gyro: Array = _model.gyro
		_gyro(Vector2(140.0, top + 160.0), 115.0, gyro[0], gyro[1], gyro[2])
	if _model.has("history"):
		_history(_model.history, Rect2(300.0, top + 40.0, size.x - 300.0 - MARGIN, 220.0))


## The barometer's last minutes as a line, the storm's line across them.
func _history(history: Array, box: Rect2) -> void:
	var values: PackedFloat32Array = history[0]
	var line: float = history[1]
	var low := minf(line, Array(values).min()) - 0.5
	var high := maxf(line, Array(values).max()) + 0.5
	var dim := _color(&"dim")
	draw_rect(box, Color(_color(&"faint"), 0.12))
	var y_of := func(hpa: float) -> float: return box.end.y - (hpa - low) / (high - low) * box.size.y
	draw_line(Vector2(box.position.x, y_of.call(line)), Vector2(box.end.x, y_of.call(line)), Color(URGENT, 0.6), 2.0)
	var points := PackedVector2Array()
	for k in values.size():
		points.append(Vector2(box.position.x + box.size.x * k / (values.size() - 1), y_of.call(values[k])))
	draw_polyline(points, _color(&"accent"), 3.0)
	_label(box.position + Vector2(6.0, 4.0), "%.1f" % high, SMALL - 6, dim)
	_label(Vector2(box.position.x + 6.0, box.end.y - 30.0), "%.1f" % low, SMALL - 6, dim)
	_label(Vector2(box.position.x, box.end.y + 8.0), "hPa · %d min" % roundi((values.size() - 1) * Console.HISTORY_EVERY / 60.0),
		SMALL - 6, dim)


## The keys along its foot, a third of it each; the one you aim at lit.
func _draw_keys(top: float) -> void:
	var keys: Array = _model.keys
	var wide := size.x / 3.0
	var text := _color(&"text")
	var accent := _color(&"accent")
	for k in keys.size():
		var box := Rect2(Vector2(k * wide + 5.0, top + 8.0), Vector2(wide - 10.0, size.y - top - 16.0))
		var aimed: bool = _model.aim == k
		draw_rect(box, Color(accent, 0.9) if aimed else Color(accent, 0.12))
		draw_rect(box, Color(accent, 0.7), false, 2.0)
		draw_string(FONT, Vector2(box.position.x, box.position.y + (box.size.y + FONT.get_ascent(KEYS)) * 0.5 - 4.0),
			_fit(keys[k], KEYS, box.size.x - 8.0), HORIZONTAL_ALIGNMENT_CENTER, box.size.x, KEYS, GLASS if aimed else text)


## Rows longer than fit go on in rows under them, indented as runs on.
static func _wrapped(rows: Array, most: int) -> PackedStringArray:
	var out := PackedStringArray()
	for row: String in rows:
		var urgent := row.begins_with("!")
		var line := row.trim_prefix("!")
		var indent := " ".repeat(7 if line.length() > 7 and line[6] == " " else 2)
		while line.length() > most:
			var cut := line.left(most + 1).rfind(" ")
			if cut <= indent.length():
				cut = most
			out.append(("!" if urgent else "") + line.left(cut))
			line = indent + line.substr(cut).strip_edges(true, false)
		out.append(("!" if urgent else "") + line)
	return out


## A label on a dark backing, its top left at a place.
func _label(at: Vector2, words: String, font_size: int, color: Color) -> void:
	var wide := FONT.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_rect(Rect2(at - Vector2(4.0, 2.0), Vector2(wide + 8.0, font_size * 1.15)), Color(GLASS, 0.75))
	draw_string(FONT, at + Vector2(0.0, FONT.get_ascent(font_size)), words, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _label_centred(at: Vector2, words: String, font_size: int, color: Color) -> void:
	var wide := FONT.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	_label(at - Vector2(wide * 0.5, 0.0), words, font_size, color)


## A label beside a spot on the map, kept within it.
func _label_at(spot: Vector2, words: String, font_size: int, color: Color, side: float) -> void:
	var wide := FONT.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var at := spot + Vector2(-wide * 0.5, 14.0 if spot.y < side * 0.5 else -font_size * 1.4)
	at.x = clampf(at.x, MARGIN, side - MARGIN - wide - 60.0)
	at.y = clampf(at.y, MARGIN + 40.0, side - 60.0 - font_size * 1.2)
	_label(at, words, font_size, color)


## Words cut to what fits a width.
static func _fit(words: String, font_size: int, width: float) -> String:
	var most := floori(width / FONT.get_char_size(ord("M"), font_size).x)
	return words if words.length() <= most else words.left(most - 1) + "…"


## A map offset in metres east and south as the screen draws it, the moon's
## north up.
func _screen(at: Vector2) -> Vector2:
	return -at if _model.flip else at
