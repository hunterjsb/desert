class_name ConsoleScreen
extends Control
## A Console's screen as its own small canvas, a terminal in the game's
## theme, monospaced, big enough to read from a step or two back. Its radar
## page is the storm map the whole width of it: storms in amber, as dense as
## their sand where a sensor reads it, humidity laid over the clear air in
## blue, unknown air dark; the front's numbers where the front is, the
## pressure's bar down its edge, the forecast along its foot, and under it the
## gyro and the legend. Its power page is the deck's electrics as a panel: one
## line from what makes power through the batteries to what draws it, each
## device's switches on its row. Its other pages draw rows as a Terminal
## prints them: a table's labels in the accent, numbers right-aligned, units
## after; what's urgent in amber, rows that run on dim. Nothing wraps: a row
## too long for its line is cut. Its tabs run along its foot. Drawn only when
## the Console hands it something new; where its keys lie is laid out here,
## for the Console to find what a press is on.

const FONT := preload("res://assets/fonts/GeistMono-Regular.ttf")
const THEME := preload("res://game/ui/theme.tres")
## Type: the map's numbers, the legend's, the rows', the tabs' and the switches'.
const BIG := 40
const MID := 32
const SMALL := 28
const TAB := 26
const KEY := 24
## A trend's arrow, set small, px.
const ARROW := 14.0
const MARGIN := 14.0
const ROW := 34.0
## The share of its height the tabs take at its foot.
const TAB_SHARE := 0.09
## Where the text pages' rows start, and how much of the stats page's foot its
## gyro and the pressure's minutes take.
const TOP := 64.0
const DETAIL := 290.0
## A table's columns, in characters from its left: where its numbers end,
## where its units start, and where its notes start.
const STATS_COLUMNS := Vector3i(17, 18, 26)
const POWER_COLUMNS := Vector3i(17, 18, 21)
const LEGEND_COLUMNS := Vector3i(11, 12, 16)
## The power panel: its line down the left, its rows' left edge, and a text
## row's height, a row of switches', and the bank's charge bar's.
const BUS := 30.0
const PANEL := 56.0
const LINE := 40.0
const SWITCHES := 52.0
const BAR := 28.0
## The legend's gyro, its middle in from the legend's corner and its radius,
## and the stats page's.
const LEGEND_GYRO := Vector3(118.0, 128.0, 92.0)
const STATS_GYRO := Vector3(130.0, 135.0, 95.0)
## The glass, what reads urgent (a storm's amber), unknown air, clear air dry
## and humid, and a storm at its wall and at its heart.
const GLASS := Color(0.02, 0.045, 0.05)
const URGENT := Color(0.98, 0.7, 0.25)
const UNKNOWN := Color(0.035, 0.05, 0.055)
const DRY := Color(0.06, 0.11, 0.11)
const HUMID := Color(0.07, 0.2, 0.36)
const WALL := Color(0.86, 0.6, 0.24)
const HEART := Color(0.6, 0.26, 0.08)
## Tu-ward's mark, Tu's lit rim.
const TU := Color("#9fc0f0")
## The pressure bar's span either side of the storm's line, in the field's units.
const BAR_SPAN := 0.6
## The gyro's vectors are full length at this wind, m/s.
const FULL_WIND := 30.0

var _model := {}


