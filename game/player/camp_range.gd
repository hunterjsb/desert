class_name CampRange
extends Node
## Never silently lose the camp. Only the ground near you exists, and a device
## whose ground is forgotten is forgotten with it: the terrain lets a chunk go
## once yours is more than view_radius + 1 chunks from it. So each of your
## devices left lying has an edge, a square of chunks round its own, and
## crossing it loses that device. This watches the edge nearest along your way
## and warns you twice before you cross it, timed by your speed: once as you
## near it, and a last time with enough left to turn back even flat out on a
## board. The look is a skeleton's (Movement PRD, open question): a chime and
## one line of the suit's text at the top of the view.

signal warned(level: int)
signal lost(labels: PackedStringArray)

## Warned once, then warned last.
const FIRST := 1
const LAST := 2
## Clear again by this share past the first warning's lines, it can warn again.
const REARM := 1.25
## A loss is told this long, s.
const LOST_SECONDS := 5.0
## The chimes are made at this many samples a second.
const RATE := 22050
## The first in the theme's plain text, the last and a loss as its warning,
## in the one accent it keeps for power and danger (Menus & UI).
const DANGER := &"Warning"

## What's been told since you were last clear: 0, FIRST or LAST.
var told := 0
## Seconds until the nearest edge along your way at your pace, INF if you're
## not heading for one; and metres to the nearest edge any way.
var seconds := INF
var near := INF

var _player: Player
var _tuning := Tuning.current()
## The devices watched last tick, by instance id: [label, chunk].
var _watched := {}
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
	_voice.volume_db = -8.0
	add_child(_voice)
	_chimes[FIRST] = _tones([660.0, 880.0], 0.16)
	_chimes[LAST] = _tones([990.0, 990.0, 990.0], 0.09)
	_chimes[0] = _tones([660.0, 440.0], 0.3)


## Your devices lying in the world: not in your hands, at your waist or under you.
func camp() -> Array[Device]:
	var mine: Array[Device] = []
	var world := _player.world
	for node in world.content.get_children():
		var device := node as Device
		if device != null and device != _player.board and device != _player.hands.held \
				and not _player.waist.holds(device):
			mine.append(device)
	return mine


func _physics_process(_delta: float) -> void:
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
		told = level
		_voice.stream = _chimes[level]
		_voice.play()
		warned.emit(level)
	elif level == 0 and seconds > _tuning.range_first_seconds * REARM and near > _tuning.range_first_m * REARM:
		told = 0
	Dev.put("range/edge", "%s · %.0fm" % ["-" if seconds == INF else "%.0fs" % seconds, near] if near < INF else "-")
	Dev.put("range/told", ["-", "first", "LAST"][told])


func _process(delta: float) -> void:
	_shown -= delta
	if told > 0:
		var when := "lost in %d s" % ceili(seconds) if seconds < INF and _player.velocity.length() > 0.5 \
			else "%d m from the edge" % ceili(near)
		_line.text = ("LAST WARNING · camp %s · turn back" if told == LAST else "Leaving camp range · %s") % when
		_line.theme_type_variation = DANGER if told == LAST else &""
		_shown = 0.0
	_line.modulate.a = move_toward(_line.modulate.a, 1.0 if told > 0 or _shown > 0.0 else 0.0, delta * 6.0)


## Devices gone since last tick because you went too far from them.
func _tell_losses(watching: Dictionary, here: Vector2i, keep: int) -> void:
	var gone := PackedStringArray()
	for id: int in _watched:
		var was: Array = _watched[id]
		var off: Vector2i = was[1] - here
		if not watching.has(id) and not is_instance_valid(instance_from_id(id)) and maxi(absi(off.x), absi(off.y)) > keep:
			gone.append(was[0])
	if gone.is_empty():
		return
	_line.text = "Camp lost · %s" % ", ".join(gone)
	_line.theme_type_variation = DANGER
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


## A chime: these notes, each this long, as a soft-edged sine.
static func _tones(notes: Array, each: float) -> AudioStreamWAV:
	var count := int(each * RATE)
	var data := PackedByteArray()
	data.resize(notes.size() * count * 2)
	for k in notes.size():
		for i in count:
			var s := float(i) / RATE
			var edge := minf(1.0, minf(s / 0.01, (each - s) / 0.04))
			data.encode_s16((k * count + i) * 2, int(sin(TAU * notes[k] * s) * edge * 0.5 * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.data = data
	return wav
