class_name Satellite
extends RefCounted
## The relay: an old colonial relay satellite still in orbit, still playing
## the port's music station on its loop. Loosely simulated: a quick circular
## orbit high over Zan, tilted by the seed (backwards round half the time),
## so it crosses the night sky far faster than the stars, while the moon turns under it once a
## day, so it rises and sets and each pass crosses the sky somewhere new. It
## starts each run passing over where the run began. A radio hears it only
## while it's over the horizon, faint low down, and its carrier slides a
## little as it comes and goes (a Doppler shift, made audible).

## How far its orbit's tilt can be from the equator, degrees.
const TILT := Vector2(25.0, 65.0)

var radius: float
var altitude: float
var period: float
var day_seconds: float

## The orbit as two axes in its plane, in the moon's frame at the run's start
## (x toward 0° longitude, y toward 90° east, z north), and where on it the
## relay was then, rad.
var _node: Vector3
var _across: Vector3
var _phase: float


## Its orbit for a run, passing over `start` (a point on the sphere) at world time 0.
func _init(run_seed: int, tuning: Tuning, start: Vector3) -> void:
	radius = tuning.moon_circumference / TAU
	altitude = tuning.relay_altitude_radii
	period = tuning.relay_period_minutes * 60.0
	day_seconds = tuning.day_minutes * 60.0
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([run_seed, "relay"])
	var latitude := Sphere.latitude(start)
	var tilt := maxf(deg_to_rad(rng.randf_range(TILT.x, TILT.y)), absf(latitude) + 0.01)
	if rng.randf() < 0.5:
		tilt = PI - tilt
	# Where on a tilted circle a point at that latitude lies, and the node that puts it under start.
	_phase = asin(clampf(sin(latitude) / sin(tilt), -1.0, 1.0))
	var node_longitude := Sphere.longitude(start) - atan2(cos(tilt) * sin(_phase), cos(_phase))
	_node = Vector3(cos(node_longitude), sin(node_longitude), 0.0)
	_across = Vector3(-sin(node_longitude) * cos(tilt), cos(node_longitude) * cos(tilt), sin(tilt))


## The point on the sphere it's over at world time t, in the moon's frame:
## round its orbit, less the turn the moon has made under it since.
func under(t: float) -> Vector3:
	var at := _phase + TAU * t / period
	var inertial := _node * cos(at) + _across * sin(at)
	return inertial.rotated(Vector3(0.0, 0.0, 1.0), -TAU * t / day_seconds).normalized()


## Where it is, seen from a point on the sphere at world time t: {elevation
## (rad over the horizon), bearing (rad clockwise from north there), metres
## (the slant range), rate (m/s it's drawing away, less as it nears)}.
func seen_from(p: Vector3, t: float) -> Dictionary:
	var now := _from(p, t)
	var later := _from(p, t + 1.0)
	return {"elevation": now.elevation, "bearing": Sphere.bearing(p, under(t)), "metres": now.metres,
		"rate": later.metres - now.metres}


## Whether the sun lights it at world time t, or it's in Zan's shadow:
## behind the moon from the sun and within the moon's width of the line to it.
func sunlit(t: float, sun: Vector3) -> bool:
	var at := under(t) * (1.0 + altitude)
	return at.dot(sun) > 0.0 or (at - sun * at.dot(sun)).length() > 1.0


## The fastest it ever draws away or nears, m/s: for scaling its slide.
func top_rate() -> float:
	return TAU * radius * ((1.0 + altitude) / period + 1.0 / day_seconds)


func _from(p: Vector3, t: float) -> Dictionary:
	var to := under(t) * (1.0 + altitude) - p
	return {"elevation": asin(clampf(to.normalized().dot(p), -1.0, 1.0)), "metres": to.length() * radius}
