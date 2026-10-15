class_name Grasp
extends RefCounted
## Your hands on something too heavy to carry. Taken, it's kept where it was
## beside you, turned as it was, as you walk and turn, as hard as your
## strength allows: a floating thing comes along and turns as you turn, and
## one on the sand drags if you can beat its friction. Only sideways and about
## the vertical: its weight and hover keep its height and keep it level. Walk
## off from what you can't shift and it slips from your hands. It pulls back on
## you the way a line does, so hauling something heavy digs you in.

## Held farther than hold_slip from where you'd have it this long, it slips, s.
const SLIP_SECONDS := 0.5
## Your hands turn it as if gripping it this far from its middle, m: a lever on
## your strength.
const LEVER := 0.5

var body: RigidBody3D
var _player: Player
## Where it sits beside you and how it's turned, in your flat frame.
var _beside := Vector3.ZERO
var _turned := 0.0
var _heading := 0.0
var _slipping := 0.0


func _init(player: Player) -> void:
	_player = player


func take(what: RigidBody3D) -> void:
	body = what
	_heading = _player.global_rotation.y
	var off := what.global_position - _player.global_position
	off.y = 0.0
	_beside = Basis(Vector3.UP, -_heading) * off
	_turned = angle_difference(_heading, what.global_rotation.y)
	_slipping = 0.0
	what.sleeping = false


func let_go() -> void:
	body = null


## One physics tick: steers it toward where you'd have it, moving and turning
## with you, the same share of the way each second at any tick rate.
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
	var beside := Basis(Vector3.UP, heading) * _beside
	var off := _player.global_position + beside - body.global_position
	off.y = 0.0
	_slipping = _slipping + h if off.length() > tuning.hold_slip else 0.0
	if _slipping > SLIP_SECONDS:
		body = null
		return
	var share := 1.0 - exp(-tuning.hold_rate * h)
	var mine := _player.velocity + Vector3.UP.cross(beside) * turning
	var miss := mine + (off * tuning.hold_rate).limit_length(tuning.hold_speed) - body.linear_velocity
	miss.y = 0.0
	var force := (miss * body.mass * share / h).limit_length(tuning.hand_strength)
	body.apply_central_force(force)
	_player.world.ropes.pull_player(-force * h)
	var state := PhysicsServer3D.body_get_direct_state(body.get_rid())
	var spin_give := maxf((state.inverse_inertia_tensor * Vector3.UP).dot(Vector3.UP), 1e-6)
	var swing := angle_difference(body.global_rotation.y, heading + _turned)
	var twist := (turning + swing * tuning.hold_rate - body.angular_velocity.y) * share / (h * spin_give)
	var most := tuning.hand_strength * LEVER
	body.apply_torque(Vector3.UP * clampf(twist, -most, most))
