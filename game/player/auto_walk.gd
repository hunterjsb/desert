class_name AutoWalk
extends Node
## Walking on along the way you faced when it began, so you can look about,
## read a compass or watch the storm and still make distance. Only the way is
## given: your own walk carries you, at its pace, stamina, slopes and lines.
## On until you move yourself or turn it off, or something stops you: a wall,
## a face too steep to climb, the board, a line at your waist taut against a
## stake, death or a menu. A small mark low in the view says it's on, and
## points the way it holds as you look round.

## Something solid this near head-on stops you: the cosine of its angle off your way.
const HEAD_ON := 0.5

## The way it holds, along engine x and z; zero while it's off.
var heading := Vector2.ZERO
## Every move key held when it began has been let go: the next is yours.
var _let_go := false
var _player: Player
var _mark: Control
## The way the mark points, on screen: kept as it fades.
var _way := Vector2.UP


func _ready() -> void:
	_player = get_parent() as Player
	var layer := CanvasLayer.new()
	layer.layer = 98
	add_child(layer)
	_mark = Control.new()
	_mark.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_mark.offset_top = -24.0
	_mark.offset_bottom = -24.0
	_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mark.modulate.a = 0.0
	_mark.draw.connect(_draw_mark)
	layer.add_child(_mark)


func is_on() -> bool:
	return heading != Vector2.ZERO


## On along the way you face, or off. Never from the board.
func toggle() -> void:
	if is_on():
		stop()
	elif _player.board == null and not _player.flying and Controls.playing():
		var ahead := -_player.global_basis.z
		heading = Vector2(ahead.x, ahead.z).normalized()
		_let_go = false


func stop() -> void:
	heading = Vector2.ZERO


## Before each step: a move of your own ends it, as does a menu or death.
## `input` is your move keys this tick.
func check(input: Vector2) -> void:
	if not is_on():
		return
	if input == Vector2.ZERO:
		_let_go = true
	elif _let_go:
		stop()
	if not Controls.playing() or _player.vitals.dead or _player.flying or _player.ride != null \
			or (_player.world != null and _moored()):
		stop()


## A line at your waist gone taut against something held fast behind your
## way, a stake in the sand say: walking on would only strain at it.
func _moored() -> bool:
	var ropes := _player.world.ropes
	for rope in ropes.ropes:
		if not is_instance_valid(rope.a) or not is_instance_valid(rope.b) or not rope.is_taut() \
				or not ropes.at_waist(rope):
			continue
		var far := rope.b if ropes.on_you(rope.a.holder) else rope.a
		var fast := far.holder as RigidBody3D
		var off := far.global_position - _player.global_position
		if fast != null and fast.freeze and Vector2(off.x, off.z).dot(heading) < 0.0:
			return true
	return false


func _process(delta: float) -> void:
	_mark.modulate.a = move_toward(_mark.modulate.a, 1.0 if is_on() else 0.0, delta * 6.0)
	if is_on():
		# Up the screen is where you look, so it swings round as you do.
		var ahead := -_player.global_basis.z
		var right := _player.global_basis.x
		_way = Vector2(heading.dot(Vector2(right.x, right.z)), -heading.dot(Vector2(ahead.x, ahead.z))).normalized()
	if _mark.modulate.a > 0.0:
		_mark.queue_redraw()


## A chevron pointing the way it holds.
func _draw_mark() -> void:
	var side := _way.orthogonal() * 5.0
	var chevron := PackedVector2Array([-_way * 2.0 + side, _way * 4.0, -_way * 2.0 - side])
	_mark.draw_polyline(chevron, _mark.get_theme_color(&"shadow", &"Palette"), 4.0, true)
	_mark.draw_polyline(chevron, _mark.get_theme_color(&"text", &"Palette"), 2.0, true)
