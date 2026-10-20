class_name Airdrop
extends Node3D
## The Surveyor's care-package cannon (gonkhub, 2026-10-20: "give the
## agricultural survey craft a care-package cannon for firing supplies down
## to the moon's surface ... if the player lights the signal flare during the
## Surveyor's pass overhead, it will fire the cannon (this should be both
## heard and seen at distance), sending a cargo container crashing into the
## surface near the flare's location ... sand kicked up in a cloud, a smooth
## lerp from sky to ground, and correct angular velocity coming from where the
## surveyor was when it fired the cargo").
##
## The Surveyor is the low crop-survey craft (Constellation &"thermal"). Fired:
## its muzzle flashes in the sky where it is, and the boom comes from there
## as long after as sound takes to cross the distance. The container leaves
## the muzzle carrying the craft's own way, then curves down on a smooth
## path (a quadratic Bezier from the muzzle, through a point the craft's
## motion carries it toward, to the ground near the flare), eased so it
## gathers speed as it falls, a smoke trail behind it and a red beacon on it
## you can follow from far off. It tumbles end over end in the plane it falls
## through, rolling away from where the craft was. Down, it hits: a cloud of
## sand thrown up, a ring of it out along the ground, an impact boom, and the
## container a body again, keeping its roll, its beacon still blinking.
## A node of the world's content, at where the container comes down, so the
## floating origin carries the whole fall with it.

const SURVEYOR := &"thermal"
## The container keeps the craft's motion for this long, s, before it turns
## down: how far along the craft's way its curve bends.
const CARRY := 1.2
## Of the path's progress, this much is even, the rest gathering as it falls.
const EVEN := 0.35
## It tumbles this fast falling, rad/s, and keeps this much of it rolling on.
const SPIN := 2.6
const ROLL := 0.5
## Its speed at the ground, kept for its roll on: along the way it came, and down, m/s.
const SKID := 7.0
const DOWN := 3.0
## The muzzle's boom: as loud as this at a kilometre, dB, and played this far off
## you toward it, m, so it's heard from the craft's way.
const MUZZLE_AT_KM := 4.0
const AWAY := 20.0
## The impact's own boom and clang, dB, heard at their level this far, m.
const IMPACT_DB := 4.0
const IMPACT_M := 30.0
## Its smoke trail's puffs, m, the least and most, as big as that from this
## high up, m, and down to this share of it near the ground.
const TRAIL_SIZE := Vector2(10.0, 22.0)
const TRAIL_FULL_M := 600.0
const TRAIL_LEAST := 0.1
## How long it lingers after the hit, s, for its sand to settle.
const SETTLE := 7.0

## The container falling, and when it was fired and lands, world time.
var cargo: Part
var fired_at := 0.0
var lands_at := 0.0
## Whether it has hit; and how it was moving and turning as it did, coming
## in (m/s) and as it was handed on to roll (rad/s).
var landed := false
var hit_velocity := Vector3.ZERO
var hit_spin := Vector3.ZERO

## The path, from this node (where it lands): the muzzle, the bend, the ground.
var _from := Vector3.ZERO
var _bend := Vector3.ZERO
## The axis it tumbles about, and its pose as it left the muzzle.
var _axis := Vector3.RIGHT
var _pose := Basis.IDENTITY
var _metres := 0.0
var _boomed := false
var _trail: CPUParticles3D
var _beacon: MeshInstance3D
var _world: World


## Where the Surveyor is from a place in the world at world time t, seen by
## you there: {up (how high, rad), metres (how far), at (its place in the
## engine's space), way (its velocity there, m/s)}.
static func surveyor(world: World, at: Vector3, t: float) -> Dictionary:
	var sky := Radio.constellation_of(world)
	var orbit: Satellite = sky.orbits[SURVEYOR]
	var moon := world.moon
	var p := Sphere.point(moon.latitude, moon.longitude)
	var place := func(u: float) -> Vector3:
		var to := orbit.at(u) - p
		return at + DayCycle.local(to.normalized(), moon.latitude, moon.longitude) * to.length() * orbit.radius
	var now: Vector3 = place.call(t)
	return {"up": orbit.seen_from(p, t).elevation, "metres": now.distance_to(at), "at": now,
		"way": place.call(t + 0.5) - place.call(t - 0.5)}


