extends RigidBody3D
## The test floater: a light box a hover tray holds a set height over the sand.
## It catches a lot of wind and stands in for every floating camp piece. The
## tray only lifts and keeps it upright; sideways, the wind and its lines decide.

## Height of its centre above the sand.
const HOVER := 1.4
const HOVER_HERTZ := 1.0
const HOVER_DAMPING := 0.8
## Most the tray lifts, in its own weights.
const MAX_LIFT := 3.0
const UPRIGHT_HERTZ := 1.6
const UPRIGHT_DAMPING := 0.7
## How fast the air slows it spinning, 1/s.
const SPIN_DRAG := 2.0

var world: World
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _physics_process(_delta: float) -> void:
	if freeze or world == null:
		return
	var omega := TAU * HOVER_HERTZ
	var low := world.height_under(global_position) + HOVER - global_position.y
	var lift := mass * (_gravity + omega * omega * low - 2.0 * HOVER_DAMPING * omega * linear_velocity.y)
	apply_central_force(Vector3.UP * clampf(lift, 0.0, MAX_LIFT * mass * _gravity))
	# Upright like a tray on a gimbal, but free to turn: lines twist it to face the wind.
	var turn := TAU * UPRIGHT_HERTZ
	var up := global_basis.y.normalized()
	var tilt := up.cross(Vector3.UP)
	var rocking := angular_velocity - Vector3.UP * angular_velocity.y
	var moment := (inertia.x + inertia.z) * 0.5
	apply_torque(moment * (turn * turn * tilt - 2.0 * UPRIGHT_DAMPING * turn * rocking))
	# The air resists it spinning. Without this a light box on off-centre rings
	# flutters in a strong wind forever, turning to and fro on its lines.
	apply_torque(Vector3.UP * -inertia.y * angular_velocity.y * SPIN_DRAG)
