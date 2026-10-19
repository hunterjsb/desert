class_name Radio
extends Device
## A radio you carry, set down or seat on a top mount, and tune: a dial from 0
## to 2000 kHz, rolled a notch at a time as you look at it, and use to sweep up
## to the next carrier, and off past the last; its needle crosses the band on
## its face and its knobs turn as you do. Nothing on the dial says what a
## carrier is. Music plays on one, a beacon pings on another, and the seven
## gods each broadcast in their own band from where they stand: the Walker's
## is the weather station. It reads the real systems and never makes anything
## up. A god's signal comes in by how far off it is, its frequency and the
## hour, and the storm between you and it garbles, slides and cuts it. Static
## comes in with a front's outflow, before the wall, and inside a bubble too:
## it's the sand charging up, not the storm's sound; an anomaly near brings a
## crackle of its own, which no forecast speaks of. With nothing to report,
## the weather station holds: its clear-skies song plays, and it breaks off
## for a report the moment there's a storm on you or in sight, read aloud in
## short phrases from a bank of recorded words. The Stoker's
## frequency carries its furnace song. Both come through the weather between
## like any signal, fading, sliding and dropping out. Its volume knob turns
## all of it down, to silence if you like, and it plays on. It draws a little
## while it's on, from its battery or the pool it sits in, and plays from
## where it is.

const GROUP := &"radios"
## What it's tuned to, as the dial reads: off, a carrier, or nothing but static.
const OFF := 0
const MUSIC := 1
const WEATHER := 2
const BEACON := 3
const GOD := 4
const STATIC := 5
const CHANNELS: Array[String] = ["off", "music", "weather", "beacon", "god", "static"]
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
## the Stoker's furnace song and the Eye's drone.
const SONGS := {&"stoker": Sounds.RADIO_STOKER, &"eye": Sounds.RADIO_EYE}
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
## Its dial on its face (+Z), m: the band window's middle and size, the band
## running from 0 kHz to 2000 across these x, and where the tuning and
## volume knobs turn.
const BAND_Y := 0.058
const BAND_WIDTH := 0.236
const BAND_HEIGHT := 0.052
const BAND := Vector2(-0.105, 0.105)
const KNOB_AT := Vector3(0.06, -0.042, 0.084)
const VOLUME_AT := Vector3(0.11, -0.06, 0.084)
const VOLUME_KNOB := 0.55
## The tuning knob goes once round every this many kHz, so a notch turns it
## a twentieth; the volume knob sweeps three quarters round, silent to full.
const KHZ_A_TURN := 100.0
const VOLUME_SWEEP := PI * 1.5
## The needle and knobs catch up with where the dial stands in about this long, s.
const TURN_SECONDS := 0.05
## Close up, the view looks at this point on its face.
const FACE := Vector3(0.0, 0.01, 0.08)

static var _gods: Gods
static var _relay: Satellite
static var _relay_for := []
static var _clips := {}
static var _letters := RegEx.create_from_string("[a-z]+")

## Whether it's switched on, and where its dial stands, kHz.
var on := false:
	set(to):
		on = to
		_recompute()
var frequency := 0.0
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
## The report it reads aloud, as its phrases, how many it has read, and when
## it last read one, world time. A storm loses phrases of it as it does the
## line's characters, "..." in their place.
var spoken := PackedStringArray()
var spoken_count := 0
var spoken_at := -INF
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
var shown_khz := 0.0
var shown_volume := 1.0
var crackle: AudioStreamPlayer3D
## The weather station's voice, reading a report a phrase at a time.
var reader: AudioStreamPlayer3D

