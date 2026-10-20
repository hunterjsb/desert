class_name WaistLines
extends Control
## Pick the rendered rope itself; hovering never changes which line the hands work.

const HEIGHT := 58.0
const PICK := 14.0
const BUTTON := Vector2(246.0, 40.0)

var reel: Reel
var waist: Waist
var controls_at := Vector2.ZERO
var hovered: RigidBody3D
var _paths: Array[Dictionary] = []
var _pointer := Vector2(-100.0, -100.0)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	show_behind_parent = true


func refresh() -> void:
	visible = true
	_paths.clear()
	var player := waist.get_parent() as Player
	var camera := player.camera
	for body in reel.waist_lines():
		var rope := reel._line_of(body)
		var points := rope.strand.shown()
		for i in points.size() - 1:
			var a := points[i]
			var b := points[i + 1]
			# The common knot at your waist does not distinguish the three lines.
			if camera.to_local(a).z >= -camera.near or camera.to_local(b).z >= -camera.near \
					or minf(a.distance_to(camera.global_position), b.distance_to(camera.global_position)) < 1.0:
				continue
			var from := camera.unproject_position(a)
			var to := camera.unproject_position(b)
			_paths.append({"body": body, "a": a, "b": b, "from": from, "to": to})
	point_at(_pointer)
	queue_redraw()


## Tiles take precedence over rope beneath the inventory pictures.
func point_at(point: Vector2) -> void:
	_pointer = point
	hovered = null
	if not waist.tied.is_empty() and _release().has_point(point):
		return
	var nearest := PICK
	for path in _paths:
		var along: Vector2 = path.to - path.from
		var share := clampf((point - path.from).dot(along) / maxf(along.length_squared(), 0.001), 0.0, 1.0)
		var gap := point.distance_to(path.from + along * share)
		if gap < nearest and _visible_point((path.a as Vector3).lerp(path.b, share)):
			nearest = gap
			hovered = path.body
	queue_redraw()


func click(point: Vector2) -> bool:
	if not visible:
		return false
	point_at(point)
	if not waist.tied.is_empty() and _release().has_point(point):
		waist.release_all()
	elif is_instance_valid(hovered):
		reel.choose(hovered)
	else:
		return false
	queue_redraw()
	return true


func _visible_point(at: Vector3) -> bool:
	var player := waist.get_parent() as Player
	var eye := player.camera.global_position
	# Solid gear and terrain use the default first layer; fitted gear keeps its shapes.
	var query := PhysicsRayQueryParameters3D.create(eye, at, 1, [player.get_rid()])
	var hit := player.get_world_3d().direct_space_state.intersect_ray(query)
	# A rope resting on sand is visible at the surface it touches.
	return hit.is_empty() or (hit.position as Vector3).distance_to(at) < RopeStrand.RADIUS


func _release() -> Rect2:
	return Rect2(controls_at, BUTTON)


func _draw() -> void:
	var chosen := reel.chosen_body()
	for path in _paths:
		if path.body != hovered and path.body != chosen:
			continue
		if not _visible_point((path.a as Vector3).lerp(path.b, 0.5)):
			continue
		var preview: bool = path.body == hovered
		draw_line(path.from, path.to, _ink(&"accent" if preview else &"text"), 4.0 if preview else 2.0, true)
	if not waist.tied.is_empty():
		_button(_release(), "Release all", false)
	var handling := waist.release_readout()
	if handling != "":
		var bar := _release()
		bar.position.y = bar.end.y - 4.0
		bar.size.y = 4.0
		draw_rect(bar, _ink(&"faint"))
		bar.size.x *= waist.release_progress()
		draw_rect(bar, _ink(&"accent"))
	var body := hovered if is_instance_valid(hovered) else chosen
	var count := reel.connected_ropes().size()
	var stake_only := waist.tied.size() == 1 and waist.tied[0] is Stake and reel.waist_lines().is_empty()
	var hint := "Stake at your waist" if stake_only else ("Sole rope ready" if count == 1 else "Hover a rope, click to select")
	_words(Vector2(32.0, 42.0), "%d connected rope%s · %s" % [count, "" if count == 1 else "s", hint], size.x - 64.0)
	var context := handling
	if context == "" and waist.untying >= 0.0:
		context = "Untying · %.1f s" % waist.untying
	if context == "" and stake_only:
		context = "%s with empty hands · take the stake back" % Controls.key_for(&"interact")
	if context == "" and is_instance_valid(body):
		context = ("Preview · " if body == hovered and body != chosen else "Selected · ") + reel.waist_description(body)
		if reel.in_hand() != null:
			context += " · held line takes priority"
	if context == "" and count == 1 and not stake_only:
		context = "Sole rope · ready to reel"
	if context == "":
		context = "No rope selected"
	_words(Vector2(32.0, 74.0), context, size.x - 64.0)


func _button(box: Rect2, text: String, selected: bool) -> void:
	draw_rect(box, _ink(&"panel"))
	draw_rect(box, _ink(&"text" if selected else &"dim"), false, 1.0)
	_words(box.position + Vector2(12.0, 27.0), ("✓ " if selected else "") + text, box.size.x - 24.0)


func _ink(name: StringName) -> Color:
	return get_theme_color(name, &"Palette")


func _words(at: Vector2, text: String, width: float, color := &"text") -> void:
	var font := get_theme_font(&"font", &"AsideName")
	var font_size := get_theme_font_size(&"font_size", &"AsideName")
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, width, font_size,
		get_theme_constant(&"outline_size", &"Label"), _ink(&"shadow"))
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, _ink(color))
