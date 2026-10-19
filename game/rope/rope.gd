class_name Rope
extends RefCounted
## One rope: a single constraint that does all the holding, and the strand that
## draws it. Both use `length`. The rope has weight, so it hangs in a catenary
## and pulls a little even short of its length; the pull straightens it, then
## a spring defined by how fast it springs back and how much it bounces takes
## over. Solved from both ends' masses with Catto's soft step, so it can only
## take energy out. A hard stop sits at max_stretch. Tension pulls both ends
## equally, at the attachment points. It never pulls past its strength: asked
## for more, it gives at that and stretches, and asked for it long enough, it
## parts.

## The hard stop's own softness: stiff enough to read as a wall, soft enough
## that hitting it never kicks back.
const STOP_HERTZ := 20.0
const STOP_DAMPING := 1.0
## Fastest the rope pulls its ends together, m/s, however far it's stretched:
## a loose end snagged while the other end drives on is dragged free, never
## slung, by the stop or the spring. The stop still keeps them from parting
## any further at once.
const CLOSING_SPEED := 3.0
## Drooping this far short of its length, as a share of it, a line pulls
## nothing: its weight lies on the sand or hangs off its ends.
const SLACK_SHARE := 0.1

var a: RopeEnd
var b: RopeEnd
## The ring it runs through between them, or null.
var through: RopeEnd
## Where a's pull lands, if not at a: a sheet's at the block it runs
## through, on its way from the boom's end; and b's.
var at_a: RopeEnd
var at_b: RopeEnd
var length: float
## All there is of it, m: paid out, it lengthens no further.
var full: float
## Still feeding off its coil, so it reaches as far as all of it.
var paying := false
## Its own weight, kg per metre; 0 is the look-test's weightless line.
var kg_per_m := 0.0
## Springs back this many times a second when stretched, whatever hangs on it.
var frequency := 3.0
## 1 settles without bouncing; below 1 it bounces.
var damping := 0.7
## Share of length it stretches before the hard stop.
var max_stretch := 0.1
## Newtons of sustained load that snap it.
var breaking := 1500.0
## Called with the two halves' strands when it snaps, if whatever owns it
## makes something of them.
var parted := Callable()
## Called instead of snapping when its load passes breaking, if whatever owns
## it gives way some other way, as a hose pops an end out of its socket.
var gives := Callable()
## Called with each step it's reeled, m, before its length changes, if
## whatever owns it takes some of the line in another way, as a sheet hauls
## its sail in; returns what's left of the step for the line itself.
var hauls := Callable()
## While it takes the line in that way: what that pulls against, N, and how
## much of it lies gathered on you from there, m.
var haul_n := 0.0
var haul_gathered := 0.0

## Pull this tick, never past breaking; what holding would have taken; and
## that load sustained long enough to break things, N.
var tension := 0.0
var asked := 0.0
var sustained := 0.0
var strand: RopeStrand
var creak: AudioStreamPlayer3D
## How strained the creak sounds, 0 to 1, eased toward the strain.
var creak_level := 0.0

## Solver state for this tick, owned by Ropes.
var body_a: RopeBody
var body_b: RopeBody
var body_p: RopeBody
## Which way it leaves a, and which way it comes into b: the same but through
## a ring, where it bends by their difference.
var normal := Vector3.UP
var normal_b := Vector3.UP
var point_a := Vector3.ZERO
var point_b := Vector3.ZERO
var point_p := Vector3.ZERO
## How far the spring is from letting go, m: past it, it pulls.
var stretch := 0.0
## How far the middle hangs below the line between its ends, by its weight and
## the pull, m; NAN for a weightless line, which the strand drapes by its length.
var sag := NAN
## Spring and stop impulses, N·s. Kept between ticks to warm-start the next.
var spring_impulse := 0.0
var stop_impulse := 0.0

var _ra := Vector3.ZERO
var _rb := Vector3.ZERO
var _rp := Vector3.ZERO
var _turn_a := Vector3.ZERO
var _turn_b := Vector3.ZERO
var _turn_p := Vector3.ZERO
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


## Stretched to twice its length: past anything a rope survives.
func torn() -> bool:
	return _beyond > length * (1.0 - max_stretch)


## Share of breaking strength the sustained load has reached.
func share() -> float:
	return sustained / breaking


