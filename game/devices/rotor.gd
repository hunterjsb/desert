class_name Rotor
extends MeshInstance3D
## A turbine's hub and blades on its mast head. Only drawn: it touches nothing
## and the simulation never reads it. It turns as the turbine makes power, read
## off the power tick, and swings round on the mast to face into the wind.

## Its speed at the turbine's rating, turns a second: brisk, but still two
## blades, not a blur.
const TOP_HERTZ := 2.0
## It has weight: how long it takes to come up to a new speed or run down, s.
const SPIN_SECONDS := 1.5
## How long it takes to swing round into a new wind, s.
const YAW_SECONDS := 2.0
## Slower than this, with nothing driving it, it has stopped.
const STILL_HERTZ := 0.02
## Further from the eye than this, nobody sees it turn, m.
const SEEN_M := 150.0

var _device: Device
var _hertz := 0.0
var _turned := 0.0
var _yaw := 0.0


func _ready() -> void:
	_device = get_parent() as Device


func _process(delta: float) -> void:
	# A rotor turns with the wind, and its power goes with the wind cubed, so
	# its speed goes with the cube root of its share of the rating.
	var goal := 0.0 if _device.wrecked() else TOP_HERTZ * pow(_device.turbine_share, 1.0 / 3.0)
	if goal == 0.0 and _hertz == 0.0:
		return
	var eye := get_viewport().get_camera_3d()
	if eye == null or eye.global_position.distance_squared_to(global_position) > SEEN_M * SEEN_M:
		return
	_hertz = lerpf(goal, _hertz, exp(-delta / SPIN_SECONDS))
	if goal == 0.0 and _hertz < STILL_HERTZ:
		_hertz = 0.0
	_turned = fmod(_turned + TAU * _hertz * delta, TAU)
	# The wind in the frame's own axes, however it stands.
	var wind := _device.global_basis.inverse() * _device.turbine_wind
	if wind.x != 0.0 or wind.z != 0.0:
		_yaw = lerp_angle(_yaw, atan2(-wind.x, -wind.z), 1.0 - exp(-delta / YAW_SECONDS))
	# Clockwise, seen from upwind.
	basis = Basis(Vector3.UP, _yaw) * Basis(Vector3.FORWARD, _turned)
