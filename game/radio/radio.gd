class_name Radio
extends Device
## A radio you carry, set down or stick on a deck, and tune: an AM dial of
## longwave and mediumwave, 150 to 1700 kHz (Dial), rolled a notch at a time
## as you look at it, and use to switch it on and off; its needle crosses the
## band on its face and its knobs turn as you do. Nothing on the dial says what
## a carrier is. Its bands (gonkhub, 2026-10-21) are each a kind of listening.
## The AM dial is the barest: the far gods, each in its own band from where it
## stands, the beacon pinging off a ruin, and the wrecks calling SOS round
## 240 kHz (Distress). FM, through a converter, is near and clean: Port Morgan
## Tower with the weather at the tower and the deliveryship's schedule, the
## port's music, the living city's chatter and reed music, and the near gods,
## each heard only near its mast. Shortwave, through its own converter, is the
## sky's: the satellites, Tu's roar and the relay repeating the tower, heard
## better the longer and higher its wire or kite. It reads the real systems and
## never makes anything up. A god's signal comes in by how far off it is, its
## frequency and the hour, and the storm between you and it garbles, slides
## and cuts it. Static comes in with a front's outflow, before the wall, and
## inside a bubble too: it's the sand charging up, not the storm's sound; an
## anomaly near brings a crackle of its own, which no forecast speaks of. The
## tower reads its report aloud in short phrases from a bank of recorded
## words, breaking off for an advisory; with nothing coming its clear-skies
## song plays. Its volume knob turns all of it down, to silence if you like,
## and it plays on. It draws a little while it's on, from its battery or the
## pool it sits in, and plays from where it is.

const GROUP := &"radios"
## What it's tuned to, as the dial reads: off, a carrier, or nothing but static.
const OFF := 0
const MUSIC := 1
const WEATHER := 2
const BEACON := 3
const GOD := 4
const STATIC := 5
const CITY := 6
const FM := 7
const SURVEY := 8
const DISTRESS := 9
const CHANNELS: Array[String] = ["off", "music", "weather", "beacon", "god", "static", "city", "fm", "survey",
	"distress"]
## Its bands: the AM dial, the FM band and the shortwave band, each of the last
## two through a converter fitted in its side.
const AM_BAND := &"am"
const FM_BAND := &"fm"
const SW_BAND := &"sw"
const BANDS: Array[StringName] = [AM_BAND, FM_BAND, SW_BAND]
const POINTS: Array[String] = ["north", "north-north-east", "north-east", "east-north-east", "east",
	"east-south-east", "south-east", "south-south-east", "south", "south-south-west", "south-west",
	"west-south-west", "west", "west-north-west", "north-west", "north-north-west"]
## Its dial's clicks are heard at their level this far off, m; what it plays,
## out to radio_heard_m.
const HEARD := 6.0
## Of full static, the hiss under a clean signal, and with nothing to hear.
const CARRIER := 0.2
const NOTHING := 0.6
## A god's tones sound this often, s.
const TONES_EVERY := 8.0
## A beacon pings this often from as far as FAINT and this often close by, s.
## Past FAINT it's faint, past CLEAR clear, nearer strong, and within HERE, m,
## you're on it.
const PING_FAR := 2.5
const PING_NEAR := 0.5
const FAINT := 1000.0
const CLEAR := 250.0
const HERE := 15.0
## Tuned within this many widths of a carrier, the dial counts it as on it.
const ON_IT := 2.0
## The gods that play a song now and then on their frequency, silent between:
## the Stoker's furnace song and the Eye's drones, one of them each time.
const SONGS := {&"stoker": [Sounds.RADIO_STOKER], &"eye": [Sounds.RADIO_EYE, Sounds.RADIO_EYE_TUNNEL]}
## A carrier slid its storm warp's full width slides a song's pitch this share.
const PITCH_SLIDE := 0.04
## An anomaly's crackle: the static pitched between these, a burst at a time,
## at its deepest this share of full static, under it and still heard.
const CRACKLE_PITCH := Vector2(1.4, 2.2)
const CRACKLE_LEVEL := 0.5
## The volume knob turns this far a notch, of full.
const VOLUME_STEP := 0.1
## A signal this clean or better comes through whole.
const WHOLE := 0.5
## An anomaly's crackle this deep, heard, is a tell.
const CRACKLE_TELL := 0.25
## The weather station's voice: its phrases, one recording each, said this
## far apart after a full stop and after a comma, s, once its tones have sounded.
const VOICE := "res://assets/audio/voice/%s.ogg"
const STOP_GAP := 0.32
const COMMA_GAP := 0.12
## It says numbers exactly up to this, and past it to the ten.
const EXACT := 60
const ONES: Array[String] = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten",
	"eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen"]
