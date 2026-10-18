class_name Feel
extends Node3D
## How moving feels: the head's bob and sway, a spring on footfalls, landings
## and changes of pace, a lean into strong wind with gusts nudging it, a wider
## view at speed, footsteps, and a slide's hiss and spray; on a board, a lean
## into the carve, a dug edge's rooster tail of sand and its hiss, a shake as
## the edge bites and a harder one as it catches, and your view smoothed
## between ticks, which at its speed would otherwise stutter. It reads the player and never writes to it, so
## none of it can change where you go: it moves only the camera, and makes
## only sound and dust.

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
## The share of a board's lean into its carve your view leans with it.
const BANK_SHARE := 0.35
## A dug edge this fast across or along the sand, m/s, throws all it can.
const GRIT_FAST := 12.0
## Grains in the air at once: a slide's, a dug edge's.
const SLIDE_GRAINS := 64
const TAIL_GRAINS := 192
## How far a shake throws your view at its hardest, m and radians, and how
## fast it dies away, s; an edge biting shakes it this share of that.
const SHAKE_REACH := 0.035
const SHAKE_ROLL := 0.03
const SHAKE_SECONDS := 0.18
const BITE_SHAKE := 0.35

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
var _bank := 0.0
var _hiss := 0.0
var _shake := 0.0
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
	var hiss: AudioStreamOggVorbis = Sounds.SLIDE
	hiss.loop = true
	_slide = _voice(hiss)
	_thud = _voice(Sounds.LANDING)
	_spray = _sand(SLIDE_GRAINS, 0.8, false)
	_spray.top_level = true
	_puff = _sand(32, 0.7, true)
	_player.landed.connect(_on_landed)
	_player.jumped.connect(_on_jumped)
	_player.edge_bit.connect(_on_edge_bit)
	_player.wiped_out.connect(_on_wiped_out)
	# Before the hands draw what you hold from where your eyes are this frame.
	process_priority = -1


## Your eyes in your own frame as the ticks know them: lowered by a crouch or
## a haul, never swayed. What you hold is placed from here, so the sway drawn
## each frame never moves what its lines pull.
func steady_eye() -> Vector3:
	return _rest + Vector3.DOWN * _eye_drop()


func _eye_drop() -> float:
	return _tuning.crouch_drop * _player.low + _tuning.haul_sink * _player.sink


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
	var ride := _player.ride
	_clock += delta

	# The stride follows ground covered, so footfalls come where feet land.
	if striding and speed > 0.1:
		var before := floori(_phase / PI)
		_phase += speed * delta / stride(speed) * PI
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

	_drop = _ease(_drop, _eye_drop(), EYE_SECONDS, delta)
	var widen := 0.0
	var fast := t.board_top_speed if ride != null else FAST
	if speed > t.walk_speed:
		widen = t.sprint_fov * clampf((speed - t.walk_speed) / (t.sprint_speed - t.walk_speed), 0.0, 1.0) \
			+ (t.slide_fov - t.sprint_fov) * clampf((speed - t.sprint_speed) / (fast - t.sprint_speed), 0.0, 1.0)
	_widen = _ease(_widen, widen, VIEW_SECONDS, delta)
	# Drawn where you were between the last tick and this one, as the board is.
	var between := Vector3.ZERO
	if ride != null:
		between = to_you * -ride.last_step * (1.0 - Engine.get_physics_interpolation_fraction())
	_bank = _ease(_bank, -ride.tilt(true).z * BANK_SHARE if ride != null else 0.0, EYE_SECONDS, delta)

	var sliding := _player.mode == "slide"
	# The sand judders through you on a fast slide.
	var judder := Vector3(sin(_clock * 41.0), sin(_clock * 53.0 + 1.3), 0.0) * 0.003 \
		* clampf(speed / FAST, 0.0, 1.0) if sliding else Vector3.ZERO
	_shake *= exp(-delta / SHAKE_SECONDS)
	var shake := Vector3(sin(_clock * 67.0), sin(_clock * 79.0 + 0.7), 0.0) * SHAKE_REACH * _shake
	camera.position = _rest + bob + _spring + _lean + judder + shake + Vector3.DOWN * _drop + between
	camera.rotation.z = roll + _roll + _bank + sin(_clock * 59.0 + 2.1) * SHAKE_ROLL * _shake
	camera.fov = _fov + _widen
	var grit := _grit(ride) if ride != null else (clampf(speed / FAST * 1.5, 0.15, 1.0) if sliding and speed > 0.3 else 0.0)
	_sound_slide(grit, speed / (t.board_top_speed if ride != null else FAST), delta)
	if ride != null:
		_dig_sand(ride, grit)
	else:
		_throw_sand(sliding, own, speed)


