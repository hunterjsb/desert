class_name Feel
extends Node3D
## How moving feels: the head's bob and sway, a spring on footfalls, landings
## and changes of pace, a lean into strong wind with gusts nudging it, a wider
## view at speed, footsteps, and a slide's hiss and spray; on a board, your
## view leaning as the board under you does, a dug edge's or a skid's rooster
## tail of sand and its hiss, a shake as the edge bites, a jar as a landing
## slams, a harder one as you're thrown off and a knock if you hit something,
## then your view tumbling over the sand with you, a thud and a burst of sand
## each time you hit it, till you're up again; a shake while lines wrench you
## past what your body takes, the ground's own trembling near a live vent
## (Rumbles), and your view smoothed between ticks, which at its speed would
## otherwise stutter. It reads the
## player and never writes to it, so none of it can change where you go: it
## moves only the camera, and makes only sound and dust.

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
## The share of a board's lean your view leans with it, as you see it: into
## a carve and across the sand.
const BANK_SHARE := 0.35
## A dug edge this fast across or along the sand, m/s, throws all it can.
const GRIT_FAST := 12.0
## Grains a dug edge's rooster tail has in the air at once, and the share of
## the board's way the sand it throws carries.
const TAIL_GRAINS := 192
const TAIL_CARRY := 0.85
## How far a shake throws your view at its hardest, m and radians, and how
## fast it dies away, s; an edge biting shakes it this share of that.
const SHAKE_REACH := 0.035
const SHAKE_ROLL := 0.03
const SHAKE_SECONDS := 0.18
const BITE_SHAKE := 0.35
## A landing at its jar shakes your view this share of the hardest.
const JAR_SHAKE := 0.7
## How far the ground trembling at its hardest moves your view, m, tips it
## and rolls it, radians: slower and lower than a jolt's shake.
const TREMBLE_REACH := 0.02
const TREMBLE_PITCH := 0.008
const TREMBLE_ROLL := 0.006
## Tumbling (Tumble): down on the sand your eyes are this high over it, m;
## your view rolls with your body no further than ROLL_MOST, and pitches into
## the sand as far as PITCH_MOST as you go face down, radians, so it never
## turns over however you do; a hit this hard, m/s, thuds and throws the most.
const LYING_EYE := 0.25
const ROLL_MOST := deg_to_rad(75.0)
const PITCH_MOST := deg_to_rad(60.0)
const TUMBLE_HARD := 8.0
## A hit's sand is thrown up this far ahead of you, m, along your way, and
## carries this share of it, so it flies on ahead rather than in your eyes.
const BURST_AHEAD := 0.8
const BURST_CARRY := 0.7

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
var _knock: AudioStreamPlayer
var _spray: CPUParticles3D
var _tail: CPUParticles3D
var _puff: CPUParticles3D
## A tumble's thuds and bursts of sand, taken in turn so one never cuts the
## last short, and the hits so far; its pitch on top of where you look, and
## the pitch as this left it, so one set from outside (a respawn, a load)
## is taken as where you look.
var _bumps: Array[AudioStreamPlayer] = []
var _bursts: Array[CPUParticles3D] = []
var _hits := 0
var _pitched := 0.0
var _pitch_left := 0.0


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
	_knock = _voice(Sounds.BOARD_KNOCK)
	_spray = _sand(64, 0.8, false)
	_tail = _sand(TAIL_GRAINS, 0.8, false)
	_tail.spread = 20.0
	# It thickens just off the edge, so grains riding along with the board
	# never show as a sheet beside it.
	_tail.color_ramp.add_point(0.15, Color(_tuning.sand_color, 0.5))
	_tail.color_ramp.set_color(0, Color(_tuning.sand_color, 0.0))
	_puff = _sand(32, 0.7, true)
	for i in 2:
		_bumps.append(_voice(Sounds.TUMBLE[i]))
		_bursts.append(_sand(64, 0.9, true))
		_bursts[i].emission_box_extents = Vector3(0.5, 0.05, 0.5)
	_player.landed.connect(_on_landed)
	_player.tumbled.connect(_on_tumbled)
	_player.jumped.connect(_on_jumped)
	_player.edge_bit.connect(_on_edge_bit)
	_player.wiped_out.connect(_on_wiped_out)
	_player.touched_down.connect(_on_touched_down)
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
		_tail.emitting = false
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
	if _player.vault.active:
		between = to_you * -_player.vault.last_step * (1.0 - Engine.get_physics_interpolation_fraction())
	if ride != null:
		between = to_you * -ride.last_step * (1.0 - Engine.get_physics_interpolation_fraction())
	_bank = _ease(_bank, _view_lean(ride, to_you) if ride != null else 0.0, EYE_SECONDS, delta)
	var tumble := _player.tumble
	var tumbled := _tumble_view(tumble)
	if tumble != null:
		between = to_you * -tumble.last_step * (1.0 - Engine.get_physics_interpolation_fraction())

	var sliding := _player.mode == "slide" or (tumble != null and tumble.ploughing())
	# The sand judders through you on a fast slide.
	var judder := Vector3(sin(_clock * 41.0), sin(_clock * 53.0 + 1.3), 0.0) * 0.003 \
		* clampf(speed / FAST, 0.0, 1.0) if sliding else Vector3.ZERO
	_shake *= exp(-delta / SHAKE_SECONDS)
	var ropes := _player.world.ropes
	if ropes != null and ropes.wrench_n > t.fulcrum_n:
		_shake = maxf(_shake, BITE_SHAKE * clampf(ropes.wrench_n / t.fulcrum_n - 1.0, 0.2, 1.0))
	var shake := Vector3(sin(_clock * 67.0), sin(_clock * 79.0 + 0.7), 0.0) * SHAKE_REACH * _shake
	camera.position = _rest + bob + _spring + _lean + judder + shake + Vector3.DOWN * maxf(_drop, tumbled.x) + between
	camera.rotation.z = roll + _roll + _bank + tumbled.y + sin(_clock * 59.0 + 2.1) * SHAKE_ROLL * _shake
	var tip := _tremble(camera)
	var looked := camera.rotation.x - (_pitched if is_equal_approx(camera.rotation.x, _pitch_left) else 0.0)
	_pitched = tumbled.z + tip
	camera.rotation.x = looked + _pitched
	_pitch_left = camera.rotation.x
	camera.fov = _fov + _widen
	var grit := _grit(ride) if ride != null else (clampf(speed / FAST * 1.5, 0.15, 1.0) if sliding and speed > 0.3 else 0.0)
	_sound_slide(grit, speed / (t.board_top_speed if ride != null else FAST), delta)
	_throw_sand(sliding and ride == null, own, speed)
	_dig_sand(ride, grit)