const TENS: Array[String] = ["", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety"]
const UNHEARD := -1
## On FM, it works out again how far each station clears the ground between
## once it's moved this far, m, or this long has gone by, s (a satellite
## moves); and a tick's move longer than this is the world shifting under it,
## not it moving.
const FM_RECKON_M := 2.0
## Its long wire is read again this often, s.
const WIRE_EVERY := 0.5
## A kite flown this high, m, on its lead, hearing a satellite clear: High Wire.
const KITE_HIGH := 50.0
const FM_RECKON_S := 1.0
const FM_JUMP_M := 50.0
## Its dial on its face (+Z), m: the band window's middle and size, the band
## running from Dial.LOWEST to Dial.HIGHEST across these x, and where the tuning and
## volume knobs turn.
const BAND_Y := 0.058
const BAND_WIDTH := 0.236
const BAND_HEIGHT := 0.052
const BAND := Vector2(-0.105, 0.105)
const KNOB_AT := Vector3(0.06, -0.042, 0.084)
const VOLUME_AT := Vector3(0.11, -0.06, 0.084)
const VOLUME_KNOB := 0.55
## The tuning knob goes once round across the whole AM dial, bottom to top
## (gonkhub, 2026-10-20: "make the visual for the knob turning match the
## bandwidth"); the volume knob sweeps three quarters round, silent to full.
const KHZ_A_TURN := Dial.HIGHEST - Dial.LOWEST
const VOLUME_SWEEP := PI * 1.5
## The needle and knobs catch up with where the dial stands in about this long, s.
const TURN_SECONDS := 0.05
## Past this much dirt a signal fades away as it's lost.
const LOST := 0.92
## Its signal's bus, where interference chews it up (Garble).
const SIGNAL_BUS := &"RadioSignal"
## Static plays only while nothing does: gone once what it hears comes
## through this loud, from this.
const STATIC_GONE := Vector2(0.02, 0.12)
## A mark's colour: any hue, this saturated and this bright, so it shows on the band.
const MARK_SATURATION := 0.7
const MARK_VALUE := 0.95
## A mark's tick on its band, m: along the top of the window, over the numerals.
const MARK_TICK := Vector3(0.003, 0.008, 0.001)
## Its signal lamps: a row of this many under the band, from this point
## across, each this big and this far from the next, m; green to amber as
## they climb, and how fast they follow what it hears, /s. Nothing written:
## you find a station by the lamps as much as by ear.
const LAMPS := 8
const LAMP_FROM := Vector3(-0.1, 0.017, 0.0)
const LAMP := Vector3(0.008, 0.006, 0.002)
const LAMP_GAP := 0.0115
const LAMP_LOW := Color(0.35, 1.0, 0.45)
const LAMP_HIGH := Color(1.0, 0.75, 0.2)
const LAMP_FOLLOW := 10.0
## Its band lamp, in the same strip right of them: a seat by each band's
## name (BANDS), from this point across, this far apart, m; the lamp stands
## in the seat of the band it's on.
const BAND_LAMP_FROM := Vector3(0.03, LAMP_FROM.y, 0.0)
const BAND_LAMP_GAP := 0.034
## Close up, the view looks at this point on its face.
const FACE := Vector3(0.0, 0.01, 0.08)
## The living city's reed music plays a phrase this often, s, on these
## semitones of a pentatonic scale.
const REED_EVERY := 1.6
const REED_SCALE: Array[float] = [-5.0, -3.0, 0.0, 2.0, 4.0, 7.0, 9.0]
## The deliveryship's altitude as it reads it wanders this far about its
## true one, m, over these periods, s: a working figure, for flavour.
const SURVEY_WANDER := Vector2(150.0, 70.0)
const SURVEY_WANDER_S := Vector2(97.0, 31.0)

static var _gods: Gods
static var _sky: Constellation
static var _sky_for := []
static var _clips := {}
static var _letters := RegEx.create_from_string("[a-z]+")

## Whether it's switched on, and where its dial stands, kHz.
var on := false:
	set(to):
		on = to
		_recompute()
var frequency := Dial.LOWEST
## Which band it's on (BANDS), and where its FM dial stands, MHz: each band
## keeps its own place, so switching back finds where you were. The AM dial
## and the shortwave band share `frequency`, kHz, one going on past the
## other's top: where the one not in use stood is kept here.
var band := AM_BAND
var fm_mhz := Fm.LOWEST
## Its maker's look (RadioKitLooks.STYLES), whose band window it lights in
## the band's own colour as it switches, or &"" for a set with its own face;
## and whether it's a crystal set (no power, weak, faint and chewed up in its
## earpiece, its face its own with no live dial on it).
var style := &""
var crystal := false
## The wrecks calling SOS it could hear (Distress.calls), and where they were
## last looked for; and the last tone of their morse it sounded.
var _calls: Array[Dictionary] = []
var _calls_at := Vector3.INF
var _sos_key := -1
## The living city's reed music: the last phrase it played.
var _reed_at := -1
## The FM band's stations as last worked out, and when.
var _stations: Array[Dictionary] = []
var _stations_t := NAN
var _window: MeshInstance3D
var _window_key := []
static var _windows := {}
var am_khz := Dial.LOWEST
var sw_khz := Shortwave.LOWEST
## Where its volume knob stands, 0 silent to 1 full: everything it plays.
var volume := 1.0
## What the dial reads now (OFF to STATIC). Set, as old saves do, it moves
## the dial to that channel's carrier, once it knows its world.
var channel: int:
	get:
		return _reads()
	set(to):
		_tune_to_channel(to)
## What the beacon points at, decided when it was tuned to it: {x, z, coord,
## index} in world metres, or {} for no signal.
var target := {}
## The weather station's last reading (forecast()), and when it was read.
var reading := {}
var read_at := -INF
## The last god signal it heard: {id, khz, metres, bearing, way, storm,
## strength, clean, cut, useful, text}, or {} off a god.
var reception := {}
## What it says now, for the line in view; "" while it plays music, or doesn't play.
var said := ""
## The Walker's log entry as it comes through, the line under it; "" off the Walker.
var logged := ""
## The report it reads aloud, as its phrases, how many it has read, and when
## it last read one, world time. A storm loses phrases of it as it does the
## line's characters, "..." in their place.
var spoken := PackedStringArray()
var spoken_count := 0
var spoken_at := -INF
## Whether what it reads now is an advisory, which breaks off what's being read.
var spoken_urgent := false
## The advisories it has issued, by kind: when each event comes, world time,
## or Advisories.NOW for the storm you're in.
var _warned := {}
## The reading last checked for an advisory, by when it was read.
var _checked_at := NAN
## How much of the storm's static gets in now, 0 to 1, and of an anomaly's
## own, which crackles where a storm's hisses.
var noise := 0.0
var odd := 0.0
var music: AudioStreamPlayer3D
var hiss: AudioStreamPlayer3D
## What you turn on its face: the needle across the band, the tuning knob and
## the volume knob; and where they've got to, kHz and of full.
var needle: MeshInstance3D
var knob: MeshInstance3D
var volume_knob: MeshInstance3D
var band_lamp: MeshInstance3D
var shown_khz := Dial.LOWEST
var shown_volume := 1.0
var crackle: AudioStreamPlayer3D
## The weather station's voice, reading a report a phrase at a time.
var reader: AudioStreamPlayer3D

var _tuning := Tuning.current()
## Every voice it plays through, its satellites' too.
var _voices: Array[AudioStreamPlayer3D] = []
var _effect_buses: Array[StringName] = []
var _spoken_station: StringName = &""
var _last_words := ""
## What it hears from the satellites.
var sky: SkyVoices
var _signal: AudioStreamPlayer3D
## Your marks' ticks on its band.
var _ticks: Array[MeshInstance3D] = []
## The wheel spun fast: how many notches its last went, when (real seconds)
## and which way.
var _spin := 1.0
var _spun_at := -INF
var _spun_way := 0
## How dirty what it plays comes through now, 0 to 1 (Garble), and the
## glitches its music breaks into.
var dirt := 0.0
var _glitch: Glitch
## How strong the strongest thing it hears comes through, 0 to 1, as its
## signal lamps show it; and the lamps.
var lamp_level := 0.0
var _lamps: Array[MeshInstance3D] = []
var _since_signal := INF
## The track it has on air, and whether its static is: a voice only starts
## playing a moment after it's told, so it keeps its own word on what it plays.
var _on_air: AudioStream
## The scheduled occurrence, independent of drift in the real-time audio mixer.
var _on_air_started := NAN
var _hissing := false
## How loud what's on air comes through, 0 to 1, before the volume knob.
var _level := 1.0
## What its voice is reading: each phrase's recording (null where the storm
## took it) and when it starts, s in; the next one due, how far in it is, when
## it ends, and whether it's a Console speaking through it rather than the air.
var _lines := []
var _line := 0
var _reading_for := 0.0
## The dirtiest a report it's reading over the air has come through, for its
## wire logger; and how many its logger has played back.
var _reading_dirt := 0.0
var played_back := 0
## The physics frame a headset last turned the weather down on, for every radio.
static var _ducked_at := -10
var _done_at := 0.0
var _local := false
## What the dial read last tick; UNHEARD before its first, so a save's beacon keeps its target.
var _was := UNHEARD
## The city's chatter slot whose motif last sounded.
var _motif_slot := NAN
## An old save's channel, waiting for its world to place it on the dial.
var _wanted := UNHEARD
## Tu's roar on shortwave, heard under whatever else plays.
var roar: AudioStreamPlayer3D
## Its long wire: an antenna reel's wire clipped to its aerial terminal and
## strung out, as a real shortwave set hears on a wire: (how far it's strung,
## m; the higher of its two ends over the ground, m), or zero with none.
var wire := Vector2.ZERO
var _wire_at := -INF
## How far it has moved, m, for the fade it passes through on FM; where it was
## last tick; and each FM station's margin as last worked out, and where.
var _moved := 0.0
var _last_at := Vector3.INF
var _margins := {}
var _margins_at := Vector3.INF
var _margins_t := -INF


func _init() -> void:
	carryable = true
	add_to_group(GROUP)
	needle = _on_face(Dress.dial_needle())
	knob = _on_face(Dress.knob())
	volume_knob = _on_face(Dress.knob())
	band_lamp = _on_face(null)
	_show_band()
	_show_dial()


func _ready() -> void:
	super()
	for loop: AudioStreamOggVorbis in [Sounds.RADIO_DAY, Sounds.RADIO_NIGHT, Sounds.RADIO_STATIC,
			Sounds.RADIO_CLEAR_SKIES]:
		loop.loop = true
	# The Stoker's song and the Eye's drone play through once, then a silence:
	# the station keeps its time.
	for once: AudioStreamOggVorbis in [Sounds.RADIO_STOKER, Sounds.RADIO_EYE, Sounds.RADIO_EYE_TUNNEL]:
		once.loop = false
	music = add_voice(signal_bus())
	_glitch = Glitch.new(music)
	hiss = _voice()
	hiss.stream = Sounds.RADIO_STATIC
	crackle = _voice()
	crackle.stream = Sounds.RADIO_STATIC
	roar = _voice()
	roar.stream = Sounds.RADIO_STATIC
	roar.pitch_scale = 0.45
	_signal = add_voice(signal_bus())
	sky = SkyVoices.new()
	add_child(sky)
	reader = _voice()
	if _wanted != UNHEARD:
		_tune_to_channel(_wanted)
	shown_khz = _needle_khz()
	shown_volume = volume
	_show_dial()
	_show_marks()
	Profile.marks_changed.connect(_show_marks)
	if crystal:
		# Its face is its own: no live needle, knobs or lamps on it.
		for view in [needle, knob, volume_knob]:
			view.visible = false
	else:
		_make_lamps()
	_show_window()


func _exit_tree() -> void:
	# Looping streams still playing at quit hold their resources past exit;
	# seated or taken off, it comes back on air next tick.
	# A reparented set keeps its reading queue and resumes in its new position.
	for voice: AudioStreamPlayer3D in _voices:
		voice.stop()
	_on_air = null
	_hissing = false
	if sky != null:
		sky.silence()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for bus in _effect_buses:
			var index := AudioServer.get_bus_index(bus)
			if index >= 0:
				AudioServer.remove_bus(index)


## The gods of a world's history, made once, the Walker placed for its run.
static func gods_of(of: World) -> Gods:
	if _gods == null or _gods.history != of.shape.history:
		_gods = Gods.new(of.shape.history, of.run_seed, Tuning.current())
	_gods.place_walker(of.start, of.began)
	return _gods


## The satellites over a world, made once a run, the relay passing over where it began.
static func constellation_of(of: World) -> Constellation:
	var run := [of.run_seed, of.start]
	if _sky == null or _sky_for != run:
		var port: Dictionary = of.shape.history.landmark(&"port_morgan") if of.shape != null else {}
		_sky = Constellation.new(of.run_seed, Tuning.current(), of.start, port.get("p", Vector3.ZERO))
		_sky_for = run
	return _sky


## The relay satellite over a world, which carries the music.
static func relay_of(of: World) -> Satellite:
	return constellation_of(of).relay()


## Use switches it on or off, always, where its dial stands (gonkhub,
## 2026-10-21: "ALWAYS toggle radios on/off"); the wheel tunes it.
func interact(_by: Player) -> bool:
	if wrecked() or world == null:
		return false
	# Found in the sand, it's yours as you use it, so this use can start it.
	world.salvage.claim(self)
	var before := channel
	on = not on
	_retuned(before)
	if powered:
		_click(Sounds.RADIO_TUNE, minf(_tuning.radio_loudness_db, 3.0))
	return true


## Sweeps the dial up to the next carrier, with a burst of static; past the
## last it goes off, and from off it comes on at the first: how a probe or a
## scenario steps along the band.
func sweep() -> bool:
	if wrecked() or world == null:
		return false
	world.salvage.claim(self)
	var before := channel
	if band == FM_BAND:
		_sweep_fm()
	else:
		if not on:
			frequency = _lowest()
			on = true
		var next := _carrier_above(frequency + _tuning.dial_width_khz * ON_IT)
		if is_nan(next):
			frequency = _lowest()
			on = false
		else:
			frequency = next
	_retuned(before)
	if powered:
		_click(Sounds.RADIO_TUNE, minf(_tuning.radio_loudness_db, 3.0))
	return true


## Use in your hands tunes it just the same.
func use(by: Player, _at: Vector3) -> bool:
	return interact(by)


## Moves the dial `notches`, a notch or a fine step each; spun fast, a notch
## goes farther each time (dial_spin_seconds, up to dial_spin_most notches).
## A dark radio comes on where its dial stands.
func tune(notches: int, fine := false) -> bool:
	if wrecked() or world == null:
		return false
	world.salvage.claim(self)
	var before := channel
	on = true
	var step := _tuning.dial_fine_khz
	if not fine:
		var now := Time.get_ticks_msec() / 1000.0
		var spinning := now - _spun_at <= _tuning.dial_spin_seconds and signi(notches) == _spun_way
		_spin = minf(_spin + _tuning.dial_spin_grow, _tuning.dial_spin_most) if spinning else 1.0
		_spun_at = now
		_spun_way = signi(notches)
		step = (_tuning.sw_notch_khz if band == SW_BAND else _tuning.dial_notch_khz) * _spin
	if band == FM_BAND:
		var mhz := _tuning.fm_fine_mhz if fine else _tuning.fm_notch_mhz
		fm_mhz = clampf(snappedf(fm_mhz + notches * mhz * (1.0 if fine else _spin), mhz), Fm.LOWEST, Fm.HIGHEST)
		_retuned(before)
		return true
	var snap := _tuning.dial_fine_khz if fine else (_tuning.sw_notch_khz if band == SW_BAND else _tuning.dial_notch_khz)
	frequency = clampf(snappedf(frequency + notches * step, snap), _lowest(), _highest())
	if band == AM_BAND:
		frequency = Dial.on_dial(frequency, notches > 0)
	if _has(&"counter"):
		_lock_on()
	_retuned(before)
	return true


## Its frequency counter reads the carrier near the dial exactly: within
## counter_lock_khz of one, the dial stands right on it.
func _lock_on() -> void:
	var nearest := _tuning.counter_lock_khz
	var on_it := NAN
	for each in carriers():
		if absf(each - frequency) < nearest:
			nearest = absf(each - frequency)
			on_it = each
	if not is_nan(on_it):
		frequency = on_it


## On FM, use sweeps up to the next station, and off past the last, coming
## on at the band's bottom.
func _sweep_fm() -> void:
	if not on:
		fm_mhz = Fm.LOWEST
		on = true
	var above := fm_mhz + _tuning.fm_width_mhz * ON_IT
	for each in fm_stations(world.time):
		if each.mhz > above:
			fm_mhz = each.mhz
			return
	fm_mhz = Fm.LOWEST
	on = false


## Whether an FM converter is fitted in its side, so it reaches the FM band.
func has_fm() -> bool:
	return _has(&"fm")


## Whether a shortwave converter is fitted in its side, so it reaches shortwave.
func has_sw() -> bool:
	return _has(&"sw")


func _has(stat: StringName) -> bool:
	if frame_stats.get(stat, 0) > 0:
		return true
	return converter(stat) != null


## The part fitted that gives `stat`, not burnt out, or null.
func converter(stat: StringName) -> Part:
	for part in parts():
		if part.stats.get(stat, 0) > 0 and not part.stats.get("burnt", false):
			return part
	return null


## Whether it's on you, carried or in your hands.
func on_you() -> bool:
	return carried() or (world != null and world.player != null and world.player.hands.held == self)


## Whether you're listening close: a headset jacked in and the set on you.
func listened_close() -> bool:
	return _has(&"headset") and on_you()


## Whether a module that needs power works in it: a crystal set has none to give.
func _runs(stat: StringName) -> bool:
	return not crystal and _has(stat)


## Whether it reaches a band: the AM dial always, the others with their converters.
## Its misc bay's module at work: whether one with this stat is fitted.
func bleeds() -> bool:
	return _has(&"bleed")


## The socket holding the converter with this stat (&"fm", &"sw"), or null.
func converter_socket(stat: StringName) -> Socket:
	for socket in sockets():
		if socket.kind == &"radio_mod" and socket.part != null and socket.part.stats.get(stat, 0) > 0:
			return socket
	return null


## The antenna kite its top hook's lead runs to, or null.
func kite() -> AntennaKite:
	if not is_inside_tree():
		return null
	for node in get_tree().get_nodes_in_group(AntennaKite.GROUP):
		var each := node as AntennaKite
		if each != null and each.rig.get("radio") == self:
			return each
	return null


## What its valve preamp and static choke make of a signal's strength. A
## crystal set, with nothing to lift it, gets only so much, and has no power
## for a preamp.
func boost() -> float:
	var lift := _tuning.crystal_gain if crystal else (_tuning.preamp_gain if _runs(&"preamp") else 1.0)
	return lift * (_tuning.choke_signal if _has(&"choke") else 1.0)


## What its static choke leaves of the storm's hash or the garbling.
func choked(amount: float, share: float) -> float:
	return amount * share if _has(&"choke") else amount


## Its headset in use: fitted, the set playing, you within its cord.
func headset_on() -> bool:
	return _has(&"headset") and playing() and world != null and not carried() \
		and world.player.global_position.distance_to(global_position) <= _tuning.headset_cord_m


func reaches(to: StringName) -> bool:
	return to == AM_BAND or (to == FM_BAND and has_fm()) or (to == SW_BAND and has_sw())


## The band switch: round its bands, AM, FM and shortwave, skipping any it has
## no converter to reach, with a burst of static. Says whether it switched.
func switch_band() -> bool:
	if wrecked() or world == null:
		return false
	var to := band
	for i in BANDS.size():
		to = BANDS[(BANDS.find(to) + 1) % BANDS.size()]
		if reaches(to):
			break
	if to == band:
		return false
	world.salvage.claim(self)
	var before := channel
	_set_band(to)
	_retuned(before)
	if powered:
		_click(Sounds.RADIO_TUNE, minf(_tuning.radio_loudness_db, 3.0))
	return true


## Onto a band, the dial kept where it stood on the one it leaves.
func _set_band(to: StringName) -> void:
	if band == SW_BAND:
		sw_khz = frequency
		frequency = am_khz
	if to == SW_BAND:
		am_khz = frequency
		frequency = sw_khz
	band = to
	_show_band()
	_show_marks()


## The bottom and top of the dial on the band it's on, kHz (the FM band's in MHz).
func _lowest() -> float:
	return Shortwave.LOWEST if band == SW_BAND else Dial.LOWEST


func _highest() -> float:
	return Shortwave.HIGHEST if band == SW_BAND else Dial.HIGHEST


## Where its dial stands, kHz, on whichever band it's on: an FM frequency as
## kHz too, so a mark keeps one number on either.
func dial_khz() -> float:
	return roundf(fm_mhz * 1000.0) if band == FM_BAND else frequency


## How wide a frequency is on the band it's on, kHz: a mark within this of
## the dial is on it.
func dial_near_khz() -> float:
	return _tuning.fm_width_mhz * 1000.0 if band == FM_BAND else _tuning.dial_width_khz


## Whether a frequency, kHz, is on the band it's on.
func on_band(khz: float) -> bool:
	if band == FM_BAND:
		return khz >= Fm.LOWEST * 1000.0 and khz <= Fm.HIGHEST * 1000.0
	return khz >= _lowest() and khz <= _highest()


## Where a frequency, kHz, stands across the dial's window, 0 at the band's
## bottom to 1 at its top.
func dial_share(khz: float) -> float:
	if band == FM_BAND:
		return Fm.share(khz / 1000.0)
	if band == SW_BAND:
		return Shortwave.share(khz)
	return Dial.share(khz)


## What the dial reads, as the set shows it: "262 kHz", "96.7 MHz" on FM, or
## "27.45 MHz" on shortwave.
func dial_reading() -> String:
	if band == FM_BAND:
		return "%.1f MHz" % fm_mhz
	if band == SW_BAND:
		return "%.2f MHz" % (frequency / 1000.0)
	return "%d kHz" % roundi(frequency)


## On or off, the dial where it stands, with a burst of static, as the
## Console's switch does. Says whether it changed.
func switch(up: bool) -> bool:
	if wrecked() or world == null or up == on:
		return false
	world.salvage.claim(self)
	var before := channel
	on = up
	_retuned(before)
	if powered:
		_click(Sounds.RADIO_TUNE, minf(_tuning.radio_loudness_db, 3.0))
	return true


func has_dial_marks() -> bool:
	return not crystal


## Marks where its dial stands, in a colour of its own, bright and picked at
## random; or, with a mark there already (within a carrier's width), takes it
## off (gonkhub, 2026-10-19: "Just place a randomly colored marker when m is
## pressed, or remove the marker if one is already present"). A soft click
## either way. Says whether it marked.
func toggle_mark() -> bool:
	if not has_dial_marks():
		return false
	var near := dial_near_khz()
	var khz := roundf(dial_khz())
	if Profile.unmark(khz, near):
		_click(Sounds.MENU_BACK, -6.0)
		return false
	Profile.mark(khz, dial_reading(), Color.from_hsv(randf(), MARK_SATURATION, MARK_VALUE), near)
	_click(Sounds.MENU_CONFIRM, -6.0)
	return true


## The volume knob: turned `notches` a notch each, between silent and full.
func turn_volume(notches: int) -> bool:
	# A crystal set has no knob: it plays as loud as what it hears.
	if wrecked() or world == null or crystal:
		return false
	world.salvage.claim(self)
	volume = clampf(snappedf(volume + notches * VOLUME_STEP, VOLUME_STEP), 0.0, 1.0)
	_loudness()
	return true


## Whether it plays: on, powered, whole and in the world.
func playing() -> bool:
	return on and powered and not wrecked() and world != null and is_inside_tree()


## The carrier the dial hears now, by its id: on the AM dial a god's, the
## beacon's or a wreck's distress call (&"distress"); on FM a station's
## (Fm.stations); on shortwave the relay repeating Port Morgan Tower
## (&"relay"), the other satellites heard apart (SkyVoices). The nearest
## within its skirt's reach (Dial.reach), or &"" with none near. Storms slide
## a god off it; the dial goes by where its carrier belongs.
func tuned_to() -> StringName:
	if world == null:
		return &""
	var best := &""
	if band == SW_BAND:
		var relay := constellation_of(world).carrier(&"relay", world.time)
		if absf(frequency - relay) <= Dial.reach(_tuning) and _relay_up():
			best = &"relay"
		return best
	if band == FM_BAND:
		var near := _tuning.fm_width_mhz * ON_IT
		for each in fm_stations(world.time):
			var off: float = absf(fm_mhz - each.mhz)
			if off <= near:
				near = off
				best = each.id
		return best
	var nearest := Dial.reach(_tuning)
	for each in Dial.carriers(gods_of(world), world.time):
		var off := absf(frequency - each[0])
		if off <= nearest:
			nearest = off
			best = each[1]
	for each in distress_calls():
		var off: float = absf(frequency - each.khz)
		if off < nearest:
			nearest = off
			best = &"distress"
	return best


## Whether the relay at L1 is over its horizon.
func _relay_up() -> bool:
	var at := point_at(world.world_x(global_position.x), world.world_z(global_position.z))
	return constellation_of(world).relay().seen_from(at, world.time).elevation > 0.0


## The wrecks calling SOS it could hear from where it stands, looked for
## again once it's moved a way.
func distress_calls() -> Array[Dictionary]:
	var here := Vector3(world.world_x(global_position.x), 0.0, world.world_z(global_position.z))
	if _calls_at == Vector3.INF or here.distance_to(_calls_at) > Distress.LOOK_AGAIN_M:
		_calls = Distress.calls(world, here.x, here.z, _tuning)
		_calls_at = here
	return _calls


## The distress call nearest the dial within its reach, or {}.
func _call_near() -> Dictionary:
	var best := {}
	var nearest := Dial.reach(_tuning)
	for each in distress_calls():
		var off: float = absf(frequency - each.khz)
		if off <= nearest:
			nearest = off
			best = each
	return best


## The bearing from it to what its beacon points at, degrees; NAN with no signal.
func beacon_bearing() -> float:
	if target.is_empty():
		return NAN
	return bearing(Vector2(target.x - world.world_x(global_position.x), target.z - world.world_z(global_position.z)))


## Where a god is from it now: {metres, bearing (on the ground, degrees from
## -z), way (as it would say it)}.
func god_way(id: StringName) -> Dictionary:
	var x := world.world_x(global_position.x)
	var z := world.world_z(global_position.z)
	var p := point_at(x, z)
	var q := gods_of(world).home(id, world.time)
	var ground := ground_bearing(rad_to_deg(Sphere.bearing(p, q)))
	return {"metres": Sphere.angle(p, q) * world.moon.radius, "bearing": ground,
		"way": Dial.way(world.shape.history, p, q, ground, say_point, _tuning)}


## The track it plays now, or null.
func track() -> AudioStream:
	return _on_air if playing() and channel == MUSIC else null


func demand_w(t := NAN) -> float:
	# A crystal set draws nothing, whatever's in its bay: it runs on what it hears.
	if crystal:
		return 0.0
	return super(t) + (_tuning.radio_w if on and not wrecked() else 0.0)


func stats() -> Dictionary:
	var now := super()
	now["tuned"] = dial_reading() if on else "off"
	# On a frequency you've marked, its name too.
	var mark := Profile.mark_at(dial_khz(), dial_near_khz()) if on else {}
	if not mark.is_empty() and mark.name != now.tuned:
		now["tuned"] += " · " + str(mark.name)
	return now


func _recompute() -> void:
	super()
	_show_window()
	# Its dial lights only while it's on.
	for view in painted():
		if view != null:
			view.set_instance_shader_parameter(&"lit", 1.0 if on and powered else 0.0)


## Its needle and knobs wear its paint too.
func painted() -> Array[MeshInstance3D]:
	var out := super()
	out.append_array([needle, knob, volume_knob, band_lamp])
	return out


## The needle and knobs turn after the dial and the volume, so you see them go.
func _process(delta: float) -> void:
	# Carried, or on its headset, its voices keep up with your eyes every frame.
	var on_headset := music != null and headset_on()
	if (carried() or on_headset) and music != null:
		_to_your_ears(true)
	if on_headset:
		_ducked_at = Engine.get_process_frames()
	# A headset in use anywhere turns the wind and storm down for you.
	var weather := AudioServer.get_bus_index(Sounds.WEATHER)
	if weather >= 0:
		var want := _tuning.headset_duck_db if Engine.get_process_frames() - _ducked_at <= 2 else 0.0
		var now_db := AudioServer.get_bus_volume_db(weather)
		if not is_equal_approx(now_db, want):
			AudioServer.set_bus_volume_db(weather, move_toward(now_db, want, 40.0 * delta))
	var to := _needle_khz()
	if shown_khz == to and shown_volume == volume:
		return
	var k := 1.0 - exp(-delta / TURN_SECONDS)
	shown_khz = to if absf(to - shown_khz) < 0.01 else lerpf(shown_khz, to, k)
	shown_volume = volume if absf(volume - shown_volume) < 0.001 else lerpf(shown_volume, volume, k)
	_show_dial()


## How far the tuning knob stands turned at a frequency, rad clockwise.
static func knob_turn(khz: float) -> float:
	return TAU * (khz - Dial.LOWEST) / KHZ_A_TURN


## Its band window in its maker's look, lit in the band's own colour while
## it plays, the tells on the bands it can reach dim, built again as any of
## that changes (RadioKitLooks.window), each look made once.
func _show_window() -> void:
	if style == &"":
		return
	var reach := []
	if has_fm():
		reach.append(FM_BAND)
	if has_sw():
		reach.append(SW_BAND)
	var key := [style, band, on and powered, reach]
	if key == _window_key:
		return
	_window_key = key
	if not _windows.has(key):
		_windows[key] = RadioKitLooks.window(style, band, on and powered, reach)
	if _window == null:
		_window = _on_face(_windows[key])
	else:
		_window.mesh = _windows[key]


## Where the needle stands on its window, as the AM dial's kHz across it:
## the FM band and shortwave spread over the same window.
func _needle_khz() -> float:
	if band == FM_BAND:
		return lerpf(Dial.LOWEST, Dial.HIGHEST, Fm.share(fm_mhz))
	return lerpf(Dial.LOWEST, Dial.HIGHEST, Shortwave.share(frequency)) if band == SW_BAND else frequency


## Its needle on the band and its knobs turned to what they show.
func _show_dial() -> void:
	needle.position = Vector3(lerpf(BAND.x, BAND.y, Dial.share(shown_khz)), BAND_Y, FACE.z + 0.0035)
	knob.transform = Transform3D(Basis(Vector3.BACK, -knob_turn(shown_khz)), KNOB_AT)
	volume_knob.transform = Transform3D(Basis(Vector3.BACK, VOLUME_SWEEP * (0.5 - shown_volume))
		.scaled(Vector3.ONE * VOLUME_KNOB), VOLUME_AT)


## Its band lamp in the seat by the name of the band it's on, in its colour.
func _show_band() -> void:
	# A maker's look tells its band by its window and its tells instead.
	band_lamp.visible = style == &""
	_show_window()
	band_lamp.mesh = Dress.band_lamp(band)
	band_lamp.position = BAND_LAMP_FROM + Vector3(BANDS.find(band) * BAND_LAMP_GAP, 0.0, FACE.z)


## Your marks on its band: a short tick in each one's colour along the top of
## the window, where the needle stands on that frequency.
func _show_marks() -> void:
	for tick in _ticks:
		tick.queue_free()
	_ticks.clear()
	if not has_dial_marks():
		return
	for each: Dictionary in Profile.marks():
		if not on_band(each.khz):
			continue
		var tick := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = MARK_TICK
		var paint := StandardMaterial3D.new()
		paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		paint.albedo_color = Color.html(each.color)
		box.material = paint
		tick.mesh = box
		add_child(tick)
		tick.position = Vector3(lerpf(BAND.x, BAND.y, dial_share(each.khz)),
			BAND_Y + BAND_HEIGHT * 0.5 - MARK_TICK.y * 0.5 - 0.0015, FACE.z + 0.003)
		_ticks.append(tick)


## Its signal lamps, dark until it hears something.
func _make_lamps() -> void:
	for i in LAMPS:
		var lamp := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = LAMP
		var paint := StandardMaterial3D.new()
		paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		box.material = paint
		lamp.mesh = box
		add_child(lamp)
		lamp.position = Vector3(LAMP_FROM.x + i * LAMP_GAP, LAMP_FROM.y, FACE.z + LAMP.z * 0.5)
		_lamps.append(lamp)
	_show_lamps(0.0, INF)


## The lamps as lit by how strong what it hears is, 0 to 1, followed over delta s:
## as many lit as it's strong, the last of them partly, the rest dark.
func _show_lamps(strength: float, delta: float) -> void:
	lamp_level = lerpf(lamp_level, clampf(strength, 0.0, 1.0), 1.0 - exp(-LAMP_FOLLOW * delta))
	for i in _lamps.size():
		var lit := clampf(lamp_level * LAMPS - i, 0.0, 1.0)
		var color := LAMP_LOW.lerp(LAMP_HIGH, float(i) / (LAMPS - 1))
		var paint := (_lamps[i].mesh as BoxMesh).material as StandardMaterial3D
		paint.albedo_color = Color(0.06, 0.07, 0.06).lerp(color, lit)


## Where its face is, to read its dial: the face's middle, its +Z out of the face.
func face() -> Transform3D:
	return global_transform.translated_local(FACE)


func _on_face(look: ArrayMesh) -> MeshInstance3D:
	var view := MeshInstance3D.new()
	view.mesh = look
	add_child(view)
	return view


func _physics_process(delta: float) -> void:
	super(delta)
	_listen(delta)


## Whether you hear it where you are: its words in the line low in your
## view, or what it plays within earshot.
func heard() -> bool:
	var far := global_position.distance_to(world.player.camera.global_position)
	return far < Broadcast.EARSHOT or far < _tuning.radio_heard_m and volume > 0.0


## What the dial reads, from where it stands.
func _reads() -> int:
	if not on:
		return OFF
	var at := tuned_to()
	if band == FM_BAND:
		match at:
			Fm.TOWER:
				return WEATHER
			Fm.PORT_MUSIC, Fm.CITY_MUSIC:
				return MUSIC
			Fm.CITY_TALK:
				return CITY
			&"":
				return STATIC
		return GOD
	match at:
		&"relay":
			return WEATHER
		&"beacon":
			return BEACON
		&"distress":
			return DISTRESS
		&"":
			return STATIC
	return GOD


## An old save's channel, or a scenario's, as a place on the dial: the
## weather is Port Morgan Tower's, on the relay's shortwave carrier through a
## shortwave converter, or else on FM; the music is the port's, on FM (with
## no converter for it, the dial's left where it stands); the beacon is on
## the AM dial.
func _tune_to_channel(to: int) -> void:
	on = to != OFF
	_wanted = to if world == null else UNHEARD
	match to:
		BEACON:
			if band != AM_BAND:
				_set_band(AM_BAND)
			frequency = Dial.BEACON_KHZ
		WEATHER:
			if world != null and reaches(SW_BAND):
				if band != SW_BAND:
					_set_band(SW_BAND)
				frequency = constellation_of(world).carrier(&"relay", world.time)
			elif world != null and reaches(FM_BAND):
				if band != FM_BAND:
					_set_band(FM_BAND)
				fm_mhz = fm_of(Fm.TOWER)
		MUSIC:
			if world != null and reaches(FM_BAND):
				if band != FM_BAND:
					_set_band(FM_BAND)
				fm_mhz = fm_of(Fm.PORT_MUSIC)


## The FM band's stations at world time t (Fm.stations), worked out once a
## moment: the dial asks after them many times a tick.
func fm_stations(t: float) -> Array[Dictionary]:
	if t != _stations_t:
		_stations = Fm.stations(gods_of(world), world.run_seed, _tuning, t)
		_stations_t = t
	return _stations


## Where an FM station stands on the dial, MHz.
func fm_of(id: StringName) -> float:
	for each in fm_stations(world.time):
		if each.id == id:
			return each.mhz
	return Fm.LOWEST


## Every carrier it could stop on now, kHz, low to high: the gods' and the
## beacon's, the wrecks' calls, and the satellites' on the air overhead with
## the relay's.
func carriers() -> Array[float]:
	var out: Array[float] = []
	for each in Dial.carriers(gods_of(world), world.time):
		out.append(each[0])
	for each in distress_calls():
		out.append(each.khz)
	var x := world.world_x(global_position.x)
	var z := world.world_z(global_position.z)
	for each in constellation_of(world).carriers(point_at(x, z), world.time):
		out.append(each[0])
	if _relay_up():
		out.append(constellation_of(world).carrier(&"relay", world.time))
	var kept: Array[float] = []
	for each in out:
		if on_band(each):
			kept.append(each)
	kept.sort()
	return kept


## The first carrier above a frequency, or NAN past the last.
func _carrier_above(khz: float) -> float:
	for each in carriers():
		if each > khz:
			return each
	return NAN


## After the dial moved: coming onto the beacon, it decides then which one it hears.
func _retuned(before: int) -> void:
	var now := channel
	if now == BEACON and before != BEACON:
		target = Finds.beacon(world.run_seed, world.shape.sites, world.world_x(global_position.x),
			world.world_z(global_position.z), _tuning, world.salvage.taken)
	if now != before:
		read_at = -INF
		_since_signal = INF
		# Tuned onto the weather station, it reports at once.
		spoken_at = -INF


## What it plays this tick, from the systems it reads.
func _listen(delta: float) -> void:
	_to_your_ears(carried() or headset_on())
	_track_moves()
	_read_wire()
	if not playing():
		noise = 0.0
		odd = 0.0
		said = ""
		spoken = PackedStringArray()
		_spoken_station = &""
		_last_words = ""
		reception = {}
		if _on_air != null or _hissing:
			_off_air()
		if sky != null:
			sky.silence()
		_show_lamps(0.0, delta)
		logged = ""
		_read(delta, OFF)
		return
	var x := world.world_x(global_position.x)
	var z := world.world_z(global_position.z)
	var t := world.time
	if not reaches(band):
		# Its converter taken off, it's back on the AM dial.
		_set_band(AM_BAND)
	if band == FM_BAND:
		_listen_fm(delta, x, z, t)
		return
	var field := world.weather.field
	# A storm front's static, and any a jammer overhead sprays round the dial.
	noise = maxf(field.outflow_at(x, z, t), constellation_of(world).jamming(frequency, point_at(x, z), t))
	# A kite flown on its lead charges up, and its static rises with it.
	var flown := kite()
	if flown != null:
		noise = maxf(noise, flown.charge * _tuning.kite_static)
	noise = choked(noise, _tuning.choke_static)
	odd = choked(field.anomaly_at(x, z, t), _tuning.choke_static)
	var now := channel
	var station := tuned_to()
	if station != _spoken_station:
		_hush()
		_spoken_station = station
		spoken = PackedStringArray()
		_last_words = ""
		spoken_at = -INF
	if now != _was:
		if _was != UNHEARD or target.is_empty():
			_retuned(_was)
		_was = now
	var dial := "%d kHz · " % roundi(frequency)
	var under := NOTHING
	var song: AudioStream = null
	var into := NAN
	var quiet := false
	_level = 1.0
	reception = {}
	logged = ""
	match now:
		GOD:
			var id := tuned_to()
			reception = receive(id, x, z, t)
			var aired := _god_air(delta, id, dial, t)
			song = aired.song
			into = aired.into
			quiet = aired.quiet
			if crystal and reception.useful and not reception.cut and reception.clean > 0.0 and heard():
				Deeds.done(world, &"foxhole")
				if listened_close():
					Deeds.done(world, &"close_listening")
			if not reception.cut and reception.broadside >= WHOLE and reception.clean <= 0.0 and volume > 0.0 \
					and heard():
				Deeds.done(world, &"null")
			under = NOTHING if reception.cut else lerpf(NOTHING, CARRIER, reception.clean)
		WEATHER:
			# On shortwave: the relay at L1 repeating Port Morgan Tower, as clean as
			# its rig hears a satellite.
			reception = receive_from(constellation_of(world).relay(), constellation_of(world).carrier(&"relay", t),
				&"relay", x, z, t)
			_level = audible(reception)
			song = _tower_air(t, _level, dial)
			under = NOTHING if reception.cut else lerpf(NOTHING, CARRIER, reception.clean)
		DISTRESS:
			reception = receive_distress(x, z, t)
			_level = audible(reception)
			if reception.is_empty() or reception.clean <= 0.0:
				said = dial + "static"
			elif reception.cut:
				said = dial + "· · ·"
			else:
				said = dial + reception.text
				if reception.clean >= WHOLE and volume > 0.0 and heard():
					Deeds.done(world, &"mayday")
			if not reception.is_empty():
				under = NOTHING if reception.cut else lerpf(NOTHING, CARRIER, reception.clean)
				_sos(t)
		BEACON:
			var heard := Dial.heard(frequency - Dial.BEACON_KHZ, _tuning)
			if target.is_empty():
				said = dial + "no signal"
			else:
				var far := Vector2(target.x - x, target.z - z).length()
				said = dial + ("a signal, right here" if far <= HERE else "a signal, %s · %s" % [
					say_point(beacon_bearing()), "faint" if far > FAINT else ("clear" if far > CLEAR else "strong")])
				under = lerpf(NOTHING, CARRIER, heard)
				_signal.pitch_scale = 1.0
				_every(delta, lerpf(PING_NEAR, PING_FAR, clampf(far / FAINT, 0.0, 1.0)), Sounds.RADIO_PING)
		STATIC:
			said = dial + "static"
	if (now == GOD or now == DISTRESS) and not reception.is_empty() and not reception.cut and audible(reception) > 0.0:
		_transmit(reception.words, t)
	elif now == BEACON and not target.is_empty() and voice_level() > 0.0:
		_transmit(said.trim_prefix(dial), t)
	if song != null:
		_put_on(song, t, into)
	elif _on_air != null:
		# A report breaks into the hold music through a burst of static.
		if _on_air == Sounds.RADIO_CLEAR_SKIES:
			_click(Sounds.RADIO_TUNE, -6.0)
		music.stop()
		_on_air = null
	if not _is_song(song) and now != MUSIC:
		music.pitch_scale = 1.0
	# The static sinks under whatever you can hear, and is all there is when there's nothing.
	var through := 0.0
	if (now == WEATHER or now == GOD or now == DISTRESS) and not reception.is_empty():
		through = 0.0 if quiet or reception.cut else reception.clean
	elif now == BEACON and not target.is_empty():
		through = Dial.heard(frequency - Dial.BEACON_KHZ, _tuning)
	# The satellites, all at once over whatever else it hears.
	var sky_heard := sky.listen(delta, x, z, t)
	through = maxf(through, sky_heard)
	if band == SW_BAND and wire.x >= _tuning.sw_wire_m and sky_heard >= WHOLE and volume > 0.0 and heard():
		Deeds.done(world, &"long_wire")
	if band == SW_BAND and flown != null and flown.up() and flown.height() >= KITE_HIGH and sky_heard >= WHOLE \
			and volume > 0.0 and heard():
		Deeds.done(world, &"high_wire")
	# Tu's roar, up on shortwave, under the rest and over the static.
	var tu := 0.0
	if band == SW_BAND:
		tu = Shortwave.roar(point_at(x, z), world.shape.history.sub_tu, frequency, t, world.weather.day.tu_turn(t),
			_tuning) * antenna_gain()
		if tu >= CRACKLE_TELL and volume > 0.0 and heard():
			Deeds.done(world, &"tu_roar")
	roar.volume_db = linear_to_db(tu + 0.0001) + knob_db()
	through = maxf(through, tu * 0.5)
	_show_lamps(through, delta)
	# Static only while nothing plays (gonkhub, 2026-10-19): interference is in
	# what you hear, not hiss laid over it.
	var ducked := 1.0 - smoothstep(STATIC_GONE.x, STATIC_GONE.y, through)
	hiss.volume_db = linear_to_db(maxf(noise, under) * ducked + 0.0001) + knob_db()
	# An anomaly's static sputters: the hiss thinned and pitched up, cut in and
	# out in short bursts, the deeper the more of it.
	var burst := Interference.crackle(t)
	crackle.pitch_scale = lerpf(CRACKLE_PITCH.x, CRACKLE_PITCH.y, burst.y)
	crackle.volume_db = linear_to_db(odd * burst.x * CRACKLE_LEVEL * ducked + 0.0001) + knob_db()
	if odd >= CRACKLE_TELL and volume > 0.0 and heard():
		Deeds.done(world, &"tells", &"crackle")
	_loudness()
	# What it plays, chewed up as dirty as it comes through, glitching.
	dirt = reception.get("dirt", 0.0) if now != BEACON else 1.0 - Dial.pull(frequency - Dial.BEACON_KHZ,
		_tuning.dial_width_khz)
	# A crystal set's earpiece chews up everything it plays; a headset less so.
	if crystal:
		dirt = maxf(dirt, _tuning.crystal_headset_dirt if listened_close() else _tuning.crystal_dirt)
	Garble.shape(AudioServer.get_bus_index(signal_bus()), 0, dirt, t, get_instance_id(), _tuning.am_audio_hz)
	var broke := _glitch.tick(delta, dirt)
	if not _local and not _lines.is_empty():
		_reading_dirt = maxf(_reading_dirt, dirt)
	music.volume_db += linear_to_db(maxf(broke.x, 0.0001))
	music.pitch_scale = maxf(0.05, music.pitch_scale * broke.y)
	_read(delta, now)
	if not _hissing:
		hiss.play(fposmod(t, hiss.stream.get_length()))
		crackle.play(fposmod(t * 0.7, crackle.stream.get_length()))
		roar.play(fposmod(t * 0.4, roar.stream.get_length()))
		_hissing = true


## Its long wire as it lies now, read every WIRE_EVERY s: the longest strung
## from a reel clipped to it, and the higher of that wire's ends over the ground.
func _read_wire() -> void:
	if world == null or not is_inside_tree() or absf(world.time - _wire_at) < WIRE_EVERY:
		return
	_wire_at = world.time
	wire = Vector2.ZERO
	for node in get_tree().get_nodes_in_group(AntennaReel.GROUP):
		var reel := node as AntennaReel
		if reel == null or reel.radio != self:
			continue
		var tip := reel.end()
		var high := maxf(global_position.y - world.height_under(global_position), tip.y - world.height_under(tip))
		wire = Vector2(maxf(wire.x, reel.strung()), maxf(wire.y, high))


## How much of a station on the AM dial its ferrite rod picks up, coming from
## `bearing` (degrees from -z, on the ground), 0 to 1. The rod lies along the
## set's own width, as a real AM set's does, or across your view while you carry
## it: all of a station broadside to it, and held there by the set's gain
## control as it turns, until within rod_width of end-on it falls into its null
## (rod_null), or only so deep by night's sky wave (`sky`, rod_night_null).
## So turning the set, or yourself with it, finds a station's line by its
## silence, both ways along it.
func rod(bearing: float, sky: bool) -> float:
	var axis := world.player.camera.global_basis.x if carried() else global_basis.x
	# A direction loop in its bay: its null sharp and deep, by night too.
	var loop := _has(&"loop")
	var flat := Vector2(axis.x, axis.z)
	# Stood on its end the rod's upright, and every way's the same to it.
	if flat.length() < 0.2:
		return 1.0
	var to := Vector2(sin(deg_to_rad(bearing)), -cos(deg_to_rad(bearing)))
	var across := absf(flat.normalized().cross(to))
	if loop:
		return lerpf(_tuning.loop_null, 1.0, smoothstep(0.0, _tuning.loop_width, across))
	return lerpf(_tuning.rod_night_null if sky else _tuning.rod_null, 1.0, smoothstep(0.0, _tuning.rod_width, across))


## How much of what's sent from above the ceiling it hears, 0 to 1: on
## shortwave, a little on its converter's terminals alone, all of it on a long
## wire strung out, less strung low along the sand; elsewhere all of it.
func antenna_gain() -> float:
	if band != SW_BAND:
		return 1.0
	var long := smoothstep(0.0, _tuning.sw_wire_m, wire.x)
	var high := lerpf(_tuning.sw_wire_low, 1.0, smoothstep(0.0, _tuning.sw_wire_high_m, wire.y))
	var got := lerpf(_tuning.sw_bare, 1.0, long * high)
	# A kite flown on its lead: the higher, the more, past a long wire's.
	var flown := kite()
	if flown != null and flown.up():
		got = maxf(got, AntennaKite.gain(flown.height(), _tuning))
	return got


## How far it has moved, in the world's own metres so the world shifting
## under it doesn't count.
func _track_moves() -> void:
	if world == null:
		return
	var here := Vector3(world.world_x(global_position.x), global_position.y, world.world_z(global_position.z))
	if _last_at != Vector3.INF:
		var step := here.distance_to(_last_at)
		if step < FM_JUMP_M:
			_moved += step
	_last_at = here


## What it plays this tick on the FM band: the station the dial takes, clean,
## or lost under hiss at its threshold, fluttering as it moves near it. A
## storm's static isn't heard here: FM's limiter clips it off. The satellites
## aren't either: they're on the AM dial.
func _listen_fm(delta: float, x: float, z: float, t: float) -> void:
	var now := channel
	if now != _was:
		_retuned(_was)
		_was = now
	if sky != null:
		sky.silence()
	noise = 0.0
	odd = 0.0
	said = ""
	logged = ""
	reception = receive_fm(x, z, t)
	var under := NOTHING
	var song: AudioStream = null
	var into := NAN
	var dial := "%.1f MHz · " % fm_mhz
	_level = 0.0
	if not reception.is_empty():
		_level = reception.heard
		under = NOTHING * (1.0 - reception.quiet)
		match reception.id:
			Fm.TOWER:
				song = _tower_air(t, reception.heard, dial)
			Fm.PORT_MUSIC:
				song = Sounds.RADIO_DAY if world.weather.day.is_day(t, world.moon.longitude) else Sounds.RADIO_NIGHT
			Fm.CITY_MUSIC:
				_reed(t)
			Fm.CITY_TALK:
				reception.merge(_city_words(reception.quiet, t))
				said = dial + ("static" if reception.text == "" else reception.text)
				_chatter(reception)
			_:
				var id: StringName = reception.id
				reception = receive_fm_god(reception, x, z, t)
				var aired := _god_air(delta, id, dial, t)
				song = aired.song
				into = aired.into
				_level = reception.heard
				# The Walker's log entry, as it comes through, for the line under.
				if reception.has("contact"):
					logged = reception.text if reception.clean > 0.0 else ""
				if audible(reception) > 0.0:
					_transmit(reception.words, t)
		if reception.id in [Fm.PORT_MUSIC, Fm.CITY_MUSIC] and reception.quiet >= WHOLE and volume > 0.0 and heard():
			Deeds.done(world, &"fm_heard")
	if song != null:
		_put_on(song, t, into)
		if _is_song(song):
			music.pitch_scale = 1.0
	elif _on_air != null:
		if _on_air == Sounds.RADIO_CLEAR_SKIES:
			_click(Sounds.RADIO_TUNE, -6.0)
		music.stop()
		_on_air = null
	_show_lamps(_level, delta)
	hiss.volume_db = linear_to_db(under + 0.0001) + knob_db()
	crackle.volume_db = linear_to_db(0.0001)
	roar.volume_db = linear_to_db(0.0001)
	_loudness()
	# Through the converter it plays as the AM set does, as narrow.
	dirt = reception.get("dirt", 0.0)
	Garble.shape(AudioServer.get_bus_index(signal_bus()), 0, dirt, t, get_instance_id(), _tuning.am_audio_hz)
	_read(delta, now)
	if not _hissing:
		hiss.play(fposmod(t, hiss.stream.get_length()))
		crackle.play(fposmod(t * 0.7, crackle.stream.get_length()))
		roar.play(fposmod(t * 0.4, roar.stream.get_length()))
		_hissing = true


## The FM station the dial takes where it stands, x, z at world time t:
## {id, mhz, margin (dB it clears the noise by, its fade and how far off it
## the dial is taken off), share (how near its frequency the dial is),
## quiet (0 lost to hiss, 1 quiet), heard (how loud, 0 to 1), dirt}, or {}
## with none near the dial. Of two on one frequency the stronger takes it
## whole; within the capture ratio of each other they fight, and it's dirty.
func receive_fm(x: float, z: float, t: float) -> Dictionary:
	var here := Vector3(x, global_position.y, z)
	if _margins_at == Vector3.INF or here.distance_to(_margins_at) > FM_RECKON_M \
			or absf(t - _margins_t) > FM_RECKON_S:
		_margins = {}
		_margins_at = here
		_margins_t = t
	var ground := func(gx: float, gz: float) -> float: return world.height_at(gx, gz)
	var best := {}
	var rival := -INF
	for each in fm_stations(t):
		var share := Dial.pull(fm_mhz - each.mhz, _tuning.fm_width_mhz)
		if share < 0.01:
			continue
		if not _margins.has(each.id):
			var from := ground_of(each.at)
			_margins[each.id] = Fm.margin(from, world.height_at(from.x, from.y) + each.mast_m, Vector2(x, z),
				global_position.y, each.mhz, world.moon.radius, ground, _tuning)
		var margin: float = _margins[each.id] + 20.0 * log(share) / log(10.0) - Fm.fade_db(_moved, each.mhz)
		if best.is_empty() or margin > best.margin:
			if not best.is_empty():
				rival = best.margin
			best = {"id": each.id, "mhz": each.mhz, "margin": margin, "share": share}
		else:
			rival = maxf(rival, margin)
	if best.is_empty():
		return {}
	var fought := 1.0 - smoothstep(0.0, _tuning.fm_capture_db, best.margin - rival) if rival > -INF else 0.0
	best["quiet"] = Fm.quieting(best.margin, _tuning)
	best["heard"] = sqrt(best.share) * smoothstep(_tuning.fm_threshold_db - 6.0, _tuning.fm_threshold_db, best.margin)
	best["dirt"] = clampf((1.0 - best.share) * Garble.OFF_TUNE + fought * 0.5, 0.0, 1.0)
	best["cut"] = false
	return best


## A god's signal as it reaches a place at world time t: how far it came and
## from which way, how much storm lies between, how strong and how clean it
## arrives, whether it's cut, and what's left of what it says.
func receive(id: StringName, x: float, z: float, t: float) -> Dictionary:
	var gods := gods_of(world)
	var p := point_at(x, z)
	var q := gods.home(id, t)
	var metres := Sphere.angle(p, q) * world.moon.radius
	var ground := ground_bearing(rad_to_deg(Sphere.bearing(p, q)))
	var night := not world.weather.day.is_day(t, Sphere.longitude(p))
	var khz := gods.carrier(id, t)
	var storm := Interference.along(world.weather.field, x, z, ground, metres, t, _tuning)
	var slid := Interference.warp(storm, t, id, _tuning)
	var share := Dial.heard(frequency - khz - slid, _tuning)
	var turned := rod(ground, Dial.by_sky(khz, metres, night, _tuning))
	var broadside := Dial.strength(id, khz, metres, night, _tuning) * boost()
	var power := broadside * turned
	var strength := share * power
	# A jammer overhead buries what's near it on the dial.
	var jammed := constellation_of(world).jamming(frequency, p, t)
	var clean := smoothstep(_tuning.signal_floor, WHOLE, strength) * Interference.let_through(storm, _tuning) \
		* (1.0 - jammed)
	# Broadside to its rod, it would come in this clean.
	var whole := smoothstep(_tuning.signal_floor, WHOLE, share * broadside) * Interference.let_through(storm, _tuning) \
		* (1.0 - jammed)
	var dirt := choked(Garble.dirt(power, Interference.let_through(storm, _tuning), jammed, odd,
		1.0 - Dial.pull(frequency - khz - slid, _tuning.dial_width_khz), _tuning), _tuning.choke_dirt)
	var words := Transmissions.say(id, self, gods, p, x, z, t)
	var heard := {"id": id, "khz": khz, "metres": metres, "bearing": ground,
		"way": Dial.way(world.shape.history, p, q, ground, say_point, _tuning), "storm": storm,
		"warp": slid, "strength": strength, "clean": clean, "cut": Interference.cut(storm, t, id, _tuning),
		"share": share, "dirt": dirt, "rod": turned, "broadside": whole, "useful": words.useful, "words": words.text,
		"text": Interference.distort(words.text, clean, t, id)}
	return heard


## The living city's chatter on FM, as clean as its station comes through
## (`clean`): the motif in its slot and the line, its tones by how they run
## and, giving its place, its star positions.
func _city_words(clean: float, t: float) -> Dictionary:
	var city := gods_of(world).city
	var heard := {"motif": &"", "slot": city.slot_start(t), "text": "", "warp": 0.0, "cut": false}
	if clean > 0.0:
		var motif := city.motif(world.weather.field, Walker.ground(world, city.at(t)), t)
		var line: String = LivingCity.SHAPES[motif]
		if motif == LivingCity.POSITION:
			line += "  " + city.stars(heard.slot, world.weather.day)
		heard.motif = motif
		heard.text = Interference.distort(line, clean, t, &"city")
	return heard


## The living city's music on FM: its reed players, a phrase of its motifs
## every REED_EVERY s, in an order and on notes of a scale the seed and the
## hour pick, so it's never quite the same twice.
func _reed(t: float) -> void:
	var phrase := floori(t / REED_EVERY)
	if phrase == _reed_at:
		return
	_reed_at = phrase
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([world.run_seed, "reed", phrase])
	var motifs: Array = Sounds.CITY_MOTIFS.keys()
	_signal.stream = Sounds.CITY_MOTIFS[motifs[rng.randi_range(0, motifs.size() - 1)]]
	_signal.pitch_scale = pow(2.0, REED_SCALE[rng.randi_range(0, REED_SCALE.size() - 1)] / 12.0)
	_signal.play()


## Its chatter's motif sounds once at the head of each slot it comes through
## in.
func _chatter(heard: Dictionary) -> void:
	if heard.motif == &"" or heard.cut or heard.slot == _motif_slot:
		return
	_motif_slot = heard.slot
	_signal.stream = Sounds.CITY_MOTIFS[heard.motif]
	_signal.pitch_scale = 1.0 + PITCH_SLIDE * heard.warp / maxf(_tuning.storm_warp_khz, 0.01)
	_signal.play()


## How loud a signal plays, 0 to 1, before the knob: by how near its carrier
## the dial stands alone, so tuning still brings one up out of the others;
## what interference does is in its sound (dirt, Garble), not its loudness,
## until it's all but lost and fades away, or drops out.
static func audible(heard: Dictionary) -> float:
	if heard.is_empty() or heard.cut:
		return 0.0
	return sqrt(heard.share) * (1.0 - smoothstep(LOST, 1.0, heard.dirt))


## The bus its signal plays through, the music, a god's song or tones: the
## interference chain (Garble) on into the radio's own. One for every radio.
func signal_bus() -> StringName:
	var bus := StringName("%s_%d" % [SIGNAL_BUS, get_instance_id()])
	if AudioServer.get_bus_index(bus) == -1:
		AudioServer.add_bus()
		var i := AudioServer.bus_count - 1
		AudioServer.set_bus_name(i, bus)
		AudioServer.set_bus_send(i, Sounds.radio_bus())
		Garble.add_chain(i)
		_effect_buses.append(bus)
	return bus


## A station's voice has its own character before this set's reception dirt.
## Neither the music nor another set inherits its speech treatment.
func _speech_bus(profile: Dictionary) -> StringName:
	if profile.is_empty():
		return signal_bus()
	var bus := StringName("RadioSpeech_%d" % get_instance_id())
	var index := AudioServer.get_bus_index(bus)
	if index == -1:
		var destination := signal_bus()
		AudioServer.add_bus()
		index = AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, bus)
		AudioServer.set_bus_send(index, destination)
		AudioServer.add_bus_effect(index, AudioEffectPitchShift.new())
		AudioServer.add_bus_effect(index, AudioEffectEQ6.new())
		_effect_buses.append(bus)
	var pitch := AudioServer.get_bus_effect(index, 0) as AudioEffectPitchShift
	pitch.pitch_scale = profile.get("pitch", 1.0) / reader.pitch_scale
	var eq := AudioServer.get_bus_effect(index, 1) as AudioEffectEQ6
	var bands: PackedFloat32Array = profile.get("eq", PackedFloat32Array())
	for band in eq.get_band_count():
		eq.set_band_gain_db(band, bands[band] if band < bands.size() else 0.0)
	return bus