## Ground covered between footfalls at a pace, m: tracks print feet where these land.
static func stride(speed: float) -> float:
	var t := Tuning.current()
	return t.step_length * sqrt(speed / t.walk_speed)


func _footfall(speed: float) -> void:
	var t := _tuning
	_kick(Vector3.DOWN * t.step_dip * speed)
	var pace := clampf((speed - t.walk_speed) / (t.sprint_speed - t.walk_speed), 0.0, 1.0)
	_step(t.step_db + pace * 4.0 - (6.0 if _player.crouched else 0.0))


## A step sound, never the same one twice running, on alternate feet.
func _step(db: float) -> void:
	var pick := _rng.randi_range(0, Sounds.STEPS.size() - 2)
	if pick >= _last_step:
		pick += 1
	_last_step = pick
	_foot = 1 - _foot
	var foot := _feet[_foot]
	foot.stream = Sounds.STEPS[pick]
	foot.pitch_scale = _rng.randf_range(0.9, 1.1)
	foot.volume_db = db + _rng.randf_range(-1.5, 1.5)
	foot.play()


func _on_jumped() -> void:
	_step(_tuning.step_db + 2.0)


## The edge bit: a small shake, harder the faster you go.
func _on_edge_bit(speed: float) -> void:
	_shake = maxf(_shake, BITE_SHAKE * clampf(speed / _tuning.board_top_speed, 0.4, 1.0))


## The edge caught and threw you: a hard shake, a lurch and a thud into the sand.
func _on_wiped_out(speed: float) -> void:
	_shake = 1.0
	_kick(Vector3(0.0, -1.0, -0.5) * speed)
	_thud.pitch_scale = _rng.randf_range(0.85, 0.95)
	_thud.volume_db = 0.0
	_thud.play()
	_puff.global_position = _player.global_position + Vector3.UP * 0.1
	_puff.gravity = Vector3.DOWN * _player.world.gravity
	_puff.restart()


func _on_landed(speed: float) -> void:
	if speed < SOFTEST:
		return
	_kick(Vector3.DOWN * _tuning.land_dip * speed)
	if speed < _tuning.hard_landing:
		_step(_tuning.step_db + 3.0)
		return
	_thud.pitch_scale = _rng.randf_range(0.92, 1.05)
	_thud.volume_db = linear_to_db(clampf(speed / (_tuning.hard_landing * 2.0), 0.4, 1.0))
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


## The sand's hiss under you, `loud` 0 to 1, higher the nearer `fast` comes to 1.
func _sound_slide(loud: float, fast: float, delta: float) -> void:
	_hiss = _ease(_hiss, loud, 0.08, delta)
	if _hiss < 0.01:
		_slide.stream_paused = true
		return
	_slide.volume_db = _tuning.slide_db + linear_to_db(_hiss)
	_slide.pitch_scale = 0.85 + 0.35 * clampf(fast, 0.0, 1.0)
	_slide.stream_paused = false
	if not _slide.playing:
		_slide.play(_rng.randf() * 2.0)


## A slide throws sand up ahead of your feet and off to the sides, under the
## moon's own gravity, so at 0.45 g it hangs.
func _throw_sand(sliding: bool, own: Vector2, speed: float) -> void:
	_grains(SLIDE_GRAINS)
	_spray.emitting = sliding and speed > 0.8
	if not _spray.emitting:
		return
	var heading := Vector3(own.x, 0.0, own.y) / speed
	_spray.color = Color.WHITE
	_spray.emission_box_extents = Vector3(0.3, 0.02, 0.3)
	_spray.scale_amount_max = 0.04 + 0.04 * clampf(speed / FAST, 0.0, 1.0)
	_spray.global_transform = Transform3D(Basis.IDENTITY, _player.global_position + heading * 0.45 + Vector3.UP * 0.05)
	_spray.direction = (heading * 0.4 + Vector3.UP).normalized()
	_spray.spread = 45.0
	_spray.initial_velocity_min = 0.5 + speed * 0.15
	_spray.initial_velocity_max = 1.0 + speed * 0.3
	_spray.gravity = Vector3.DOWN * _player.world.gravity