## Whether the Surveyor is passing high enough over a place at the world's
## time to fire at a flare there.
static func overhead(world: World, at: Vector3) -> bool:
	return surveyor(world, at, world.time).up >= deg_to_rad(world.tuning.airdrop_elevation_degrees)


## The cannon fired at a place, from wherever the Surveyor is now: the
## container on its way down near it. Says the drop.
static func fire(world: World, at: Vector3) -> Airdrop:
	var drop := Airdrop.new()
	drop._world = world
	var craft := surveyor(world, at, world.time)
	# It comes down short of the flare, toward the craft's side, a little either way.
	var toward := Vector3(craft.at.x - at.x, 0.0, craft.at.z - at.z)
	toward = toward.normalized() if toward.length() > 1.0 else Vector3.FORWARD
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([world.run_seed, "airdrop", roundi(world.time)])
	var land: Vector2 = world.tuning.airdrop_land_m
	var ground := at + toward.rotated(Vector3.UP, rng.randf_range(-0.7, 0.7)) * rng.randf_range(land.x, land.y)
	ground.y = world.height_under(ground)
	world.content.add_child(drop)
	drop.global_position = ground
	drop._launch(craft, world.time)
	return drop


func _launch(craft: Dictionary, t: float) -> void:
	fired_at = t
	lands_at = t + _world.tuning.airdrop_fall_seconds
	_metres = craft.metres
	_from = craft.at - global_position
	_bend = _from + craft.way * CARRY
	# It comes in from the bend's side: rolling on away from it, end over end.
	var coming := -_bend
	coming.y = 0.0
	coming = coming.normalized() if coming.length() > 0.01 else Vector3.FORWARD
	_axis = Vector3.UP.cross(coming).normalized()
	_pose = Basis.looking_at(-_from.normalized() if _from.length() > 0.01 else Vector3.DOWN, _axis)
	# The muzzle flashes in the sky where the craft is.
	Radio.constellation_of(_world).fire(SURVEYOR, t)
	cargo = Catalog.part(&"cargo")
	cargo.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	cargo.freeze = true
	add_child(cargo)
	cargo.position = _from
	_effects()
	_fly(t)


## Only effects: loading a drop must not fire the cannon or play an impact again.
func _effects() -> void:
	_beacon = _make_beacon()
	cargo.add_child(_beacon)
	_trail = puffs(260, 7.0, Color(0.36, 0.33, 0.3, 0.75), Color(0.5, 0.46, 0.42, 0.0), TRAIL_SIZE, false, true)
	# Seen through a kilometre or two of haze it would be gone: it's drawn clear of it.
	((_trail.mesh as QuadMesh).material as StandardMaterial3D).disable_fog = true
	_trail.initial_velocity_max = 0.6
	_trail.gravity = Vector3.ZERO
	add_child(_trail)
	_trail.emitting = true
	_trail.global_position = cargo.global_position


## State relative to the landing point, which Snapshot stores in world metres.
func memory() -> Dictionary:
	return {"fired_at": fired_at, "lands_at": lands_at, "landed": landed,
		"from": _from, "bend": _bend, "axis": _axis, "pose": _pose,
		"metres": _metres, "boomed": _boomed, "hit_velocity": hit_velocity, "hit_spin": hit_spin}


static func recall(world: World, body: Part, at: Transform3D, state: Dictionary) -> Airdrop:
	var drop := Airdrop.new()
	drop._world = world
	world.content.add_child(drop)
	drop.global_transform = at
	drop.cargo = body
	body.reparent(drop, true)
	drop.fired_at = state.fired_at
	drop.lands_at = state.lands_at
	drop.landed = state.landed
	drop._from = state.from
	drop._bend = state.bend
	drop._axis = state.axis
	drop._pose = state.pose
	drop._metres = state.metres
	drop._boomed = state.boomed
	drop.hit_velocity = state.hit_velocity
	drop.hit_spin = state.hit_spin
	drop._effects()
	drop._trail.emitting = not drop.landed
	return drop