## A god on the air as `reception` has it: its deeds, its line, a wire
## logger's copy, a song it plays now and then or its tones between. Says
## {song, into (s into it), quiet (silent between songs)}.
func _god_air(delta: float, id: StringName, dial: String, t: float) -> Dictionary:
	var out := {"song": null, "into": NAN, "quiet": false}
	if reception.useful and not reception.cut and reception.clean > 0.0 and heard():
		Deeds.done(world, &"god_heard")
		Deeds.done(world, &"gods", id)
	if reception.cut:
		said = dial + "· · ·"
	elif reception.clean <= 0.0:
		said = dial + "static"
	else:
		said = dial + reception.text
	if SONGS.has(id):
		var own: Array = SONGS[id]
		var lengths: Array[float] = []
		for each: AudioStream in own:
			lengths.append(each.get_length())
		var at := gods_of(world).song(id, t, lengths)
		out.into = at.y
		# Between drones the Eye is silent; the Stoker, its song not called up, talks as ever.
		out.quiet = at.y < 0.0 and id != &"stoker"
		if at.y >= 0.0:
			out.song = own[roundi(at.x)]
			music.pitch_scale = 1.0 + PITCH_SLIDE * reception.warp / maxf(_tuning.storm_warp_khz, 0.01)
	# A faint signal still carries its song, chewed up by the interference.
	_level = audible(reception)
	if out.song == null and not out.quiet and not reception.cut and reception.clean > 0.0:
		_signal.pitch_scale = (0.6 + Gods.ids().find(id) * 0.12) * (1.0 + 0.08 * reception.storm * sin(t * 3.1))
		_every(delta, TONES_EVERY, Sounds.RADIO_TONES)
	return out


