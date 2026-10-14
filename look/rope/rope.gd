class_name Rope
extends RefCounted
## One rope: a single constraint that does all the holding, and the strand that
## draws it. Both use `length`. Slack below it; past it, a spring defined by how
## fast it springs back and how much it bounces, solved from both ends' masses
## with Catto's soft step, so it can only take energy out. A hard stop sits at
## max_stretch. Tension pulls both ends equally, at the attachment points.

## The hard stop's own softness: stiff enough to read as a wall, soft enough
## that hitting it never kicks back.
const STOP_HERTZ := 20.0
const STOP_DAMPING := 1.0

var a: RopeEnd
var b: RopeEnd
var length: float
## Springs back this many times a second when stretched, whatever hangs on it.
var frequency := 3.0
## 1 settles without bouncing; below 1 it bounces.
var damping := 0.7
## Share of length it stretches before the hard stop.
var max_stretch := 0.1
## Newtons of sustained load that snap it.
var breaking := 1500.0

## Pull this tick, and the load sustained long enough to break things, N.
var tension := 0.0
var sustained := 0.0
var strand: RopeStrand
var creak: AudioStreamPlayer3D

## Solver state for this tick, owned by Ropes.
var body_a: RopeBody
var body_b: RopeBody
var normal := Vector3.UP
var point_a := Vector3.ZERO
var point_b := Vector3.ZERO
var stretch := 0.0
## Spring and stop impulses, N·s. Kept between ticks to warm-start the next.
var spring_impulse := 0.0
var stop_impulse := 0.0

var _ra := Vector3.ZERO
var _rb := Vector3.ZERO
var _turn_a := Vector3.ZERO
var _turn_b := Vector3.ZERO
var _mass := 0.0
var _beyond := 0.0
var _h := 1.0 / 60.0
var _soft := Vector3.ZERO
var _stop := Vector3.ZERO


## Catto's soft step for a spring of this frequency and damping ratio over a
## step h: (bias rate, mass scale, impulse scale). Implicit, so any frequency
## at any tick rate is stable.
static func soft_step(hertz: float, ratio: float, h: float) -> Vector3:
	var omega := TAU * hertz
	var a1 := 2.0 * ratio + h * omega
	var a2 := h * omega * a1
	var a3 := 1.0 / (1.0 + a2)
	return Vector3(omega / a1, a2 * a3, a3)


func is_taut() -> bool:
	return stretch > 0.0


## Share of breaking strength the sustained load has reached.
func share() -> float:
	return sustained / breaking


func prepare(h: float) -> void:
	point_a = a.global_position
	point_b = b.global_position
	_ra = point_a - body_a.center
	_rb = point_b - body_b.center
	var along := point_b - point_a
	var distance := along.length()
	normal = along / distance if distance > 1e-5 else Vector3.UP
	stretch = distance - length
	_beyond = distance - length * (1.0 + max_stretch)
	var arm_a := _ra.cross(normal)
	var arm_b := _rb.cross(normal)
	_turn_a = body_a.inv_inertia * arm_a
	_turn_b = body_b.inv_inertia * arm_b
	var k := normal.dot(body_a.inv_mass * normal) + arm_a.dot(_turn_a) \
		+ normal.dot(body_b.inv_mass * normal) + arm_b.dot(_turn_b)
	_mass = 1.0 / k if k > 1e-9 else 0.0
	if h != _h or _soft == Vector3.ZERO:
		_soft = soft_step(frequency, damping, h)
		_stop = soft_step(STOP_HERTZ, STOP_DAMPING, h)
	_h = h


func warm_start() -> void:
	_push(spring_impulse + stop_impulse)


func solve() -> void:
	if _mass == 0.0:
		return
	var ba := body_a
	var bb := body_b
	# How fast the ends move apart along the rope, at the attachment points.
	var rate := normal.dot(bb.velocity + bb.spin.cross(_rb) - ba.velocity - ba.spin.cross(_ra))
	var spring := 0.0
	if stretch > 0.0:
		spring = maxf(0.0, spring_impulse + _mass * _soft.y * (rate + _soft.x * stretch)
			- _soft.z * spring_impulse)
	var stop: float
	var change := spring - spring_impulse
	rate -= change / _mass
	if _beyond < 0.0:
		# Short of the stop: only pull if this tick would carry it past.
		stop = maxf(0.0, stop_impulse + _mass * (rate + _beyond / _h))
	else:
		stop = maxf(0.0, stop_impulse + _mass * _stop.y * (rate + _stop.x * _beyond)
			- _stop.z * stop_impulse)
	change += stop - stop_impulse
	spring_impulse = spring
	stop_impulse = stop
	_push(change)


## Impulse on end a this tick; end b gets its opposite.
func impulse() -> Vector3:
	return normal * (spring_impulse + stop_impulse)


## Tension pulls each end toward the other, at its attachment point.
func _push(amount: float) -> void:
	body_a.velocity += body_a.inv_mass * normal * amount
	body_a.spin += _turn_a * amount
	body_b.velocity -= body_b.inv_mass * normal * amount
	body_b.spin -= _turn_b * amount
