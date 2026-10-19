class_name Broadcast
extends Node
## What the nearest radio you can hear says, as one line low in the view: the
## weather station's reading or a beacon's bearing, while you're in earshot of
## a radio tuned to one. A stand-in for a voice (Radio PRD, open question).

## Heard from this far, m: anywhere in a light shield's bubble round it.
const EARSHOT := 5.0

## What the line says now, "" when it's down.
var said := ""
## What the weather station's voice last read, and from which radio.
var reading := ""

var _speaker: Radio
var _heard_count := -1
var _voice := ""

var _player: Player
var _line: Label


func _ready() -> void:
	_player = get_parent() as Player
	var layer := CanvasLayer.new()
	layer.layer = 98
	add_child(layer)
	_line = Label.new()
	_line.theme_type_variation = &"Readout"
	_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_line.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_line.offset_left = -400.0
	_line.offset_right = 400.0
	_line.offset_top = -64.0
	_line.offset_bottom = -44.0
	_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_line.modulate.a = 0.0
	layer.add_child(_line)


func _process(delta: float) -> void:
	said = ""
	var nearest := EARSHOT
	for radio: Radio in get_tree().get_nodes_in_group(Radio.GROUP):
		var far := radio.global_position.distance_to(_player.camera.global_position)
		if radio.said != "" and far < nearest:
			nearest = far
			said = radio.said
	if said != "":
		_line.text = said
	_line.modulate.a = move_toward(_line.modulate.a, 1.0 if said != "" else 0.0, delta * 6.0)
	_speak()


## The nearest radio on the weather station in its voice's reach reads its
## report aloud through the system's text-to-speech, as loud as its knob, its
## signal and how far off it is allow. Tuned away or left behind, the voice
## stops. Not spatial: it's heard as a voice in your ear.
func _speak() -> void:
	var tuning := Tuning.current()
	var nearest := tuning.radio_voice_m
	var speaker: Radio = null
	for radio: Radio in get_tree().get_nodes_in_group(Radio.GROUP):
		var far := radio.global_position.distance_to(_player.camera.global_position)
		if radio.playing() and radio.channel == Radio.WEATHER and far < nearest:
			nearest = far
			speaker = radio
	# A report already reaching you is read to its end through a dropout; a
	# dropout only keeps the next from starting, on the radio's side.
	var broken: bool = speaker == null or speaker.spoken == ""
	if speaker != _speaker or broken:
		if _speaker != null and reading != "":
			_stop_voice()
		_speaker = speaker
		_heard_count = speaker.spoken_count if speaker != null and not broken else -1
		if broken:
			return
	if speaker.spoken_count == _heard_count:
		return
	_heard_count = speaker.spoken_count
	reading = speaker.spoken
	var near := clampf(tuning.radio_heard_m / maxf(nearest, 0.01), 0.0, 1.0)
	var loud := speaker.knob_share() * sqrt(speaker.reception.get("clean", 0.0)) * near
	if _can_speak() and loud > 0.01:
		DisplayServer.tts_speak(reading, _voice, roundi(loud * 100.0), 1.0, 1.05, 0, true)


func _stop_voice() -> void:
	reading = ""
	if _can_speak():
		DisplayServer.tts_stop()


## Whether the system has a voice to read with: none headless.
func _can_speak() -> bool:
	if not Settings.radio_voice or not ProjectSettings.get_setting("audio/general/text_to_speech", false) \
			or not DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		return false
	if _voice == "":
		var voices := DisplayServer.tts_get_voices_for_language("en")
		if voices.is_empty():
			return false
		_voice = voices[0]
	return true