## Port Morgan Tower on the air, heard at `level` (0 to 1): its reading of
## the weather at the tower, read afresh every radio_forecast_every s; an
## advisory the moment one's due, its report and the deliveryship's schedule
## every radio_report_every s; its line; and, with nothing coming, its
## clear-skies song. Says the song, or null.
func _tower_air(t: float, level: float, dial: String) -> AudioStream:
	var at := tower_at()
	if t >= read_at + _tuning.radio_forecast_every or t < read_at:
		reading = forecast(world.weather.field, at.x, at.y, t, _tuning.radio_forecast_minutes * 60.0,
			Weather.FORECAST_STEP)
		read_at = t
	if level <= 0.0:
		said = dial + "static"
		return null
	_report(at.x, at.y, t)
	said = dial + "Port Morgan Tower · " + weather_words(t)
	return Sounds.RADIO_CLEAR_SKIES if Transmissions.calm(reading, t) else null


## Where Port Morgan Tower stands, world x, z: on the port's mast.
func tower_at() -> Vector2:
	return ground_of(gods_of(world).home(&"ledger", 0.0))


## A wreck's distress call as it reaches a place at world time t: the call
## nearest the dial (Distress), carried as a low AM ground wave through the
## storm between, as a god's is. {} with none near the dial.
func receive_distress(x: float, z: float, t: float) -> Dictionary:
	var call := _call_near()
	if call.is_empty():
		return {}
	var p := point_at(x, z)
	var metres := Sphere.angle(p, call.p) * world.moon.radius
	var ground := ground_bearing(rad_to_deg(Sphere.bearing(p, call.p)))
	var storm := Interference.along(world.weather.field, x, z, ground, metres, t, _tuning)
	var share := Dial.heard(frequency - call.khz, _tuning)
	var power := Distress.strength(call.khz, metres, _tuning) * boost() * rod(ground, false)
	var jammed := constellation_of(world).jamming(frequency, p, t)
	var through := Interference.let_through(storm, _tuning)
	var clean := smoothstep(_tuning.signal_floor, WHOLE, share * power) * through * (1.0 - jammed)
	var dirt := choked(Garble.dirt(power, through, jammed, odd, 1.0 - Dial.pull(frequency - call.khz,
		_tuning.dial_width_khz), _tuning), _tuning.choke_dirt)
	var words := Distress.words(call.p)
	return {"id": &"distress", "khz": call.khz, "metres": metres, "bearing": ground, "storm": storm, "warp": 0.0,
		"strength": share * power, "clean": clean, "cut": Interference.cut(storm, t, &"distress", _tuning),
		"share": share, "dirt": dirt, "useful": true, "words": words,
		"text": Interference.distort(words, clean, t, &"distress")}


