class_name Radio
extends Device
## A radio you carry, set down or seat on a top mount, and tune: a dial from 0
## to 2000 kHz, rolled with the wheel as you look at it, and use to sweep up
## to the next carrier, and off past the last. Nothing on the dial says what a
## carrier is. Music plays on one, a beacon pings on another, and the seven
## gods each broadcast in their own band from where they stand: the Walker's
## is the weather station. It reads the real systems and never makes anything
## up. A god's signal comes in by how far off it is, its frequency and the
## hour, and the storm between you and it garbles, slides and cuts it. Static
## comes in with a front's outflow, before the wall, and inside a bubble too:
## it's the sand charging up, not the storm's sound. With nothing to report,
## the weather station holds: its clear-skies song plays, and it breaks off
## for a report the moment there's a storm on you or in sight. The Stoker's
## frequency carries its furnace song. Both come through the weather between
## like any signal, fading, sliding and dropping out. Its volume knob, the
## wheel with alt, turns all of it down, to silence if you like, and it plays
## on. It draws a little while it's on, from its battery or the pool it sits
## in, and plays from where it is.

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
## Heard at its level this far off, m: through a light shield's bubble round it.
const HEARD := 3.0
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
## The volume knob turns this far a notch, of full.
const VOLUME_STEP := 0.1
## A signal this clean or better comes through whole.
const WHOLE := 0.5

static var _gods: Gods

## Whether it's switched on, and where its dial stands, kHz.
var on := false:
	set(to):
		on = to
		_recompute()
var frequency := 0.0
## Where its volume knob stands, 0 silent to 1 full: everything it plays.
var volume := 1.0
## What the dial reads now (OFF to STATIC). Set, as old saves do, it moves
## the dial to that channel's carrier.
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
## How much of the storm's static gets in now, 0 to 1.
var noise := 0.0
var music: AudioStreamPlayer3D
var hiss: AudioStreamPlayer3D

var _tuning := Tuning.current()
var _signal: AudioStreamPlayer3D
var _since_signal := INF
## The track it has on air, and whether its static is: a voice only starts
## playing a moment after it's told, so it keeps its own word on what it plays.
var _on_air: AudioStream
var _hissing := false
## How loud what's on air comes through, 0 to 1, before the volume knob.
var _level := 1.0
var _was := OFF


func _init() -> void:
	carryable = true
	add_to_group(GROUP)


func _ready() -> void:
	super()
	for loop: AudioStreamOggVorbis in [Sounds.RADIO_DAY, Sounds.RADIO_NIGHT, Sounds.RADIO_STATIC,
			Sounds.RADIO_CLEAR_SKIES, Sounds.RADIO_STOKER]:
		loop.loop = true
	music = _voice()
	hiss = _voice()
	hiss.stream = Sounds.RADIO_STATIC
	_signal = _voice()


func _exit_tree() -> void:
	# Looping streams still playing at quit hold their resources past exit;
	# seated or taken off, it comes back on air next tick.
	_off_air()


## The gods of a world's history, made once.
static func gods_of(of: World) -> Gods:
	if _gods == null or _gods.history != of.shape.history:
		_gods = Gods.new(of.shape.history, of.run_seed, Tuning.current())
	return _gods


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
		Sounds.play_at(self, Sounds.RADIO_TUNE, 0.0, HEARD)
	return true


## Use in your hands tunes it just the same.
func use(by: Player, _at: Vector3) -> bool:
	return interact(by)


## The wheel: moves the dial `notches`, a notch or a fine step each. A dark
## radio comes on where its dial stands.
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
	now["tuned"] = ("%d kHz · volume %d%%" % [roundi(frequency), roundi(volume * 100.0)]) if on else "off"
	return now


func _recompute() -> void:
	super()
	# Its dial lights only while it's on.
	if frame_view != null:
		frame_view.set_instance_shader_parameter(&"lit", 1.0 if on and powered else 0.0)


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


