extends SceneTree
## Packs make_words.py's rendered pieces into word_bank.res, one QOA clip per
## words.txt entry, cut apart here once so saying a word copies nothing.
##   godot --headless --path ROOT -s res://assets/audio/voice/pack_words.gd -- PIECES

const WORDS := "res://assets/audio/voice/words.txt"
const VoiceBank := preload("res://game/radio/voice_words.gd")
## The WAV importer's compress/mode for QOA, about a fifth the size of 16-bit PCM.
const QOA := 2


func _init() -> void:
	var pieces: String = OS.get_cmdline_user_args()[0]
	var bank := VoiceBank.new()
	for word in FileAccess.get_file_as_string(WORDS).split("\n", false):
		var path := pieces.path_join(word.replace(" ", "_") + ".wav")
		var clip := AudioStreamWAV.load_from_file(path, {"compress/mode": QOA})
		if clip == null:
			printerr("no piece for \"%s\" at %s" % [word, path])
			quit(1)
			return
		bank.clips[word] = clip
	var failed := ResourceSaver.save(bank, VoiceBank.BANK, ResourceSaver.FLAG_COMPRESS)
	print("%d words packed into %s" % [bank.clips.size(), VoiceBank.BANK])
	quit(failed)