## A near god on FM as its station comes through (`fm`, receive_fm): what it
## says, as clean as the station's quiet.
func receive_fm_god(fm: Dictionary, x: float, z: float, t: float) -> Dictionary:
	var id: StringName = fm.id
	var words := Transmissions.say(id, self, gods_of(world), point_at(x, z), x, z, t)
	var heard := fm.duplicate()
	heard.merge({"clean": fm.quiet, "useful": words.useful, "words": words.text, "warp": 0.0, "storm": 0.0,
		"broadside": 0.0, "text": Interference.distort(words.text, fm.quiet, t, id)})
	# The Walker's log: the contact its entry reads, as clean as its station.
	if words.has("contact"):
		heard.merge({"contact": words.contact, "log_clean": fm.quiet})
	return heard


## A wreck's SOS in morse on its carrier, between its spoken fixes, once a
## call (distress_every s): each tone sounds once as its moment comes.
func _sos(t: float) -> void:
	if reception.is_empty() or reception.cut or reception.clean <= 0.0 or not _lines.is_empty():
		return
	var cycle := floori(t / _tuning.distress_every)
	var into := t - cycle * _tuning.distress_every
	for i in Distress.SOS.size():
		var key := cycle * Distress.SOS.size() + i
		if into >= Distress.SOS[i][0] and key > _sos_key:
			_sos_key = key
			_signal.stream = Sounds.RADIO_PING
			_signal.pitch_scale = 0.8 if Distress.SOS[i][1] else 1.25
			_signal.play()