## An old save's channel, or a scenario's, as a place on the dial.
func _tune_to_channel(to: int) -> void:
	on = to != OFF
	match to:
		MUSIC:
			frequency = Dial.MUSIC_KHZ
		BEACON:
			frequency = Dial.BEACON_KHZ
		WEATHER:
			var b := Gods.band(&"walker")
			frequency = gods_of(world).carrier(&"walker", world.time) if world != null else (b.x + b.y) * 0.5


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
		said = ""
		reception = {}
		if _on_air != null or _hissing:
			_off_air()
		return
	var x := world.world_x(global_position.x)
	var z := world.world_z(global_position.z)
	var t := world.time
	var field := world.weather.field
	noise = field.outflow_at(x, z, t)
	var now := channel
	if now != _was:
		_retuned(_was)
		_was = now
	var dial := "%d kHz · " % roundi(frequency)
	var under := NOTHING
	var song: AudioStream = null
	_level = 1.0
	if now == MUSIC:
		said = ""
		under = lerpf(NOTHING, 0.0, Dial.pull(frequency - Dial.MUSIC_KHZ, _tuning.dial_width_khz))
		song = Sounds.RADIO_DAY if world.weather.day.is_day(t, world.moon.longitude) else Sounds.RADIO_NIGHT
	reception = {}
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
			elif id == &"stoker":
				song = Sounds.RADIO_STOKER
				music.pitch_scale = 1.0 + 0.04 * reception.warp / maxf(_tuning.storm_warp_khz, 0.01)
			# A faint signal still carries its song: down by the root of how clean it is.
			_level = 0.0 if reception.cut else sqrt(reception.clean)
			if song == null and not reception.cut and reception.clean > 0.0:
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
		_put_on(song, t)
	elif _on_air != null:
		# A report breaks into the hold music through a burst of static.
		if _on_air == Sounds.RADIO_CLEAR_SKIES:
			Sounds.play_at(self, Sounds.RADIO_TUNE, -6.0, HEARD)
		music.stop()
		_on_air = null
	if song != Sounds.RADIO_STOKER:
		music.pitch_scale = 1.0
	hiss.volume_db = linear_to_db(maxf(noise, under) * volume + 0.0001)
	_loudness()
	if not _hissing:
		hiss.play(fposmod(t, hiss.stream.get_length()))
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
	var clean := smoothstep(_tuning.signal_floor, WHOLE, strength) * (1.0 - 0.8 * storm)
	var words := Transmissions.say(id, self, gods, p, x, z, t)
	return {"id": id, "khz": khz, "metres": metres, "bearing": ground,
		"way": Dial.way(world.shape.history, p, q, ground, say_point, _tuning), "storm": storm,
		"warp": slid, "strength": strength, "clean": clean, "cut": Interference.cut(storm, t, id, _tuning),
		"useful": words.useful, "calm": words.get("calm", false), "words": words.text, "text": Interference.distort(words.text, clean, t, id)}


## A song on the air, from where its station is in it: it plays on whether
## anyone listens. Another changes over through a burst of static.
func _put_on(song: AudioStream, t: float) -> void:
	if _on_air == song:
		return
	if _on_air != null:
		Sounds.play_at(self, Sounds.RADIO_TUNE, -6.0, HEARD)
	music.stream = song
	music.play(fposmod(t, song.get_length()))
	_on_air = song


## The song on the air now, if it plays: the music, the hold music or the
## Stoker's; null with none.
func on_air() -> AudioStream:
	return _on_air if playing() else null


func _off_air() -> void:
	for voice: AudioStreamPlayer3D in [music, hiss, _signal]:
		voice.stop()
	_on_air = null
	_hissing = false


## A station's signal again each `seconds`, at once on tuning in.
func _every(delta: float, seconds: float, stream: AudioStream) -> void:
	_since_signal += delta
	if _since_signal >= seconds:
		_since_signal = 0.0
		_signal.stream = stream
		_signal.play()


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


## The knob on what it plays besides the hiss: the music and a station's tones.
func _loudness() -> void:
	var db := linear_to_db(volume + 0.0001)
	if music != null:
		music.volume_db = linear_to_db(volume * _level + 0.0001)
	if _signal != null:
		_signal.volume_db = db


func _voice() -> AudioStreamPlayer3D:
	var voice := Sounds.world_voice(null, 0.0, HEARD)
	add_child(voice)
	return voice
