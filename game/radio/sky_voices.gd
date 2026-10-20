class_name SkyVoices
extends Node
## What a radio hears from the satellites (Constellation), all at once: each
## one over the horizon and on the air comes through by how near its carrier
## the dial stands (its skirt too, so near ones overlap), how high it is and
## the storm its signal crosses, as the relay's music does. Each sounds its
## own track, looping as its station keeps time or pulsing, shaped by its
## LFOs: its pitch, loudness, tremolo and pulse here, its tone (a low-pass)
## and its grit (a distortion) on a bus of its own. Interference chews it up
## there too (Garble), and it glitches (Glitch), rather than fading. A child
## of the radio.

var radio: Radio
## How loud each satellite comes through now, 0 to 1, before the knob, by id;
## and what its LFOs set (Constellation.shaped).
var levels := {}
var shapes := {}

var _voices := {}
var _since := {}
var _glitches := {}

static var _loops := {}

## Where the interference chain (Garble) starts on a satellite's bus: after
## its own tone and grit.
const GARBLE_FROM := 2


func _ready() -> void:
	radio = get_parent() as Radio
	for id: StringName in Constellation.voiced():
		var voice := radio.add_voice(Sounds.radio_bus())
		voice.stream = track(id)
		_voices[id] = voice
		_glitches[id] = Glitch.new(voice)
		_since[id] = INF


## What the radio hears from the satellites this tick at world place x, z and
## time t. Says how loud the loudest comes through, 0 to 1, for the static to
## sink under.
func listen(delta: float, x: float, z: float, t: float) -> float:
	var sky := Radio.constellation_of(radio.world)
	var tuning := Tuning.current()
	var loudest := 0.0
	var p := radio.point_at(x, z)
	var far := Dial.reach(tuning) * 2.0
	for id: StringName in _voices:
		var voice: AudioStreamPlayer3D = _voices[id]
		var khz := sky.carrier(id, t)
		var level := 0.0
		var heard := {}
		# Only one on the air, near enough the dial to hear and over the horizon
		# is worth the storm on its way: most of them aren't, most of the time.
		if sky.on_air(id, t) and absf(radio.frequency - khz) < far \
				and sky.orbits[id].seen_from(p, t).elevation > 0.0:
			heard = radio.receive_from(sky.orbits[id], khz, id, x, z, t)
			level = Radio.audible(heard)
		levels[id] = level
		if level <= 0.0:
			if voice.playing:
				voice.stop()
			_since[id] = INF
			continue
		var shape := sky.shaped(id, radio, heard, x, z, t)
		shapes[id] = shape
		loudest = maxf(loudest, level)
		var sound: Dictionary = sky.rows[id].sound
		var tremble := 1.0
		if shape.tremolo > 0.0:
			tremble = 1.0 - 0.8 * (0.5 + 0.5 * sin(TAU * shape.tremolo * t))
		voice.volume_db = linear_to_db(level * tremble + 0.0001) + radio.knob_db() + sound.db + shape.volume
		voice.pitch_scale = maxf(0.05, shape.pitch * (1.0 + Radio.PITCH_SLIDE * heard.warp
			/ maxf(tuning.storm_warp_khz, 0.01)))
		# Allocate the private chain only when this satellite reaches the dial.
		voice.bus = bus_for(id)
		_shape_bus(id, shape)
		# Chewed up as dirty as it comes through, and glitching.
		Garble.shape(AudioServer.get_bus_index(bus_for(id)), GARBLE_FROM, heard.dirt, t, hash(id))
		var broke: Vector2 = _glitches[id].tick(delta, heard.dirt)
		voice.volume_db += linear_to_db(maxf(broke.x, 0.0001))
		voice.pitch_scale = maxf(0.05, voice.pitch_scale * broke.y)
		if shape.pulse > 0.0:
			_since[id] += delta
			if _since[id] >= shape.pulse:
				_since[id] = 0.0
				voice.play()
		elif not voice.playing:
			# Its station kept time while you weren't listening.
			voice.play(fposmod(t, voice.stream.get_length()))
	return loudest


## All of them gone quiet: the radio's off.
func silence() -> void:
	for id: StringName in _voices:
		(_voices[id] as AudioStreamPlayer3D).stop()
		levels[id] = 0.0
		_since[id] = INF


## The voice a satellite plays through on this radio.
func voice_of(id: StringName) -> AudioStreamPlayer3D:
	return _voices.get(id)


## A satellite's sound as it plays here: a short one as it is, pulsed; a
## long one its own looping copy, so the same file elsewhere keeps its own.
static func track(id: StringName) -> AudioStream:
	var sound: Dictionary = Constellation.ROSTER[Constellation.ids().find(id)].sound
	var stream: AudioStream = sound.track
	if sound.get("pulse", 0.0) > 0.0:
		return stream
	if not _loops.has(id):
		var copy := stream.duplicate()
		if copy is AudioStreamOggVorbis:
			(copy as AudioStreamOggVorbis).loop = true
		_loops[id] = copy
	return _loops[id]


## A satellite's own bus, on into the radio's: a low-pass for its tone and a
## distortion for its grit, both open until its LFOs turn them.
func bus_for(id: StringName) -> StringName:
	var bus_name := StringName("RadioSky_%d_%s" % [radio.get_instance_id(), id])
	if AudioServer.get_bus_index(bus_name) == -1:
		AudioServer.add_bus()
		var i := AudioServer.bus_count - 1
		AudioServer.set_bus_name(i, bus_name)
		AudioServer.set_bus_send(i, Sounds.radio_bus())
		var tone := AudioEffectLowPassFilter.new()
		tone.cutoff_hz = 20000.0
		AudioServer.add_bus_effect(i, tone)
		var grit := AudioEffectDistortion.new()
		grit.mode = AudioEffectDistortion.MODE_OVERDRIVE
		AudioServer.add_bus_effect(i, grit)
		AudioServer.set_bus_effect_enabled(i, 1, false)
		Garble.add_chain(i)
		radio._effect_buses.append(bus_name)
	return bus_name


func _shape_bus(id: StringName, shape: Dictionary) -> void:
	var i := AudioServer.get_bus_index(bus_for(id))
	(AudioServer.get_bus_effect(i, 0) as AudioEffectLowPassFilter).cutoff_hz = shape.cutoff
	var gritty: bool = shape.drive > 0.01
	AudioServer.set_bus_effect_enabled(i, 1, gritty)
	if gritty:
		(AudioServer.get_bus_effect(i, 1) as AudioEffectDistortion).drive = shape.drive
