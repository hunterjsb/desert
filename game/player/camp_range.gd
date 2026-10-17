class_name CampRange
extends Node
## Never silently lose the camp. Only the ground near you exists, and a device
## whose ground is forgotten is forgotten with it: the terrain lets a chunk go
## once yours is more than view_radius + 1 chunks from it. So each of your
## devices left lying has an edge, a square of chunks round its own, and
## crossing it loses that device. This watches the edge nearest along your way
## and warns you twice before you cross it, timed by your speed: once as you
## near it, and a last time with enough left to turn back even flat out on a
## board. Each comes once and stays up until you're clearly back in range,
## however your way swings. The look is a skeleton's (Movement PRD, open
## question): a soft chime and one line of the suit's text at the top of the
## view.

signal warned(level: int)
signal lost(labels: PackedStringArray)

## Warned once, then warned last.
const FIRST := 1
const LAST := 2
## Back from the edge by this share more than where the first warning came,
## you're clearly in range again and it can warn again.
const REARM := 1.25
## The line counts down once the edge is as near in time as the first
## warning's, and gives the distance again once it's this many times further
## off: you've turned back, not carved.
const COUNT_UNTIL := 2.0
## A loss is told this long, s.
const LOST_SECONDS := 5.0
## The first in the theme's plain text, the last and a loss as its warning,
## in the one accent it keeps for power and danger (Menus & UI).
const DANGER := &"Warning"

## What's been told since you were last clear: 0, FIRST or LAST.
var told := 0
## What the line says now, "" when it's down.
var said := ""
## Seconds until the nearest edge along your way at your pace, INF if you're
## not heading for one; and metres to the nearest edge any way.
var seconds := INF
var near := INF

var _player: Player
var _tuning := Tuning.current()
## The devices watched last tick, by instance id: [label, chunk].
var _watched := {}
## Metres from the edge you're clearly back in range, from the first warning.
var _clear := INF
## Whether the line counts down, or gives the distance.
var _counting := false
var _line: Label
var _shown := 0.0
var _voice: AudioStreamPlayer
var _chimes := {}


func _ready() -> void:
	_player = get_parent() as Player
	var layer := CanvasLayer.new()
	layer.layer = 98
	add_child(layer)
	_line = Label.new()
	_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_line.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_line.offset_left = -400.0
	_line.offset_right = 400.0
	_line.offset_top = 40.0
	_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_line.modulate.a = 0.0
	layer.add_child(_line)
	_voice = AudioStreamPlayer.new()
	_voice.bus = Sounds.UI
	add_child(_voice)
	_chimes[FIRST] = Sounds.CHIME_FIRST
	_chimes[LAST] = Sounds.CHIME_LAST
	_chimes[0] = Sounds.CHIME_LOST


## Your devices lying in the world: not in your hands, at your waist or under you.
func camp() -> Array[Device]:
	var mine: Array[Device] = []
	var world := _player.world
	for node in world.content.get_children():
		var device := node as Device
		# One the world has let go of is gone now, not at the frame's end.
		if device != null and not device.is_queued_for_deletion() and device != _player.board \
				and device != _player.hands.held \
				and not _player.waist.holds(device):
			mine.append(device)
	return mine


func _physics_process(delta: float) -> void:
	var world := _player.world
	if world == null:
		return
	var size := float(world.tuning.chunk_size)
	var keep := world.tuning.view_radius + 1
	var here := Vector2(world.player_world_x(), world.player_world_z())
	var way := Vector2(_player.velocity.x, _player.velocity.z)
	var pace := way.length()
	seconds = INF
	near = INF
	var watching := {}
	for device in camp():
		var coord := world.terrain.chunk_at(world.world_x(device.global_position.x), world.world_z(device.global_position.z))
		watching[device.get_instance_id()] = [device.label, coord]
		# The world metres you can stand in and keep it.
		var low := Vector2(coord - Vector2i.ONE * keep) * size
		var high := Vector2(coord + Vector2i.ONE * (keep + 1)) * size
		near = minf(near, minf(minf(here.x - low.x, high.x - here.x), minf(here.y - low.y, high.y - here.y)))
		if pace > 0.1:
			seconds = minf(seconds, _out(here, way / pace, low, high) / pace)
	_tell_losses(watching, world.terrain.chunk_at(here.x, here.y), keep)
	_watched = watching
	var level := LAST if seconds <= _tuning.range_last_seconds or near <= _tuning.range_last_m \
		else (FIRST if seconds <= _tuning.range_first_seconds or near <= _tuning.range_first_m else 0)
	if level > told:
		if told == 0:
			_clear = maxf(near, _tuning.range_first_m) * REARM
		told = level
		_voice.stream = _chimes[level]
		_voice.play()
		warned.emit(level)
	elif told > 0 and near > _clear:
		told = 0
	if seconds <= _tuning.range_first_seconds:
		_counting = true
	elif seconds > _tuning.range_first_seconds * COUNT_UNTIL:
		_counting = false
	_shown -= delta
	if _shown <= 0.0:
		said = ""
		if told > 0:
			var when := "lost in %d s" % ceili(seconds) if _counting else "%d m from the edge" % maxi(0, ceili(near))
			said = ("LAST WARNING · camp %s · turn back" if told == LAST else "Leaving camp range · %s") % when
	Dev.put("range/edge", "%s · %.0fm" % ["-" if seconds == INF else "%.0fs" % seconds, near] if near < INF else "-")
	Dev.put("range/told", ["-", "first", "LAST"][told])


func _process(delta: float) -> void:
	if said != "":
		_line.text = said
		_line.theme_type_variation = DANGER if told == LAST or _shown > 0.0 else &""
	_line.modulate.a = move_toward(_line.modulate.a, 1.0 if said != "" else 0.0, delta * 6.0)


## Devices gone since last tick because you went too far from them.
func _tell_losses(watching: Dictionary, here: Vector2i, keep: int) -> void:
	var gone := PackedStringArray()
	for id: int in _watched:
		var was: Array = _watched[id]
		var off: Vector2i = was[1] - here
		var still := instance_from_id(id)
		if not watching.has(id) and (still == null or still.is_queued_for_deletion()) \
				and maxi(absi(off.x), absi(off.y)) > keep:
			gone.append(was[0])
	if gone.is_empty():
		return
	said = "Camp lost · %s" % ", ".join(gone)
	_shown = LOST_SECONDS
	_voice.stream = _chimes[0]
	_voice.play()
	lost.emit(gone)


## How far along `way` from `at` you leave the box low..high, m.
static func _out(at: Vector2, way: Vector2, low: Vector2, high: Vector2) -> float:
	var most := INF
	for axis in 2:
		if way[axis] > 1e-6:
			most = minf(most, (high[axis] - at[axis]) / way[axis])
		elif way[axis] < -1e-6:
			most = minf(most, (low[axis] - at[axis]) / way[axis])
	return maxf(most, 0.0)
