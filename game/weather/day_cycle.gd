class_name DayCycle
extends RefCounted
## The 20-minute day. The moon has no axial tilt, so the sun rises due east,
## sets due west, and climbs only as high as the latitude allows.

var _day_seconds: float
var _start: float


func _init(tuning: Tuning) -> void:
	_day_seconds = tuning.day_minutes * 60.0
	_start = tuning.start_time_of_day


## 0 at midnight, 0.5 at noon.
func time_of_day(t: float) -> float:
	return fposmod(_start + t / _day_seconds, 1.0)


## Whole days since the run began, counting the first as day 1.
func day(t: float) -> int:
	return floori(_start + t / _day_seconds) + 1


## Unit vector toward the sun in engine axes (x east, y up, -z north).
func sun_direction(t: float, latitude: float) -> Vector3:
	var hour_angle := (time_of_day(t) - 0.5) * TAU
	var east := -sin(hour_angle)
	var north := -cos(hour_angle) * sin(latitude)
	var up := cos(hour_angle) * cos(latitude)
	return Vector3(east, up, -north)


## Sunlight on open ground, 0 to 1, before the weather takes its share.
func sunlight(t: float, latitude: float) -> float:
	return maxf(0.0, sun_direction(t, latitude).y)
