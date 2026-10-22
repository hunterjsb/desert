class_name Streamer
extends Device
## A wind streamer: a strip of cloth on a short wand. It streams downwind of
## the air it feels, flapping harder and faster as that blows harder, and
## hangs limp in a calm. It feels the air less its own way, so stuck on a
## rig or a mast it shows the air the rig sails through, a telltale to trim
## by; in your hand or your suit, the air where you are. The anemometer is
## the one that gives numbers.

## The cloth's pieces, from the wand's tip out, each this long, m.
const PIECES := 7
const PIECE := 0.09
const WIDE := 0.05
## How far its flap's wave lags from piece to piece down the cloth, rad.
const LAG := 0.8

## The air it streams in now, flat, m/s, and how far through a flap it is.
var air := Vector3.ZERO
var _phase := 0.0
var _cloth: Array[MeshInstance3D] = []


func _ready() -> void:
	super()
	_build_cloth()


## Where the cloth hangs from: the wand's tip, in its own frame.
func tip() -> Vector3:
	return Vector3(0.0, Catalog.DEVICES[&"streamer"].size.y * 0.5, 0.0)


func _process(delta: float) -> void:
	if world == null or _cloth.is_empty():
		return
	var at := global_transform * tip()
	air = world.weather.felt_wind(at) - _moving(at)
	air.y = 0.0
	var speed := air.length()
	var tuning := world.tuning
	_phase = fmod(_phase + TAU * (tuning.streamer_flap_hz.x + tuning.streamer_flap_hz.y * speed) * delta, TAU)
	pose(speed, air / speed if speed > 0.01 else Vector3.ZERO, _phase)


## Lays the cloth out from the tip: drooping toward hanging in light air,
## out along `way` (world, flat) as it blows, a wave running down it.
func pose(speed: float, way: Vector3, phase: float) -> void:
	var back := global_basis.orthonormalized().inverse()
	var down := back * Vector3.DOWN
	var out := back * way if way != Vector3.ZERO else down
	var feels := Tuning.current().streamer_air
	var stands := smoothstep(feels.x, feels.y, speed)
	var swing := clampf(speed / feels.z, 0.0, 1.0)
	var side := out.cross(back * Vector3.UP)
	side = side.normalized() if side.length() > 1e-3 else back * Vector3.RIGHT
	var at := tip()
	for i in _cloth.size():
		var share := float(i + 1) / _cloth.size()
		var wave := sin(phase - LAG * i) * swing * share
		var dir := down.slerp(out, stands).normalized()
		dir = (dir + side * wave * 0.9 + down * absf(wave) * 0.25 * (1.0 - stands)).normalized()
		var flat := (back * Vector3.UP).cross(dir)
		flat = flat.normalized() if flat.length() > 1e-3 else side
		var piece := _cloth[i]
		piece.transform = Transform3D(Basis(flat, dir, flat.cross(dir)).orthonormalized(), at + dir * PIECE * 0.5)
		at += dir * PIECE


## Its own way through the air: what it's on carries it, or you do.
func _moving(at: Vector3) -> Vector3:
	var on := host()
	while on != null and on.host() != null:
		on = on.host()
	if on != null:
		return on.linear_velocity + on.angular_velocity.cross(at - on.global_transform * on.center_of_mass)
	var player := world.player
	if player != null and (get_parent() == player or player.hands.held == self):
		return player.velocity
	return linear_velocity


func _build_cloth() -> void:
	var look := NomadLooks.cloth()
	for i in PIECES:
		var piece := MeshInstance3D.new()
		piece.mesh = look
		piece.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(piece)
		_cloth.append(piece)
	pose(0.0, Vector3.ZERO, 0.0)


## The cloth, for the inventory to draw it as it streams.
func cloth() -> Array[MeshInstance3D]:
	return _cloth