var _tuning := Tuning.current()
var _signal: AudioStreamPlayer3D
var _since_signal := INF
## The track it has on air, and whether its static is: a voice only starts
## playing a moment after it's told, so it keeps its own word on what it plays.
var _on_air: AudioStream
var _hissing := false
## How loud what's on air comes through, 0 to 1, before the volume knob.
var _level := 1.0
## What its voice is reading: each phrase's recording (null where the storm
## took it) and when it starts, s in; the next one due, how far in it is, when
## it ends, and whether it's a Console speaking through it rather than the air.
var _lines := []
var _line := 0
var _reading_for := 0.0
var _done_at := 0.0
var _local := false
## What the dial read last tick; UNHEARD before its first, so a save's beacon keeps its target.
var _was := UNHEARD
## An old save's channel, waiting for its world to place it on the dial.
var _wanted := UNHEARD


func _init() -> void:
	carryable = true
	add_to_group(GROUP)
	needle = _on_face(Dress.dial_needle())
	knob = _on_face(Dress.knob())
	volume_knob = _on_face(Dress.knob())
	_show_dial()


func _ready() -> void:
	super()
	for loop: AudioStreamOggVorbis in [Sounds.RADIO_DAY, Sounds.RADIO_NIGHT, Sounds.RADIO_STATIC,
			Sounds.RADIO_CLEAR_SKIES]:
		loop.loop = true
	# The Stoker's song and the Eye's drone play through once, then a silence:
	# the station keeps its time.
	for once: AudioStreamOggVorbis in [Sounds.RADIO_STOKER, Sounds.RADIO_EYE]:
		once.loop = false
	music = _voice()
	hiss = _voice()
	hiss.stream = Sounds.RADIO_STATIC
	crackle = _voice()
	crackle.stream = Sounds.RADIO_STATIC
	_signal = _voice()
	reader = _voice()
	if _wanted != UNHEARD:
		_tune_to_channel(_wanted)
	shown_khz = frequency
	shown_volume = volume
	_show_dial()


func _exit_tree() -> void:
	# Looping streams still playing at quit hold their resources past exit;
	# seated or taken off, it comes back on air next tick.
	_off_air()


## The gods of a world's history, made once.
static func gods_of(of: World) -> Gods:
	if _gods == null or _gods.history != of.shape.history:
		_gods = Gods.new(of.shape.history, of.run_seed, Tuning.current())
	return _gods


## The relay satellite over a world, made once a run, passing over where it began.
static func relay_of(of: World) -> Satellite:
	var run := [of.run_seed, of.start]
	if _relay == null or _relay_for != run:
		_relay = Satellite.new(of.run_seed, Tuning.current(), of.start)
		_relay_for = run
	return _relay


## Use: sweeps the dial up to the next carrier, with a burst of static; past
## the last it goes off, and from off it comes on at the first.
func interact(_by: Player) -> bool:
	if wrecked():
		return false
	# Found in the sand, it's yours as you use it, so this use can start it.
	world.salvage.claim(self)
	var before := channel
	if not on:
		frequency = Dial.LOWEST
		on = true
	var next := _carrier_above(frequency + _tuning.dial_width_khz * ON_IT)
	if is_nan(next):
		frequency = Dial.LOWEST
		on = false
	else:
		frequency = next
	_retuned(before)
	if powered:
		Sounds.play_at(self, Sounds.RADIO_TUNE, minf(_tuning.radio_loudness_db, 3.0), HEARD)
	return true


## Use in your hands tunes it just the same.
func use(by: Player, _at: Vector3) -> bool:
	return interact(by)


## Moves the dial `notches`, a notch or a fine step each. A dark radio comes
## on where its dial stands.
func tune(notches: int, fine := false) -> bool:
	if wrecked() or world == null:
		return false
	world.salvage.claim(self)
	var before := channel
	on = true
	var step := _tuning.dial_fine_khz if fine else _tuning.dial_notch_khz
	frequency = clampf(snappedf(frequency + notches * step, step), Dial.LOWEST, Dial.HIGHEST)
	_retuned(before)
	return true


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
		Sounds.play_at(self, Sounds.RADIO_TUNE, minf(_tuning.radio_loudness_db, 3.0), HEARD)
	return true


