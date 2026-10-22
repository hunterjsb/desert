class_name VoiceWords
extends Resource
## The radio's spoken words, each its own clip, packed once by
## assets/audio/voice/make_words.py from words.txt; the bank loads the first
## time a word is said, never with the scripts.

const BANK := "res://assets/audio/voice/word_bank.res"

@export var clips: Dictionary[String, AudioStreamWAV] = {}

static var _bank: VoiceWords


## Loads the bank now, with a set, so the first word said doesn't wait on it.
static func warm() -> void:
	_loaded()


static func has(word: String) -> bool:
	return _loaded().clips.has(word)


static func track(word: String) -> AudioStream:
	return _loaded().clips.get(word)


static func _loaded() -> VoiceWords:
	if _bank == null:
		_bank = load(BANK)
	return _bank
