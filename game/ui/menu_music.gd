class_name MenuMusic
extends AudioStreamPlayer
## The main menu's theme, Hunter's "Salt", from its start as the menu's
## desert shows, on the menus' bus while the menu's world stays silent. Its
## switch mutes it (Settings.music), and it fades out as the screen does into
## a run. Unmuted, it's heard at once, never after a fade up from silence or
## the file's own quiet.

## Where the song sounds in its file, s: it opens on four seconds of quiet
## and ends on two and a half, its breath between loops.
const SOUNDS := Vector2(4.0, 77.4)
## Unmuted it comes up this fast, s: at once, short of a click.
const UNMUTE_SECONDS := 0.05

var ui: UIRoot
## How loud it is, 0 to 1 of its level, and where a mute left it, s in.
var _level := 0.0
var _at := 0.0
## The switch as it stood last frame, and coming up at once after it was switched on.
var _on := true
var _quick := false


func _ready() -> void:
	bus = Sounds.UI
	var song: AudioStreamOggVorbis = Sounds.MENU_THEME
	song.loop = true
	stream = song
	_on = Settings.music


func _process(delta: float) -> void:
	var heard := Settings.music and not ui.is_fading()
	if Settings.music and not _on:
		_quick = true
		var at := get_playback_position() if playing else _at
		_at = at if at >= SOUNDS.x and at < SOUNDS.y else SOUNDS.x
		if playing and _at != at:
			seek(_at)
	_on = Settings.music
	_quick = _quick and heard and _level < 1.0
	_level = move_toward(_level, 1.0 if heard else 0.0, delta / (UNMUTE_SECONDS if _quick else UIRoot.FADE_SECONDS))
	if _level == 0.0:
		if playing:
			_at = get_playback_position()
			stop()
	elif not playing:
		play(_at)
	volume_db = linear_to_db(maxf(_level, 0.001))
