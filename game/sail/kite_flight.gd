class_name KiteFlight
extends RefCounted
## The wind sets a kite's line angle; both kinds share its sway and settling.

const SETTLE_S := 1.5
const SWAY_DEG := Vector2(6.0, 3.0)
const SWAY_RATE := Vector2(0.31, 0.47)


## Degrees above the ground: lifting, rising, then pressed back in hard wind.
static func angle(w: float, tuning: Tuning) -> float:
	if w < tuning.kite_lift_ms:
		return 0.0
	var rise := clampf((w - tuning.kite_lift_ms) / (tuning.kite_best_ms.x - tuning.kite_lift_ms), 0.0, 1.0)
	var a := lerpf(tuning.kite_angle_deg.x, tuning.kite_angle_deg.y, rise) \
		- maxf(w - tuning.kite_best_ms.y, 0.0) * tuning.kite_pressed_deg
	return clampf(a, 10.0, tuning.kite_angle_deg.y)


## Downwind and aloft; a disabled kite keeps the sideways sway but no lift.
static func direction(w: Vector2, t: float, phase: float, tuning: Tuning, enabled := true) -> Vector3:
	var along := w.normalized() if w.length() > 0.01 else Vector2(0.0, 1.0)
	var round := deg_to_rad(SWAY_DEG.x) * sin(t * SWAY_RATE.x + phase)
	along = along.rotated(round)
	var a := deg_to_rad(angle(w.length(), tuning)) if enabled else 0.0
	a += deg_to_rad(SWAY_DEG.y) * sin(t * SWAY_RATE.y + phase * 2.0) * (1.0 if a > 0.0 else 0.0)
	return Vector3(along.x, 0.0, along.y) * cos(a) + Vector3.UP * sin(a)


static func settling(delta: float) -> float:
	return 1.0 - exp(-delta / SETTLE_S)


## Aloft cloth wear per world second, including the sand a storm carries.
static func wear_rate(speed: float, storm: float, tuning: Tuning) -> float:
	return 1.0 / tuning.kite_wear_s + tuning.kite_wear_wind * maxf(speed - tuning.kite_harm_ms, 0.0) \
		+ (1.0 / tuning.kite_storm_ruin_s if storm > 0.0 else 0.0)
