class_name Rumbles
extends Node3D
## What the vents and the gas pockets sound like from where you stand. A burst,
## or a pocket blowing out, booms: heard after it's seen, as thunder is after
## lightning, by how far its sound has come at the speed of sound in Zan's air;
## quieter the further, as sound spreads, and duller, since air takes a
## sound's high end first, and thin air the more; and from its way, so a boom
## says where a vent is. A live vent's steady roar is heard only near. No
## shake: sound alone. It reads the game and never feeds it.

## Sound's speed is sqrt(γRT/M): for nitrogen, Zan's air, γ 1.4 and M 0.028
## kg/mol, about 353 m/s at 27 °C. How thin the air is doesn't enter it; how
## warm it is does, read where you stand.
const SPEED_SQUARED_PER_K := 1.4 * 8.314 / 0.028
## A boom is heard this far at most, m; at a kilometre a vent's least burst,
## or a pocket's least, is this loud over its file, dB, a pocket this much
## less, louder by its size; spreading takes 6 dB each time the distance
## doubles.
const HEARD := 45000.0
const AT_KM := -2.0
const POCKET_LESS := -8.0
## Its high end, Hz: all of it at a kilometre, less past it by distance to
## this power, never under the second.
const CLEAR_HZ := 3000.0
const DULLS := 0.9
const LEAST_HZ := 50.0
## Heard this late, s, a boom still plays; later, a jump in time passed it.
const LATE := 2.0
## A live vent roars within this far, m; at the first it's at its file's level,
## and duller past it as a boom is.
const ROARS := 2500.0
const ROAR_AT := 150.0
## A sound's player stands this far off you its way, m, so you hear its side.
const AWAY := 20.0

## The booms heard, latest last: {source, at (world s), distance m, delay s,
## volume_db, cutoff_hz, toward (world x and z, unit)}.
var heard: Array[Dictionary] = []

var _world: World
var _weather: Weather
var _booms: Array[AudioStreamPlayer3D] = []
var _turn := 0
var _ways: Array[Vector3] = []
var _roar: AudioStreamPlayer3D
var _roar_way := Vector3.FORWARD
var _boom_filter: AudioEffectLowPassFilter
var _roar_filter: AudioEffectLowPassFilter
## Bursts and blowouts already heard, by their source's seed and start.
var _done := {}


func setup(world: World, weather: Weather) -> void:
	_world = world
	_weather = weather
	for i in 2:
		_booms.append(_player(Sounds.BOOM, Sounds.BOOMS))
		_ways.append(Vector3.FORWARD)
	var roar := Sounds.VENT_ROAR
	roar.loop = true
	_roar = _player(roar, Sounds.VENTS)
	_roar.volume_db = -80.0
	_roar.play()
	_boom_filter = AudioServer.get_bus_effect(AudioServer.get_bus_index(Sounds.BOOMS), 0) as AudioEffectLowPassFilter
	_roar_filter = AudioServer.get_bus_effect(AudioServer.get_bus_index(Sounds.VENTS), 0) as AudioEffectLowPassFilter


## How fast sound goes through the air where you stand now, m/s.
func speed() -> float:
	var celsius := _weather.field_temperature(_world.player.camera.global_position)
	return sqrt(SPEED_SQUARED_PER_K * (celsius + 273.15))


func _process(_delta: float) -> void:
	if _world == null:
		return
	var sites := _world.shape.sites
	var camera := _world.player.camera.global_position
	var running := _world.time_warp > 0.0
	for each in _booms + [_roar]:
		each.stream_paused = not running
	if not sites.anchored():
		return
	var geology := _world.shape.history.geology
	var t := _world.time
	var here := Sphere.point(_world.moon.latitude, _world.moon.longitude)
	var c := speed()
	var nearest := INF
	var roaring := {}
	for each in geology.live() + geology.pockets(t - HEARD / c, t):
		var by := Sphere.angle(here, each.p) * geology.radius
		if by > HEARD:
			continue
		if each.state == Geology.LIVE_VENT and by < minf(nearest, ROARS):
			nearest = by
			roaring = each
		var burst := geology.last_burst(each, t)
		var arrives := burst.x + by / c
		var key := hash([each.seed, burst.x])
		if burst.y > 0.0 and t >= arrives and t - arrives < LATE and not _done.has(key):
			_done[key] = true
			_boom(each, by, by / c, burst.y, t)
	if _done.size() > 64:
		_done.clear()
	_roaring(roaring, nearest)
	for i in _booms.size():
		_booms[i].global_position = camera + _ways[i] * AWAY
	_roar.global_position = camera + _roar_way * AWAY