## How far down its path it is at world time t, 0 at the muzzle to 1 on the
## ground: even at first, gathering as it falls.
func progress(t: float) -> float:
	var u := clampf((t - fired_at) / maxf(lands_at - fired_at, 0.01), 0.0, 1.0)
	return lerpf(u, u * u, 1.0 - EVEN)


## Its place on its path at progress s, from where it lands.
func along(s: float) -> Vector3:
	return _from * (1.0 - s) * (1.0 - s) + _bend * 2.0 * (1.0 - s) * s


## Which way it's moving at world time t, m/s.
func velocity(t: float) -> Vector3:
	return (to_global(along(progress(t + 0.05))) - to_global(along(progress(t - 0.05)))) / 0.1


func _process(_delta: float) -> void:
	if _world == null or not is_instance_valid(_world):
		return
	if not is_instance_valid(cargo) or cargo.get_parent() != self:
		queue_free()
		return
	var t := _world.time
	if _beacon != null:
		_beacon.visible = fmod(t, 1.0) < 0.5
	if not _boomed and t >= fired_at + _metres / _world.weather.rumbles.speed():
		_boomed = true
		_muzzle_boom()
	if not landed:
		if t >= lands_at:
			_hit(t)
		else:
			_fly(t)
	elif t >= lands_at + SETTLE:
		_let_go()


func _fly(t: float) -> void:
	var s := progress(t)
	cargo.position = along(s)
	cargo.basis = _pose.rotated(_axis, -SPIN * (t - fired_at)).orthonormalized()
	_trail.global_position = cargo.global_position
	# Its smoke big enough to see a kilometre up, and no bigger near the ground.
	var near := clampf(cargo.position.y / TRAIL_FULL_M, TRAIL_LEAST, 1.0)
	_trail.scale_amount_min = TRAIL_SIZE.x * near
	_trail.scale_amount_max = TRAIL_SIZE.y * near
	if _beacon != null:
		_beacon.visible = fmod(t, 1.0) < 0.5


func _hit(t: float) -> void:
	landed = true
	var coming := velocity(t - 0.1)
	_trail.emitting = false
	cargo.position = Vector3(0.0, 0.7, 0.0)
	var flat := Vector3(coming.x, 0.0, coming.z)
	flat = flat.normalized() if flat.length() > 0.01 else Vector3.ZERO
	cargo.freeze = false
	cargo.linear_velocity = flat * SKID + Vector3.DOWN * DOWN
	cargo.angular_velocity = _axis * SPIN * ROLL
	hit_velocity = coming
	hit_spin = cargo.angular_velocity
	# Sand thrown up in a cloud, and a ring of it out along the ground.
	var sand := _world.tuning.sand_color
	var cloud := puffs(420, 6.5, Color(sand, 0.85), Color(sand, 0.0), Vector2(3.0, 9.0), true, true)
	cloud.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	cloud.emission_sphere_radius = 1.2
	cloud.direction = Vector3.UP + flat * 0.5
	cloud.spread = 55.0
	cloud.initial_velocity_min = 3.0
	cloud.initial_velocity_max = 13.0
	cloud.damping_min = 2.5
	cloud.damping_max = 4.5
	cloud.gravity = Vector3(0.0, -1.2, 0.0)
	# Each puff swells as it rises and thins.
	var swell := Curve.new()
	swell.add_point(Vector2(0.0, 0.35))
	swell.add_point(Vector2(0.4, 0.85))
	swell.add_point(Vector2(1.0, 1.0))
	cloud.scale_amount_curve = swell
	var ring := puffs(220, 4.0, Color(sand, 0.75), Color(sand, 0.0), Vector2(1.5, 4.0), true, true)
	ring.direction = Vector3.UP
	ring.spread = 88.0
	ring.initial_velocity_min = 2.0
	ring.initial_velocity_max = 4.0
	ring.radial_accel_min = 14.0
	ring.radial_accel_max = 22.0
	ring.damping_min = 5.0
	ring.damping_max = 8.0
	ring.gravity = Vector3(0.0, -3.0, 0.0)
	for burst: CPUParticles3D in [cloud, ring]:
		add_child(burst)
		burst.position = Vector3(0.0, 0.3, 0.0)
		burst.restart()
	Sounds.play_at(self, Sounds.BOOM, IMPACT_DB, IMPACT_M)
	Sounds.play_at(self, Sounds.CLANG, IMPACT_DB - 4.0, IMPACT_M * 0.5)
	Sounds.play_at(self, Sounds.LANDING, IMPACT_DB - 2.0, IMPACT_M * 0.5)