## Lays out a page's keys, its tabs and any switches, each given its box on
## the canvas, and the power panel's rows their places: model.keys lists
## them all, tabs first, for the drawing and for the Console to find a
## press's key alike.
static func lay_out(model: Dictionary) -> void:
	var canvas := Vector2(Console.PIXELS)
	var keys: Array = []
	var tabs: Array = model.tabs
	var top := canvas.y * (1.0 - TAB_SHARE)
	var wide := canvas.x / tabs.size()
	for k in tabs.size():
		tabs[k]["box"] = Rect2(Vector2(k * wide + 5.0, top + 8.0), Vector2(wide - 10.0, canvas.y - top - 16.0))
		keys.append(tabs[k])
	var panel: Dictionary = model.get("panel", {})
	if not panel.is_empty():
		var y := TOP
		panel["makes_y"] = y
		y += LINE
		for source: Dictionary in panel.sources:
			source["y"] = y
			y += LINE
		panel.bank["y"] = y
		y += 3.0 * LINE + BAR
		panel["draws_y"] = y
		y += LINE
		var shown := 0
		for load: Dictionary in panel.loads:
			var tall: float = LINE + SWITCHES * load.groups.size()
			# Room is kept for a row saying how many more there are.
			if y + tall > top - LINE:
				break
			load["y"] = y
			y += LINE
			for group: Array in load.groups:
				var each := (canvas.x - MARGIN - PANEL - 8.0 * (group.size() - 1)) / group.size()
				for i in group.size():
					group[i]["box"] = Rect2(Vector2(PANEL + i * (each + 8.0), y + 4.0), Vector2(each, SWITCHES - 8.0))
					keys.append(group[i])
				y += SWITCHES
			shown += 1
		panel["shown"] = shown
		panel["end_y"] = y
	model["keys"] = keys


func show_model(model: Dictionary) -> void:
	_model = model
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), GLASS)
	if _model.is_empty():
		return
	var keys_top := size.y * (1.0 - TAB_SHARE)
	match _model.page:
		"RADAR":
			_draw_radar(keys_top)
		"POWER":
			_draw_header()
			_draw_power()
		_:
			_draw_header()
			_draw_rows(keys_top)
	_draw_keys()


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


## Under the map: the gyro, the wind's speed and where it's from and its
## angle off the bow; the pressure, humidity and sand as a small table, each
## by its colour on the map; the map's scale and resolution.
func _draw_legend(map: Dictionary, box: Rect2) -> void:
	var text := _color(&"text")
	var dim := _color(&"dim")
	var accent := _color(&"accent")
	var gyro: Dictionary = map.get("gyro", {})
	var centre := box.position + Vector2(LEGEND_GYRO.x, LEGEND_GYRO.y)
	if not gyro.is_empty():
		_gyro(centre, LEGEND_GYRO.z, gyro, false)
		_label_centred(centre + Vector2(0.0, LEGEND_GYRO.z + 16.0), _model.wind, MID, text)
		_label_centred(centre + Vector2(0.0, LEGEND_GYRO.z + 56.0), _model.angle, MID, accent)
	var x := LEGEND_GYRO.x * 2.0 - 4.0
	var y := box.position.y + 24.0
	for item: Array in [["pressure", URGENT if map.get("pressure", [0, 0, 0, false])[3] else accent],
			["humidity", HUMID.lightened(0.4)], ["sand", WALL]]:
		if _model.get(item[0], "") == "":
			continue
		draw_rect(Rect2(Vector2(x, y + 6.0), Vector2(22.0, 22.0)), item[1])
		_table_row(_model[item[0]], x + 30.0, y, LEGEND_COLUMNS)
		y += 62.0
	if _model.get("cells", "") != "":
		var scale := "%s · %d km" % [_model.cells, roundi(map.get("reach", 0.0) / 1000.0)]
		_label(Vector2(x, box.end.y - 44.0), scale + (" · est." if map.get("estimate", false) else ""), SMALL - 4, dim)