## The volume knob: turned `notches` a notch each, between silent and full.
func turn_volume(notches: int) -> bool:
	if wrecked() or world == null:
		return false
	world.salvage.claim(self)
	volume = clampf(snappedf(volume + notches * VOLUME_STEP, VOLUME_STEP), 0.0, 1.0)
	_loudness()
	return true


## Whether it plays: on, powered, whole and in the world.
func playing() -> bool:
	return on and powered and not wrecked() and world != null and is_inside_tree()


## The carrier the dial is on now, by its id (&"music", &"beacon" or a god's),
## or &"" between carriers. Storms slide a god off it; the dial goes by where
## its carrier belongs.
func tuned_to() -> StringName:
	if world == null:
		return &""
	var best := &""
	var nearest := _tuning.dial_width_khz * ON_IT
	for each in Dial.carriers(gods_of(world), world.time):
		var off := absf(frequency - each[0])
		if off <= nearest:
			nearest = off
			best = each[1]
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
	return super(t) + (_tuning.radio_w if on and not wrecked() else 0.0)


func stats() -> Dictionary:
	var now := super()
	now["tuned"] = "%d kHz" % roundi(frequency) if on else "off"
	return now


func _recompute() -> void:
	super()
	# Its dial lights only while it's on.
	for view in painted():
		if view != null:
			view.set_instance_shader_parameter(&"lit", 1.0 if on and powered else 0.0)


## Its needle and knobs wear its paint too.
func painted() -> Array[MeshInstance3D]:
	var out := super()
	out.append_array([needle, knob, volume_knob])
	return out


## The needle and knobs turn after the dial and the volume, so you see them go.
func _process(delta: float) -> void:
	if shown_khz == frequency and shown_volume == volume:
		return
	var k := 1.0 - exp(-delta / TURN_SECONDS)
	shown_khz = frequency if absf(frequency - shown_khz) < 0.01 else lerpf(shown_khz, frequency, k)
	shown_volume = volume if absf(volume - shown_volume) < 0.001 else lerpf(shown_volume, volume, k)
	_show_dial()


## How far the tuning knob stands turned at a frequency, rad clockwise.
static func knob_turn(khz: float) -> float:
	return TAU * khz / KHZ_A_TURN


## Its needle on the band and its knobs turned to what they show.
func _show_dial() -> void:
	needle.position = Vector3(lerpf(BAND.x, BAND.y, shown_khz / Dial.HIGHEST), BAND_Y, FACE.z + 0.0035)
	knob.transform = Transform3D(Basis(Vector3.BACK, -knob_turn(shown_khz)), KNOB_AT)
	volume_knob.transform = Transform3D(Basis(Vector3.BACK, VOLUME_SWEEP * (0.5 - shown_volume))
		.scaled(Vector3.ONE * VOLUME_KNOB), VOLUME_AT)


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


## What the dial reads, from where it stands.
func _reads() -> int:
	if not on:
		return OFF
	match tuned_to():
		&"music":
			return MUSIC
		&"walker":
			return WEATHER
		&"beacon":
			return BEACON
		&"":
			return STATIC
	return GOD


## An old save's channel, or a scenario's, as a place on the dial: the
## weather station's is the Walker's carrier on the day it's placed.
func _tune_to_channel(to: int) -> void:
	on = to != OFF
	_wanted = to if world == null else UNHEARD
	match to:
		MUSIC:
			frequency = Dial.MUSIC_KHZ
		BEACON:
			frequency = Dial.BEACON_KHZ
		WEATHER:
			if world != null:
				frequency = gods_of(world).carrier(&"walker", world.time)


## The first carrier above a frequency, or NAN past the last.
func _carrier_above(khz: float) -> float:
	for each in Dial.carriers(gods_of(world), world.time):
		if each[0] > khz:
			return each[0]
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


