class_name Glitch
extends RefCounted
## The glitches a dirty signal breaks into, on one voice, on top of Garble's
## chain: now and then, the more often the dirtier it is, it
##
## - stutters, a fragment of it caught and repeated a few times before it
##   catches up with where it would have been (so a station keeps its time);
## - drops out for a moment;
## - jumps in pitch for a moment;
## - drags, slowing like tape and back.
##
## Each tick the radio asks it what to do to the voice: tick() says how
## much louder (a share) and how much higher (a scale) to play it now.

## At full dirt, about this many glitches a second.
const RATE := 5.0
## Below this dirt, none.
const LEAST := 0.12

var voice: AudioStreamPlayer3D
## What it's doing now: &"" for nothing, or &"stutter", &"drop", &"jump", &"drag".
var kind := &""

var _rng := RandomNumberGenerator.new()
var _left := 0.0
var _length := 0.0
var _anchor := 0.0
var _period := 0.0
var _since := 0.0
var _factor := 1.0


func _init(on: AudioStreamPlayer3D) -> void:
	voice = on
	_rng.seed = hash([on.get_instance_id(), "glitch"])


## What to do to the voice this tick, `delta` s on, at this dirt: (a share of
## its loudness, a scale of its pitch).
func tick(delta: float, dirt: float) -> Vector2:
	if not voice.playing or voice.stream == null:
		kind = &""
		return Vector2.ONE
	if kind == &"":
		var chance := pow(maxf(dirt - LEAST, 0.0) / (1.0 - LEAST), 1.5) * RATE * delta
		if _rng.randf() < chance:
			_start()
		else:
			return Vector2.ONE
	_left -= delta
	_since += delta
	var out := Vector2.ONE
	match kind:
		&"stutter":
			if _since >= _period:
				_since = 0.0
				voice.seek(_anchor)
		&"drop":
			out.x = 0.0
		&"jump":
			out.y = _factor
		&"drag":
			# Down and back, like a finger on the reel.
			var k := 1.0 - absf(1.0 - 2.0 * (1.0 - _left / _length))
			out.y = lerpf(1.0, _factor, k)
	if _left <= 0.0:
		_end()
	return out


func _start() -> void:
	var long := voice.stream.get_length() > 1.0
	var pick := _rng.randf()
	if pick < 0.35 and long:
		kind = &"stutter"
		_period = _rng.randf_range(0.04, 0.12)
		_length = _period * _rng.randi_range(2, 6)
		_anchor = voice.get_playback_position()
	elif pick < 0.6:
		kind = &"drop"
		_length = _rng.randf_range(0.03, 0.18)
	elif pick < 0.85:
		kind = &"jump"
		_length = _rng.randf_range(0.05, 0.25)
		_factor = _rng.randf_range(0.6, 1.6)
	else:
		kind = &"drag"
		_length = _rng.randf_range(0.3, 0.7)
		_factor = _rng.randf_range(0.45, 0.75)
	_left = _length
	_since = 0.0


func _end() -> void:
	if kind == &"stutter":
		# Caught up with where it would have been, as if it never stuck.
		voice.seek(fposmod(_anchor + _length, voice.stream.get_length()))
	kind = &""
