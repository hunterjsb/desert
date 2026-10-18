class_name Radio
extends Device
## A radio you carry, set down or seat on a top mount, and tune with use: off,
## music, the weather station, a beacon, and off again. It reads the real
## systems and never makes anything up. The music is the day's track while
## the sun is up and the night's after; the weather station reads the storm
## field ahead where the radio is; a beacon points at a find the world will
## lay out. Static comes in with a front's outflow, before the wall, and
## inside a bubble too: it's the sand charging up, not the storm's sound. It
## draws a little while it's on, from its battery or the pool it sits in, and
## plays from where it is.

const GROUP := &"radios"
## The dial, in the order use turns it.
const OFF := 0
const MUSIC := 1
const WEATHER := 2
const BEACON := 3
const CHANNELS: Array[String] = ["off", "music", "weather", "beacon"]
const POINTS: Array[String] = ["north", "north-north-east", "north-east", "east-north-east", "east",
	"east-south-east", "south-east", "south-south-east", "south", "south-south-west", "south-west",
	"west-south-west", "west", "west-north-west", "north-west", "north-north-west"]
## Heard at its level this far off, m: through a light shield's bubble round it.
const HEARD := 3.0
## Of full static, the hiss under a station's signal, and on a beacon's
## channel with nothing to hear.
const CARRIER := 0.2
const NOTHING := 0.6
## The weather station sounds its tones before each reading this often, s.
const TONES_EVERY := 8.0
## A beacon pings this often from as far as FAINT and this often close by, s.
## Past FAINT it's faint, past CLEAR clear, nearer strong, and within HERE, m,
## you're on it.
const PING_FAR := 2.5
const PING_NEAR := 0.5
const FAINT := 1000.0
const CLEAR := 250.0
const HERE := 15.0

var channel := OFF:
	set(to):
		channel = to
		_recompute()
## What the beacon points at, decided when it was tuned to it: {x, z, coord,
## index} in world metres, or {} for no signal.
var target := {}
## The weather station's last reading (forecast()), and when it was read.
var reading := {}
var read_at := -INF
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


func _init() -> void:
	carryable = true
	add_to_group(GROUP)


func _ready() -> void:
	super()
	for loop: AudioStreamOggVorbis in [Sounds.RADIO_DAY, Sounds.RADIO_NIGHT, Sounds.RADIO_STATIC]:
		loop.loop = true
	music = _voice()
	hiss = _voice()
	hiss.stream = Sounds.RADIO_STATIC
	_signal = _voice()


func _exit_tree() -> void:
	# Looping streams still playing at quit hold their resources past exit;
	# seated or taken off, it comes back on air next tick.
	_off_air()


## Use: turns the dial on a channel.
func interact(_by: Player) -> bool:
	if wrecked():
		return false
	# Found in the sand, it's yours as you use it, so this use can start it.
	world.salvage.claim(self)
	tune((channel + 1) % CHANNELS.size())
	return true


## Turns the dial to a channel, as use does and a Console's screen, with a
## burst of static between stations. Coming to the beacon, it decides then
## which one it hears.
func tune(to: int) -> void:
	if wrecked() or to == channel:
		return
	if to == BEACON:
		target = Finds.beacon(world.run_seed, world.shape.sites, world.world_x(global_position.x),
			world.world_z(global_position.z), _tuning, world.salvage.taken)
	read_at = -INF
	_since_signal = INF
	channel = to
	if powered:
		Sounds.play_at(self, Sounds.RADIO_TUNE, 0.0, HEARD)


## Use in your hands tunes it just the same.
func use(by: Player, _at: Vector3) -> bool:
	return interact(by)


## Whether it plays: on, powered, whole and in the world.
func playing() -> bool:
	return channel != OFF and powered and not wrecked() and world != null and is_inside_tree()


## The bearing from it to what its beacon points at, degrees; NAN with no signal.
func beacon_bearing() -> float:
	if target.is_empty():
		return NAN
	return bearing(Vector2(target.x - world.world_x(global_position.x), target.z - world.world_z(global_position.z)))


## The track it plays now, or null.
func track() -> AudioStream:
	return _on_air if playing() and channel == MUSIC else null