## A satellite's signal on carrier `khz` as it reaches a place at world time
## t: where it is in the sky, how much storm its signal crosses (the more the
## lower it is), how far its carrier has slid (coming and going, and with the
## storm), how strong and clean it arrives, and whether it's cut.
func receive_from(relay: Satellite, khz: float, id: StringName, x: float, z: float, t: float) -> Dictionary:
	var p := point_at(x, z)
	var sky := relay.seen_from(p, t)
	var ground := ground_bearing(rad_to_deg(sky.bearing))
	var low := maxf(sky.elevation, deg_to_rad(2.0))
	var through := minf(_tuning.dust_height_m / tan(low), _tuning.interference_reach_m)
	var storm := Interference.along(world.weather.field, x, z, ground, through, t, _tuning) if sky.elevation > 0.0 else 0.0
	var slid: float = -_tuning.relay_doppler_khz * clampf(sky.rate / relay.top_rate(), -1.0, 1.0) \
		+ Interference.warp(storm, t, id, _tuning)
	var up := smoothstep(0.0, deg_to_rad(_tuning.relay_rise_degrees), sky.elevation)
	# A tumbling satellite's signal swells and fades as it turns.
	var share := Dial.heard(frequency - khz - slid, _tuning)
	var power := up * constellation_of(world).tumble(id, t) * antenna_gain() * boost()
	var strength := share * power
	var jammed := constellation_of(world).jamming(frequency, p, t, id)
	var clean := smoothstep(_tuning.signal_floor, WHOLE, strength) * Interference.let_through(storm, _tuning) \
		* (1.0 - jammed)
	var dirt := choked(Garble.dirt(power, Interference.let_through(storm, _tuning), jammed, odd,
		1.0 - Dial.pull(frequency - khz - slid, _tuning.dial_width_khz), _tuning), _tuning.choke_dirt)
	return {"id": id, "elevation": sky.elevation, "bearing": ground, "metres": sky.metres, "storm": storm,
		"warp": slid, "strength": strength, "clean": clean, "cut": Interference.cut(storm, t, id, _tuning),
		"share": share, "dirt": dirt}