## The ground trembling under you near a live vent: your view moved and
## rolled by a few slow waves together, on top of everything else; and how
## far they tip it, radians, which goes on your look with the tumble's pitch.
func _tremble(camera: Camera3D) -> float:
	var weather := _player.world.weather
	var amount := weather.rumbles.tremble if weather != null and weather.rumbles != null else 0.0
	var c := _clock
	camera.position += Vector3(sin(c * 23.0 + 0.4) + 0.5 * sin(c * 37.0), sin(c * 29.0) + 0.5 * sin(c * 43.0 + 1.1),
		0.0) * TREMBLE_REACH * amount
	camera.rotation.z += (sin(c * 31.0 + 0.9) + 0.4 * sin(c * 47.0)) * TREMBLE_ROLL * amount
	return (sin(c * 27.0 + 2.0) + 0.5 * sin(c * 41.0)) * TREMBLE_PITCH * amount


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


## How far your view leans with the board under you, radians: as you see it
## from where you look, so a board across your way leans your view less.
func _view_lean(ride: Ride, to_you: Basis) -> float:
	var up := to_you * ride.board_pose(true).basis.y
	return -atan2(up.x, up.y) * BANK_SHARE


## How far a tumble drops, rolls and pitches your view: down onto the sand
## as you go over, rolled with your body and into the sand face down, and
## righted as you get up.
func _tumble_view(tumble: Tumble) -> Vector3:
	if tumble == null:
		return Vector3.ZERO
	var at := tumble.view(true)
	var held := 1.0 - smoothstep(0.0, 1.0, at.z)
	return Vector3((_rest.y - LYING_EYE) * smoothstep(0.0, 1.0, at.y) * held, -ROLL_MOST * sin(at.x) * held,
		-PITCH_MOST * maxf(0.0, -cos(at.x)) * held)