## What it plays this tick, from the systems it reads.
func _listen(delta: float) -> void:
	if not playing():
		noise = 0.0
		odd = 0.0
		said = ""
		spoken = PackedStringArray()
		reception = {}
		if _on_air != null or _hissing:
			_off_air()
		_read(delta, OFF)
		return
	var x := world.world_x(global_position.x)
	var z := world.world_z(global_position.z)
	var t := world.time
	var field := world.weather.field
	noise = field.outflow_at(x, z, t)
	odd = field.anomaly_at(x, z, t)
	var now := channel
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
	if now == MUSIC:
		# The music comes down from the relay, while it's over the horizon.
		reception = receive_relay(x, z, t)
		said = "" if not reception.cut and reception.clean > 0.0 else dial + ("· · ·" if reception.cut else "static")
		under = NOTHING if reception.cut else lerpf(NOTHING, 0.0, reception.clean)
		song = Sounds.RADIO_DAY if world.weather.day.is_day(t, world.moon.longitude) else Sounds.RADIO_NIGHT
		_level = 0.0 if reception.cut else sqrt(reception.clean)
		# Heard sliding: the relay's own coming and going, and a storm's warp.
		music.pitch_scale = 1.0 + PITCH_SLIDE * reception.warp / maxf(_tuning.storm_warp_khz, 0.01)
	match now:
		WEATHER, GOD:
			var id := tuned_to()
			if now == WEATHER and (t >= read_at + _tuning.radio_forecast_every or t < read_at):
				reading = forecast(field, x, z, t, _tuning.radio_forecast_minutes * 60.0, Weather.FORECAST_STEP)
				read_at = t
			reception = receive(id, x, z, t)
			if reception.cut:
				said = dial + "· · ·"
			elif reception.clean <= 0.0:
				said = dial + "static"
			else:
				said = dial + reception.text
			under = NOTHING if reception.cut else lerpf(NOTHING, CARRIER, reception.clean)
			# A song on the air comes and goes with the signal, never restarting.
			if now == WEATHER and reception.calm:
				song = Sounds.RADIO_CLEAR_SKIES
			elif now == WEATHER and not reception.cut and reception.clean > 0.0:
				# Something to report: read aloud now as it breaks in, and again every so often.
				if _on_air == Sounds.RADIO_CLEAR_SKIES or t >= spoken_at + _tuning.radio_speak_every or t < spoken_at:
					_read_out(speech(reception.spoken, reception.clean, t), reception.spoken)
					spoken_count += 1
					spoken_at = t
			elif SONGS.has(id):
				var own: AudioStream = SONGS[id]
				into = gods_of(world).song(id, t, own.get_length())
				# Between drones the Eye is silent; the Stoker, its song not called up, talks as ever.
				quiet = into < 0.0 and id != &"stoker"
				if into >= 0.0:
					song = own
					music.pitch_scale = 1.0 + PITCH_SLIDE * reception.warp / maxf(_tuning.storm_warp_khz, 0.01)
			# A faint signal still carries its song: down by the root of how clean it is.
			_level = 0.0 if reception.cut else sqrt(reception.clean)
			if song == null and not quiet and not reception.cut and reception.clean > 0.0:
				_signal.pitch_scale = (0.6 + Gods.ids().find(id) * 0.12) \
					* (1.0 + 0.08 * reception.storm * sin(t * 3.1))
				_every(delta, TONES_EVERY, Sounds.RADIO_TONES)
		BEACON:
			var heard := Dial.pull(frequency - Dial.BEACON_KHZ, _tuning.dial_width_khz)
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
	if song != null:
		_put_on(song, t, into)
	elif _on_air != null:
		# A report breaks into the hold music through a burst of static.
		if _on_air == Sounds.RADIO_CLEAR_SKIES:
			Sounds.play_at(self, Sounds.RADIO_TUNE, -6.0, HEARD)
		music.stop()
		_on_air = null
	if not song in SONGS.values() and now != MUSIC:
		music.pitch_scale = 1.0
	# The static sinks under whatever you can hear, and is all there is when there's nothing.
	var through := 0.0
	if now == MUSIC:
		through = _level
	elif now == WEATHER or now == GOD:
		through = 0.0 if quiet or reception.cut else reception.clean
	elif now == BEACON and not target.is_empty():
		through = Dial.pull(frequency - Dial.BEACON_KHZ, _tuning.dial_width_khz)
	var ducked := lerpf(1.0, db_to_linear(-_tuning.radio_static_duck_db), clampf(through, 0.0, 1.0))
	hiss.volume_db = linear_to_db(maxf(noise, under) * ducked + 0.0001) + knob_db()
	# An anomaly's static sputters: the hiss thinned and pitched up, cut in and
	# out in short bursts, the deeper the more of it.
	var burst := Interference.crackle(t)
	crackle.pitch_scale = lerpf(CRACKLE_PITCH.x, CRACKLE_PITCH.y, burst.y)
	crackle.volume_db = linear_to_db(odd * burst.x * CRACKLE_LEVEL * ducked + 0.0001) + knob_db()
	_loudness()
	_read(delta, now)
	if not _hissing:
		hiss.play(fposmod(t, hiss.stream.get_length()))
		crackle.play(fposmod(t * 0.7, crackle.stream.get_length()))
		_hissing = true


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
	var strength := Dial.pull(frequency - khz - slid, _tuning.dial_width_khz) \
		* Dial.strength(id, khz, metres, night, _tuning)
	var clean := smoothstep(_tuning.signal_floor, WHOLE, strength) * Interference.let_through(storm, _tuning)
	var words := Transmissions.say(id, self, gods, p, x, z, t)
	return {"id": id, "khz": khz, "metres": metres, "bearing": ground,
		"way": Dial.way(world.shape.history, p, q, ground, say_point, _tuning), "storm": storm,
		"warp": slid, "strength": strength, "clean": clean, "cut": Interference.cut(storm, t, id, _tuning),
		"useful": words.useful, "calm": words.get("calm", false), "words": words.text,
		"spoken": words.get("spoken", PackedStringArray()), "text": Interference.distort(words.text, clean, t, id)}