## Whether a stream is one a god plays now and then (SONGS).
static func _is_song(stream: AudioStream) -> bool:
	for own: Array in SONGS.values():
		if own.has(stream):
			return true
	return false


## A song on the air, from where its station is in it: it plays on whether
## anyone listens. Another changes over through a burst of static.
## A song that keeps its own time says where it is, s into it (`into`).
func _put_on(song: AudioStream, t: float, into := NAN) -> void:
	var started := t - into
	if _on_air == song and (is_nan(into) or is_zero_approx(started - _on_air_started)):
		return
	if _on_air != null:
		_click(Sounds.RADIO_TUNE, -6.0)
	_glitch.reset()
	music.stream = song
	music.play(into if not is_nan(into) else fposmod(t, song.get_length()))
	_on_air = song
	_on_air_started = started


## The song on the air now, if it plays: the music, the hold music or the
## Stoker's; null with none.
func on_air() -> AudioStream:
	return _on_air if playing() else null


func _off_air() -> void:
	for voice: AudioStreamPlayer3D in [music, hiss, crackle, roar, _signal]:
		voice.stop()
	_hush()
	_on_air = null
	_hissing = false


## A station's signal again each `seconds`, at once on tuning in.
func _every(delta: float, seconds: float, stream: AudioStream) -> void:
	_since_signal += delta
	if _since_signal >= seconds:
		_since_signal = 0.0
		_signal.stream = stream
		_signal.play()


## A line as a voice reads it: units in words and the line's dots as pauses,
## every word of it. (It used to lose words to a weak signal, so numbers went
## missing; interference is in the sound now, and a report is read whole.)
static func spoken_words(line: String) -> String:
	var out := PackedStringArray()
	var words := line.replace(" · ", ". ").replace("m/s", "metres a second").split(" ", false)
	for word in words:
		if word == "min" or word == "min." or word == "min,":
			word = word.replace("min", "minutes")
		elif word == "s" or word == "s." or word == "s,":
			word = word.replace("s", "seconds")
		out.append(word)
	return " ".join(out)
## A report as it comes through at `clean`: as many of its phrases lost as
## the signal loses, gone into the static.
static func speech(phrases: PackedStringArray, clean: float, t: float) -> PackedStringArray:
	var out := PackedStringArray()
	var slice := floori(t / Interference.SLICE)
	for i in phrases.size():
		out.append("..." if float(hash([slice, i, "spoken"]) & 0xffff) / 65536.0 < 1.0 - clean else phrases[i])
	return out


## What the weather station says aloud of its last reading, in short radio
## phrases, the storm first: "Storm coming. From the north-east. Four minutes."
## Wind and the long outlook stay in the continuous written report.
func report(t: float, _long := {}) -> PackedStringArray:
	var out := PackedStringArray()
	if reading.is_empty():
		out.append("No reading.")
		return out
	var horizon := _tuning.radio_forecast_minutes * 60.0
	if reading.stormy:
		out.append("Storm here.")
		out.append_array(_ahead(reading, t, horizon))
	elif not Transmissions.calm(reading, t):
		out.append_array(PackedStringArray(["Storm coming.", "From the %s." % say_point(reading.from),
			_sentence(spoken_span(reading.change - t))]))
	else:
		out.append("All clear.")
		out.append_array(_ahead(reading, t, horizon))
	return out


## What comes next where a reading was taken, as a lead and when: clearing or
## the next storm, or none within the horizon, s.
static func _ahead(of: Dictionary, t: float, horizon: float) -> PackedStringArray:
	if of.change == INF:
		return PackedStringArray(["No clearing," if of.stormy else "No storms,", spoken_span(horizon) + "."])
	return PackedStringArray(["Clearing," if of.stormy else "Next storm,", spoken_span(of.change - t) + "."])


## Seconds as the station says them aloud: to the ten under a minute and a
## half, else in minutes.
static func spoken_span(seconds: float) -> String:
	var s := maxi(0, roundi(seconds))
	if s < 90:
		return "%s seconds" % number_words(maxi(10, roundi(s / 10.0) * 10))
	var m := roundi(s / 60.0)
	return "one minute" if m == 1 else "%s minutes" % number_words(m)


## A number in words: exactly up to EXACT, past it to the ten, a hundred at most.
static func number_words(n: int) -> String:
	n = clampi(n, 0, 100)
	if n > EXACT:
		n = roundi(n / 10.0) * 10
	if n == 100:
		return "a hundred"
	if n < 20:
		return ONES[n]
	return TENS[floori(n / 10.0)] + ("" if n % 10 == 0 else "-" + ONES[n % 10])


static func _sentence(words: String) -> String:
	return words[0].to_upper() + words.substr(1) + "."


## A phrase's recording, by its words: "Wind speed forty." is wind_speed_forty.ogg;
## null for one the bank hasn't got.
static func clip(phrase: String) -> AudioStream:
	if not _clips.has(phrase):
		var words := PackedStringArray()
		for found in _letters.search_all(phrase.to_lower()):
			words.append(found.get_string())
		var path := VOICE % "_".join(words)
		_clips[phrase] = load(path) if ResourceLoader.exists(path) else null
	return _clips[phrase]


## A report read out from the top: the station's tones first, then each
## phrase after the last with a breath between, those the storm took left
## as gaps of their own length, the static in them. While a Console speaks
## through it, a report due goes unread.
func _read_out(heard: PackedStringArray, whole: PackedStringArray) -> void:
	spoken = heard
	if _local and not _lines.is_empty():
		return
	_since_signal = INF
	_hush()
	if Settings.radio_voice:
		_queue(heard, whole, Sounds.RADIO_TONES.get_length() / maxf(_signal.pitch_scale, 0.5))


## A Console in its system speaking through it: `phrases` read after the
## Console's tones from its speaker, at its knob, whatever it's tuned to and
## on or off, since they don't come over the air.
func announce(phrases: PackedStringArray) -> void:
	_hush()
	if Settings.radio_voice:
		_local = true
		_queue(phrases, phrases, Sounds.RADIO_TONES.get_length())


func _queue(heard: PackedStringArray, whole: PackedStringArray, lead: float) -> void:
	var profile: Dictionary = {} if _local else _tuning.radio_voice_profiles.get(tuned_to(), {})
	reader.pitch_scale = profile.get("rate", 1.0)
	reader.bus = Sounds.radio_bus() if _local else _speech_bus(profile)
	var at := lead + STOP_GAP
	for i in whole.size():
		for entry: Array in RadioSpeech.plan(whole[i], Radio.clip):
			var own: AudioStream = entry[0]
			_lines.append([own if heard[i] != "..." else null, at])
			_done_at = at + own.get_length() / reader.pitch_scale
			at = _done_at + (STOP_GAP if entry[1] else _tuning.radio_word_gap_seconds)
		if whole[i].ends_with(","):
			at = _done_at + COMMA_GAP



## Its voice read on, each phrase as it comes due, from the radio, a report
## coming and going with its signal; the station's tones keep off till it's
## done. Tuned away, held for clear skies, dark or switched off in Options, it
## stops.
func _read(delta: float, now: int) -> void:
	if _lines.is_empty():
		return
	if not Settings.radio_voice or not powered or wrecked() \
			or not _local and now not in [WEATHER, GOD, BEACON, DISTRESS]:
		_hush()
		return
	_since_signal = 0.0
	_reading_for += delta
	if _local:
		reader.volume_db = knob_db()
	while _line < _lines.size() and _reading_for >= _lines[_line][1]:
		var own: AudioStream = _lines[_line][0]
		if own != null:
			reader.stream = own
			reader.play()
		_line += 1
	if _line > 0 and not reader.playing:
		var current: Array = _lines[_line - 1]
		var own: AudioStream = current[0]
		var into: float = (_reading_for - current[1]) * reader.pitch_scale
		if own != null and into >= 0.0 and into < own.get_length():
			reader.stream = own
			reader.play(into)
	if _reading_for >= _done_at:
		var over_air := not _local
		_lines = []
		_local = false
		# Heard half through the storm, its wire logger plays it back clean.
		if over_air and _has(&"logger") and _reading_dirt >= _tuning.logger_dirty and not spoken.is_empty():
			_play_back()
		_reading_dirt = 0.0


## Its wire logger playing back the report it just recorded, from its own
## speaker, clean of the storm the signal came through.
func _play_back() -> void:
	played_back += 1
	_click(Sounds.RADIO_TUNE, -8.0)
	_line = 0
	_reading_for = 0.0
	_local = true
	_queue(spoken, spoken, Sounds.RADIO_TUNE.get_length())


func _hush() -> void:
	if reader != null:
		reader.stop()
	_lines = []
	_line = 0
	_reading_for = 0.0
	_local = false
	_reading_dirt = 0.0


## The weather station on the air at world place x, z and time t: an advisory
## the moment one's due, breaking off whatever it's saying; else its regular
## report every radio_report_every s, and at once as you tune in. Only while
## its signal reaches you at all; read whole however dirty it comes.
func _report(x: float, z: float, t: float) -> void:
	if Radio.audible(reception) <= 0.0:
		return
	# A storm warned of before it came is the storm you're in once it's here;
	# the one you were in is over once you're out.
	for kind: StringName in _warned.keys():
		var at: float = _warned[kind]
		if at == Advisories.NOW and not reading.get("stormy", false):
			_warned.erase(kind)
		elif at != Advisories.NOW and t >= at - Advisories.SAME and reading.get("stormy", false):
			_warned[kind] = Advisories.NOW
	# Each fresh reading is checked once, as soon as the signal's through:
	# a dropout on the tick it was read only holds it back a moment.
	if read_at != _checked_at:
		_checked_at = read_at
		var advisory := Advisories.check(self, reading, x, z, t)
		if not advisory.is_empty() and not _warned_of(advisory):
			_warned[advisory.kind] = advisory.at
			_say_aloud(advisory.words, true, t)
			return
	if t >= spoken_at + _tuning.radio_report_every or t < spoken_at:
		_say_aloud(report_words(x, z, t) + ". " + survey_words(t), false, t)
		if heard():
			Deeds.done(world, &"flight_plan")