func _boom(source: Dictionary, metres: float, delay: float, size: float, t: float) -> void:
	var toward := _toward(source)
	var player := _booms[_turn % _booms.size()]
	_ways[_turn % _booms.size()] = Vector3(toward.x, 0.0, toward.y)
	_turn += 1
	var pocket: bool = source.state == Geology.POCKET
	var least := Geology.POCKET_SIZE.x if pocket else Geology.BURST_SIZE.x
	var volume := AT_KM + (POCKET_LESS if pocket else 0.0) - 20.0 * log(maxf(metres, 100.0) / 1000.0) / log(10.0) \
		+ 10.0 * log(size / least) / log(10.0)
	var cutoff := dull(metres)
	player.volume_db = volume
	# A pocket's gas blows out sharper than a vent's throat clears.
	player.pitch_scale = 1.25 if pocket else clampf(1.1 - 0.1 * log(size / least), 0.85, 1.1)
	_boom_filter.cutoff_hz = cutoff
	player.play()
	heard.append({"source": source.id, "at": t, "distance": metres, "delay": delay, "volume_db": volume,
		"cutoff_hz": cutoff, "toward": toward})
	if heard.size() > 16:
		heard.pop_front()


## What's left of a sound's high end after `metres` of air, Hz.
static func dull(metres: float) -> float:
	return clampf(CLEAR_HZ * pow(1000.0 / maxf(metres, 1000.0), DULLS), LEAST_HZ, CLEAR_HZ)


## The nearest live vent's roar, near, harder the harder it vents.
func _roaring(vent: Dictionary, metres: float) -> void:
	if vent.is_empty():
		_roar.volume_db = -80.0
		return
	var hard := _world.shape.history.geology.venting(vent, _world.time).x
	var toward := _toward(vent)
	_roar_way = Vector3(toward.x, 0.0, toward.y)
	var fade := 1.0 - smoothstep(ROARS * 0.6, ROARS, metres)
	_roar.volume_db = linear_to_db(fade * minf(sqrt(hard), 4.0) * ROAR_AT / maxf(metres, ROAR_AT) + 1e-5)
	_roar_filter.cutoff_hz = clampf(4000.0 * pow(ROAR_AT / maxf(metres, ROAR_AT), 0.8), 120.0, 4000.0)


## Which way a source lies from you on the ground, world x and z, unit.
func _toward(source: Dictionary) -> Vector2:
	var at := _world.shape.sites.anchor().place(source.p)
	var camera := _world.player.camera.global_position
	var way := at - Vector2(_world.world_x(camera.x), _world.world_z(camera.z))
	return way.normalized() if way.length() > 1e-3 else Vector2(0.0, -1.0)


func _player(stream: AudioStream, bus: StringName) -> AudioStreamPlayer3D:
	var player := AudioStreamPlayer3D.new()
	player.stream = stream
	player.bus = bus
	# Loud as it is far, by the rule above, not by how far the player stands.
	player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_DISABLED
	player.doppler_tracking = AudioStreamPlayer3D.DOPPLER_TRACKING_DISABLED
	player.attenuation_filter_cutoff_hz = 20500.0
	add_child(player)
	return player


func _exit_tree() -> void:
	# Looping streams still playing at quit hold their resources past exit.
	_roar.stop()
	for each in _booms:
		each.stop()
