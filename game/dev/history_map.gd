class_name HistoryMap
extends Control
## Dev: the history under the sand round you, seen from above with the moon's
## north up. What the sheet has laid is drawn bright: path pieces, sites by
## era (hollow where only planned), the grid's ruins, landmarks with their
## parts, and how far the loaded ground and the laying reach. Past what's laid
## the whole plan is drawn faint through your own point on the moon, so a wide
## map shows the artery, the spokes and the great sites.

## Each era's colour on the map.
const ERA := {Eras.COLONIAL: Color(0.62, 0.72, 0.82), Eras.SKIMMER: Color(0.9, 0.55, 0.25),
	Eras.FIRST: Color(0.83, 0.68, 0.2), Eras.DARK: Color(0.6, 0.55, 0.46), Eras.SECOND: Color(0.93, 0.87, 0.74)}
const WATER := Color(0.36, 0.64, 0.86)
## The map's side as a share of the screen's height, and its edge, px.
const SHARE := 0.8
const EDGE := 24.0
## The far plan is drawn again once you've moved this far, m.
const REDRAW_FAR := 50.0
## The grid's ruins are drawn on maps up to this wide, m.
const GRID_RUINS_M := 6000.0

## Metres across the map.
var width_m := 2000.0

var _ui: UIRoot
## The map is drawn in a panel that clips what runs off its edge.
var _panel: Control
var _far := []
var _far_from := Vector2(INF, INF)
var _far_width := 0.0


static func of(ui: UIRoot) -> HistoryMap:
	for child in ui.get_children():
		if child is HistoryMap:
			return child
	var made := HistoryMap.new()
	made._ui = ui
	made.visible = false
	made.mouse_filter = Control.MOUSE_FILTER_IGNORE
	made.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	made._panel = Control.new()
	made._panel.clip_contents = true
	made._panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	made._panel.draw.connect(made._draw_map)
	made.add_child(made._panel)
	ui.add_child(made)
	ui.move_child(made, 0)
	return made


func _process(_delta: float) -> void:
	if visible:
		var side := get_viewport_rect().size.y * SHARE
		_panel.position = Vector2(get_viewport_rect().size.x - side - EDGE, (get_viewport_rect().size.y - side) * 0.5)
		_panel.size = Vector2.ONE * side
		_panel.queue_redraw()


func _draw_map() -> void:
	var world := _ui.main.world() if _ui != null and _ui.main != null else null
	if world == null:
		return
	var box := Rect2(Vector2.ZERO, _panel.size)
	var side := box.size.y
	_panel.draw_rect(box, get_theme_color(&"panel", &"Palette"))
	var px := world.player_world_x()
	var pz := world.player_world_z()
	var facing := -world.moon.north().z
	var scale := side / width_m
	var to_map := func(x: float, z: float) -> Vector2:
		return box.get_center() + Vector2(x - px, z - pz) * facing * scale
	var sites := world.shape.sites
	_draw_far(world, box, to_map)
	# How far the loaded ground and the laying reach.
	var loaded := (world.tuning.view_radius + 0.5) * world.tuning.chunk_size
	_panel.draw_rect(Rect2(to_map.call(px - loaded, pz - loaded), Vector2.ONE * loaded * 2.0 * scale), Color(1, 1, 1, 0.15),
		false, 1.0)
	_panel.draw_arc(box.get_center(), world.tuning.history_lay_m * scale, 0.0, TAU, 64, Color(1, 1, 1, 0.1), 1.0)
	for unit in sites.units():
		for piece in unit.pieces:
			var line := PackedVector2Array()
			for point in piece.points:
				line.append(to_map.call(point.x, point.y))
			if line.size() > 1:
				_panel.draw_polyline(line, _path_colour(piece.eras, piece.carries), 2.0)
	for unit in sites.units():
		for site in unit.sites:
			var at: Vector2 = to_map.call(site.x, site.z)
			if box.has_point(at):
				var colour: Color = ERA[site.era]
				var r := maxf(2.0, site.reach * scale)
				if SiteKinds.is_sign(site.kind):
					_panel.draw_circle(at, 1.5, colour)
				else:
					_panel.draw_rect(Rect2(at - Vector2.ONE * r, Vector2.ONE * r * 2.0), colour, not site.planned, 1.0)
	var half := width_m * 0.5
	# The grid's ruins only up close: wider, there are thousands to survey.
	for ruin in world.shape.ruins.around(px, pz, half * 1.5) if width_m <= GRID_RUINS_M else []:
		var at: Vector2 = to_map.call(ruin.x, ruin.z)
		if box.has_point(at):
			_panel.draw_rect(Rect2(at - Vector2.ONE * 3.0, Vector2.ONE * 6.0), ERA[Eras.SECOND])
	for mark in sites.landmarks_in(Rect2(px - half, pz - half, width_m, width_m)):
		var at: Vector2 = to_map.call(mark.x, mark.z)
		_panel.draw_arc(at, mark.radius * scale, 0.0, TAU, 48, Color(get_theme_color(&"accent", &"Palette"), 0.7), 1.5)
		for part: Dictionary in mark.parts:
			var spot: Vector2 = to_map.call(part.x, part.z)
			if box.has_point(spot):
				_panel.draw_arc(spot, maxf(2.0, part.radius * scale), 0.0, TAU, 24, get_theme_color(&"accent", &"Palette"), 1.0)
				_text(spot + Vector2(4.0, -4.0), part.name)
		_text(at + Vector2(6.0, 12.0), mark.landmark.name)
	# You, and which way you face.
	var ahead := Vector2(-sin(world.player.global_rotation.y), -cos(world.player.global_rotation.y)) * facing
	var tip := box.get_center() + ahead * 9.0
	_panel.draw_colored_polygon(PackedVector2Array([tip, box.get_center() + ahead.rotated(2.5) * 6.0,
		box.get_center() + ahead.rotated(-2.5) * 6.0]), get_theme_color(&"text", &"Palette"))
	_legend(world, box)