## Tumbling, you hit the sand: a thud by how hard, a burst of sand thrown up
## ahead of you and a jolt through your view.
func _on_tumbled(speed: float) -> void:
	var hard := clampf(speed / TUMBLE_HARD, 0.25, 1.0)
	_shake = maxf(_shake, hard)
	_kick(Vector3.DOWN * MOST_KICK * hard)
	var bump := _bumps[_hits % 2]
	bump.pitch_scale = _rng.randf_range(0.9, 1.1)
	bump.volume_db = linear_to_db(hard)
	bump.play()
	var burst := _bursts[_hits % 2]
	var way := Vector3(_player.own.x, 0.0, _player.own.y)
	var ahead := way.normalized() if way.length() > 0.5 else -_player.global_basis.z
	burst.global_position = _player.global_position + ahead * BURST_AHEAD + Vector3.UP * 0.1
	burst.direction = (ahead * 0.6 + Vector3.UP).normalized()
	burst.initial_velocity_min = 1.0 + 1.5 * hard + way.length() * BURST_CARRY * 0.8
	burst.initial_velocity_max = 2.0 + 3.0 * hard + way.length() * BURST_CARRY * 1.2
	burst.scale_amount_max = 0.06 + 0.08 * hard
	burst.gravity = Vector3.DOWN * _player.world.gravity
	burst.restart()
	_hits += 1


## The edge bit: a small shake, harder the faster you go.
func _on_edge_bit(speed: float) -> void:
	_shake = maxf(_shake, BITE_SHAKE * clampf(speed / _tuning.board_top_speed, 0.4, 1.0))


## Thrown off: a hard shake, a lurch and a thud into the sand; off something
## you hit, a knock as you meet it and the head thrown on.
func _on_wiped_out(speed: float, how: StringName) -> void:
	_shake = 1.0
	_kick((Vector3(0.0, -0.5, -1.0) if how == &"crash" else Vector3(0.0, -1.0, -0.5)) * speed)
	_thud.pitch_scale = _rng.randf_range(0.85, 0.95)
	_thud.volume_db = 0.0
	_thud.play()
	if how == &"crash":
		_knock.pitch_scale = _rng.randf_range(0.9, 1.05)
		_knock.volume_db = linear_to_db(clampf(speed / (_tuning.board_crash * 2.0), 0.5, 1.0))
		_knock.play()
	_puff.global_position = _player.global_position + Vector3.UP * 0.1
	_puff.gravity = Vector3.DOWN * _player.world.gravity
	_puff.restart()


