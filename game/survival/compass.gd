class_name Compass
extends Part
## A compass: its needle lines up with Tu's field, which along the axis Tu and
## Zan share points to the moon's north as you've walked it, so past a pole it
## turns round with the moon (MoonPosition). The field is weak: the needle is
## slow to settle, swings when its case turns, sways once each turn of Tu, and
## swims in a storm's charged dust and over old volcanic ground. It can't know
## Tu-ward. Read it in your hand, held up or flat, or in the inventory. Its
## needle glows, so it reads at night and in a storm, when the sun can't tell you.

## Where the needle turns, above its card.
const PIVOT := Vector3(0.0, 0.0, 0.034)
## Its swing is worked in steps no longer than this, s, nor than this share
## of a radian of its swing; after longer than SETTLED unread it has long
## since settled.
const STEP := 1.0 / 60.0
const STEADY := 0.25
const SETTLED := 10.0

var needle: MeshInstance3D
var _world: World
## Where its north tip lies, a bearing on the ground (north -z), and how fast
## it's swinging, rad/s; when it was last read and where its case's top lay.
var _bearing := NAN
var _swing := 0.0
var _read_at := 0.0
var _case := 0.0


func _enter_tree() -> void:
	_world = World.of(self)


func _process(_delta: float) -> void:
	if _world != null and needle != null:
		needle.transform = pose(needle_on(global_basis, _world))


## Where its needle lies on a card facing out along `face`'s +Z, rad
## clockwise from the card's top: swung on to the world's time from when it
## was last read, Tu's field pulling it round and the liquid dragging it with
## the case. In your hands or carried, off the ground, it's where you are.
func needle_on(face: Basis, world: World) -> float:
	var t := world.time
	var at := global_position if is_inside_tree() else world.player.global_position
	var case := -turn(face, Vector3.FORWARD)
	if is_nan(_bearing) or t < _read_at or t - _read_at > SETTLED:
		_bearing = field_bearing(world, at, t)
		_swing = 0.0
	elif t > _read_at:
		var tuning := world.tuning
		var natural := TAU / tuning.compass_swing_seconds
		var steps := ceili((t - _read_at) / minf(STEP, STEADY / natural))
		var dt := (t - _read_at) / steps
		var dragged := angle_difference(_case, case) / (t - _read_at)
		var target := field_bearing(world, at, t)
		for i in steps:
			var pull := natural * natural * angle_difference(_bearing, target)
			_swing += (pull - 2.0 * tuning.compass_damping * natural * (_swing - dragged)) * dt
			_bearing += _swing * dt
	_read_at = t
	_case = case
	return turn(face, Vector3(sin(_bearing), 0.0, -cos(_bearing)))


## The way Tu's field lies at a place, a bearing on the ground: the moon's
## north, swayed by the field's tilt as Tu turns, swum by a storm's charged
## dust, and turned by the ground's own magnetism.
static func field_bearing(world: World, at: Vector3, t: float) -> float:
	var tuning := world.tuning
	var north := world.moon.north()
	var bearing := atan2(north.x, -north.z) + deg_to_rad(tuning.compass_sway_degrees) * sin(world.weather.day.tu_turn(t))
	var storm := world.weather.field_storm(at, t)
	if storm > 0.0:
		var phase := float(world.run_seed % 997)
		bearing += deg_to_rad(tuning.compass_storm_degrees) * storm * (0.6 * sin(t * 0.83 + phase)
			+ 0.4 * sin(t * 2.17 + phase * 1.7))
	return bearing + ground_deviation(world, at)


## How far old volcanic ground's own magnetism turns the field at a place,
## rad clockwise: none until the geology says where that ground lies.
static func ground_deviation(_world: World, _at: Vector3) -> float:
	return 0.0


## The needle on its pivot, turned `angle` rad clockwise from the card's top.
static func pose(angle: float) -> Transform3D:
	return Transform3D(Basis(Vector3.BACK, -angle), PIVOT)


## How far clockwise from the card's top a way on the ground lies, rad, on a
## card facing out along `face`'s +Z: as it would lie with the compass tipped
## level, so one held up to read shows north ahead as straight up, as one held
## flat does with its top ahead.
static func turn(face: Basis, way: Vector3) -> float:
	var out := face.z.normalized()
	var level := Basis.IDENTITY
	var axis := out.cross(Vector3.UP)
	if axis.length() > 1e-4:
		level = Basis(axis.normalized(), out.angle_to(Vector3.UP))
	elif out.y < 0.0:
		level = Basis(face.x.normalized(), PI)
	return atan2(way.dot(level * face.x), way.dot(level * face.y))