## How hard a dug edge throws sand, 0 to 1: deeper and faster, and most
## dragged across.
func _grit(ride: Ride) -> float:
	var v := ride.velocity
	var speed := v.length()
	var across := absf(sin(v.angle_to(ride.ahead))) if speed > 0.05 else 0.0
	return ride.dig * clampf(speed / GRIT_FAST, 0.0, 1.0) * lerpf(0.6, 1.0, across)


## A dug edge throws a rooster tail of sand up off its length and outward,
## away from where it pulls the board; left behind as you go, it streams out
## after you.
func _dig_sand(ride: Ride, grit: float) -> void:
	_grains(TAIL_GRAINS)
	_spray.emitting = grit > 0.03
	if not _spray.emitting:
		return
	var pose := ride.board_pose(true)
	var low := signf(ride.tilt(true).z)
	if low == 0.0:
		low = 1.0
	var size: Vector3 = Catalog.DEVICES[&"board"].size
	var nose := Vector3(pose.basis.z.x, 0.0, pose.basis.z.z).normalized()
	var flat := Basis(Vector3.UP.cross(nose).normalized(), Vector3.UP, nose)
	_spray.global_transform = Transform3D(flat, pose * Vector3(low * size.x * 0.5, -size.y * 0.5, 0.0))
	_spray.emission_box_extents = Vector3(0.03, 0.02, size.z * 0.4)
	_spray.direction = Vector3(-low * 0.8, 1.0, 0.2).normalized()
	_spray.spread = 25.0
	_spray.color = Color(1.0, 1.0, 1.0, lerpf(0.5, 1.6, grit))
	_spray.scale_amount_max = 0.05 + 0.09 * grit
	var speed := ride.velocity.length()
	_spray.initial_velocity_min = (1.0 + 0.15 * speed) * grit
	_spray.initial_velocity_max = (2.0 + 0.3 * speed) * grit
	_spray.gravity = Vector3.DOWN * _player.world.gravity


## The spray's grains: setting how many starts it over, so only on a change.
func _grains(amount: int) -> void:
	if _spray.amount != amount:
		_spray.amount = amount


func _voice(stream: AudioStream) -> AudioStreamPlayer:
	var voice := AudioStreamPlayer.new()
	voice.stream = stream
	voice.bus = Sounds.WORLD
	add_child(voice)
	return voice


## Soft grains of the sand's own colour, thrown from across your width, that
## fade as they fall.
func _sand(amount: int, lifetime: float, burst: bool) -> CPUParticles3D:
	var sand := CPUParticles3D.new()
	sand.amount = amount
	sand.lifetime = lifetime
	sand.one_shot = burst
	sand.explosiveness = 1.0 if burst else 0.0
	sand.emitting = false
	sand.local_coords = false
	sand.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	sand.emission_box_extents = Vector3(0.3, 0.02, 0.3)
	sand.direction = Vector3.UP
	sand.spread = 80.0 if burst else 45.0
	sand.initial_velocity_min = 0.6
	sand.initial_velocity_max = 1.6
	sand.scale_amount_min = 0.02
	sand.scale_amount_max = 0.1 if burst else 0.05
	var fade := Gradient.new()
	fade.set_color(0, Color(_tuning.sand_color, 0.5))
	fade.set_color(1, Color(_tuning.sand_color, 0.0))
	sand.color_ramp = fade
	var round := Gradient.new()
	round.set_color(0, Color.WHITE)
	round.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	var dot := GradientTexture2D.new()
	dot.gradient = round
	dot.fill = GradientTexture2D.FILL_RADIAL
	dot.fill_from = Vector2(0.5, 0.5)
	dot.fill_to = Vector2(0.5, 0.0)
	dot.width = 32
	dot.height = 32
	var grain := QuadMesh.new()
	var look := StandardMaterial3D.new()
	look.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	look.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	look.vertex_color_use_as_albedo = true
	look.albedo_texture = dot
	grain.material = look
	sand.mesh = grain
	sand.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sand)
	return sand


static func _ease(from: float, to: float, seconds: float, delta: float) -> float:
	return to + (from - to) * exp(-delta / seconds)
