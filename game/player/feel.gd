class_name Feel
extends Node3D
## How moving feels: the head's bob and sway, a spring on footfalls, landings
## and changes of pace, a lean into strong wind with gusts nudging it, a wider
## view at speed, footsteps, and a slide's hiss and spray. It reads the player
## and never writes to it, so none of it can change where you go: it moves
## only the camera, and makes only sound and dust.

const STEPS: Array[AudioStream] = [preload("res://assets/audio/step_a.ogg"),
	preload("res://assets/audio/step_b.ogg"), preload("res://assets/audio/step_c.ogg"),
	preload("res://assets/audio/step_d.ogg"), preload("res://assets/audio/step_e.ogg"),
	preload("res://assets/audio/step_f.ogg")]
const HISS: AudioStreamOggVorbis = preload("res://assets/audio/slide.ogg")
const THUD: AudioStream = preload("res://assets/audio/impact.ogg")
## Landings slower than this, m/s, are settling, like a respawn's drop.
const SOFTEST := 1.5
## The spring never carries the head further than this, m.
const REACH := 0.15
## The most one change of pace or one gust kicks the head, m/s.
const MOST_KICK := 0.6
## How fast the bob, the eyes, the lean and the view follow you, s.
const BOB_SECONDS := 0.15
const EYE_SECONDS := 0.05
const LEAN_SECONDS := 0.5
const VIEW_SECONDS := 0.3
## A slide this fast, m/s, hisses loudest and widens the view most.
const FAST := 10.0

var _player: Player
var _tuning := Tuning.current()
var _rest: Vector3
var _fov: float
var _phase := 0.0
var _bob := 0.0
var _drop := 0.0
var _spring := Vector3.ZERO
var _spring_v := Vector3.ZERO
var _lean := Vector3.ZERO
var _roll := 0.0
var _widen := 0.0
var _hiss := 0.0
var _clock := 0.0
var _last_own := Vector2.ZERO
var _last_gust := -1.0
var _last_step := -1
var _foot := 0
## Its own dice, so sound never shifts what a probe's seed decides.
var _rng := RandomNumberGenerator.new()
var _feet: Array[AudioStreamPlayer] = []
var _slide: AudioStreamPlayer
var _thud: AudioStreamPlayer
var _spray: CPUParticles3D
var _puff: CPUParticles3D


func _ready() -> void:
	_player = get_parent() as Player
	_rest = _player.camera.position
	_fov = _player.camera.fov
	_rng.seed = 7
	for i in 2:
		_feet.append(_voice(null))
	var hiss := HISS
	hiss.loop = true
	_slide = _voice(hiss)
	_thud = _voice(THUD)
	_spray = _sand(40, 0.8, false)
	_puff = _sand(28, 0.7, true)
	_player.landed.connect(_on_landed)
	_player.jumped.connect(_on_jumped)


func _process(delta: float) -> void:
	var camera := _player.camera
	if _player.flying or _player.world == null:
		camera.position = _rest
		camera.rotation.z = 0.0
		camera.fov = _fov
		_slide.stream_paused = true
		_spray.emitting = false
		return
	var t := _tuning
	var own := _player.own
	var speed := own.length()
	var to_you := _player.global_basis.inverse()
	var striding := _player.mode == "walk" or _player.mode == "sprint"
	_clock += delta

	# The stride follows ground covered, so footfalls come where feet land.
	if striding and speed > 0.1:
		var stride := t.step_length * sqrt(speed / t.walk_speed)
		var before := floori(_phase / PI)
		_phase += speed * delta / stride * PI
		if floori(_phase / PI) != before:
			_footfall(speed)
	var size := clampf(speed / t.walk_speed, 0.0, 2.0) * (0.6 if _player.crouched else 1.0) if striding else 0.0
	_bob = _ease(_bob, size, BOB_SECONDS, delta)
	# Lowest as a foot lands; side to side once every two steps.
	var bob := Vector3(t.bob_sway * sin(_phase), -t.bob_height * (1.0 + cos(2.0 * _phase)) * 0.5, 0.0) * _bob
	var roll := deg_to_rad(t.bob_roll_degrees) * _bob * sin(_phase)

	# The head lags a change of pace and swings back.
	var change := own - _last_own
	_last_own = own
	_kick(to_you * -Vector3(change.x, 0.0, change.y) * t.lurch)
	var wind := _player.wind
	var gust := wind.length()
	var brace := 1.0 - 0.6 * _player.low
	if _last_gust >= 0.0 and gust > _last_gust and gust > 0.01:
		_kick(to_you * wind / gust * (gust - _last_gust) * t.gust_nudge * brace)
	_last_gust = gust
	_swing(delta)

	# Into a wind you can just stand against, you lean: head upwind, view tipped.
	var strength := smoothstep(t.wind_resist_speed * 0.4, t.wind_resist_speed, gust) * brace
	var upwind := to_you * -wind / gust if gust > 0.01 else Vector3.ZERO
	_lean = _lean.lerp(upwind * t.wind_lean * strength, 1.0 - exp(-delta / LEAN_SECONDS))
	_roll = _ease(_roll, -deg_to_rad(t.wind_lean_degrees) * upwind.x * strength, LEAN_SECONDS, delta)

	_drop = _ease(_drop, t.crouch_drop * _player.low + t.haul_sink * _player.sink, EYE_SECONDS, delta)
	var widen := 0.0
	if speed > t.walk_speed:
		widen = t.sprint_fov * clampf((speed - t.walk_speed) / (t.sprint_speed - t.walk_speed), 0.0, 1.0) \
			+ (t.slide_fov - t.sprint_fov) * clampf((speed - t.sprint_speed) / (FAST - t.sprint_speed), 0.0, 1.0)
	_widen = _ease(_widen, widen, VIEW_SECONDS, delta)

	var sliding := _player.mode == "slide"
	# The sand judders through you on a fast slide.
	var judder := Vector3(sin(_clock * 41.0), sin(_clock * 53.0 + 1.3), 0.0) * 0.003 \
		* clampf(speed / FAST, 0.0, 1.0) if sliding else Vector3.ZERO
	camera.position = _rest + bob + _spring + _lean + judder + Vector3.DOWN * _drop
	camera.rotation.z = roll + _roll
	camera.fov = _fov + _widen
	_sound_slide(sliding, speed, delta)
	_throw_sand(sliding, own, speed)