## The relay's signal as it reaches a place at world time t: where the relay
## is in the sky, how much storm its signal crosses (the more the lower it is),
## how far its carrier has slid (coming and going, and with the storm), how
## strong and clean it arrives, and whether it's cut.
func receive_relay(x: float, z: float, t: float) -> Dictionary:
	var relay := relay_of(world)
	var p := point_at(x, z)
	var sky := relay.seen_from(p, t)
	var ground := ground_bearing(rad_to_deg(sky.bearing))
	var low := maxf(sky.elevation, deg_to_rad(2.0))
	var through := minf(_tuning.dust_height_m / tan(low), _tuning.interference_reach_m)
	var storm := Interference.along(world.weather.field, x, z, ground, through, t, _tuning) if sky.elevation > 0.0 else 0.0
	var slid: float = -_tuning.relay_doppler_khz * clampf(sky.rate / relay.top_rate(), -1.0, 1.0) \
		+ Interference.warp(storm, t, &"relay", _tuning)
	var up := smoothstep(0.0, deg_to_rad(_tuning.relay_rise_degrees), sky.elevation)
	var strength := Dial.pull(frequency - Dial.MUSIC_KHZ - slid, _tuning.dial_width_khz) * up
	var clean := smoothstep(_tuning.signal_floor, WHOLE, strength) * Interference.let_through(storm, _tuning)
	return {"id": &"music", "elevation": sky.elevation, "bearing": ground, "metres": sky.metres, "storm": storm,
		"warp": slid, "strength": strength, "clean": clean, "cut": Interference.cut(storm, t, &"relay", _tuning)}


## A song on the air, from where its station is in it: it plays on whether
## anyone listens. Another changes over through a burst of static.
## A song that keeps its own time says where it is, s into it (`into`).
func _put_on(song: AudioStream, t: float, into := NAN) -> void:
	if _on_air == song:
		# Called up again from its start while it plays: back to its start.
		if not is_nan(into) and absf(music.get_playback_position() - into) > 1.5:
			music.play(into)
		return
	if _on_air != null:
		Sounds.play_at(self, Sounds.RADIO_TUNE, -6.0, HEARD)
	music.stream = song
	music.play(into if not is_nan(into) else fposmod(t, song.get_length()))
	_on_air = song