## A god's words or a beacon's bearing, without the dial's visual prefix.
## A changing line has a bounded cadence; an unchanged reading repeats less often.
func _transmit(words: String, t: float) -> void:
	if words.strip_edges() == "" or not _lines.is_empty():
		return
	var every := _tuning.radio_report_every if words == _last_words else Transmissions.IDLE_EVERY
	if t < spoken_at + every and t >= spoken_at:
		return
	_last_words = words
	_say_aloud(words, false, t)


## Beacons use their own dial strength rather than a god's reception record.
func voice_level() -> float:
	if channel not in [WEATHER, GOD, BEACON, DISTRESS]:
		return 0.0
	if channel == BEACON:
		return 0.0 if target.is_empty() else Dial.heard(frequency - Dial.BEACON_KHZ, _tuning)
	# On FM, as loud as its station comes through.
	if band == FM_BAND:
		return reception.get("heard", 0.0)
	return audible(reception)


## Whether an advisory's event has been warned of already.
func _warned_of(advisory: Dictionary) -> bool:
	if not _warned.has(advisory.kind):
		return false
	var at: float = _warned[advisory.kind]
	if at == Advisories.NOW or advisory.at == Advisories.NOW:
		return at == advisory.at
	return absf(at - advisory.at) < Advisories.SAME


## Words read aloud: a report, or an advisory that breaks off whatever's being read.
func _say_aloud(words: String, urgent: bool, t: float) -> void:
	if not urgent and not _lines.is_empty():
		if t >= spoken_at and t < spoken_at + _tuning.radio_report_every:
			return
		_hush()
	spoken = PackedStringArray([spoken_words(words)])
	spoken_urgent = urgent
	spoken_count += 1
	spoken_at = t
	if not _local or _lines.is_empty():
		_hush()
		if Settings.radio_voice:
			_queue(spoken, spoken, 0.0)


## Frontier Ag's deliveryship's flight plan as Port Morgan Control Tower reads
## it out on FM at world time t (gonkhub, 2026-10-21: "give Port Morgan a
## Surveyor schedule announcement every 5mins on an FM channel. Port Morgan
## Control Tower can be an FM broadcast that we use for this and other
## worldbuilding tracks"): its speed over the ground, its altitude (a working
## figure wandering about its true one: flavour for now) and how long until
## it's over Port Morgan, which it passes every lap. Said "elevation": the
## bundled voice has no "altitude" yet.
func survey_words(t: float) -> String:
	var orbit: Satellite = constellation_of(world).orbits[Airdrop.DELIVERYSHIP]
	var speed := orbit.at(t + 0.5).distance_to(orbit.at(t - 0.5)) * orbit.radius
	var altitude := orbit.height(t) * orbit.radius + SURVEY_WANDER.x * sin(t / SURVEY_WANDER_S.x) \
		+ SURVEY_WANDER.y * sin(t / SURVEY_WANDER_S.y)
	var words := "Deliveryship · Speed %d m/s · Elevation %d metres" % [roundi(speed), roundi(altitude / 10.0) * 10]
	var eta := orbit.until_through(t)
	if eta == INF:
		return words
	var when := "%d seconds" % maxi(roundi(eta / 10.0) * 10, 10) if eta < 60.0 else (
		"1 minute" if eta < 90.0 else "%d minutes" % roundi(eta / 60.0))
	return words + " · Port Morgan in " + when


## The weather station's regular report for where the radio stands at world
## time t: the local time, the wind there and the temperature, all read from
## the world, then its outlook.
func report_words(x: float, z: float, t: float) -> String:
	var day := world.weather.day
	var local := day.time_of_day(t, Sphere.longitude(point_at(x, z)))
	var minutes := roundi(local * 24.0 * 60.0) % (24 * 60)
	var wind := world.weather.field.steady_wind_at(x, z, t)
	var blowing := "Calm" if wind.length() < 0.5 else "Wind %d m/s from the %s" % [roundi(wind.length()),
		say_point(bearing(-wind))]
	var heat := roundi(world.weather.field_temperature(Vector3(world.engine_x(x), world.height_at(x, z),
		world.engine_z(z)), t))
	var degrees := "%d degrees" % heat if heat >= 0 else "minus %d degrees" % -heat
	return "Port Morgan Tower · Local time %d:%02d · %s · Temperature %s · %s" % [minutes / 60, minutes % 60,
		blowing, degrees, outlook_words(t)]


## The weather station's outlook from its last reading, for its report: the
## storm it's in or the next, without the wind now, which the report gives.
func outlook_words(t: float) -> String:
	if reading.is_empty():
		return "No reading"
	var from := say_point(reading.from)
	var horizon := roundi(_tuning.radio_forecast_minutes)
	if reading.stormy:
		return "In a storm from the %s, winds to %d m/s, %s" % [from, roundi(reading.wind),
			"clearing in %s" % span(reading.change - t) if reading.change < INF else "no clearing for %d min" % horizon]
	if reading.change == INF:
		return "Clear for %d min and more" % horizon
	return "A storm from the %s in %s, winds to %d m/s, %s" % [from, span(reading.change - t), roundi(reading.wind),
		"for %s" % span(reading.back - reading.change) if reading.back < INF else "lasting past %d min" % horizon]


## The weather station's words for its last reading.
func weather_words(t: float) -> String:
	if reading.is_empty():
		return "no reading"
	var from := say_point(reading.from)
	var wind := roundi(reading.wind)
	var horizon := roundi(_tuning.radio_forecast_minutes)
	if reading.stormy:
		return "in a storm from the %s · winds to %d m/s · %s" % [from, wind,
			"clearing in %s" % span(reading.change - t) if reading.change < INF
			else "no clearing for %d min" % horizon]
	if reading.change == INF:
		return "clear for %d min and more · wind %d m/s from the %s" % [horizon, wind, from]
	return "a storm from the %s in %s · winds to %d m/s · %s" % [from, span(reading.change - t), wind,
		"for %s" % span(reading.back - reading.change) if reading.back < INF
		else "lasting past %d min" % horizon]


## What the weather station reads of a place at world time t, looking
## `horizon` s ahead in `step`s: whether it's in a storm, the world times that
## changes and changes back (INF past the horizon), the strongest steady wind
## of the storm it's in or the next, m/s (or the wind now, with none in
## sight), and the compass bearing storms come from: they ride the wind.
static func forecast(field: WeatherField, x: float, z: float, t: float, horizon: float, step: float) -> Dictionary:
	var stormy := field.raw_storm_at(x, z, t) > 0.0
	var change := t + field.next_change(x, z, t, horizon, step)
	var back := INF
	if change < INF:
		back = change + field.next_change(x, z, change, t + horizon - change, step)
	var start := t if stormy else change
	var end := minf(change if stormy else back, t + horizon)
	var wind := field.steady_wind_at(x, z, t).length() if start == INF else 0.0
	var at := start
	while at < end:
		wind = maxf(wind, field.steady_wind_at(x, z, at).length())
		at += step
	if start < INF:
		wind = maxf(wind, field.steady_wind_at(x, z, end).length())
	return {"stormy": stormy, "change": change, "back": back, "wind": wind,
		"from": bearing(-field.prevailing_at(t))}


## The compass bearing along a direction in world x and z, degrees: north is -z.
static func bearing(along: Vector2) -> float:
	return fposmod(rad_to_deg(atan2(along.x, -along.y)), 360.0)


## A bearing as a station says it: the nearest of sixteen points.
static func compass(degrees: float) -> String:
	return POINTS[roundi(degrees / 22.5) % POINTS.size()]


## A bearing on the ground, from the world's -z, by the moon's north where you
## are, degrees: past a pole the two are opposite. The same turn takes one on
## the sphere back to the ground.
func true_bearing(degrees: float) -> float:
	return fposmod(degrees if world.moon.north().z < 0.0 else degrees + 180.0, 360.0)


func ground_bearing(degrees: float) -> float:
	return true_bearing(degrees)


## A bearing from the world's -z, said by the moon's north where you are, as
## a compass reads it.
func say_point(degrees: float) -> String:
	return compass(true_bearing(degrees))


## The place on the moon under a world place: dead-reckoned from where you
## stand, as the sheet lays history.
func point_at(x: float, z: float) -> Vector3:
	var moon := world.moon
	var facing := -moon.north().z
	var off := Vector2((x - world.player_world_x()) * facing, -(z - world.player_world_z()) * facing) / moon.radius
	return Sphere.from_flat(Sphere.point(moon.latitude, moon.longitude), off)


## A place on the moon as world metres from where you stand: point_at's inverse.
func ground_of(q: Vector3) -> Vector2:
	var moon := world.moon
	var facing := -moon.north().z
	var off := Sphere.flat_from(Sphere.point(moon.latitude, moon.longitude), q) * moon.radius
	return Vector2(world.player_world_x() + off.x * facing, world.player_world_z() - off.y * facing)


## Seconds as a station says them.
static func span(seconds: float) -> String:
	return "%d s" % maxi(0, roundi(seconds)) if seconds < 90.0 else "%d min" % roundi(seconds / 60.0)


## Where the volume knob puts everything it plays, dB: a fixed step a notch,
## as ears hear loudness, from radio_loudness_db at full down through
## radio_volume_range_db to barely there at a tenth, and silence at none.
func knob_db() -> float:
	if volume <= 0.0:
		return -80.0
	var db := _tuning.radio_loudness_db - _tuning.radio_volume_range_db * (1.0 - volume)
	# A crystal set plays into its earpiece, barely heard; a headset jacked in
	# and the set on you brings it nearer.
	if crystal:
		return db - (_tuning.crystal_headset_quiet_db if listened_close() else _tuning.crystal_quiet_db)
	return db


## The knob on what it plays besides the hiss: the music, a station's tones
## and the weather station's voice, which comes and goes with its signal as a song does.
func _loudness() -> void:
	var db := knob_db()
	if music != null:
		music.volume_db = linear_to_db(_level + 0.0001) + db
	if reader != null and not _local:
		reader.volume_db = linear_to_db(voice_level() + 0.0001) + db
	if _signal != null:
		_signal.volume_db = db


## Whether it's on you, in what you carry (Suit): then it plays straight into
## your ears.
func carried() -> bool:
	return has_meta(&"carried")


## Its voices sound from its middle, the point your hands hold ahead of you.
## Carried, they sound from just before your eyes, where that would be held
## as near as you can bring it (Hands.nearest_hold), straight ahead, with no
## panning, so looking round never moves them from side to side:
## as loud as that, and stowing one held close changes nothing you hear. Out
## again, they're back on the set.
func _to_your_ears(on_you: bool) -> void:
	for each: AudioStreamPlayer3D in _voices:
		_place(each, on_you)


func _place(voice: AudioStreamPlayer3D, on_you: bool) -> void:
	var player := get_parent() as Player
	if player == null and on_you and world != null:
		# On its headset, it's in your ears from wherever it stands.
		player = world.player
	# No side to it in your ears, however fast you look round.
	voice.panning_strength = 0.0 if on_you else 1.0
	if on_you and player != null and voice.is_inside_tree():
		var eyes := player.camera.global_transform
		voice.global_position = eyes.origin - eyes.basis.z.normalized() * player.hands.nearest_hold_of(self)
	else:
		voice.position = Hands.middle_of(self)


## A click of its dial, heard at its level within HEARD, from where its voices are.
func _click(stream: AudioStream, db: float) -> void:
	var voice := Sounds.world_voice(stream, db, HEARD)
	voice.autoplay = true
	voice.finished.connect(voice.queue_free)
	add_child.call_deferred(voice)
	_place.call_deferred(voice, carried())


## One of its voices: as loud as its knob at full allows, past the cap other
## things in the world have.
func _voice() -> AudioStreamPlayer3D:
	return add_voice(Sounds.radio_bus())


## A voice of its own through `bus`, which goes on into the radio's (the
## satellites' each have one), placed as its others are.
func add_voice(bus: StringName) -> AudioStreamPlayer3D:
	var out := Sounds.world_voice(null, 0.0, _tuning.radio_heard_m)
	out.max_db = _tuning.radio_loudness_db + 3.0
	# Through a small speaker: its lows cut.
	out.bus = bus
	add_child(out)
	out.position = Hands.middle_of(self)
	_voices.append(out)
	return out