## A compass gyro, north up: Tu-ward, a mark on the rim in Tu's colour; the
## way the deck points, a line out to a mark on the rim; the wind as the deck
## feels it, a vector flying in from where it comes from, as long as it's
## strong; and the angle between the two marked. A dimmer vector for the
## wind's steady part, if asked.
func _gyro(centre: Vector2, radius: float, gyro: Dictionary, steady: bool) -> void:
	var text := _color(&"text")
	var dim := _color(&"dim")
	var accent := _color(&"accent")
	draw_arc(centre, radius, 0.0, TAU, 48, Color(accent, 0.6), 2.0)
	var turn := PI if _model.flip else 0.0
	for k in 4:
		var way := Vector2.from_angle(k * PI * 0.5 + turn - PI * 0.5)
		draw_line(centre + way * radius * 0.86, centre + way * radius, accent if k == 0 else dim, 3.0)
	_label_centred(centre + Vector2.from_angle(turn - PI * 0.5) * (radius + 22.0) - Vector2(0.0, SMALL * 0.6), "N", SMALL, accent)
	if gyro.has("tu"):
		var tu := _way(gyro.tu, turn)
		draw_line(centre + tu * radius * 0.8, centre + tu * (radius + 6.0), TU, 5.0)
		# Inside the rim: out past it, west runs off the legend's edge.
		_label_centred(centre + tu * radius * 0.6 - Vector2(0.0, KEY * 0.6), "TU", KEY, TU)
	var bow := _way(gyro.heading, turn)
	var from := _way(gyro.from, turn)
	draw_line(centre, centre + bow * radius, Color(accent, 0.8), 3.0)
	var rim := centre + bow * (radius + 3.0)
	draw_colored_polygon(PackedVector2Array([rim + bow * 16.0, rim + bow.orthogonal() * 10.0, rim - bow.orthogonal() * 10.0]),
		accent)
	var a := bow.angle()
	draw_arc(centre, radius * 0.32, a, a + angle_difference(a, from.angle()), 24, accent.lightened(0.35), 3.0)
	var inner := radius * 0.1
	if steady:
		var reach: float = radius * clampf(gyro.steady / FULL_WIND, 0.15, 0.9)
		_arrow(centre + from * (inner + reach), centre + from * inner, dim, 4.0)
	_arrow(centre + from * (inner + radius * clampf(gyro.speed / FULL_WIND, 0.15, 0.9)), centre + from * inner, text, 5.0)


## A compass bearing's way on the screen, the moon's north up.
static func _way(bearing: float, turn: float) -> Vector2:
	return Vector2.from_angle(deg_to_rad(bearing) + turn - PI * 0.5)


func _arrow(tail: Vector2, tip: Vector2, color: Color, width: float) -> void:
	draw_line(tail, tip, color, width)
	var back := (tail - tip).normalized() * 18.0
	draw_line(tip, tip + back.rotated(0.45), color, width)
	draw_line(tip, tip + back.rotated(-0.45), color, width)


## A text page's name and the clock over a rule.
func _draw_header() -> void:
	var accent := _color(&"accent")
	_label(Vector2(MARGIN, 10.0), _model.page, MID, accent)
	draw_string(FONT, Vector2(MARGIN, 10.0 + FONT.get_ascent(MID)), _model.clock, HORIZONTAL_ALIGNMENT_RIGHT,
		size.x - 2.0 * MARGIN, MID, accent)
	draw_line(Vector2(MARGIN, 54.0), Vector2(size.x - MARGIN, 54.0), Color(accent, 0.4), 2.0)


## A text page's rows, and on the stats page the gyro and the pressure's last
## minutes in detail under them.
func _draw_rows(keys_top: float) -> void:
	var dim := _color(&"dim")
	var detail := _model.has("gyro") or _model.has("history")
	var bottom := keys_top - (DETAIL if detail else 0.0)
	var y := TOP
	for row: String in _model.get("rows", []):
		if y + ROW > bottom:
			break
		_table_row(row, MARGIN, y, STATS_COLUMNS)
		y += ROW
	if not detail:
		return
	var top := keys_top - DETAIL + 10.0
	draw_line(Vector2(MARGIN, top - 4.0), Vector2(size.x - MARGIN, top - 4.0), Color(dim, 0.3))
	if _model.has("gyro"):
		var centre := Vector2(STATS_GYRO.x, top + STATS_GYRO.y)
		_gyro(centre, STATS_GYRO.z, _model.gyro, true)
		_label_centred(centre + Vector2(0.0, STATS_GYRO.z + 10.0), _model.gyro.angle, SMALL, _color(&"accent"))
	if _model.has("history"):
		var left := STATS_GYRO.x * 2.0 + 30.0
		_history(_model.history, Rect2(left, top + 30.0, size.x - left - MARGIN, 200.0))


