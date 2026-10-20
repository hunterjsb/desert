class_name Rumbles
extends Node3D
## What the vents and the gas pockets sound like from where you stand, and
## what a live vent feels like near. A burst, or a pocket blowing out, booms:
## heard after it's seen, as thunder is after lightning, by how far its sound
## has come at the speed of sound in Zan's air; quieter the further, as sound
## spreads, and duller, since air takes a sound's high end first, and thin air
## the more; its low end rolls on after it, the more and the longer the
## further off; and from its way, so a boom says where a vent is. Near a live
## vent its steady roar is heard, and the ground is felt: a deep build as a
## burst nears, then the ground trembling under you, which shakes your view
## (Feel) and jostles loose things on the sand.

## Sound's speed is sqrt(γRT/M): for nitrogen, Zan's air, γ 1.4 and M 0.028
## kg/mol, about 353 m/s at 27 °C. How thin the air is doesn't enter it; how
## warm it is does, read where you stand.
const SPEED_SQUARED_PER_K := 1.4 * 8.314 / 0.028
## A boom is heard this far at most, m; at a kilometre a vent's least burst,
## or a pocket's least, is this loud over its file, dB, a pocket this much
## less, louder by its size; spreading takes 6 dB each time the distance
## doubles. Never louder than LOUDEST, however near: felt, not loud.
const HEARD := 45000.0
const AT_KM := -2.0
const POCKET_LESS := -8.0
const LOUDEST := 0.0
## Its high end, Hz: all of it at a kilometre, less past it by distance to
## this power, never under the second.
const CLEAR_HZ := 3000.0
const DULLS := 0.9
const LEAST_HZ := 50.0
## Its roll's low end carries along the ground: past a kilometre it falls
## this much less each doubling than the thump, dB, and plays this much lower
## and longer, never under the last.
const ROLL_CARRIES := 1.5
const ROLL_DROPS := 0.07
const ROLL_LOWEST := 0.75
## Heard this late, s, a boom still plays; later, a jump in time passed it.
const LATE := 2.0
## A live vent roars within this far, m; at the first it's at its file's level,
## and duller past it as a boom is.
const ROARS := 2500.0
const ROAR_AT := 150.0
## A live vent is felt within this far, m, fading out past 0.6 of it, and
## fully within the second: the ground's shaking spreads over the ground, not
## through the air, so it falls as the root of distance.
const FELT := 5000.0
const CLOSE := 300.0
## A burst's build begins this long before it, s, growing as the square of how
## near it is, in pitch over these two, and trembling this share of the jolt.
const BUILD := 50.0
const BUILD_PITCH := Vector2(0.8, 1.0)
const BUILD_SHARE := 0.6
## At its onset the ground jolts, dying by e over the first, s, and roars,
## dying over the second; a burst holding its push trembles this share at the
## strongest.
const JOLT := 4.0
const ROAR_DIES := 8.0
const HOLD_SHARE := 0.35
## A boom arriving near is felt too, dying by e over this, s.
const BLAST := 1.0
## Loose things within this far of you, m, no heavier than this, kg, are
## jostled this often, Hz, while the ground trembles past the first share:
## kicked up to this fast, m/s, and spun up to this, rad/s, by the root of
## how hard, so a far tremble still rattles them.
const JOSTLES := 40.0
const JOSTLED_KG := 40.0
const KICKS_HZ := 8.0
const KICK_FROM := 0.05
const KICK := 0.35
const SPIN := 0.6
## A sound's player stands this far off you its way, m, so you hear its side.
const AWAY := 20.0

## The booms heard, latest last: {source, at (world s), distance m, delay s,
## volume_db, cutoff_hz, toward (world x and z, unit), pitch, roll_db, roll_pitch}.
var heard: Array[Dictionary] = []
## How hard the ground trembles under you now, 0 to 1, by how near a live vent
## is and how big its burst; and how loud its build is, 0 to 1 of its file's.
var tremble := 0.0
var build := 0.0

var _world: World
var _weather: Weather
var _booms: Array[AudioStreamPlayer3D] = []
var _rolls: Array[AudioStreamPlayer3D] = []
var _turn := 0
var _ways: Array[Vector3] = []
var _roar: AudioStreamPlayer3D
var _rising: AudioStreamPlayer3D
var _roar_way := Vector3.FORWARD
var _boom_filter: AudioEffectLowPassFilter
var _roar_filter: AudioEffectLowPassFilter
## Bursts and blowouts already heard, by their source's seed and start.
var _done := {}
## The last boom felt arriving: how hard, and when, world s.
var _blast := 0.0
var _blast_at := 0.0
var _jostled := -1