## The song on the air now, if it plays: the music, the hold music or the
## Stoker's; null with none.
func on_air() -> AudioStream:
	return _on_air if playing() else null


func _off_air() -> void:
	for voice: AudioStreamPlayer3D in [music, hiss, crackle, _signal]:
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


## A report as it comes through at `clean`: as many of its phrases lost as
## the signal loses, gone into the static.
static func speech(phrases: PackedStringArray, clean: float, t: float) -> PackedStringArray:
	var out := PackedStringArray()
	var slice := floori(t / Interference.SLICE)
	for i in phrases.size():
		out.append("..." if float(hash([slice, i, "spoken"]) & 0xffff) / 65536.0 < 1.0 - clean else phrases[i])
	return out


## What the weather station says aloud of its last reading, in short radio
## phrases, the storm first: "Storm coming. From the north-east. Four minutes.
## Wind speed forty." With `long`, the long report's reading, its outlook after.
func report(t: float, long := {}) -> PackedStringArray:
	var out := PackedStringArray()
	if reading.is_empty():
		out.append("No reading.")
		return out
	var horizon := _tuning.radio_forecast_minutes * 60.0
	var wind := "Wind speed %s." % number_words(roundi(reading.wind))
	if reading.stormy:
		out.append_array(PackedStringArray(["Storm here.", wind]))
		out.append_array(_ahead(reading, t, horizon))
	elif not Transmissions.calm(reading, t):
		out.append_array(PackedStringArray(["Storm coming.", "From the %s." % say_point(reading.from),
			_sentence(spoken_span(reading.change - t)), wind]))
	else:
		out.append("All clear.")
		out.append_array(_ahead(reading, t, horizon))
	if not long.is_empty():
		out.append("Long range.")
		out.append_array(_ahead(long, t, horizon * 2.0))
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
	var at := lead + STOP_GAP
	for i in whole.size():
		var own := clip(whole[i])
		_lines.append([own if heard[i] != "..." else null, at])
		_done_at = at + (own.get_length() if own != null else 1.0)
		at = _done_at + (COMMA_GAP if whole[i].ends_with(",") else STOP_GAP)


## Its voice read on, each phrase as it comes due, from the radio, a report
## coming and going with its signal; the station's tones keep off till it's
## done. Tuned away, held for clear skies, dark or switched off in Options, it
## stops.
func _read(delta: float, now: int) -> void:
	if _lines.is_empty():
		return
	if not Settings.radio_voice or not powered or wrecked() \
			or not _local and (now != WEATHER or reception.get("calm", false)):
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
	if _reading_for >= _done_at:
		_lines = []
		_local = false


func _hush() -> void:
	if reader != null:
		reader.stop()
	_lines = []
	_line = 0
	_reading_for = 0.0
	_local = false


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
	return _tuning.radio_loudness_db - _tuning.radio_volume_range_db * (1.0 - volume)


## The knob on what it plays besides the hiss: the music, a station's tones
## and the weather station's voice, which comes and goes with its signal as a song does.
func _loudness() -> void:
	var db := knob_db()
	if music != null:
		music.volume_db = linear_to_db(_level + 0.0001) + db
	if reader != null and not _local:
		reader.volume_db = linear_to_db(_level + 0.0001) + db
	if _signal != null:
		_signal.volume_db = db


## One of its voices: as loud as its knob at full allows, past the cap other
## things in the world have.
func _voice() -> AudioStreamPlayer3D:
	var voice := Sounds.world_voice(null, 0.0, _tuning.radio_heard_m)
	voice.max_db = _tuning.radio_loudness_db + 3.0
	# Through a small speaker: its lows cut.
	voice.bus = Sounds.radio_bus()
	add_child(voice)
	return voice
