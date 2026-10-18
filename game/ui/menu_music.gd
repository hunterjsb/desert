class_name MenuMusic
extends AudioStreamPlayer
## The main menu's theme, Hunter's "Salt", from its start as the menu's
## desert shows, on the menus' bus while the menu's world stays silent. Its
## switch mutes it (Settings.music), and it fades out as the screen does into
## a run.

var ui: UIRoot
## How loud it is, 0 to 1 of its level, and where a mute left it, s in.
var _level := 0.0
var _at := 0.0


func _ready() -> void:
	bus = Sounds.UI
	var song: AudioStreamOggVorbis = Sounds.MENU_THEME
	song.loop = true
	stream = song


func _process(delta: float) -> void:
	var heard := Settings.music and not ui.is_fading()
	_level = move_toward(_level, 1.0 if heard else 0.0, delta / UIRoot.FADE_SECONDS)
	if _level == 0.0:
		if playing:
			_at = get_playback_position()
			stop()
	elif not playing:
		play(_at)
	volume_db = linear_to_db(maxf(_level, 0.001))
