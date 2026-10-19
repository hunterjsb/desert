class_name RideSound
extends Node
## The board's voice while you ride it: its make's hum, higher the faster it
## goes, sagging as the battery dies and dropping under a dug edge; a carve's
## hiss as the hover holds you round; the wind's rush with speed; a whoosh
## as a deep edge lets go; a pop off a lip; a landing by how hard; and a
## skid's bite as it takes hold again. A skid's and a dig's grit is Feel's,
## with the sand they throw. It reads the ride and never writes to it.

## The dug edge's load drops the hum this far, full from DUG_FAST m/s, and
## the hum sags this far over the battery's last WARNING s.
const HUM_DUG := 0.72
const DUG_FAST := 12.0
const HUM_SAG := 0.7
## A dug edge let out this fast, m/s, from at least this deep, whooshes.
const WHOOSH_FROM := 5.0
const WHOOSH_DEEP := 0.5
## A skid biting again this fast or faster, m/s, is heard.
const BITE_FROM := 5.0
## A pop this fast, m/s, is heard at its loudest.
const POP_FULL := 6.0

var _board: Hoverboard
var _rider: Player
var _hum: AudioStreamPlayer
var _whoosh: AudioStreamPlayer
var _carve: AudioStreamPlayer
var _rush: AudioStreamPlayer
var _hiss := 0.0
## The deepest the edge has been dug since it last came out, or below 0
## once it has whooshed; and whether it skidded last frame.
var _dug_most := 0.0
var _skidded := false
var _tuning := Tuning.current()
## Its own dice, so sound never shifts what a probe's seed decides.
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_board = get_parent() as Hoverboard
	var hum: AudioStream = Sounds.BOARD_HUMS.get(BoardMakes.make_of(_board), Sounds.HOVER)
	_hum = _voice(_looping(hum))
	_whoosh = _voice(Sounds.THROW)
	_whoosh.pitch_scale = 0.6
	_carve = _voice(Sounds.looping(Sounds.BOARD_CARVE))
	_rush = _voice(Sounds.looping(Sounds.BOARD_RUSH))


## On: its hum starts, and it listens to who rides it.
func start(by: Player) -> void:
	_rider = by
	_dug_most = 0.0
	_skidded = false
	_hiss = 0.0
	_hum.play()
	for voice in [_carve, _rush]:
		voice.volume_db = -80.0
		voice.play(_rng.randf() * 1.5)
	by.took_off.connect(_on_took_off)
	by.touched_down.connect(_on_touched_down)


func stop() -> void:
	for voice in [_hum, _carve, _rush]:
		voice.stop()
	if _rider != null and is_instance_valid(_rider):
		_rider.took_off.disconnect(_on_took_off)
		_rider.touched_down.disconnect(_on_touched_down)
	_rider = null


func _process(delta: float) -> void:
	if _rider == null or _rider.ride == null:
		return
	var ride := _rider.ride
	var make := ride.make
	var top: float = _tuning.board_top_speed * make.top
	var going := ride.velocity.length()
	var speed := clampf(going / top, 0.0, 1.2)
	var low := clampf(1.0 - _board.seconds_left() / Hoverboard.WARNING, 0.0, 1.0)
	var load := ride.dig * clampf(going / DUG_FAST, 0.0, 1.0)
	_hum.pitch_scale = lerpf(make.hum[0], make.hum[1], speed) * lerpf(1.0, HUM_SAG, low) * lerpf(1.0, HUM_DUG, load)
	# The hover holding a carve hisses as hard as it leans, until it lets go.
	var holding := absf(sin(ride.tilt(true).z)) / sin(Ride.BANK) * clampf(going / 8.0, 0.0, 1.0)
	if ride.skidding or ride.drifting or ride.gap > Ride.AIR_FROM:
		holding = 0.0
	_hiss = holding + (_hiss - holding) * exp(-delta / 0.08)
	_carve.volume_db = linear_to_db(maxf(_hiss, 1e-4))
	_carve.pitch_scale = 0.85 + 0.3 * minf(speed, 1.0)
	# The wind's rush grows with your speed.
	_rush.volume_db = linear_to_db(maxf(pow(minf(speed, 1.0), 1.5), 1e-4))
	_rush.pitch_scale = 0.8 + 0.4 * minf(speed, 1.0)
	# Let out, the edge leaves the sand with a whoosh, once.
	if ride.dig < 0.1:
		_dug_most = 0.0
	elif _dug_most >= 0.0:
		_dug_most = maxf(_dug_most, ride.dig)
		if _dug_most > WHOOSH_DEEP and ride.dig < _dug_most * 0.8 and going > WHOOSH_FROM:
			_whoosh.volume_db = linear_to_db(clampf(going / top, 0.4, 1.0))
			_whoosh.play()
			_dug_most = -1.0
	# A skid takes hold again with a scuff.
	if _skidded and not ride.skidding and going > BITE_FROM and not ride.drifting:
		Sounds.play(self, Sounds.BOARD_BITE, Sounds.WORLD, linear_to_db(clampf(going / top, 0.4, 1.0)))
	_skidded = ride.skidding


func _on_took_off(speed: float) -> void:
	Sounds.play(self, Sounds.BOARD_POP, Sounds.WORLD, linear_to_db(clampf(speed / POP_FULL, 0.3, 1.0)))


## Pressed into the sand: softly, firmly, or slammed through past its jar.
func _on_touched_down(speed: float) -> void:
	var jar: float = _tuning.board_land_jar * _rider.ride.make.sturdy if _rider != null and _rider.ride != null \
		else _tuning.board_land_jar
	var hard := speed / jar
	if hard < 0.2:
		return
	var voice := AudioStreamPlayer.new()
	voice.stream = Sounds.BOARD_SLAM if hard >= 1.0 else Sounds.BOARD_LAND
	voice.bus = Sounds.WORLD
	voice.volume_db = linear_to_db(clampf(hard, 0.3, 1.0))
	voice.pitch_scale = lerpf(1.1, 0.85, clampf(hard, 0.0, 1.5) / 1.5)
	voice.autoplay = true
	voice.finished.connect(voice.queue_free)
	add_child(voice)


func _voice(stream: AudioStream) -> AudioStreamPlayer:
	var voice := AudioStreamPlayer.new()
	voice.stream = stream
	voice.bus = Sounds.WORLD
	add_child(voice)
	return voice


static func _looping(stream: AudioStream) -> AudioStream:
	if stream is AudioStreamWAV:
		return Sounds.looping(stream)
	var made := stream.duplicate() as AudioStreamOggVorbis
	made.loop = true
	return made
