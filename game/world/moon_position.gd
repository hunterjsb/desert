class_name MoonPosition
extends RefCounted
## The player's true point on the moon, dead-reckoned from movement on the flat
## ground. Circling is shorter near the poles, and walking over a pole brings you
## down the other side with north becoming south.

var radius: float
var latitude: float
var longitude: float

var _spawn_latitude: float
var _spawn_longitude: float
## Flips each time you cross a pole: straight ahead on the ground is now the other way.
var _facing := 1.0


func _init(tuning: Tuning) -> void:
	radius = tuning.moon_circumference / TAU
	latitude = deg_to_rad(tuning.spawn_latitude_degrees)
	longitude = deg_to_rad(tuning.spawn_longitude_degrees)
	_spawn_latitude = latitude
	_spawn_longitude = longitude


func advance(east: float, north: float) -> void:
	latitude += _facing * north / radius
	if latitude > PI / 2 or latitude < -PI / 2:
		latitude = signf(latitude) * PI - latitude
		longitude += PI
		_facing = -_facing
	var circle := cos(latitude)
	if circle > 1e-9:
		longitude += _facing * east / (radius * circle)
	longitude = wrapf(longitude, -PI, PI)


## Which way the moon's north lies on the ground, engine axes: -z, turned
## round each time you walk over a pole.
func north() -> Vector3:
	return Vector3(0.0, 0.0, -_facing)


## Metres from spawn, measured round the moon.
func distance_from_spawn() -> float:
	var d_lat := latitude - _spawn_latitude
	var d_lon := longitude - _spawn_longitude
	var a := sin(d_lat / 2) ** 2 + cos(_spawn_latitude) * cos(latitude) * sin(d_lon / 2) ** 2
	return 2.0 * radius * asin(minf(1.0, sqrt(a)))
