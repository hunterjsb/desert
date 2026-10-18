class_name MenuMusic
extends AudioStreamPlayer
## The main menu's theme, Hunter's "Salt", on the menus' bus while the menu's
## world stays silent. Its switch mutes it (Settings.music), and it fades in
## and out with the screen: in as the menu shows, out into a run.

## Its level: the theme's file is made to be heard plainly.
const DB := 0.0

var view: World
var ui: UIRoot
## How loud it is, 0 to 1 of its level.
var _level := 0.0


func _ready() -> void:
	bus = Sounds.UI
	var theme: AudioStreamOggVorbis = Sounds.MENU_THEME
	theme.loop = true
	stream = theme


func _process(delta: float) -> void:
	var heard := Settings.music and not ui.is_fading()
	_level = move_toward(_level, 1.0 if heard else 0.0, delta / UIRoot.FADE_SECONDS)
	if _level == 0.0:
		stop()
	elif not playing:
		play()
	volume_db = DB + linear_to_db(maxf(_level, 0.001))