## The board met the sand after flying: a dip as it presses, and past half
## its jar a shake, at its jar a hard one and a burst of sand.
func _on_touched_down(speed: float) -> void:
	var ride := _player.ride
	var sturdy: float = ride.make.sturdy if ride != null else 1.0
	var hard := speed / (_tuning.board_land_jar * sturdy)
	_kick(Vector3.DOWN * _tuning.land_dip * speed)
	if hard < 0.5:
		return
	_shake = maxf(_shake, JAR_SHAKE * clampf(hard, 0.0, 1.0))
	if hard >= 1.0:
		_puff.global_position = _player.global_position + Vector3.DOWN * 0.3
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
	_spray.emitting = sliding and speed > 0.8
	if not _spray.emitting:
		return
	var heading := Vector3(own.x, 0.0, own.y) / speed
	_spray.scale_amount_max = 0.04 + 0.04 * clampf(speed / FAST, 0.0, 1.0)
	_spray.global_position = _player.global_position + heading * 0.45 + Vector3.UP * 0.05
	_spray.direction = (heading * 0.4 + Vector3.UP).normalized()
	_spray.initial_velocity_min = 0.5 + speed * 0.15
	_spray.initial_velocity_max = 1.0 + speed * 0.3
	_spray.gravity = Vector3.DOWN * _player.world.gravity


## How hard a dug edge or a slide throws sand, 0 to 1: deeper and faster,
## and most dragged across; a skid, a drift or a landing's slide as hard as
## it slides across, on the sand.
func _grit(ride: Ride) -> float:
	var v := ride.velocity
	var speed := v.length()
	var across := absf(sin(v.angle_to(ride.ahead))) if speed > 0.05 else 0.0
	var fast := clampf(speed / GRIT_FAST, 0.0, 1.0)
	var dug := ride.dig * fast * lerpf(0.6, 1.0, across)
	var sliding := ride.skidding or ride.drifting or ride.loose > 0.1
	return maxf(dug, across * fast if sliding and ride.gap < Ride.AIR_FROM else 0.0)


## A dug edge or a slide throws a rooster tail of sand up off its length and
## outward, away from where it pulls the board, carrying most of the board's
## way: in a carve it rises off the edge and falls behind, in a stop it flies
## on ahead. It's the slide's spray, thicker the harder it digs or slides.
func _dig_sand(ride: Ride, grit: float) -> void:
	_tail.emitting = ride != null and grit > 0.03
	if not _tail.emitting:
		return
	var pose := ride.board_pose(true)
	var low := signf(ride.tilt(true).z)
	if low == 0.0:
		low = 1.0
	var size: Vector3 = Catalog.DEVICES[&"board"].size
	var back := Vector3(pose.basis.z.x, 0.0, pose.basis.z.z).normalized()
	var flat := Basis(Vector3.UP.cross(back).normalized(), Vector3.UP, back)
	_tail.global_transform = Transform3D(flat, pose * Vector3(low * size.x * 0.5, -size.y * 0.5, 0.0))
	_tail.emission_box_extents = Vector3(0.03, 0.02, size.z * 0.25)
	var speed := ride.velocity.length()
	var way := flat.inverse() * Vector3(ride.velocity.x, 0.0, ride.velocity.y)
	var thrown := Vector3(-low * 0.6, 1.0, 0.25).normalized() * (2.0 + 0.4 * speed) * grit + way * TAIL_CARRY
	_tail.direction = thrown.normalized()
	_tail.initial_velocity_min = thrown.length() * 0.7
	_tail.initial_velocity_max = thrown.length() * 1.2
	_tail.color = Color(1.0, 1.0, 1.0, grit)
	_tail.scale_amount_max = 0.03 + 0.12 * grit
	_tail.gravity = Vector3.DOWN * _player.world.gravity


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
	# Thin dust lets the sun through: against it, grains glow rather than go grey.
	look.backlight_enabled = true
	look.backlight = Color(_tuning.sand_color * 0.7)
	grain.material = look
	sand.mesh = grain
	sand.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sand)
	# A grain never yet thrown draws as an opaque black square at the emitter,
	# so a steady spray throws one lifetime of them far out of sight first.
	if not burst:
		sand.position = Vector3.DOWN * 1000.0
		sand.preprocess = lifetime * 1.2
		sand.restart()
		sand.emitting = false
		sand.preprocess = 0.0
	return sand


static func _ease(from: float, to: float, seconds: float, delta: float) -> float:
	return to + (from - to) * exp(-delta / seconds)
