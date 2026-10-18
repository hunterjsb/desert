class_name MenuMusic
extends AudioStreamPlayer
## The radio's music at the main menu, its day or night track by the menu's
## own light, on the menus' bus while the menu's world stays silent. Its
## switch mutes it (Settings.music), it changes track through a moment's
## quiet, and it fades out as the screen does into a run.

## Ridden down from the radio's level: a set playing in the next room.
const DB := -6.0

var view: World
var ui: UIRoot
## How loud it is, 0 to 1 of its level.
var _level := 0.0


func _ready() -> void:
	bus = Sounds.UI
	for loop: AudioStreamOggVorbis in [Sounds.RADIO_DAY, Sounds.RADIO_NIGHT]:
		loop.loop = true


func _process(delta: float) -> void:
	var want := Radio.track_at(view, view.time)
	if stream != want and _level == 0.0:
		stop()
		stream = want
	var heard := Settings.music and not ui.is_fading() and stream == want
	_level = move_toward(_level, 1.0 if heard else 0.0, delta / UIRoot.FADE_SECONDS)
	if _level == 0.0:
		stop()
	elif not playing:
		# Where the radio's station has got to, as a radio tuned in would hear it.
		play(fposmod(view.time, stream.get_length()))
	volume_db = DB + linear_to_db(maxf(_level, 0.001))