func demand_w(t := NAN) -> float:
	return super(t) + (_tuning.radio_w if channel != OFF and not wrecked() else 0.0)


func stats() -> Dictionary:
	var now := super()
	now["tuned"] = CHANNELS[channel]
	return now


func _recompute() -> void:
	super()
	# Its dial lights only while it's on.
	if frame_view != null:
		frame_view.set_instance_shader_parameter(&"lit", 1.0 if channel != OFF and powered else 0.0)


func _physics_process(delta: float) -> void:
	super(delta)
	_listen(delta)


## What it plays this tick, from the systems it reads.
func _listen(delta: float) -> void:
	if not playing():
		noise = 0.0
		said = ""
		if _on_air != null or _hissing:
			_off_air()
		return
	var x := world.world_x(global_position.x)
	var z := world.world_z(global_position.z)
	var t := world.time
	var field := world.weather.field
	noise = field.outflow_at(x, z, t)
	var under := 0.0
	if channel == MUSIC:
		said = ""
		_play_music(t)
	elif _on_air != null:
		music.stop()
		_on_air = null
	if channel == WEATHER:
		if t >= read_at + _tuning.radio_forecast_every or t < read_at:
			reading = forecast(field, x, z, t, _tuning.radio_forecast_minutes * 60.0, Weather.FORECAST_STEP)
			read_at = t
		said = "Weather · " + _weather_words(t)
		under = CARRIER
		_every(delta, TONES_EVERY, Sounds.RADIO_TONES)
	elif channel == BEACON:
		if target.is_empty():
			said = "Beacon · no signal"
			under = NOTHING
		else:
			var far := Vector2(target.x - x, target.z - z).length()
			said = "Beacon · a signal, right here" if far <= HERE \
				else "Beacon · a signal, %s · %s" % [_point(beacon_bearing()), "faint" if far > FAINT
					else ("clear" if far > CLEAR else "strong")]
			under = CARRIER
			_every(delta, lerpf(PING_NEAR, PING_FAR, clampf(far / FAINT, 0.0, 1.0)), Sounds.RADIO_PING)
	hiss.volume_db = linear_to_db(maxf(noise, under) + 0.0001)
	if not _hissing:
		hiss.play(fposmod(t, hiss.stream.get_length()))
		_hissing = true


## The day's track while the sun is up, the night's after, from where the
## station is in it: it plays on whether anyone listens. It changes over
## through a burst of static.
func _play_music(t: float) -> void:
	var now: AudioStream = Sounds.RADIO_DAY if world.weather.day.is_day(t, world.moon.longitude) else Sounds.RADIO_NIGHT
	if _on_air == now:
		return
	if _on_air != null:
		Sounds.play_at(self, Sounds.RADIO_TUNE, -6.0, HEARD)
	music.stream = now
	music.play(fposmod(t, now.get_length()))
	_on_air = now


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


func _weather_words(t: float) -> String:
	var from := _point(reading.from)
	var wind := roundi(reading.wind)
	var horizon := roundi(_tuning.radio_forecast_minutes)
	if reading.stormy:
		return "in a storm from the %s · winds to %d m/s · %s" % [from, wind,
			"clearing in %s" % _span(reading.change - t) if reading.change < INF
			else "no clearing for %d min" % horizon]
	if reading.change == INF:
		return "clear for %d min and more · wind %d m/s from the %s" % [horizon, wind, from]
	return "a storm from the %s in %s · winds to %d m/s · %s" % [from, _span(reading.change - t), wind,
		"for %s" % _span(reading.back - reading.change) if reading.back < INF
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


## A bearing from the world's -z, said by the moon's north where you are, as
## a compass reads it: past a pole the two still agree.
func _point(degrees: float) -> String:
	return compass(degrees if world.moon.north().z < 0.0 else degrees + 180.0)


## Seconds as a station says them.
static func _span(seconds: float) -> String:
	return "%d s" % maxi(0, roundi(seconds)) if seconds < 90.0 else "%d min" % roundi(seconds / 60.0)


func _voice() -> AudioStreamPlayer3D:
	var voice := Sounds.world_voice(null, 0.0, HEARD)
	add_child(voice)
	return voice