func setup(world: World, weather: Weather) -> void:
	_world = world
	_weather = weather
	for i in 2:
		_booms.append(_player(Sounds.BOOM, Sounds.BOOMS))
		_rolls.append(_player(Sounds.BOOM_ROLL, Sounds.BOOMS))
		_ways.append(Vector3.FORWARD)
	var roar := Sounds.VENT_ROAR
	roar.loop = true
	_roar = _player(roar, Sounds.VENTS)
	_roar.volume_db = -80.0
	_roar.play()
	var rising := Sounds.VENT_BUILD
	rising.loop = true
	_rising = _player(rising, Sounds.VENTS)
	_rising.volume_db = -80.0
	_rising.play()
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
	for each in _booms + _rolls + [_roar, _rising]:
		each.stream_paused = not running
	if not sites.anchored():
		return
	var geology := _world.shape.history.geology
	var t := _world.time
	var here := Sphere.point(_world.moon.latitude, _world.moon.longitude)
	var c := speed()
	var nearest := INF
	var vent := {}
	for each in geology.live() + geology.pockets(t - HEARD / c, t):
		var by := Sphere.angle(here, each.p) * geology.radius
		if by > HEARD:
			continue
		if each.state == Geology.LIVE_VENT and by < minf(nearest, FELT):
			nearest = by
			vent = each
		var burst := geology.last_burst(each, t)
		var arrives := burst.x + by / c
		var key := hash([each.seed, burst.x])
		if burst.y > 0.0 and t >= arrives and t - arrives < LATE and not _done.has(key):
			_done[key] = true
			_boom(each, by, by / c, burst.y, t)
	if _done.size() > 64:
		_done.clear()
	_roaring(vent, nearest)
	_felt(vent, nearest, t)
	for i in _booms.size():
		_booms[i].global_position = camera + _ways[i] * AWAY
		_rolls[i].global_position = _booms[i].global_position
	_roar.global_position = camera + _roar_way * AWAY
	_rising.global_position = _roar.global_position


func _boom(source: Dictionary, metres: float, delay: float, size: float, t: float) -> void:
	var toward := _toward(source)
	var turn := _turn % _booms.size()
	var player := _booms[turn]
	var roll := _rolls[turn]
	_ways[turn] = Vector3(toward.x, 0.0, toward.y)
	_turn += 1
	var pocket: bool = source.state == Geology.POCKET
	var least := Geology.POCKET_SIZE.x if pocket else Geology.BURST_SIZE.x
	var volume := AT_KM + (POCKET_LESS if pocket else 0.0) - 20.0 * log(maxf(metres, 100.0) / 1000.0) / log(10.0) \
		+ 10.0 * log(size / least) / log(10.0)
	var doublings := log(maxf(metres, 1000.0) / 1000.0) / log(2.0)
	var cutoff := dull(metres)
	player.volume_db = minf(volume, LOUDEST)
	# A pocket's gas blows out sharper than a vent's throat clears.
	player.pitch_scale = 1.25 if pocket else clampf(1.1 - 0.1 * log(size / least), 0.85, 1.1)
	roll.volume_db = minf(volume + ROLL_CARRIES * doublings, LOUDEST)
	roll.pitch_scale = player.pitch_scale * maxf(1.0 - ROLL_DROPS * doublings, ROLL_LOWEST)
	_boom_filter.cutoff_hz = cutoff
	player.play()
	roll.play()
	_blast = nearness(metres) * big(size)
	_blast_at = t
	heard.append({"source": source.id, "at": t, "distance": metres, "delay": delay, "volume_db": player.volume_db,
		"cutoff_hz": cutoff, "toward": toward, "pitch": player.pitch_scale, "roll_db": roll.volume_db,
		"roll_pitch": roll.pitch_scale})
	if not pocket and metres >= _world.tuning.deed_thunder_m:
		Deeds.done(_world, &"thunder")
	if heard.size() > 16:
		heard.pop_front()


