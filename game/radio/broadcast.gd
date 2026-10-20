class_name Broadcast
extends Node
## What the nearest radio you can hear says. The radio is sound only
## (gonkhub, 2026-10-19: "Remove all text dialogue from the radio. Audio
## only."): nothing it says is written in the view. `said` keeps what the
## nearest one in earshot would say, for the dev overlay and the probes, and
## transmitted words are read aloud.

## Heard from this far, m: anywhere in a light shield's bubble round it.
const EARSHOT := 5.0
## A report begun within this long, s, is still worth reading from its start
## to someone who's just come in earshot of it.
const FRESH := 3.0

## What the nearest radio in earshot says now, "" when none does. Never shown.
var said := ""
## What the nearest radio's voice last read, and from which radio.
var reading := ""

var _speaker: Radio
var _heard_count := -1
var _station: StringName = &""
var _voice := ""

var _player: Player


func _ready() -> void:
	_player = get_parent() as Player


func _process(_delta: float) -> void:
	said = ""
	var nearest := EARSHOT
	for radio: Radio in get_tree().get_nodes_in_group(Radio.GROUP):
		var far := radio.global_position.distance_to(_player.camera.global_position)
		if radio.said != "" and far < nearest:
			nearest = far
			said = radio.said
	_speak()


## The nearest radio with transmitted words in its voice's reach reads its
## report aloud through the system's text-to-speech, as loud as its knob, its
## signal and how far off it is allow. Tuned away or left behind, the voice
## stops. Not spatial: it's heard as a voice in your ear.
func _speak() -> void:
	var tuning := Tuning.current()
	var nearest := tuning.radio_voice_m
	var speaker: Radio = null
	for radio: Radio in get_tree().get_nodes_in_group(Radio.GROUP):
		var far := radio.global_position.distance_to(_player.camera.global_position)
		if radio.playing() and radio.spoken != "" and radio.volume > 0.0 and far < nearest \
				and radio.channel in [Radio.WEATHER, Radio.GOD, Radio.BEACON]:
			nearest = far
			speaker = radio
	# A report already reaching you is read to its end through a dropout; a
	# dropout only keeps the next from starting, on the radio's side.
	var broken: bool = speaker == null or speaker.spoken == ""
	if speaker != _speaker or broken or speaker._spoken_station != _station:
		if _speaker != null and reading != "":
			_stop_voice()
		_speaker = speaker
		_station = speaker._spoken_station if not broken else &""
		if broken:
			_heard_count = -1
			return
		# A report it has only just begun is yours to hear: as you tune in, it
		# reports at once, and that one mustn't be passed over as already heard.
		var fresh: bool = speaker.world != null and speaker.world.time - speaker.spoken_at < FRESH
		_heard_count = speaker.spoken_count - (1 if fresh else 0)
	if speaker.spoken_count == _heard_count:
		return
	if _can_speak() and DisplayServer.tts_is_speaking() and not speaker.spoken_urgent:
		return
	_heard_count = speaker.spoken_count
	reading = speaker.spoken
	var near := clampf(tuning.radio_heard_m / maxf(nearest, 0.01), 0.0, 1.0)
	var loud := speaker.knob_share() * speaker.voice_level() * near
	if _can_speak() and loud > 0.01:
		# An advisory breaks off what's being read; a report waits its turn, whole.
		DisplayServer.tts_speak(reading, _voice, roundi(loud * 100.0), 1.0, 1.05, 0, speaker.spoken_urgent)


func _stop_voice() -> void:
	reading = ""
	if _can_speak():
		DisplayServer.tts_stop()


## Whether the system has a voice to read with: none headless.
func _can_speak() -> bool:
	if not ProjectSettings.get_setting("audio/general/text_to_speech", false) \
			or not DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		return false
	if _voice == "":
		var voices := DisplayServer.tts_get_voices_for_language("en")
		if voices.is_empty():
			return false
		_voice = voices[0]
	return true