## The whole plan past what's laid, through your point on the moon: faint.
func _draw_far(world: World, box: Rect2, to_map: Callable) -> void:
	var at := Vector2(world.player_world_x(), world.player_world_z())
	if at.distance_to(_far_from) > REDRAW_FAR or width_m != _far_width:
		_far_from = at
		_far_width = width_m
		_far = _plan(world)
	for entry: Array in _far:
		var line := PackedVector2Array()
		for point: Vector2 in entry[0]:
			line.append(to_map.call(point.x, point.y))
		_panel.draw_polyline(line, Color(entry[1], 0.3), 1.0)
	var history := world.shape.history
	var anchor := _anchor(world)
	for each in history.settlements:
		var spot: Vector2 = to_map.call(anchor.place(each.p).x, anchor.place(each.p).y)
		if box.has_point(spot):
			_panel.draw_circle(spot, 2.0, Color(ERA[each.era], 0.4))
	for each in history.landmarks:
		var spot: Vector2 = to_map.call(anchor.place(each.p).x, anchor.place(each.p).y)
		if box.has_point(spot):
			_panel.draw_circle(spot, 3.0, Color(get_theme_color(&"accent", &"Palette"), 0.6))
			_text(spot + Vector2(5.0, 4.0), each.name)


## Every path within the map's reach, laid through your point on the moon.
func _plan(world: World) -> Array:
	var anchor := _anchor(world)
	var reach := width_m * 0.75 / world.shape.history.radius
	var out := []
	for path in world.shape.history.network.paths:
		var line := PackedVector2Array()
		for point in path.points:
			if Sphere.angle(anchor.p, point) <= reach:
				line.append(anchor.place(point))
			elif line.size() > 1:
				out.append([line, _path_colour(path.eras, path.carries)])
				line = PackedVector2Array()
			else:
				line.clear()
		if line.size() > 1:
			out.append([line, _path_colour(path.eras, path.carries)])
	return out


func _anchor(world: World) -> Sites.Anchor:
	return Sites.Anchor.new(world.player_world_x(), world.player_world_z(),
		Sphere.point(world.moon.latitude, world.moon.longitude), -world.moon.north().z, world.shape.history.radius)


## A path in its latest era's colour; a water line blue.
func _path_colour(eras: int, carries: int) -> Color:
	if carries & PathNetwork.WATER and not carries & PathNetwork.ROAD:
		return WATER
	for era: StringName in [Eras.SECOND, Eras.FIRST, Eras.SKIMMER, Eras.COLONIAL]:
		if eras & Eras.BITS[era]:
			return ERA[era]
	return Color.WHITE


func _legend(world: World, box: Rect2) -> void:
	var p := Sphere.point(world.moon.latitude, world.moon.longitude)
	var history := world.shape.history
	var near := history.nearest_landmark(p)
	var lines := ["history  %d m across  %s, %s" % [roundi(width_m), history.region_of(p), history.tu_words(p)]]
	if not near.is_empty():
		lines.append("nearest: %s, %.1f km %s" % [near.landmark.name, near.metres / 1000.0,
			Radio.compass(rad_to_deg(near.bearing))])
	var laid := 0
	for unit in world.shape.sites.units():
		laid += unit.sites.size()
	lines.append("%d sites laid in %d units" % [laid, world.shape.sites.units().size()])
	for i in lines.size():
		_text(box.position + Vector2(8.0, 16.0 + 14.0 * i), lines[i])


func _text(at: Vector2, line: String) -> void:
	var font := get_theme_font(&"font", &"Readout")
	var size := get_theme_font_size(&"font_size", &"Readout")
	_panel.draw_string_outline(font, at, line, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 3, get_theme_color(&"shadow", &"Palette"))
	_panel.draw_string(font, at, line, HORIZONTAL_ALIGNMENT_LEFT, -1, size, get_theme_color(&"text", &"Palette"))