## What's left of a sound's high end after `metres` of air, Hz.
static func dull(metres: float) -> float:
	return clampf(CLEAR_HZ * pow(1000.0 / maxf(metres, 1000.0), DULLS), LEAST_HZ, CLEAR_HZ)


## How much of a live vent's ground is felt `metres` off it, 0 to 1.
static func nearness(metres: float) -> float:
	return sqrt(CLOSE / maxf(metres, CLOSE)) * (1.0 - smoothstep(FELT * 0.6, FELT, metres))


## How big a burst of `size` times the seep is felt, 0 to 1: a vent's least
## about two thirds, its greatest all.
static func big(size: float) -> float:
	return clampf(log(maxf(size, 1.0)) / log(Geology.BURST_SIZE.y), 0.0, 1.0)


## A live vent's ground at world time t, before how near it is: how hard it
## trembles, 0 to 1; how loud its build is, 0 to 1; and how far its pitch has
## risen, 0 to 1.
func ground(vent: Dictionary, t: float) -> Vector3:
	var geology := _world.shape.history.geology
	var coming := geology.coming_burst(vent, t)
	var due := clampf(1.0 - (coming.x - t) / BUILD, 0.0, 1.0) if coming.y > 0.0 else 0.0
	var rising := big(coming.y) * due * due
	var last := geology.last_burst(vent, t)
	var jolt := 0.0
	var roar := 0.0
	if last.y > 0.0:
		jolt = big(last.y) * exp(-(t - last.x) / JOLT)
		roar = big(last.y) * exp(-(t - last.x) / ROAR_DIES)
	var push := clampf(geology.venting(vent, t).x / Geology.BURST_SIZE.y, 0.0, 1.0)
	return Vector3(maxf(BUILD_SHARE * rising, maxf(jolt, HOLD_SHARE * sqrt(push))), maxf(rising, roar),
		1.0 if roar > rising else due)


## The nearest live vent's ground, `metres` off: its build heard, its
## trembling felt, and a boom's blast as it arrives.
func _felt(vent: Dictionary, metres: float, t: float) -> void:
	var now := Vector3.ZERO
	if not vent.is_empty():
		now = ground(vent, t)
		var near := nearness(metres)
		now.x *= near
		now.y *= near
	# Before it arrived, a jump back in time, it was never felt.
	var blast := _blast * exp(-(t - _blast_at) / BLAST) if t >= _blast_at else 0.0
	tremble = clampf(maxf(now.x, blast), 0.0, 1.0)
	build = now.y
	_rising.volume_db = linear_to_db(build + 1e-5)
	_rising.pitch_scale = lerpf(BUILD_PITCH.x, BUILD_PITCH.y, now.z)
	Dev.put("weather/ground", "tremble %.2f · build %.2f" % [tremble, build])


## The ground jostles what lies loose on the sand near you as it trembles,
## all of it at once as the ground moves under it, each its own way.
func _physics_process(_delta: float) -> void:
	if _world == null or tremble < KICK_FROM or _world.time_warp <= 0.0:
		return
	var tick := floori(_world.time * KICKS_HZ)
	if tick == _jostled:
		return
	_jostled = tick
	var at := _world.player.global_position
	var dice := RandomNumberGenerator.new()
	for node in _world.content.get_children():
		var body := node as RigidBody3D
		if body == null or body.freeze or body.collision_layer == 0 or body.mass > JOSTLED_KG \
				or body.global_position.distance_squared_to(at) > JOSTLES * JOSTLES \
				or body.linear_velocity.length() > KICK or body.angular_velocity.length() > SPIN:
			continue
		var device := body as Device
		if device != null and (device.hovering() or device.host() != null):
			continue
		# Its own dice by where it lies and the tick, so a resumed run jostles alike.
		dice.seed = hash([tick, roundi(_world.world_x(body.global_position.x) * 100.0),
			roundi(_world.world_z(body.global_position.z) * 100.0)])
		var hard := sqrt(tremble)
		body.sleeping = false
		body.linear_velocity += Vector3(dice.randf_range(-0.4, 0.4), dice.randf_range(0.6, 1.0),
			dice.randf_range(-0.4, 0.4)) * KICK * hard
		body.angular_velocity += Vector3(dice.randf_range(-1.0, 1.0), dice.randf_range(-1.0, 1.0),
			dice.randf_range(-1.0, 1.0)) * SPIN * hard


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
	_rising.stop()
	for each in _booms + _rolls:
		each.stop()