## A row as a terminal prints it, at a place: a table's label in the accent
## (dim, indented, under a reading), its number right-aligned where the
## columns say, its unit dim after it and its note after that, a trend's
## arrow small; a lead and its text, a log line's time dim; or plain words.
## What's urgent is amber. Cut, never wrapped, if it runs past the edge. A
## name, a device on the power panel, reads in the text's colour.
func _table_row(row: String, x: float, y: float, columns: Vector3i, named := false) -> void:
	var text := _color(&"text")
	var dim := _color(&"dim")
	var accent := _color(&"accent")
	var urgent := row.begins_with("!")
	var cells := row.trim_prefix("!").split("\t")
	var advance := FONT.get_char_size(ord("M"), SMALL).x
	var base := y + (ROW + FONT.get_ascent(SMALL) - FONT.get_descent(SMALL)) * 0.5
	var room := size.x - MARGIN - x
	if cells.size() == 1:
		_words(Vector2(x, base), cells[0], room, SMALL, URGENT if urgent else (dim if cells[0].begins_with(" ") else text))
		return
	if cells.size() == 2:
		var lead := maxf(6.0, cells[0].length() + 1.0) * advance
		_words(Vector2(x, base), cells[0], lead, SMALL, dim)
		_words(Vector2(x + lead, base), cells[1], room - lead, SMALL, URGENT if urgent else text)
		return
	var label := cells[0].trim_prefix(" ") if named else cells[0]
	var sub := label.begins_with(" ")
	_words(Vector2(x, base), label, (columns.x - cells[1].length() - 1) * advance, SMALL,
		URGENT if urgent and not sub else (dim if sub else (text if named else accent)))
	var number_x := x + columns.x * advance - cells[1].length() * advance
	_words(Vector2(number_x, base), cells[1], room, SMALL, URGENT if urgent else text)
	_words(Vector2(x + columns.y * advance, base), cells[2], (columns.z - columns.y) * advance, SMALL, dim)
	var note: String = cells[3] if cells.size() > 3 else ""
	var note_x := x + columns.z * advance
	if note in ["▲", "▼", "–"]:
		_trend(Vector2(note_x + ARROW, y + ROW * 0.5), note, URGENT if urgent else text)
	else:
		_words(Vector2(note_x, base), note, size.x - MARGIN - note_x, SMALL, URGENT if urgent else text)


## A trend as a small arrow centred on a spot: up, down, or a dash for steady.
func _trend(at: Vector2, note: String, color: Color) -> void:
	var half := ARROW * 0.5
	if note == "–":
		draw_line(at - Vector2(half, 0.0), at + Vector2(half, 0.0), color, 3.0)
		return
	var up := -1.0 if note == "▲" else 1.0
	draw_colored_polygon(PackedVector2Array([at + Vector2(0.0, half * up), at + Vector2(-half, -half * up),
		at + Vector2(half, -half * up)]), color)