## The cannon's boom, from the craft's way, as loud as its distance allows.
func _muzzle_boom() -> void:
	var camera := _world.player.camera.global_position
	var muzzle := to_global(_from)
	var voice := Sounds.world_voice(Sounds.BOOM, MUZZLE_AT_KM - 20.0 * log(maxf(_metres, 100.0) / 1000.0) / log(10.0),
		1.0)
	voice.attenuation_model = AudioStreamPlayer3D.ATTENUATION_DISABLED
	voice.doppler_tracking = AudioStreamPlayer3D.DOPPLER_TRACKING_DISABLED
	voice.max_db = 6.0
	voice.pitch_scale = 0.8
	voice.autoplay = true
	voice.finished.connect(voice.queue_free)
	_world.content.add_child(voice)
	voice.global_position = camera + (muzzle - camera).normalized() * AWAY


## Down and settled: the container stays in the world, beacon and all; the rest goes.
func _let_go() -> void:
	var pose := cargo.global_transform
	var keep := cargo.linear_velocity
	var spin := cargo.angular_velocity
	remove_child(cargo)
	_world.content.add_child(cargo)
	cargo.global_transform = pose
	cargo.linear_velocity = keep
	cargo.angular_velocity = spin
	queue_free()


## A blinking red beacon, the same size on screen however far, so a falling
## container can be followed down from the sky.
func _make_beacon() -> MeshInstance3D:
	var light := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.025, 0.025)
	var look := StandardMaterial3D.new()
	look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	look.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	look.fixed_size = true
	look.no_depth_test = false
	look.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	look.albedo_color = Color(1.0, 0.2, 0.12)
	look.albedo_texture = _dot()
	quad.material = look
	light.mesh = quad
	light.position = Vector3(0.0, 0.0, Catalog.PARTS[&"cargo"].size.z + 0.05)
	return light


## Soft round puffs of colour, fading as they go: for smoke, sparks and sand.
## `size` is their least and most, m; a burst throws them all at once.
## Lit, they take the light the sand and sky do: smoke and dust; unlit, they glow: sparks.
static func puffs(amount: int, lifetime: float, from: Color, to: Color, size: Vector2, burst: bool,
		lit := false) -> CPUParticles3D:
	var made := CPUParticles3D.new()
	made.amount = amount
	made.lifetime = lifetime
	made.one_shot = burst
	made.explosiveness = 1.0 if burst else 0.0
	made.emitting = false
	made.local_coords = false
	made.direction = Vector3.UP
	made.spread = 45.0
	made.initial_velocity_min = 0.2
	made.initial_velocity_max = 1.0
	made.scale_amount_min = size.x
	made.scale_amount_max = size.y
	var fade := Gradient.new()
	fade.set_color(0, from)
	fade.set_color(1, to)
	made.color_ramp = fade
	var grain := QuadMesh.new()
	var look := StandardMaterial3D.new()
	look.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	# Each puff as big as it's thrown: a billboard drops its scale otherwise.
	look.billboard_keep_scale = true
	look.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	look.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL if lit else BaseMaterial3D.SHADING_MODE_UNSHADED
	look.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	look.vertex_color_use_as_albedo = true
	look.albedo_texture = _dot()
	grain.material = look
	made.mesh = grain
	return made


static func _dot() -> GradientTexture2D:
	var falling_off := Gradient.new()
	falling_off.set_color(0, Color.WHITE)
	falling_off.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	var dot := GradientTexture2D.new()
	dot.gradient = falling_off
	dot.fill = GradientTexture2D.FILL_RADIAL
	dot.fill_from = Vector2(0.5, 0.5)
	dot.fill_to = Vector2(0.5, 0.0)
	dot.width = 32
	dot.height = 32
	return dot