func _footfall(speed: float) -> void:
	var t := _tuning
	_kick(Vector3.DOWN * t.step_dip * speed)
	var pace := clampf((speed - t.walk_speed) / (t.sprint_speed - t.walk_speed), 0.0, 1.0)
	_step(t.step_db + pace * 4.0 - (6.0 if _player.crouched else 0.0))


## A step sound, never the same one twice running, on alternate feet.
func _step(db: float) -> void:
	var pick := _rng.randi_range(0, STEPS.size() - 2)
	if pick >= _last_step:
		pick += 1
	_last_step = pick
	_foot = 1 - _foot
	var foot := _feet[_foot]
	foot.stream = STEPS[pick]
	foot.pitch_scale = _rng.randf_range(0.9, 1.1)
	foot.volume_db = db + _rng.randf_range(-1.5, 1.5)
	foot.play()


func _on_jumped() -> void:
	_step(_tuning.step_db + 2.0)


func _on_landed(speed: float) -> void:
	if speed < SOFTEST:
		return
	_kick(Vector3.DOWN * _tuning.land_dip * speed)
	if speed < _tuning.hard_landing:
		_step(_tuning.step_db + 3.0)
		return
	_thud.pitch_scale = _rng.randf_range(0.92, 1.05)
	_thud.volume_db = linear_to_db(clampf(speed / (_tuning.hard_landing * 2.0), 0.4, 1.0)) - 4.0
	_thud.play()
	_puff.global_position = _player.global_position + Vector3.UP * 0.1
	_puff.gravity = Vector3.DOWN * _player.world.gravity
	_puff.restart()


func _kick(head_speed: Vector3) -> void:
	_spring_v += head_speed.limit_length(MOST_KICK)


## A damped spring pulls the head back to rest, stepped finely so a long
## frame can't throw it.
func _swing(delta: float) -> void:
	var w := TAU * _tuning.spring_hertz
	var n := ceili(delta * 240.0)
	var h := delta / maxi(n, 1)
	for i in n:
		_spring_v += (-w * w * _spring - 2.0 * _tuning.spring_damping * w * _spring_v) * h
		_spring += _spring_v * h
	_spring = _spring.limit_length(REACH)


func _sound_slide(sliding: bool, speed: float, delta: float) -> void:
	_hiss = _ease(_hiss, clampf(speed / FAST * 1.5, 0.15, 1.0) if sliding and speed > 0.3 else 0.0, 0.08, delta)
	if _hiss < 0.01:
		_slide.stream_paused = true
		return
	_slide.volume_db = _tuning.slide_db + linear_to_db(_hiss)
	_slide.pitch_scale = 0.85 + 0.35 * clampf(speed / FAST, 0.0, 1.0)
	_slide.stream_paused = false
	if not _slide.playing:
		_slide.play(_rng.randf() * 2.0)


## A slide throws sand up ahead of your feet and off to the sides, under the
## moon's own gravity, so at 0.45 g it hangs.
func _throw_sand(sliding: bool, own: Vector2, speed: float) -> void:
	_spray.emitting = sliding and speed > 0.8
	if not _spray.emitting:
		return
	var heading := Vector3(own.x, 0.0, own.y) / speed
	_spray.scale_amount_max = 0.06 + 0.1 * clampf(speed / FAST, 0.0, 1.0)
	_spray.global_position = _player.global_position + heading * 0.45 + Vector3.UP * 0.05
	_spray.direction = (heading * 0.4 + Vector3.UP).normalized()
	_spray.initial_velocity_min = 0.5 + speed * 0.15
	_spray.initial_velocity_max = 1.0 + speed * 0.3
	_spray.gravity = Vector3.DOWN * _player.world.gravity


func _voice(stream: AudioStream) -> AudioStreamPlayer:
	var voice := AudioStreamPlayer.new()
	voice.stream = stream
	add_child(voice)
	return voice


## Grains of the sand's own colour that fade as they fall.
func _sand(amount: int, lifetime: float, burst: bool) -> CPUParticles3D:
	var sand := CPUParticles3D.new()
	sand.amount = amount
	sand.lifetime = lifetime
	sand.one_shot = burst
	sand.explosiveness = 1.0 if burst else 0.0
	sand.emitting = false
	sand.local_coords = false
	sand.direction = Vector3.UP
	sand.spread = 80.0 if burst else 45.0
	sand.initial_velocity_min = 0.6
	sand.initial_velocity_max = 1.6
	sand.scale_amount_min = 0.04
	sand.scale_amount_max = 0.12
	var fade := Gradient.new()
	fade.set_color(0, Color(Weather.SAND, 0.6))
	fade.set_color(1, Color(Weather.SAND, 0.0))
	sand.color_ramp = fade
	var grain := QuadMesh.new()
	var look := StandardMaterial3D.new()
	look.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	look.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	look.vertex_color_use_as_albedo = true
	grain.material = look
	sand.mesh = grain
	sand.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sand)
	return sand


static func _ease(from: float, to: float, seconds: float, delta: float) -> float:
	return to + (from - to) * exp(-delta / seconds)