## Words on a baseline, cut to what fits a width.
func _words(at: Vector2, words: String, width: float, font_size: int, color: Color) -> void:
	if words != "":
		draw_string(FONT, at, _fit(words, font_size, width), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


## The deck's electrics as one line down the left: what makes power feeding
## it at the top, the batteries on it with their charge, and what draws it
## below, each a branch off the line with its watts, and under each device
## its rows of switches.
func _draw_power() -> void:
	var panel: Dictionary = _model.get("panel", {})
	if panel.is_empty():
		return
	var text := _color(&"text")
	var dim := _color(&"dim")
	var accent := _color(&"accent")
	var mid := LINE * 0.5
	var nodes: Array[float] = [panel.makes_y + mid]
	_power_row(panel.makes, panel.makes_y)
	for source: Dictionary in panel.sources:
		_power_row(source.row, source.y, true)
		# What makes power feeds the line.
		var at: float = source.y + mid
		_arrow(Vector2(PANEL - 6.0, at), Vector2(BUS + 6.0, at), accent, 3.0)
		nodes.append(at)
	var bank: Dictionary = panel.bank
	_power_row(bank.row, bank.y)
	nodes.append(bank.y + mid)
	var bar := Rect2(PANEL, bank.y + LINE + 4.0, size.x - MARGIN - PANEL, BAR - 8.0)
	draw_rect(bar, Color(_color(&"faint"), 0.3))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * bank.share, bar.size.y)), URGENT if bank.share < Power.RESERVE else accent)
	draw_rect(bar, Color(accent, 0.6), false, 2.0)
	_power_row(bank.net, bank.y + LINE + BAR)
	_power_row(bank.left, bank.y + 2.0 * LINE + BAR)
	_power_row(panel.draws, panel.draws_y)
	nodes.append(panel.draws_y + mid)
	var loads: Array = panel.loads
	for i in panel.shown:
		var load: Dictionary = loads[i]
		_power_row(("!" if load.dark else "") + load.row, load.y, true)
		# What draws takes from the line.
		var at: float = load.y + mid
		_arrow(Vector2(BUS + 6.0, at), Vector2(PANEL - 8.0, at), dim if load.dark else text, 3.0)
		nodes.append(at)
	if panel.shown < loads.size():
		_power_row(" +%d more" % (loads.size() - panel.shown), panel.end_y)
	draw_line(Vector2(BUS, nodes[0]), Vector2(BUS, nodes[-1]), accent, 4.0)
	for at in nodes:
		draw_circle(Vector2(BUS, at), 5.0, accent)
	# The batteries sit on the line: a cell's mark.
	var cell := Rect2(Vector2(BUS - 12.0, bank.y + mid - 7.0), Vector2(24.0, 14.0))
	draw_rect(cell, GLASS)
	draw_rect(cell, accent, false, 2.0)
	draw_rect(Rect2(Vector2(BUS - 4.0, cell.position.y - 4.0), Vector2(8.0, 4.0)), accent)


## A row of the power panel, centred in its line.
func _power_row(row: String, y: float, named := false) -> void:
	_table_row(row, PANEL, y + (LINE - ROW) * 0.5, POWER_COLUMNS, named)


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


## Every key in its box: the one you aim at lit up, a tab on its own page
## and a switch for how its device stands marked, the rest faint.
func _draw_keys() -> void:
	var keys: Array = _model.keys
	var text := _color(&"text")
	var dim := _color(&"dim")
	var accent := _color(&"accent")
	for k in keys.size():
		var key: Dictionary = keys[k]
		var box: Rect2 = key.box
		var aimed: bool = _model.aim == k
		var font_size := TAB if key.device == null else KEY
		draw_rect(box, Color(accent, 0.9) if aimed else (Color(accent, 0.35) if key.lit else Color(accent, 0.08)))
		draw_rect(box, Color(accent, 0.9 if key.lit else 0.45), false, 3.0 if key.lit else 2.0)
		draw_string(FONT, Vector2(box.position.x, box.position.y + (box.size.y + FONT.get_ascent(font_size)) * 0.5 - 3.0),
			_fit(key.text, font_size, box.size.x - 8.0), HORIZONTAL_ALIGNMENT_CENTER, box.size.x, font_size,
			GLASS if aimed else (text if key.lit else dim))


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
	return words if words.length() <= most else words.left(maxi(most - 1, 0)) + "…"


## A map offset in metres east and south as the screen draws it, the moon's
## north up.
func _screen(at: Vector2) -> Vector2:
	return -at if _model.flip else at