func prepare(h: float, gravity: float) -> void:
	point_a = (at_a if at_a != null else a).global_position
	point_b = (at_b if at_b != null else b).global_position
	_ra = point_a - body_a.center
	_rb = point_b - body_b.center
	var distance: float
	if through != null:
		point_p = through.global_position
		_rp = point_p - body_p.center
		var one := point_p - point_a
		var two := point_b - point_p
		normal = one.normalized() if one.length() > 1e-5 else Vector3.UP
		normal_b = two.normalized() if two.length() > 1e-5 else normal
		distance = one.length() + two.length()
	else:
		var along := point_b - point_a
		distance = along.length()
		normal = along / distance if distance > 1e-5 else Vector3.UP
		normal_b = normal
	_beyond = distance - length * (1.0 + max_stretch)
	asked = 0.0
	var arm_a := _ra.cross(normal)
	var arm_b := _rb.cross(normal_b)
	_turn_a = body_a.inv_inertia * arm_a
	_turn_b = body_b.inv_inertia * arm_b
	var k := normal.dot(body_a.inv_mass * normal) + arm_a.dot(_turn_a) \
		+ normal_b.dot(body_b.inv_mass * normal_b) + arm_b.dot(_turn_b)
	if through != null:
		var turned := bend()
		var arm_p := _rp.cross(turned)
		_turn_p = body_p.inv_inertia * arm_p
		k += turned.dot(body_p.inv_mass * turned) + arm_p.dot(_turn_p)
	_mass = 1.0 / k if k > 1e-9 else 0.0
	if h != _h or _stop == Vector3.ZERO:
		_stop = soft_step(STOP_HERTZ, STOP_DAMPING, h)
	_h = h
	var weight := kg_per_m * gravity
	if weight <= 0.0 or _mass == 0.0:
		stretch = distance - length
		sag = NAN
		_soft = soft_step(frequency, damping, h)
		return
	# Hanging: the spring is linearised about where the ends are now, with the
	# stiffness the catenary and the stretch have there, so it settles exactly
	# where the full law says at any tick rate.
	var spring := _mass * (TAU * frequency) ** 2
	var c := weight * weight * length * length * length / 24.0
	var pull := catenary_pull(distance, length, c, spring)
	sag = weight * distance * distance / (8.0 * pull)
	var stiff := 1.0 / (2.0 * c / (pull * pull * pull) + 1.0 / spring)
	pull -= sqrt(c / (SLACK_SHARE * length))
	stretch = pull / stiff
	if pull <= 0.0:
		# Too slack for the shallow catenary: the strand drapes it by its length.
		sag = NAN
	_soft = soft_step(sqrt(stiff / _mass) / TAU, damping, h)


## The pull, N, on a line of this length and weight (c = w²L³/24, w in N/m)
## whose ends are `chord` apart, sagging and stretching as a spring of
## stiffness `spring`: chord = length - c/pull² + pull/spring. The shallow
## catenary, so it holds while the sag is a small share of the span.
static func catenary_pull(chord: float, line: float, c: float, spring: float) -> float:
	# Started right of the answer: the first step lands left of it, and the
	# law is concave, so every step after closes in from the left.
	var pull := pow(c * spring, 1.0 / 3.0) + spring * maxf(chord - line, 0.0)
	if chord < line:
		pull = minf(pull, sqrt(c / (line - chord)))
	for i in 8:
		var off := line - c / (pull * pull) + pull / spring - chord
		pull -= off / (2.0 * c / (pull * pull * pull) + 1.0 / spring)
		if absf(off) < 1e-7 * line:
			break
	return pull


func warm_start() -> void:
	_push(spring_impulse + stop_impulse)


func solve() -> void:
	if _mass == 0.0:
		return
	var ba := body_a
	var bb := body_b
	# How fast the ends move apart along the rope, at the attachment points.
	var rate := normal_b.dot(bb.velocity + bb.spin.cross(_rb)) - normal.dot(ba.velocity + ba.spin.cross(_ra))
	# Against the ends as they move, not as the rope expects them to: a snag can
	# push back harder than it credits, and lets go all at once.
	var expected := normal_b.dot(bb.expected + bb.expected_spin.cross(_rb)) - normal.dot(ba.expected + ba.expected_spin.cross(_ra))
	if through != null:
		var bp := body_p
		var turned := bend()
		rate -= turned.dot(bp.velocity + bp.spin.cross(_rp))
		expected -= turned.dot(bp.expected + bp.expected_spin.cross(_rp))
	var most := _mass * (rate - expected + CLOSING_SPEED)
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
		stop = maxf(0.0, stop_impulse + _mass * _stop.y * (rate + minf(_stop.x * _beyond, CLOSING_SPEED))
			- _stop.z * stop_impulse)
	change += stop - stop_impulse
	if change > most:
		# Closing as fast as it may, nothing parts: the stop gives way first.
		var over := change - most
		var eased := minf(over, stop)
		stop -= eased
		spring = maxf(0.0, spring - (over - eased))
		change = spring - spring_impulse + stop - stop_impulse
	asked = maxf(asked, (spring + stop) / _h)
	var most_pull := breaking * _h
	if spring + stop > most_pull:
		# Past its strength it gives at that, the stop first.
		var past := spring + stop - most_pull
		var given := minf(past, stop)
		stop -= given
		spring -= past - given
		change = spring - spring_impulse + stop - stop_impulse
	spring_impulse = spring
	stop_impulse = stop
	_push(change)


## Impulse on end a this tick; end b gets its opposite, along the way it comes in.
func impulse() -> Vector3:
	return normal * (spring_impulse + stop_impulse)


func impulse_b() -> Vector3:
	return -normal_b * (spring_impulse + stop_impulse)


## What the ring it runs through takes, per unit of pull: the bend, nothing
## while it runs straight.
func bend() -> Vector3:
	return normal_b - normal


## Tension pulls each end toward the other, at its attachment point; a ring
## between is pushed into the bend.
func _push(amount: float) -> void:
	body_a.velocity += body_a.inv_mass * normal * amount
	body_a.spin += _turn_a * amount
	body_b.velocity -= body_b.inv_mass * normal_b * amount
	body_b.spin -= _turn_b * amount
	if through != null:
		body_p.velocity += body_p.inv_mass * bend() * amount
		body_p.spin += _turn_p * amount
