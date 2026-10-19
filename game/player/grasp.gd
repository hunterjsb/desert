class_name Grasp
extends RefCounted
## Your hands on something too heavy to carry. Taken, it's kept where it was
## beside you, turned as it was, as you walk and turn, as hard as your
## strength allows: a floating thing comes along and turns as you turn, and
## one on the sand drags if you can beat its friction. It rises and sinks as
## you look up and down, so you can lift it, or haul it up a slope, if you can
## take its weight; your hands only ever lift, and its weight lets it down.
## Rotate turns how you'd have it, so you roll a tipped thing back upright.
## Walk off from what you can't shift and it slips from your hands. It pulls
## back on you the way a line does, so hauling something heavy digs you in.
## The dev console's god has the strength for anything, and is never dug in.

## Held farther than hold_slip from where you'd have it this long, it slips, s.
const SLIP_SECONDS := 0.5
## Your hands turn it as if gripping it this far from its middle, m: a lever on
## your strength.
const LEVER := 0.5
## Its speed catches up this many times faster than its place does, so it
## settles where you'd have it without swinging past.
const DAMPED := 3.0
## You lift it no higher than this above your eyes, m, unless it was higher
## when you took hold of it.
const OVERHEAD := 0.3
## How you'd have it turned runs at most this far ahead of how it is, rad: a
## turn it can't follow is lost, not wound up.
const LEAD := PI / 2.0

var body: RigidBody3D
var _player: Player
## Where it sits beside you, in your flat frame, and how far from your eyes.
var _beside := Vector3.ZERO
var _reach := 0.0
## How far above your look it sits, rad, and the highest above your eyes you'd lift it, m.
var _above := 0.0
var _highest := OVERHEAD
## How it's turned in your flat frame.
var _hold := Basis.IDENTITY
var _heading := 0.0
var _slipping := 0.0
## It just slipped from your hands, for the hands to say so.
var slipped := false


func _init(player: Player) -> void:
	_player = player


func take(what: RigidBody3D) -> void:
	body = what
	_heading = _player.global_rotation.y
	var flat := Basis(Vector3.UP, -_heading)
	var off := what.global_position - _player.global_position
	off.y = 0.0
	_beside = flat * off
	var seen := what.global_position - _eye()
	_reach = seen.length()
	_above = atan2(seen.y, Vector2(seen.x, seen.z).length()) - _player.camera.rotation.x
	_highest = maxf(seen.y, OVERHEAD)
	_hold = flat * what.global_basis.orthonormalized()
	_slipping = 0.0
	what.sleeping = false


func let_go() -> void:
	body = null


## Rotate: turns how you'd have it by `by`, a turn in your flat frame.
func turn(by: Basis) -> void:
	_hold = (by * _hold).orthonormalized()


## Reel in or pay out: where you'd have it comes `by` m nearer, or goes
## farther for a negative `by`, between `nearest` and `farthest` from you;
## your strength and the slip still say whether it follows.
func bring(by: float, nearest: float, farthest: float) -> void:
	var now := _beside.length()
	if now < 1e-3:
		return
	var to := clampf(now - by, minf(nearest, now), maxf(farthest, now))
	_beside *= to / now
	_reach *= to / now


## What a save keeps of it, and puts back: everything else comes from where
## it and you are.
func memory() -> Dictionary:
	return {"beside": _beside, "reach": _reach, "above": _above, "highest": _highest, "hold": _hold,
		"heading": _heading, "slipping": _slipping}


func recall(what: RigidBody3D, kept: Dictionary) -> void:
	take(what)
	_beside = kept.get("beside", _beside)
	_reach = kept.get("reach", _reach)
	_above = kept.get("above", _above)
	_highest = kept.get("highest", _highest)
	_hold = kept.get("hold", Basis(Vector3.UP, kept.turned) if kept.has("turned") else _hold)
	_heading = kept.get("heading", _heading)
	_slipping = kept.get("slipping", _slipping)


## One physics tick: steers it toward where you'd have it, moving and turning
## with you, its place the same share of the way each second at any tick rate.
func step(h: float) -> void:
	if body == null:
		return
	if not is_instance_valid(body) or body.freeze:
		body = null
		return
	var tuning := _player.world.tuning
	var heading := _player.global_rotation.y
	var turning := angle_difference(_heading, heading) / h
	_heading = heading
	var facing := Basis(Vector3.UP, heading)
	var beside := facing * _beside
	var off := _player.global_position + beside - body.global_position
	off.y = _eye().y + _rise() - body.global_position.y
	_slipping = _slipping + h if Vector2(off.x, off.z).length() > tuning.hold_slip else 0.0
	if _slipping > SLIP_SECONDS:
		body = null
		slipped = true
		return
	var share := 1.0 - exp(-tuning.hold_rate * DAMPED * h)
	var mine := Vector3(_player.velocity.x, 0.0, _player.velocity.z) + Vector3.UP.cross(beside) * turning
	var miss := mine + (off * tuning.hold_rate).limit_length(tuning.hold_speed) - body.linear_velocity
	var force := miss * body.mass * share / h
	# On the sand it's never pressed in, so dragging is no harder for looking down.
	force.y = maxf(force.y, 0.0)
	var god := _player.vitals.god
	if not god:
		force = force.limit_length(tuning.hand_strength)
	body.apply_central_force(force)
	if not god:
		_player.world.ropes.pull_player(-Vector3(force.x, 0.0, force.z) * h)

	var now := body.global_basis.orthonormalized()
	var as_held := (facing.inverse() * now).get_rotation_quaternion()
	var wanted := _hold.get_rotation_quaternion()
	var ahead := as_held.angle_to(wanted)
	if ahead > LEAD:
		_hold = Basis(as_held.slerp(wanted, LEAD / ahead))
	var swing := _turn_between(now, facing * _hold)
	var spin := Vector3.UP * turning + (swing * tuning.hold_rate).limit_length(tuning.hold_speed / LEVER)
	# Its spin is set the whole way each tick, not a share: on the sand it turns
	# against friction and tips about an edge, lifting its own weight, and a
	# gentler turn would stall short on a light thing.
	var state := PhysicsServer3D.body_get_direct_state(body.get_rid())
	var twist := state.inverse_inertia_tensor.inverse() * (spin - body.angular_velocity) / h
	body.apply_torque(twist if god else twist.limit_length(tuning.hand_strength * LEVER))


## Where you'd have it above your eyes, m: as far up or down as you look, at
## the reach you took it at.
func _rise() -> float:
	var up := clampf(_player.camera.rotation.x + _above, -PI / 2.0, PI / 2.0)
	return minf(_reach * sin(up), _highest)


## Your eyes as the tick knows them, steady of any sway.
func _eye() -> Vector3:
	return _player.global_transform * _player.feel.steady_eye()


## The turn from one way to another, as an axis scaled by its angle, rad.
static func _turn_between(from: Basis, to: Basis) -> Vector3:
	var q := (to * from.inverse()).get_rotation_quaternion()
	if q.w < 0.0:
		q = -q
	var axis := Vector3(q.x, q.y, q.z)
	var s := axis.length()
	return axis * (2.0 * atan2(s, q.w) / s) if s > 1e-9 else axis * 2.0
